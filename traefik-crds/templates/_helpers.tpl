{{/* vim: set filetype=mustache: */}}

{{/*
Render CRDs file.
*/}}
{{- define "traefik-crds.render-crds" -}}
    {{- $scope := .scope -}}
    {{- range $path, $bytes := $scope.Files.Glob .path }}
        {{- range $doc := regexSplit "\n---\n" ($scope.Files.Get $path) -1 }}
            {{- $crd :=  $doc | fromYaml -}}
            {{ with $crd }}
                {{- if not $scope.Values.deleteOnUninstall -}}
                    {{- $_ := set $crd.metadata.annotations "helm.sh/resource-policy" "keep" -}}
                {{- end }}
---
{{ $crd | toYaml }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end -}}
