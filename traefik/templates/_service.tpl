{{- define "traefik.service-name" -}}
{{- $fullname := printf "%s-%s" (include "traefik.fullname" .root) .name -}}
{{- if eq .name "default" -}}
{{- $fullname = include "traefik.fullname" .root -}}
{{- end -}}

{{- if ge (len $fullname) 60 -}} # 64 - 4 (udp-postfix) = 60
  {{- fail "ERROR: Cannot create a service whose full name contains more than 60 characters" -}}
{{- end -}}

{{- $fullname -}}
{{- end -}}

{{- define "traefik.service-metadata" }}
  labels:
  {{- include "traefik.labels" .root | nindent 4 -}}
  {{- with .service.labels }}
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}

{{- define "traefik.service-spec" -}}
  {{- $type := default "LoadBalancer" .service.type }}
  type: {{ $type }}
  {{- with .service.loadBalancerClass }}
  loadBalancerClass: {{ . }}
  {{- end}}
  {{- with .service.spec }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  selector:
    {{- include "traefik.labelselector" .root | nindent 4 }}
  {{- if eq $type "LoadBalancer" }}
  {{- with .service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
  {{- end -}}
  {{- with .service.externalIPs }}
  externalIPs:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
  {{- with .service.ipFamilyPolicy }}
  ipFamilyPolicy: {{ . }}
  {{- end }}
  {{- with .service.ipFamilies }}
  ipFamilies:
  {{- toYaml . | nindent 2 }}
  {{- end -}}
{{- end }}

{{- define "traefik.service-ports" }}
  {{- range $name, $config := .ports }}
  {{- if (index (default dict $config.expose) $.serviceName) }}
  - port: {{ default $config.port $config.exposedPort }}
    name: {{ $name | quote }}
    targetPort: {{ default $name $config.targetPort }}
    protocol: {{ default "TCP" $config.protocol }}
    {{- if $config.nodePort }}
    nodePort: {{ $config.nodePort }}
    {{- end }}
    {{- if $config.appProtocol }}
    appProtocol: {{ $config.appProtocol }}
    {{- end }}
  {{- end }}
  {{- if $config.http3 }}
  {{- if $config.http3.enabled }}
  {{- $http3Port := default $config.exposedPort $config.http3.advertisedPort }}
  - port: {{ $http3Port }}
    name: "{{ $name }}-http3"
    targetPort: {{ $name }}-http3
    protocol: UDP
    {{- if $config.nodePort }}
    nodePort: {{ $config.nodePort }}
    {{- end }}
    {{- if $config.appProtocol }}
    appProtocol: {{ $config.appProtocol }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
