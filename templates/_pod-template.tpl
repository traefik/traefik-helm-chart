{{- define "metadata.labels" }}
    app: {{ template "traefik.name" . }}
    chart: {{ template "traefik.chart" . }}
    release: {{ .Release.Name | quote }}
    heritage: {{ .Release.Service | quote }}
{{- end }}

{{- define "spec.template.metadata.labels" }}
        app: {{ template "traefik.name" . }}
        chart: {{ template "traefik.chart" . }}
        release: {{ .Release.Name | quote }}
        heritage: {{ .Release.Service | quote }}
{{- end }}

{{- define "spec.selector" }}
    matchLabels:
      app: {{ template "traefik.name" . }}
      release: {{ .Release.Name }}
{{- end }}

{{- define "spec.strategy" }}
    type: RollingUpdate
    rollingUpdate:
    {{- with .Values.rollingUpdate }}
      {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end }}

{{- define "spec.template.spec" }}
      serviceAccountName: {{ template "traefik.fullname" . }}
      terminationGracePeriodSeconds: 60
      containers:
      - image: {{ .Values.image.name }}:{{ .Values.image.tag }}
        name: {{ template "traefik.fullname" . }}
        {{- with .Values.resources }}
        resources:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        readinessProbe:
          httpGet:
            path: /ping
            port: {{ .Values.ports.traefik.port }}
          failureThreshold: 1
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        livenessProbe:
          httpGet:
            path: /ping
            port: {{ .Values.ports.traefik.port }}
          failureThreshold: 3
          initialDelaySeconds: 10
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 2
        ports:
        {{- range $name, $config := .Values.ports }}
        - name: {{ $name | quote }}
          containerPort: {{ $config.port }}
          protocol: TCP
        {{- end }}
        args:
          - "--global.checknewversion=true"
          - "--global.sendanonymoususage=true"
          {{- range $name, $config := .Values.ports }}
          - "--entryPoints.{{$name}}.address=:{{ $config.port }}"
          {{- end }}
          - "--api.dashboard={{ .Values.dashboard.enable }}"
          - "--ping=true"
          - "--providers.kubernetescrd"
          - "--log.level={{ .Values.logs.loglevel }}"
          {{- with .Values.additionalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
