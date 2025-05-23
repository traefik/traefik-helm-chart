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
{{- if .Values.oci_meta.enabled -}}
 {{- if .Values.hub.token -}}
{{- printf "%s/%s:%s" .Values.oci_meta.repo .Values.oci_meta.images.hub.image .Values.oci_meta.images.hub.tag }}
 {{- else -}}
{{- printf "%s/%s:%s" .Values.oci_meta.repo .Values.oci_meta.images.proxy.image .Values.oci_meta.images.proxy.tag }}
 {{- end -}}
{{- else if .Values.global.azure.enabled -}}
 {{- if .Values.hub.token -}}
{{- printf "%s/%s:%s" .Values.global.azure.images.hub.registry .Values.global.azure.images.hub.image .Values.global.azure.images.hub.tag }}
 {{- else -}}
{{- printf "%s/%s:%s" .Values.global.azure.images.proxy.registry .Values.global.azure.images.proxy.image .Values.global.azure.images.proxy.tag }}
 {{- end -}}
{{- else -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end -}}
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
Change input to a valid name for a port.
This is a best effort to convert input to a valid port name for Kubernetes,
which per RFC 6335 only allows lowercase alphanumeric characters and '-',
and additionally imposes a limit of 15 characters on the length of the name.
See also https://kubernetes.io/docs/concepts/services-networking/service/#multi-port-services
and https://www.rfc-editor.org/rfc/rfc6335#section-5.1.
*/}}
{{- define "traefik.portname" -}}
{{- $portName := . -}}
{{- $portName = $portName | lower -}}
{{- $portName = $portName | trimPrefix "-" | trunc 15 | trimSuffix "-" -}}
{{- print $portName -}}
{{- end -}}

{{/*
Change input to a valid port reference.
See also the traefik.portname helper.
*/}}
{{- define "traefik.portreference" -}}
{{- if kindIs "string" . -}}
    {{- print (include "traefik.portname" .) -}}
{{- else -}}
    {{- print . -}}
{{- end -}}
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


{{/*
This is a hack to avoid too much complexity when proxyVersion is required on Hub.
It requires a dict with "Version" and "Hub".
*/}}
{{- define "traefik.proxyVersionFromHub" -}}
 {{- $version := .Version -}}
 {{- if .Hub -}}
   {{- $hubProxyVersion := "v3.3" }}
   {{- if regexMatch "v[0-9]+.[0-9]+.[0-9]+" (default "" $version) -}}
     {{- if semverCompare "<v3.3.2-0" $version -}}
        {{- $hubProxyVersion = "v3.0" }}
     {{- else if semverCompare "<v3.7.0-0" $version -}}
        {{- $hubProxyVersion = "v3.1" }}
     {{- else if semverCompare "<v3.11.0-0" $version -}}
        {{ $hubProxyVersion = "v3.2" }}
     {{- end -}}
   {{- end -}}
   {{ $hubProxyVersion }}
 {{- else -}}
   {{ $version }}
 {{- end -}}
{{- end -}}


{{/*
The version can comes many sources: appVersion, image.tag, override, marketplace.
*/}}
{{- define "traefik.proxyVersion" -}}
 {{- if $.Values.versionOverride }}
  {{- include "traefik.proxyVersionFromHub" (dict "Version" $.Values.versionOverride "Hub" $.Values.hub.token) }}
 {{- else if $.Values.hub.token -}}
  {{- $version := ($.Values.oci_meta.enabled | ternary $.Values.oci_meta.images.hub.tag $.Values.image.tag) -}}
  {{- $version = ($.Values.global.azure.enabled | ternary $.Values.global.azure.images.hub.tag $version) -}}
  {{- include "traefik.proxyVersionFromHub" (dict "Version" $version "Hub" true) }}
 {{- else -}}
  {{- $imageVersion := ($.Values.oci_meta.enabled | ternary $.Values.oci_meta.images.proxy.tag $.Values.image.tag) -}}
  {{- $imageVersion = ($.Values.global.azure.enabled | ternary $.Values.global.azure.images.proxy.tag $imageVersion) -}}
  {{- (split "@" (default $.Chart.AppVersion $imageVersion))._0 | replace "latest-" "" | replace "experimental-" "" }}
 {{- end -}}
{{- end -}}

{{/* Generate/load self-signed certificate for admission webhooks */}}
{{- define "traefik-hub.webhook_cert" -}}
{{- if $.Values.hub.apimanagement.admission.customWebhookCertificate }}
Cert: {{ index $.Values.hub.apimanagement.admission.customWebhookCertificate "tls.crt" }}
Key: {{ index $.Values.hub.apimanagement.admission.customWebhookCertificate "tls.key" }}
Hash: {{ sha1sum (index $.Values.hub.apimanagement.admission.customWebhookCertificate "tls.crt") }}
{{- else -}}
    {{- $cert := lookup "v1" "Secret" (include "traefik.namespace" .) $.Values.hub.apimanagement.admission.secretName -}}
    {{- if $cert -}}
    {{/* reusing value of existing cert */}}
Cert: {{ index $cert.data "tls.crt" }}
Key: {{ index $cert.data "tls.key" }}
Hash: {{ sha1sum (index $cert.data "tls.crt") }}
    {{- else -}}
    {{/* generate a new one */}}
    {{- $altNames := list ( printf "admission.%s.svc" (include "traefik.namespace" .) ) -}}
    {{- $cert := genSelfSignedCert ( printf "admission.%s.svc" (include "traefik.namespace" .) ) (list) $altNames 3650 -}}
Cert: {{ $cert.Cert | b64enc }}
Key: {{ $cert.Key | b64enc }}
Hash: {{ sha1sum ($cert.Cert | b64enc) }}
    {{- end -}}
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

{{- define "list.difference" -}}
    {{- $a := .a }}
    {{- $b := .b }}
    {{- $diff := list }}
    {{- range $a }}
        {{- if not (has . $b) }}
            {{- $diff = append $diff . }}
        {{- end }}
    {{- end }}
    {{- toYaml $diff }}
{{- end }}
