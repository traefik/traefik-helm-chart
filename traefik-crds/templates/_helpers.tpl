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
                {{- set $crd.metadata.annotations "app.kubernetes.io/managed-by" "Helm" -}}
                {{- set $crd.metadata.annotations "meta.helm.sh/release-name" .Release.Name -}}
                {{- if not $scope.Values.deleteOnUninstall -}}
                    {{- $_ := set $crd.metadata.annotations "helm.sh/resource-policy" "keep" -}}
                {{- end }}
---
{{ $crd | toYaml }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end -}}
