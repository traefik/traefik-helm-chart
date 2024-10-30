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
                {{- $labelsAndAnnotations :=
                (dict "metadata" (dict
                    "annotations" (dict
                            "app.kubernetes.io/managed-by" "Helm"
                            "meta.helm.sh/release-name" $scope.Release.Name
                            "meta.helm.sh/release-namespace" $scope.Release.Namespace
                    )
                    "labels" (dict
                        "app.kubernetes.io/managed-by" "Helm"
                    )
                ))
                -}}
                {{- if not $scope.Values.deleteOnUninstall -}}
                    {{- $_ := set $labelsAndAnnotations.metadata.annotations "helm.sh/resource-policy" "keep" -}}
                {{- end }}
                {{- $newCrd := merge $crd $labelsAndAnnotations }}
---
# source: {{ $path }}
{{ $newCrd | toYaml }}
            {{- end }}
        {{- end }}
    {{- end }}
{{- end -}}
