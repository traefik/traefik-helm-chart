{{/*
Expand the name of the chart.
*/}}
{{- define "hhub-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hhub-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hhub-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart image name.
*/}}
{{- define "hhub-manager.image-name" -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end -}}

{{/* Shared labels used for selector*/}}
{{- define "hhub-manager.labelselector" -}}
app.kubernetes.io/name: {{ template "hhub-manager.name" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hhub-manager.labels" -}}
helm.sh/chart: {{ include "hhub-manager.chart" . }}
{{ include "hhub-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hhub-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hhub-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hhub-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hhub-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Construct the namespace for all namespaced resources
Preserve the default behavior of the Release namespace if no override is provided
*/}}
{{- define "hhub-manager.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Change input to a valid name for a port.
This is a best effort to convert input to a valid port name for Kubernetes,
which per RFC 6335 only allows lowercase alphanumeric characters and '-',
and additionally imposes a limit of 15 characters on the length of the name.
See also https://kubernetes.io/docs/concepts/services-networking/service/#multi-port-services
and https://www.rfc-editor.org/rfc/rfc6335#section-5.1.
*/}}
{{- define "hhub-manager.portname" -}}
{{- $portName := . -}}
{{- $portName = $portName | lower -}}
{{- $portName = $portName | trimPrefix "-" | trunc 15 | trimSuffix "-" -}}
{{- print $portName -}}
{{- end -}}