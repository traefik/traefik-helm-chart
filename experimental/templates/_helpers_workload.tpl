{{/*
Builds the chart's traefik `Container` as a dict. Reads `.resources` from .Values.<key>.
Args (dict): ctx (root context), key ("deployment" or "daemonset").
*/}}
{{- define "traefik.container" -}}
{{- $ctx := .ctx -}}
{{- $values := index $ctx.Values .key | default dict -}}
{{- $config := include "traefik.mergedConfig" $ctx | fromYaml -}}

{{- $ports := list -}}
{{- range $name, $ep := ($config.entryPoints | default dict) -}}
  {{- $parts := splitList "/" (last (splitList ":" ($ep.address | default ""))) -}}
  {{- $ports = append $ports (dict
      "name" $name
      "containerPort" (first $parts | int)
      "protocol" (default "tcp" (index $parts 1) | upper)
  ) -}}
{{- end -}}
{{/* Hub agent listens on the admission port for any online Hub install (like legacy),
     not only under API Management. */}}
{{- if and (include "traefik.hubEnabled" $ctx) (not ((($ctx.Values.traefik).hub).offline)) -}}
  {{- $ports = append $ports (dict
      "name" "admission"
      "containerPort" (include "traefik.hubAdmissionContainerPort" $ctx | int)
      "protocol" "TCP"
  ) -}}
{{- end -}}
{{- if include "traefik.hubAPIManagementEnabled" $ctx -}}
  {{- $ports = append $ports (dict
      "name" "apiportal"
      "containerPort" 9903
      "protocol" "TCP"
  ) -}}
{{- end -}}

{{/* /config (ConfigMap) + /tmp (writable; required by readOnlyRootFilesystem). */}}
{{- $volumeMounts := list
    (dict "name" "config" "mountPath" "/config")
    (dict "name" "tmp" "mountPath" "/tmp")
-}}
{{- if include "traefik.hubTokenInline" $ctx -}}
  {{- $volumeMounts = append $volumeMounts (dict
      "name" "hub-token"
      "mountPath" (include "traefik.hubTokenMountPath" $ctx)
      "readOnly" true
  ) -}}
{{- end -}}
{{- $dataMount := dict "name" "data" "mountPath" ((($ctx.Values.persistence | default dict).mountPath) | default "/data") -}}
{{- if kindIs "map" $ctx.Values.persistence -}}
  {{- with $ctx.Values.persistence.subPath -}}{{- $_ := set $dataMount "subPath" . -}}{{- end -}}
{{- end -}}
{{- $volumeMounts = append $volumeMounts $dataMount -}}

{{/* Base env + Go runtime tuning (GOMAXPROCS from CPU limit, GOMEMLIMIT at 90% of
     memory limit), like legacy. Merge by name, so overridable via the deployment.spec hatch. */}}
{{- $env := list
    (dict "name" "POD_NAME"
          "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.name")))
    (dict "name" "POD_NAMESPACE"
          "valueFrom" (dict "fieldRef" (dict "fieldPath" "metadata.namespace")))
    (dict "name" "USER" "value" "traefik")
-}}
{{- $limits := ($values.resources).limits | default dict -}}
{{- if $limits.cpu -}}
  {{- $env = append $env (dict "name" "GOMAXPROCS"
      "valueFrom" (dict "resourceFieldRef" (dict "resource" "limits.cpu" "divisor" "1"))) -}}
{{- end -}}
{{- if $limits.memory -}}
  {{- $env = append $env (dict "name" "GOMEMLIMIT"
      "value" (include "traefik.gomemlimit" (dict "memory" $limits.memory "percentage" 0.9) | trim)) -}}
{{- end -}}

{{- $container := dict
    "name" "traefik"
    "image" (include "traefik.imageName" $ctx)
    "imagePullPolicy" "IfNotPresent"
    "args" (list "--configfile=/config/traefik.yaml")
    "ports" $ports
    "volumeMounts" $volumeMounts
    "securityContext" (dict
        "allowPrivilegeEscalation" false
        "readOnlyRootFilesystem" true
        "capabilities" (dict "drop" (list "ALL"))
    )
    "env" $env
-}}

{{- if hasKey $config "ping" -}}
  {{- $ep := (get ($config.ping | default dict) "entryPoint") | default "traefik" -}}
  {{- $port := 8080 -}}
  {{- range $p := $ports -}}{{- if eq $p.name $ep -}}{{- $port = $p.containerPort -}}{{- end -}}{{- end -}}
  {{- $httpGet := dict "path" "/ping" "port" $port "scheme" "HTTP" -}}
  {{- $_ := set $container "readinessProbe" (dict "httpGet" $httpGet
      "failureThreshold" 1 "initialDelaySeconds" 2 "periodSeconds" 10 "successThreshold" 1 "timeoutSeconds" 2) -}}
  {{- $_ := set $container "livenessProbe" (dict "httpGet" $httpGet
      "failureThreshold" 3 "initialDelaySeconds" 2 "periodSeconds" 10 "successThreshold" 1 "timeoutSeconds" 2) -}}
{{- end -}}

{{- with $values.resources -}}
  {{- $_ := set $container "resources" . -}}
{{- end -}}

{{- $container | toYaml -}}
{{- end -}}

{{/*
Builds the chart's `PodSpec` as a dict — wraps the traefik Container, adds
chart-managed volumes (config + hub-token), serviceAccountName, imagePullSecrets.
Args (dict): ctx (root context), key ("deployment" or "daemonset").
*/}}
{{- define "traefik.podSpec" -}}
{{- $ctx := .ctx -}}
{{- $fullname := include "traefik.fullname" $ctx -}}
{{- $container := include "traefik.container" (dict "ctx" $ctx "key" .key) | fromYaml -}}

{{- $volumes := list
    (dict "name" "config" "configMap" (dict "name" $fullname))
    (dict "name" "tmp" "emptyDir" (dict))
-}}
{{- if include "traefik.hubTokenInline" $ctx -}}
  {{- $volumes = append $volumes (dict
      "name" "hub-token"
      "secret" (dict "secretName" (printf "%s-hub-license" $fullname))
  ) -}}
{{- end -}}
{{- if kindIs "map" $ctx.Values.persistence -}}
  {{- $claim := $ctx.Values.persistence.existingClaim | default $fullname -}}
  {{- $volumes = append $volumes (dict
      "name" "data"
      "persistentVolumeClaim" (dict "claimName" $claim)
  ) -}}
{{- else -}}
  {{- $volumes = append $volumes (dict "name" "data" "emptyDir" (dict)) -}}
{{- end -}}

{{- $podSpec := dict
    "serviceAccountName" $fullname
    "automountServiceAccountToken" true
    "terminationGracePeriodSeconds" 60
    "securityContext" (dict
        "runAsNonRoot" true
        "runAsUser" 65532
        "runAsGroup" 65532
        "seccompProfile" (dict "type" "RuntimeDefault")
    )
    "containers" (list $container)
    "volumes" $volumes
-}}
{{- with $ctx.Values.imagePullSecrets -}}
  {{- $_ := set $podSpec "imagePullSecrets" . -}}
{{- end -}}

{{- $podSpec | toYaml -}}
{{- end -}}

{{/*
Builds the chart's `PodTemplateSpec` (metadata + spec) as a dict. Metadata uses
`traefik.objectMeta` with no name/namespace (pod templates have none) so chart and
common labels/annotations apply. A `checksum/config` annotation (hash of the static
config) rolls the pods on traefik.yaml changes — ConfigMap updates alone wouldn't.
Args (dict): ctx (root context), key ("deployment" or "daemonset").
*/}}
{{- define "traefik.podTemplateSpec" -}}
{{- $ctx := .ctx -}}
{{- $config := include "traefik.mergedConfig" $ctx | fromYaml -}}
{{- $metadata := include "traefik.objectMeta" (dict "ctx" $ctx) | fromYaml -}}
{{- $checksum := include "traefik.mergedConfig" $ctx | sha256sum -}}
{{- $annotations := $metadata.annotations | default dict -}}
{{- $_ := set $annotations "checksum/config" $checksum -}}
{{/* Prometheus scrape annotations when Prometheus metrics are on (like legacy). */}}
{{- if hasKey ($config.metrics | default dict) "prometheus" -}}
  {{- $ep := (($config.metrics.prometheus | default dict).entryPoint) | default "metrics" -}}
  {{- $port := "9100" -}}
  {{- with index ($config.entryPoints | default dict) $ep -}}
    {{- $port = first (splitList "/" (last (splitList ":" (.address | default "")))) -}}
  {{- end -}}
  {{- $_ := set $annotations "prometheus.io/scrape" "true" -}}
  {{- $_ := set $annotations "prometheus.io/path" "/metrics" -}}
  {{- $_ := set $annotations "prometheus.io/port" $port -}}
{{- end -}}
{{- $_ := set $metadata "annotations" $annotations -}}
{{- $podSpec := include "traefik.podSpec" (dict "ctx" $ctx "key" .key) | fromYaml -}}
{{- $template := dict "metadata" $metadata "spec" $podSpec -}}
{{- $template | toYaml -}}
{{- end -}}

{{/*
Builds the workload `.spec` (Deployment or DaemonSet — same shape: selector + template).
User overrides via .Values.<key>.spec are JSON-merge-patched on top.
Args (dict): ctx (root context), key ("deployment" or "daemonset").
*/}}
{{- define "traefik.workloadSpec" -}}
{{- $ctx := .ctx -}}
{{- $values := index $ctx.Values .key | default dict -}}

{{- $selectorLabels := include "traefik.selectorLabels" $ctx | fromYaml -}}
{{- $template := include "traefik.podTemplateSpec" (dict "ctx" $ctx "key" .key) | fromYaml -}}

{{- $chartSpec := dict
    "selector" (dict "matchLabels" $selectorLabels)
    "template" $template
-}}
{{- if eq .key "deployment" -}}
  {{- $_ := set $chartSpec "replicas" 1 -}}
  {{- $_ := set $chartSpec "strategy" (dict "type" "RollingUpdate" "rollingUpdate" (dict "maxUnavailable" 0 "maxSurge" 1)) -}}
{{- else -}}
  {{- $_ := set $chartSpec "updateStrategy" (dict "type" "RollingUpdate") -}}
{{- end -}}

{{- $userSpec := $values.spec | default dict -}}
{{- include "traefik.strategicMerge" (dict "base" $chartSpec "patch" $userSpec) -}}
{{- end -}}

{{/*
GOMEMLIMIT for the traefik container: floor of memory*percentage in MiB.
Input dict: {memory, percentage}. Memory parsing is in _lib_units.tpl.
*/}}
{{- define "traefik.gomemlimit" }}
{{- $percentage := .percentage -}}
{{- $memlimitBytes := include "traefik.convertMemToBytes" .memory | mulf $percentage -}}
{{- printf "%dMiB" (divf $memlimitBytes 0x1p20 | floor | int64) -}}
{{- end }}
