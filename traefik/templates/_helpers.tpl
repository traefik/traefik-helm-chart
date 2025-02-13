{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "traefik.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "traefik.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the chart image name.
*/}}
{{- define "traefik.image-name" -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "traefik.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow customization of the instance label value.
*/}}
{{- define "traefik.instance-name" -}}
{{- default (printf "%s-%s" .Release.Name (include "traefik.namespace" .)) .Values.instanceLabelOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Shared labels used for selector*/}}
{{/* This is an immutable field: this should not change between upgrade */}}
{{- define "traefik.labelselector" -}}
app.kubernetes.io/name: {{ template "traefik.name" . }}
app.kubernetes.io/instance: {{ template "traefik.instance-name" . }}
{{- end }}

{{/* Shared labels used in metada */}}
{{- define "traefik.labels" -}}
{{ include "traefik.labelselector" . }}
helm.sh/chart: {{ template "traefik.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Construct the namespace for all namespaced resources
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Preserve the default behavior of the Release namespace if no override is provided
*/}}
{{- define "traefik.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "traefik.serviceAccountName" -}}
{{- default (include "traefik.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}

{{/*
The name of the ClusterRole and ClusterRoleBinding to use.
Adds the namespace to name to prevent duplicate resource names when there
are multiple namespaced releases with the same release name.
*/}}
{{- define "traefik.clusterRoleName" -}}
{{- (printf "%s-%s" (include "traefik.fullname" .) (include "traefik.namespace" .)) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Construct the path for the providers.kubernetesingress.ingressendpoint.publishedservice.
By convention this will simply use the <namespace>/<service-name> to match the name of the
service generated.
Users can provide an override for an explicit service they want bound via `.Values.providers.kubernetesIngress.publishedService.pathOverride`
*/}}
{{- define "providers.kubernetesIngress.publishedServicePath" -}}
{{- $defServiceName := printf "%s/%s" (include "traefik.namespace" .) (include "traefik.fullname" .) -}}
{{- $servicePath := default $defServiceName .Values.providers.kubernetesIngress.publishedService.pathOverride }}
{{- print $servicePath | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct a comma-separated list of whitelisted namespaces
*/}}
{{- define "providers.kubernetesCRD.namespaces" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.providers.kubernetesCRD.namespaces) }}
{{- end -}}
{{- define "providers.kubernetesGateway.namespaces" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.providers.kubernetesGateway.namespaces) }}
{{- end -}}
{{- define "providers.kubernetesIngress.namespaces" -}}
{{- default (include "traefik.namespace" .) (join "," .Values.providers.kubernetesIngress.namespaces) }}
{{- end -}}

{{/*
Renders a complete tree, even values that contains template.
*/}}
{{- define "traefik.render" -}}
  {{- if typeIs "string" .value }}
    {{- tpl .value .context }}
  {{ else }}
    {{- tpl (.value | toYaml) .context }}
  {{- end }}
{{- end -}}

{{- define "imageVersion" -}}
{{/*
Traefik hub is based on v3.1 (v3.0 before v3.3.1) of traefik proxy, so this is a hack to avoid to much complexity in RBAC management which are
based on semverCompare
*/}}
{{- if $.Values.hub.token -}}
 {{ $hubVersion := "v3.2" }}
 {{- if regexMatch "v[0-9]+.[0-9]+.[0-9]+" (default "" $.Values.image.tag) -}}
    {{- if semverCompare "<v3.3.2-0" $.Values.image.tag -}}
        {{ $hubVersion = "v3.0" }}
    {{- else if semverCompare "<v3.7.0-0" $.Values.image.tag -}}
        {{ $hubVersion = "v3.1" }}
    {{- end -}}
 {{- end -}}
{{ $hubVersion }}
{{- else -}}
{{ (split "@" (default $.Chart.AppVersion $.Values.image.tag))._0 | replace "latest-" "" | replace "experimental-" "" }}
{{- end -}}
{{- end -}}

{{/* Generate/load self-signed certificate for admission webhooks */}}
{{- define "traefik-hub.webhook_cert" -}}
{{- $cert := lookup "v1" "Secret" (include "traefik.namespace" .) "hub-agent-cert" -}}
{{- if $cert -}}
{{/* reusing value of existing cert */}}
Cert: {{ index $cert.data "tls.crt" }}
Key: {{ index $cert.data "tls.key" }}
{{- else -}}
{{/* generate a new one */}}
{{- $altNames := list ( printf "admission.%s.svc" (include "traefik.namespace" .) ) -}}
{{- $cert := genSelfSignedCert ( printf "admission.%s.svc" (include "traefik.namespace" .) ) (list) $altNames 3650 -}}
Cert: {{ $cert.Cert | b64enc }}
Key: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}

{{- define "traefik.yaml2CommandLineArgsRec" -}}
    {{- $path := .path -}}
    {{- range $key, $value := .content -}}
        {{- if kindIs "map" $value }}
            {{- include "traefik.yaml2CommandLineArgsRec" (dict "path" (printf "%s.%s" $path $key) "content" $value) -}}
        {{- else }}
            {{- with $value  }}
--{{ join "." (list $path $key)}}={{ join "," $value }}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- end -}}

{{- define "traefik.yaml2CommandLineArgs" -}}
    {{- range ((regexSplit "\n" ((include "traefik.yaml2CommandLineArgsRec" (dict "path" .path "content" .content)) | trim) -1) | compact) -}}
      {{ printf "- \"%s\"\n" . }}
    {{- end -}}
{{- end -}}

{{- define "traefik.hasPluginsVolume" -}}
    {{- $found := false -}}
    {{- range . -}}
       {{- if eq .name "plugins" -}}
           {{ $found = true }}
       {{- end -}}
    {{- end -}}
    {{- $found -}}
{{- end -}}
