{{/*
Generic semver predicates — pure functions over version strings, no chart
knowledge (see README "Template layout").
*/}}

{{/* "true" for a stable release (vX.Y.Z), "false" for experimental/ea/rc/etc. */}}
{{- define "traefik.isStableVersion" -}}
{{- if regexMatch "^v?[0-9]+\\.[0-9]+\\.[0-9]+$" . -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{/* "true" when version is above max but shares its major (the warn case). dict: version, max. */}}
{{- define "traefik.isAboveMaxVersion" -}}
{{- if eq (include "traefik.isStableVersion" .version) "true" -}}
{{- semverCompare (printf ">%s" .max) .version -}}
{{- else -}}
{{- semverCompare (printf ">%s-0" .max) .version -}}
{{- end -}}
{{- end -}}

{{/* "true" when version's major is strictly above max's major (the fail case). dict: version, max. */}}
{{- define "traefik.isMajorAboveMax" -}}
{{- semverCompare (printf ">=%d.0.0-0" (add1 (int (semver .max).Major))) .version -}}
{{- end -}}
