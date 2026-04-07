{{- define "hub-manager.podTemplate" }}
    metadata:
      labels:
      {{- include "hub-manager.labels" . | nindent 8 -}}
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
      serviceAccountName: {{ include "hub-manager.serviceAccountName" . }}
      automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
      terminationGracePeriodSeconds: {{ default 60 .Values.deployment.terminationGracePeriodSeconds }}
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - image: {{ include "hub-manager.image-name" . }}
        name: {{ include "hub-manager.fullname" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        {{- with .Values.resources }}
        resources: {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.readinessProbe }}
        readinessProbe: {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.livenessProbe }}
        livenessProbe: {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.startupProbe}}
        startupProbe: {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.deployment.lifecycle }}
        lifecycle: {{- toYaml . | nindent 10 }}
        {{- end }}
        ports:
        {{- range $name, $config := .Values.ports }}
         {{- if $config }}
        - name: {{ include "hub-manager.portname" $name }}
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

          {{- with .Values.token }}
          - "--hub.token=$(HUB_TOKEN)"
          {{- end }}

          {{- with .Values.logs }}
          - "--log-level={{ .level }}"
          - "--log-format={{ .format }}"
          {{- end }}

          {{- with .Values.tracing }}
            {{- if .insecure }}
          - "--tracing-insecure"
            {{- end }}
          {{- end }}
        env:
          {{- with .Values.token }}
          - name: HUB_TOKEN
            valueFrom:
              secretKeyRef:
                key: token
                name: {{ . }}
          {{- end }}

          {{- with .Values.postgres }}
          - name: POSTGRES_URI
            valueFrom:
              secretKeyRef:
                key: postgres-uri
                name: {{ .uri }}
          - name: POSTGRES_ENCRYPTION_KEY
            valueFrom:
              secretKeyRef:
                key: postgres-encryption-key
                name: {{ .encryptionKey }}
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
{{ end -}}
