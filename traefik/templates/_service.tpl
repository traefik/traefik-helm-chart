{{- define "traefik.service-metadata" }}
  labels:
    app.kubernetes.io/name: {{ template "traefik.name" . }}
    helm.sh/chart: {{ template "traefik.chart" . }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  {{- with .Values.service.labels }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

{{- define "traefik.service-spec" -}}
  {{- $type := default "LoadBalancer" .Values.service.type }}
  type: {{ $type }}
  {{- with .Values.service.spec }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  selector:
    app.kubernetes.io/name: {{ template "traefik.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
  {{- if eq $type "LoadBalancer" }}
  {{- with .Values.service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
  {{- end -}}
  {{- with .Values.service.externalIPs }}
  externalIPs:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
  {{- if .Values.service.ipFamilyPolicy }}
  ipFamilyPolicy: {{ .Values.service.ipFamilyPolicy }}
  {{- end }}
  {{- with .Values.service.ipFamilies }}
  ipFamilies:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
{{- end }}

