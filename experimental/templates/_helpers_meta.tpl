{{/*
Builds a k8s `ObjectMeta` dict, layering: chart-info labels (traefik.labels),
.Values.commonLabels/commonAnnotations, then per-object .metadata (user override).
`name`/`namespace` are chart-owned and restored after the merge. Both are optional —
omitting them suits embedded PodTemplateSpec.metadata (k8s auto-names, inherits namespace).
Args (dict): ctx, name (optional), namespace (optional), userMetadata (optional).
*/}}
{{- define "traefik.objectMeta" -}}
{{- $ctx := .ctx -}}
{{- $name := .name -}}
{{- $namespace := .namespace -}}
{{- $userMetadata := .userMetadata | default dict -}}

{{- $chartLabels := include "traefik.labels" $ctx | fromYaml -}}
{{- $commonLabels := $ctx.Values.commonLabels | default dict -}}
{{- $commonAnnotations := $ctx.Values.commonAnnotations | default dict -}}

{{- $baseLabels := include "traefik.strategicMerge" (dict "base" $chartLabels "patch" $commonLabels) | fromYaml -}}

{{- $chartMetadata := dict "labels" $baseLabels -}}
{{- if $name -}}
  {{- $_ := set $chartMetadata "name" $name -}}
{{- end -}}
{{- if $namespace -}}
  {{- $_ := set $chartMetadata "namespace" $namespace -}}
{{- end -}}
{{- if not (empty $commonAnnotations) -}}
  {{- $_ := set $chartMetadata "annotations" $commonAnnotations -}}
{{- end -}}

{{- $merged := include "traefik.strategicMerge" (dict "base" $chartMetadata "patch" $userMetadata) | fromYaml -}}
{{- if $name -}}
  {{- $_ := set $merged "name" $name -}}
{{- end -}}
{{- if $namespace -}}
  {{- $_ := set $merged "namespace" $namespace -}}
{{- end -}}
{{- $merged | toYaml -}}
{{- end -}}

{{/*
ObjectMeta for a chart-managed singleton manifest: user override from
`.Values.<key>.metadata`, chart-computed name, and (when `namespaced`) the chart
namespace. Used by every one-per-install manifest (Deployment, DaemonSet,
ServiceAccount, RBAC, Hub Secrets/Services, …). Map-iterated manifests (Service,
IngressRoute, MWCs) call traefik.objectMeta directly (their naming + values path differ).
Args (dict): ctx, key, name, namespaced (bool, default false).
*/}}
{{- define "traefik.singletonMeta" -}}
{{- $values := index .ctx.Values .key | default dict -}}
{{- $args := dict
    "ctx" .ctx
    "name" .name
    "userMetadata" ($values.metadata | default dict)
-}}
{{- if .namespaced -}}
  {{- $_ := set $args "namespace" (include "traefik.namespace" .ctx) -}}
{{- end -}}
{{- include "traefik.objectMeta" $args -}}
{{- end -}}
