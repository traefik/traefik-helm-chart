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
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - image: {{ printf "%s/%s:%s" .Values.image.registry .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
        name: {{ include "hub-manager.fullname" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        {{- with .Values.resources }}
        resources: {{- toYaml . | nindent 10 }}
        {{- end }}
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          failureThreshold: 2
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /live
            port: 8080
          failureThreshold: 2
          initialDelaySeconds: 5
          periodSeconds: 5
        {{- with .Values.deployment.lifecycle }}
        lifecycle: {{- toYaml . | nindent 10 }}
        {{- end }}
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
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
          - "--addr={{ .Values.address }}"

          {{- with .Values.logs }}
          - "--log-level={{ .level }}"
          {{- end }}

          {{- if .Values.tracing.insecure }}
          - "--tracing-insecure"
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
          {{- with .uri }}
          - name: POSTGRES_URI
            valueFrom:
              secretKeyRef:
                key: postgres-uri
                name: {{ . }}
          {{- end }}
          {{- with .encryptionKey }}
          - name: POSTGRES_ENCRYPTION_KEY
            valueFrom:
              secretKeyRef:
                key: postgres-encryption-key
                name: {{ .encryptionKey }}
          {{- end }}
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
            value: {{ default "0.0" .probability | quote }}
          {{- end }}
{{ end -}}
