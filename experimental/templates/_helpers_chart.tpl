{{- define "traefik.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard Helm fullname (matches `helm create`): collapse the prefix when the
release name already contains the chart name. Mirrors the legacy chart so object
names match for a given release (in-place upgrade).
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
Namespace for every namespaced manifest. Defaults to the release namespace;
override with .Values.namespaceOverride.
*/}}
{{- define "traefik.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}

{{/*
Name for cluster-scoped objects (ClusterRole, ClusterRoleBinding). Namespace
suffix keeps releases in different namespaces from colliding (these objects are
global). Mirrors the legacy chart so names match for an in-place upgrade.
*/}}
{{- define "traefik.clusterScopedName" -}}
{{- printf "%s-%s" (include "traefik.fullname" .) (include "traefik.namespace" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
