{{/*
IngressRoute .spec for one entry. No chart defaults — every entry's spec lives in
values.yaml (the chart ships `dashboard.spec` inline; user entries must set their
own `spec:`). Validates presence and emits the spec verbatim.
Args (dict): ctx, name (route key), config (entry value).
*/}}
{{- define "traefik.ingressRouteSpec" -}}
{{- $userSpec := (.config | default dict).spec | default dict -}}
{{- if empty $userSpec -}}
  {{- fail (printf "ingressRoute.%s: spec is required (chart has no defaults for this route)" .name) -}}
{{- end -}}
{{- $userSpec | toYaml -}}
{{- end -}}
