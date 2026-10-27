{{/*
Service .spec for one entry. The chart owns the `selector` (targets the
Deployment) for its managed entries — `default`, `hub-admission`, `hub-apiportal`
(the Hub ones also get chart-provided ports). Every other entry MUST set its own
`spec:`. User `.spec` is strategic-merged over the chart's (ports merge by `name`).
Args (dict): ctx, name (entry key), config (entry value).
*/}}
{{- define "traefik.serviceSpec" -}}
{{- $ctx := .ctx -}}
{{- $name := .name -}}
{{- $config := .config | default dict -}}

{{- $chartSpec := dict -}}
{{- if eq $name "default" -}}
  {{- $chartSpec = dict "selector" (include "traefik.selectorLabels" $ctx | fromYaml) -}}
{{- else if eq $name "hub-admission" -}}
  {{- $chartSpec = dict
      "selector" (include "traefik.selectorLabels" $ctx | fromYaml)
      "ports" (list (dict "name" "admission" "port" 443 "targetPort" "admission" "protocol" "TCP"))
  -}}
{{- else if eq $name "hub-apiportal" -}}
  {{- $chartSpec = dict
      "selector" (include "traefik.selectorLabels" $ctx | fromYaml)
      "ports" (list (dict "name" "apiportal" "port" 9903 "targetPort" "apiportal" "protocol" "TCP"))
  -}}
{{- end -}}

{{- $userSpec := $config.spec | default dict -}}
{{- if and (empty $chartSpec) (empty $userSpec) -}}
  {{- fail (printf "service.%s: spec is required (chart has no defaults for this service)" $name) -}}
{{- end -}}
{{- include "traefik.strategicMerge" (dict "base" $chartSpec "patch" $userSpec) -}}
{{- end -}}
