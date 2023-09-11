{{- define "traefik.service-internal-ingress-metadata" }}
  labels:
  {{- include "traefik.labels" . | nindent 4 -}}
  {{- with .Values.service.internal.ingress.labels }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

{{- define "traefik.service-internal-ingress-tls" }}
  - hosts:
    {{- range $host := .Values.service.internal.ingress.tls.hosts }}
    - {{ $host }}
    {{- end }}
    secretName: {{ .Values.service.internal.ingress.tls.secretName }}
{{- end }}

{{- define "traefik.service-internal-ingress-rules" }}
  {{- $serviceName := printf "%s-internal" (include "traefik.fullname" .)}}
  {{- range $name, $config := .Values.service.internal.ports }}
  {{- if $config.host  }}
  - host: {{ $config.host }}
    http:
  {{- else }}
  - http:
  {{- end }}
      paths:
      - path: {{ default "/" $config.path }}
        pathType: {{ default "Prefix" $config.prefix }}
        backend:
          service:
            name: {{ $serviceName }}
            port:
              number: {{ default $config.port $config.exposedPort }}
  {{- end }}
{{- end }}

{{- define "traefik.service-internal-ingress-spec" -}}
  {{- with .Values.service.internal.ingress.spec }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end }}