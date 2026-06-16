{{/*
Image + version resolution: the single source of truth for the workload
container image and the version guard (traefik-helm-chart#1884 / #1885).
Semver math lives in _lib_semver.tpl; the NOTES warning in _helpers_notes.tpl;
the hard-fail guard in _helpers_validate.tpl.
*/}}

{{/*
Effective traefik container image. Explicit `image:` wins; else the Hub default
(when `traefik.hub.token` is set) or Proxy default (`docker.io/traefik:<appVersion>`).
*/}}
{{- define "traefik.imageName" -}}
{{- $default := printf "docker.io/traefik:%s" .Chart.AppVersion -}}
{{- if include "traefik.hubTokenInline" . -}}
  {{- $default = include "traefik.hubImageDefault" . -}}
{{- end -}}
{{- .Values.image | default $default -}}
{{- end -}}

{{/*
Tag portion of an image ref: part after the last ':' in the name segment,
'@digest' suffix stripped. Empty for digest-only refs. Input: the image string.
*/}}
{{- define "traefik.imageTag" -}}
{{- $ref := (split "@" (. | default ""))._0 -}}
{{- $nameTag := last (splitList "/" $ref) -}}
{{- $parts := splitList ":" $nameTag -}}
{{- if gt (len $parts) 1 -}}{{- last $parts -}}{{- end -}}
{{- end -}}

{{/*
Guarded version context as YAML: {version, tag, min, max, label, isHub, skip}.
`skip` is true for a digest-pinned ref with no parseable tag (a digest carries no
version) and for a non-semver Proxy tag, so the guard doesn't guess; a non-semver
Hub tag is treated as latest in-range (v3.99), per legacy chart.
*/}}
{{- define "traefik.versionContext" -}}
{{- $ann := .Chart.Annotations -}}
{{- $imageRef := include "traefik.imageName" . -}}
{{- $tag := include "traefik.imageTag" $imageRef -}}
{{- $digestNoTag := and (contains "@" $imageRef) (eq $tag "") -}}
{{- if include "traefik.hubTokenInline" . -}}
  {{- $v := $tag -}}
  {{- if not (regexMatch "v[0-9]+\\.[0-9]+\\.[0-9]+" (default "" $v)) -}}{{- $v = "v3.99" -}}{{- end -}}
  {{- dict "version" $v "tag" (default "v3.99" $tag) "min" (index $ann "traefik.io/hub-min-version") "max" (index $ann "traefik.io/hub-max-version") "label" "Traefik Hub image tag" "isHub" true "skip" $digestNoTag | toYaml -}}
{{- else -}}
  {{- $raw := $tag | default .Chart.AppVersion -}}
  {{- $v := $raw | replace "latest-" "" | replace "experimental-" "" -}}
  {{- dict "version" $v "tag" $raw "min" (index $ann "traefik.io/proxy-min-version") "max" (index $ann "traefik.io/proxy-max-version") "label" "image tag" "isHub" false "skip" (or $digestNoTag (not (regexMatch "^v?[0-9]+\\.[0-9]+\\.[0-9]+" $v))) | toYaml -}}
{{- end -}}
{{- end -}}
