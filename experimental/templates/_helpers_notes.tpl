{{/*
NOTES.txt presentation helpers — the version warning shown to the user.
Decision logic reads the version context from _helpers_image.tpl.
*/}}

{{- define "traefik.nonStandardVersionWarning" -}}
⚠️ WARNING: You are using a non-standard {{ .label }} ({{ .tag }}). Non-standard versions can
be unstable, may contain breaking changes, and are NOT recommended for production use.
This version is not officially supported by this chart. Use at your own risk. ⚠️
{{- end -}}

{{/* The "use at your own risk" warning for NOTES.txt (empty when the version is fine). */}}
{{- define "traefik.versionWarning" -}}
{{- $c := include "traefik.versionContext" . | fromYaml -}}
{{- if not $c.skip -}}
{{- $warn := false -}}
{{- if and (not $c.isHub) (hasPrefix "experimental-" $c.tag) -}}{{- $warn = true -}}{{- end -}}
{{- if eq (include "traefik.isAboveMaxVersion" (dict "version" $c.version "max" $c.max)) "true" -}}{{- $warn = true -}}{{- end -}}
{{- if $warn -}}
{{ include "traefik.nonStandardVersionWarning" (dict "label" $c.label "tag" $c.tag) }}
{{- end -}}
{{- end -}}
{{- end -}}
