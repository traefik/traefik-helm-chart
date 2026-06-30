{{/*
Default Hub image. Tag follows the `traefik.io/hub-max-version` Chart.yaml
annotation (mirrors traefik-helm-chart#1791); ghcr.io is the canonical registry.
*/}}
{{- define "traefik.hubImageDefault" -}}
{{- $tag := index .Chart.Annotations "traefik.io/hub-max-version" -}}
ghcr.io/traefik/traefik-hub:{{ $tag }}
{{- end -}}

{{/*
Mount path for the Hub token Secret. Chart auto-sets `traefik.hub.tokenfilepath`
to <hubTokenMountPath>/token so traefik.yaml never holds the inline token.
*/}}
{{- define "traefik.hubTokenMountPath" -}}/etc/secrets{{- end -}}

{{- define "traefik.hubTokenFilePath" -}}{{- include "traefik.hubTokenMountPath" . -}}/token{{- end -}}

{{/*
Non-empty when an inline Hub license token is set (.Values.traefik.hub.token).
Gates the hub-license Secret, its volumeMount, and the auto-injected tokenfilepath.
*/}}
{{- define "traefik.hubTokenInline" -}}
{{- $hub := (.Values.traefik | default dict).hub | default dict -}}
{{- $hub.token | default "" -}}
{{- end -}}

{{/*
True when a `traefik.hub` block is present (inline token or BYO Secret).
Gates Hub-wide concerns like the extra RBAC.
*/}}
{{- define "traefik.hubEnabled" -}}
{{- if hasKey (.Values.traefik | default dict) "hub" -}}true{{- end -}}
{{- end -}}

{{/*
True when traefik.hub.apimanagement is present (presence-as-enable).
Gates apimanagement k8s objects (admissionWebhookService, apiPortalService, MWCs).
*/}}
{{- define "traefik.hubAPIManagementEnabled" -}}
{{- $hub := (.Values.traefik | default dict).hub | default dict -}}
{{- if hasKey $hub "apimanagement" -}}true{{- end -}}
{{- end -}}

{{/*
True when traefik.hub.apimanagement.admission is present. Gates the
admission webhook Secret, Service, MWCs, and admission containerPort.
*/}}
{{- define "traefik.hubAdmissionEnabled" -}}
{{- $apim := (((.Values.traefik | default dict).hub | default dict).apimanagement | default dict) -}}
{{- if hasKey $apim "admission" -}}true{{- end -}}
{{- end -}}

{{/*
Admission webhook port from listenaddr (default 0.0.0.0:9943).
*/}}
{{- define "traefik.hubAdmissionContainerPort" -}}
{{- $admission := (((.Values.traefik | default dict).hub | default dict).apimanagement | default dict).admission | default dict -}}
{{- $listen := $admission.listenaddr | default "0.0.0.0:9943" -}}
{{- last (splitList ":" $listen) -}}
{{- end -}}

{{/*
Names of chart-managed Hub objects (chart-owned).
*/}}
{{- define "traefik.admissionWebhookSecretName" -}}
{{- printf "%s-hub-admission-cert" (include "traefik.fullname" .) -}}
{{- end -}}

{{- define "traefik.admissionWebhookServiceName" -}}
{{- printf "%s-hub-admission" (include "traefik.fullname" .) -}}
{{- end -}}

{{- define "traefik.apiPortalServiceName" -}}
{{- printf "%s-hub-apiportal" (include "traefik.fullname" .) -}}
{{- end -}}

{{/*
TLS cert + key for the admission webhook, returned base64-encoded for Secret.data.
Reuses the existing Secret via `lookup` (stable across upgrades), else generates a
self-signed cert. `helm template` (no API access) always regenerates — expected.
*/}}
{{- define "traefik.admissionWebhookCert" -}}
{{- $name := include "traefik.admissionWebhookSecretName" . -}}
{{- $ns := include "traefik.namespace" . -}}
{{- $existing := lookup "v1" "Secret" $ns $name -}}
{{- if and $existing (hasKey ($existing.data | default dict) "tls.crt") (hasKey ($existing.data | default dict) "tls.key") -}}
cert: {{ index $existing.data "tls.crt" }}
key: {{ index $existing.data "tls.key" }}
{{- else -}}
{{- $svc := include "traefik.admissionWebhookServiceName" . -}}
{{- $cn := printf "%s.%s.svc" $svc $ns -}}
{{- $san := list $cn (printf "%s.%s.svc.cluster.local" $svc $ns) -}}
{{- $ca := genCA (printf "%s-ca" $svc) 3650 -}}
{{- $cert := genSignedCert $cn nil $san 3650 $ca -}}
cert: {{ $cert.Cert | b64enc }}
key: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}

{{/*
Default MutatingWebhookConfiguration bodies shipped under API Management.
Map of name → body (just the `webhooks:` array; other fields added by the template).
Override per-entry via `mutatingWebhookConfigurations.<name>` (JSON Merge Patch).
*/}}
{{- define "traefik.mutatingWebhookConfigurationsDefaults" -}}
{{- $svc := include "traefik.admissionWebhookServiceName" . -}}
{{- $ns := include "traefik.namespace" . -}}
{{- $cert := include "traefik.admissionWebhookCert" . | fromYaml -}}
{{- $apiResources := list
    (dict "name" "api"                  "endpoint" "/api"                  "resource" "apis")
    (dict "name" "bundle"               "endpoint" "/api-bundle"           "resource" "apibundles")
    (dict "name" "catalog-item"         "endpoint" "/api-catalog-item"     "resource" "apicatalogitems")
    (dict "name" "managed-subscription" "endpoint" "/managed-subscription" "resource" "managedsubscriptions")
    (dict "name" "plan"                 "endpoint" "/api-plan"             "resource" "apiplans")
    (dict "name" "portal"               "endpoint" "/api-portal"           "resource" "apiportals")
    (dict "name" "version"              "endpoint" "/api-version"          "resource" "apiversions")
-}}
hub-acp:
  webhooks:
    - name: admission.traefik.svc
      clientConfig:
        service:
          name: {{ $svc }}
          namespace: {{ $ns }}
          path: /acp
        caBundle: {{ $cert.cert }}
      sideEffects: None
      admissionReviewVersions: [v1]
      rules:
        - operations: [CREATE, UPDATE, DELETE]
          apiGroups: [hub.traefik.io]
          apiVersions: [v1alpha1]
          resources: [accesscontrolpolicies]
hub-api:
  webhooks:
{{- range $r := $apiResources }}
    - name: hub-agent.traefik.{{ $r.name }}
      clientConfig:
        service:
          name: {{ $svc }}
          namespace: {{ $ns }}
          path: {{ $r.endpoint }}
        caBundle: {{ $cert.cert }}
      sideEffects: None
      admissionReviewVersions: [v1]
      rules:
        - operations: [CREATE, UPDATE, DELETE]
          apiGroups: [hub.traefik.io]
          apiVersions: [v1alpha1]
          resources: [{{ $r.resource }}]
{{- end }}
{{- end -}}

