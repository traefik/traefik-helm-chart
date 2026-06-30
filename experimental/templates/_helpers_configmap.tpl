{{- define "traefik.mergedConfig" -}}
{{- $merged := deepCopy (.Values.traefik | default dict) -}}

{{/*
Hub: an inline token is stripped from the config (it lands in the hub-license
Secret) and tokenfilepath is auto-set so traefik-hub reads it from the mounted
file. User can still override tokenfilepath under traefik.hub.
*/}}
{{- if include "traefik.hubTokenInline" . -}}
  {{- $hub := $merged.hub | default dict -}}
  {{- $_ := unset $hub "token" -}}
  {{- if not (hasKey $hub "tokenfilepath") -}}
    {{- $_ := set $hub "tokenfilepath" (include "traefik.hubTokenFilePath" .) -}}
  {{- end -}}
  {{- $_ := set $merged "hub" $hub -}}
{{- end -}}

{{/*
Hub apimanagement: auto-set the admission webhook secretname to match the
chart-rendered Secret. Honors a user override under
traefik.hub.apimanagement.admission.
*/}}
{{- if include "traefik.hubAdmissionEnabled" . -}}
  {{- $hub := $merged.hub | default dict -}}
  {{- $apim := $hub.apimanagement | default dict -}}
  {{- $admission := $apim.admission | default dict -}}
  {{- if not (hasKey $admission "secretname") -}}
    {{- $_ := set $admission "secretname" (include "traefik.admissionWebhookSecretName" .) -}}
    {{- $_ := set $apim "admission" $admission -}}
    {{- $_ := set $hub "apimanagement" $apim -}}
    {{- $_ := set $merged "hub" $hub -}}
  {{- end -}}
{{- end -}}

{{/*
kubernetesIngress: default ingressEndpoint to the chart's own Service
(<namespace>/<fullname>) so Ingress objects get the Traefik address in their
status (like the legacy chart). Skipped if the provider is absent or the user
set ingressEndpoint.
*/}}
{{- $providers := $merged.providers | default dict -}}
{{- if hasKey $providers "kubernetesIngress" -}}
  {{- $ki := $providers.kubernetesIngress | default dict -}}
  {{- if not (hasKey $ki "ingressEndpoint") -}}
    {{- $_ := set $ki "ingressEndpoint" (dict "publishedService" (printf "%s/%s" (include "traefik.namespace" .) (include "traefik.fullname" .))) -}}
    {{- $_ := set $providers "kubernetesIngress" $ki -}}
    {{- $_ := set $merged "providers" $providers -}}
  {{- end -}}
{{- end -}}

{{- $merged | toYaml -}}
{{- end -}}
