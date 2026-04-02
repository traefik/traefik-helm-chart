{{- define "hub-platform.podTemplate" }}
    metadata:
      labels:
      {{- include "hub-platform.labels" . | nindent 8 -}}
      {{- with .Values.deployment.podLabels }}
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.podAnnotations }}
      annotations:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.affinity }}
      affinity:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "hub-platform.serviceAccountName" . }}
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: {{ default 60 .Values.deployment.terminationGracePeriodSeconds }}
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - image: {{ include "hub-platform.image-name" . }}
        name: {{ include "hub-platform.fullname" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        {{- with .Values.resources }}
        resources:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.readinessProbe }}
        readinessProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.livenessProbe }}
        livenessProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.startupProbe}}
        startupProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.lifecycle }}
        lifecycle:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        ports:
        {{- range $name, $config := .Values.ports }}
         {{- if $config }}
        - name: {{ include "hub-platform.portname" $name }}
          containerPort: {{ default $config.port $config.containerPort }}
          protocol: {{ default "TCP" $config.protocol }}
         {{- end }}
        {{- end }}
        {{- with .Values.securityContext }}
        securityContext:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.volumeMounts }}
        volumeMounts:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        args:
          - "serve"
          - "--addr={{ default ":80" .Values.address }}"

          {{- with .Values.logs }}
          - "--log-level={{ .level }}"
          - "--log-format={{ .format }}"
          {{- end }}

          {{- with .Values.services.offerURL }}
          - "--offer-service-url={{ . }}"
          {{- end }}
          {{- with .Values.services.workspaceURL }}
          - "--workspace-service-url={{ . }}"
          {{- end }}
          {{- with .Values.services.traceURL }}
          - "--trace-service-url={{ . }}"
          {{- end }}

          {{- with .Values.hydra }}
            {{- with .url }}
          - "--hydra-url={{ . }}"
            {{- end }}
            {{- with .issuerURL }}
          - "--hydra-issuer-url={{ . }}"
            {{- end }}
          {{- end }}

          {{- with .Values.tracing }}
            {{- if .insecure }}
          - "--tracing-insecure"
            {{- end }}
          {{- end }}
        env:
          {{- with .Values.postgres }}
          - name: POSTGRES_URI
            valueFrom:
              secretKeyRef:
                key: postgres-uri
                name: {{ .uri }}
          {{- end }}

          {{- with .Values.tracing }}
            {{- with .address }}
          - name: TRACING_ADDRESS
            value: {{ . }}
            {{- end }}
            {{- with .username }}
          - name: TRACING_USERNAME
            value: {{ . }}
            {{- end }}
            {{- with .password }}
          - name: TRACING_PASSWORD
            valueFrom:
              secretKeyRef:
                key: tracing-password
                name: {{ . }}
            {{- end }}
          - name: TRACING_PROBABILITY
            value: {{ default "0" .probability }}
          {{- end }}

          {{- with .Values.jwt }}
          - name: JWT_CERT
            valueFrom:
              secretKeyRef:
                key: jwt-cert
                name: {{ .cert }}
          - name: JWT_ISS
            valueFrom:
              secretKeyRef:
                key: jwt-iss
                name: {{ .iss }}
          - name: JWT_SUB
            valueFrom:
              secretKeyRef:
                key: jwt-sub
                name: {{ .sub }}
          {{- end }}
{{ end -}}
