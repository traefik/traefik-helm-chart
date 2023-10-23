{{- define "traefik.podTemplate" }}
    metadata:
      annotations:
      {{- with .Values.deployment.podAnnotations }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.metrics }}
      {{- if and (.Values.metrics.prometheus) (not .Values.metrics.prometheus.serviceMonitor) }}
        prometheus.io/scrape: "true"
        prometheus.io/path: "/metrics"
        prometheus.io/port: {{ quote (index .Values.ports .Values.metrics.prometheus.entryPoint).port }}
      {{- end }}
      {{- end }}
      labels:
      {{- include "traefik.labels" . | nindent 8 -}}
      {{- with .Values.deployment.podLabels }}
      {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "traefik.serviceAccountName" . }}
      terminationGracePeriodSeconds: {{ default 60 .Values.deployment.terminationGracePeriodSeconds }}
      hostNetwork: {{ .Values.hostNetwork }}
      {{- with .Values.deployment.dnsPolicy }}
      dnsPolicy: {{ . }}
      {{- end }}
      {{- with .Values.deployment.dnsConfig }}
      dnsConfig:
        {{- if .searches }}
        searches:
          {{- toYaml .searches | nindent 10 }}
        {{- end }}
        {{- if .nameservers }}
        nameservers:
          {{- toYaml .nameservers | nindent 10 }}
        {{- end }}
        {{- if .options }}
        options:
          {{- toYaml .options | nindent 10 }}
        {{- end }}
      {{- end }}
      {{- with .Values.deployment.initContainers }}
      initContainers:
      {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- if .Values.deployment.shareProcessNamespace }}
      shareProcessNamespace: true
      {{- end }}
      containers:
      - image: {{ template "traefik.image-name" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        name: {{ template "traefik.fullname" . }}
        resources:
          {{- with .Values.resources }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        {{- if (and (empty .Values.ports.traefik) (empty .Values.deployment.healthchecksPort)) }}
          {{- fail "ERROR: When disabling traefik port, you need to specify `deployment.healthchecksPort`" }}
        {{- end }}
        {{- $healthchecksPort := (default (.Values.ports.traefik).port .Values.deployment.healthchecksPort) }}
        {{- $healthchecksScheme := (default "HTTP" .Values.deployment.healthchecksScheme) }}
        readinessProbe:
          httpGet:
            path: /ping
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml .Values.readinessProbe | nindent 10 }}
        livenessProbe:
          httpGet:
            path: /ping
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml .Values.livenessProbe | nindent 10 }}
        lifecycle:
          {{- with .Values.deployment.lifecycle }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        ports:
        {{- $hostNetwork := .Values.hostNetwork }}
        {{- range $name, $config := .Values.ports }}
        {{- if $config }}
          {{- if and $hostNetwork (and $config.hostPort $config.port) }}
            {{- if ne ($config.hostPort | int) ($config.port | int) }}
              {{- fail "ERROR: All hostPort must match their respective containerPort when `hostNetwork` is enabled" }}
            {{- end }}
          {{- end }}
        - name: {{ $name | quote }}
          containerPort: {{ default $config.port $config.containerPort }}
          {{- if $config.hostPort }}
          hostPort: {{ $config.hostPort }}
          {{- end }}
          {{- if $config.hostIP }}
          hostIP: {{ $config.hostIP }}
          {{- end }}
          protocol: {{ default "TCP" $config.protocol | quote }}
        {{- if $config.http3 }}
        {{- if and $config.http3.enabled $config.hostPort }}
        {{- $http3Port := default $config.hostPort $config.http3.advertisedPort }}
        - name: "{{ $name }}-http3"
          containerPort: {{ $config.port }}
          hostPort: {{ $http3Port }}
          protocol: UDP
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- with .Values.securityContext }}
        securityContext:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        volumeMounts:
          - name: {{ .Values.persistence.name }}
            mountPath: {{ .Values.persistence.path }}
            {{- if .Values.persistence.subPath }}
            subPath: {{ .Values.persistence.subPath }}
            {{- end }}
          - name: tmp
            mountPath: /tmp
          {{- $root := . }}
          {{- range .Values.volumes }}
          - name: {{ tpl (.name) $root | replace "." "-" }}
            mountPath: {{ .mountPath }}
            readOnly: true
          {{- end }}
          {{- if .Values.experimental.plugins.enabled }}
          - name: plugins
            mountPath: "/plugins-storage"
          {{- end }}
          {{- if .Values.additionalVolumeMounts }}
            {{- toYaml .Values.additionalVolumeMounts | nindent 10 }}
          {{- end }}
        args:
          {{- with .Values.globalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
          {{- range $name, $config := .Values.ports }}
          {{- if $config }}
          - "--entrypoints.{{$name}}.address=:{{ $config.port }}/{{ default "tcp" $config.protocol | lower }}"
          {{- with $config.asDefault }}
          {{- if semverCompare "<3.0.0-0" (include "imageVersion" $) }}
            {{- fail "ERROR: Default entrypoints are only available on Traefik v3. Please set `image.tag` to `v3.x`." }}
          {{- end }}
          - "--entrypoints.{{$name}}.asDefault={{ . }}"
          {{- end }}
          {{- end }}
          {{- end }}
          - "--api.dashboard=true"
          - "--ping=true"

          {{- if .Values.metrics }}
          {{- with .Values.metrics.datadog }}
          - "--metrics.datadog=true"
           {{- with .address }}
          - "--metrics.datadog.address={{ . }}"
           {{- end }}
           {{- with .pushInterval }}
          - "--metrics.datadog.pushInterval={{ . }}"
           {{- end }}
           {{- with .prefix }}
          - "--metrics.datadog.prefix={{ . }}"
           {{- end }}
           {{- if ne .addRoutersLabels nil }}
            {{- with .addRoutersLabels | toString }}
          - "--metrics.datadog.addRoutersLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.datadog.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.datadog.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}

          {{- with .Values.metrics.influxdb }}
          - "--metrics.influxdb=true"
          - "--metrics.influxdb.address={{ .address }}"
          - "--metrics.influxdb.protocol={{ .protocol }}"
           {{- with .database }}
          - "--metrics.influxdb.database={{ . }}"
           {{- end }}
           {{- with .retentionPolicy }}
          - "--metrics.influxdb.retentionPolicy={{ . }}"
           {{- end }}
           {{- with .username }}
          - "--metrics.influxdb.username={{ . }}"
           {{- end }}
           {{- with .password }}
          - "--metrics.influxdb.password={{ . }}"
           {{- end }}
           {{- with .pushInterval }}
          - "--metrics.influxdb.pushInterval={{ . }}"
           {{- end }}
           {{- range $name, $value := .additionalLabels }}
          - "--metrics.influxdb.additionalLabels.{{ $name }}={{ $value }}"
           {{- end }}
           {{- if ne .addRoutersLabels nil }}
            {{- with .addRoutersLabels | toString }}
          - "--metrics.influxdb.addRoutersLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.influxdb.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.influxdb.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}

          {{- with .Values.metrics.influxdb2 }}
          - "--metrics.influxdb2=true"
          - "--metrics.influxdb2.address={{ .address }}"
          - "--metrics.influxdb2.token={{ .token }}"
          - "--metrics.influxdb2.org={{ .org }}"
          - "--metrics.influxdb2.bucket={{ .bucket }}"
           {{- with .pushInterval }}
          - "--metrics.influxdb2.pushInterval={{ . }}"
           {{- end }}
           {{- range $name, $value := .additionalLabels }}
          - "--metrics.influxdb2.additionalLabels.{{ $name }}={{ $value }}"
           {{- end }}
           {{- if ne .addRoutersLabels nil }}
            {{- with .addRoutersLabels | toString }}
          - "--metrics.influxdb2.addRoutersLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.influxdb2.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.influxdb2.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}
          {{- if (.Values.metrics.prometheus) }}
          - "--metrics.prometheus=true"
          - "--metrics.prometheus.entrypoint={{ .Values.metrics.prometheus.entryPoint }}"
          {{- if (eq (.Values.metrics.prometheus.addRoutersLabels | toString) "true") }}
          - "--metrics.prometheus.addRoutersLabels=true"
          {{- end }}
          {{- if ne .Values.metrics.prometheus.addEntryPointsLabels nil }}
           {{- with .Values.metrics.prometheus.addEntryPointsLabels | toString }}
          - "--metrics.prometheus.addEntryPointsLabels={{ . }}"
           {{- end }}
          {{- end }}
          {{- if ne .Values.metrics.prometheus.addServicesLabels nil }}
           {{- with .Values.metrics.prometheus.addServicesLabels| toString }}
          - "--metrics.prometheus.addServicesLabels={{ . }}"
           {{- end }}
          {{- end }}
          {{- if .Values.metrics.prometheus.buckets }}
          - "--metrics.prometheus.buckets={{ .Values.metrics.prometheus.buckets }}"
          {{- end }}
          {{- if .Values.metrics.prometheus.manualRouting }}
          - "--metrics.prometheus.manualrouting=true"
          {{- end }}
          {{- end }}
          {{- with .Values.metrics.statsd }}
          - "--metrics.statsd=true"
          - "--metrics.statsd.address={{ .address }}"
           {{- with .pushInterval }}
          - "--metrics.statsd.pushInterval={{ . }}"
           {{- end }}
           {{- with .prefix }}
          - "--metrics.statsd.prefix={{ . }}"
           {{- end }}
           {{- if .addRoutersLabels}}
          - "--metrics.statsd.addRoutersLabels=true"
           {{- end }}
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.statsd.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.statsd.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}

          {{- end }}

          {{- with .Values.metrics.openTelemetry }}
           {{- if semverCompare "<3.0.0-0" (include "imageVersion" $) }}
             {{- fail "ERROR: OpenTelemetry features are only available on Traefik v3. Please set `image.tag` to `v3.x`." }}
           {{- end }}
          - "--metrics.openTelemetry=true"
          - "--metrics.openTelemetry.address={{ .address }}"
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.openTelemetry.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addRoutersLabels nil }}
            {{- with .addRoutersLabels | toString }}
          - "--metrics.openTelemetry.addRoutersLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.openTelemetry.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- with .explicitBoundaries }}
          - "--metrics.openTelemetry.explicitBoundaries={{ join "," . }}"
           {{- end }}
           {{- with .headers }}
            {{- range $name, $value := . }}
          - "--metrics.openTelemetry.headers.{{ $name }}={{ $value }}"
            {{- end }}
           {{- end }}
           {{- with .insecure }}
          - "--metrics.openTelemetry.insecure={{ . }}"
           {{- end }}
           {{- with .pushInterval }}
          - "--metrics.openTelemetry.pushInterval={{ . }}"
           {{- end }}
           {{- with .path }}
          - "--metrics.openTelemetry.path={{ . }}"
           {{- end }}
           {{- with .tls }}
            {{- with .ca }}
          - "--metrics.openTelemetry.tls.ca={{ . }}"
            {{- end }}
            {{- with .cert }}
          - "--metrics.openTelemetry.tls.cert={{ . }}"
            {{- end }}
            {{- with .key }}
          - "--metrics.openTelemetry.tls.key={{ . }}"
            {{- end }}
            {{- with .insecureSkipVerify }}
          - "--metrics.openTelemetry.tls.insecureSkipVerify={{ . }}"
            {{- end }}
           {{- end }}
           {{- with .grpc }}
          - "--metrics.openTelemetry.grpc={{ . }}"
           {{- end }}
          {{- end }}

          {{- if .Values.tracing }}

          {{- if .Values.tracing.openTelemetry }}
           {{- if semverCompare "<3.0.0-0" (include "imageVersion" $) }}
             {{- fail "ERROR: OpenTelemetry features are only available on Traefik v3. Please set `image.tag` to `v3.x`." }}
           {{- end }}
          - "--tracing.openTelemetry=true"
          - "--tracing.openTelemetry.address={{ required "ERROR: When enabling openTelemetry on tracing, `tracing.openTelemetry.address` is required." .Values.tracing.openTelemetry.address }}"
          {{- range $key, $value := .Values.tracing.openTelemetry.headers }}
          - "--tracing.openTelemetry.headers.{{ $key }}={{ $value }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.insecure }}
          - "--tracing.openTelemetry.insecure={{ .Values.tracing.openTelemetry.insecure }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.path }}
          - "--tracing.openTelemetry.path={{ .Values.tracing.openTelemetry.path }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.tls }}
          {{- if .Values.tracing.openTelemetry.tls.ca }}
          - "--tracing.openTelemetry.tls.ca={{ .Values.tracing.openTelemetry.tls.ca }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.tls.cert }}
          - "--tracing.openTelemetry.tls.cert={{ .Values.tracing.openTelemetry.tls.cert }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.tls.key }}
          - "--tracing.openTelemetry.tls.key={{ .Values.tracing.openTelemetry.tls.key }}"
          {{- end }}
          {{- if .Values.tracing.openTelemetry.tls.insecureSkipVerify }}
          - "--tracing.openTelemetry.tls.insecureSkipVerify={{ .Values.tracing.openTelemetry.tls.insecureSkipVerify }}"
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.openTelemetry.grpc }}
          - "--tracing.openTelemetry.grpc=true"
          {{- end }}
          {{- end }}

          {{- if .Values.tracing.instana }}
          - "--tracing.instana=true"
          {{- if .Values.tracing.instana.localAgentHost }}
          - "--tracing.instana.localAgentHost={{ .Values.tracing.instana.localAgentHost }}"
          {{- end }}
          {{- if .Values.tracing.instana.localAgentPort }}
          - "--tracing.instana.localAgentPort={{ .Values.tracing.instana.localAgentPort }}"
          {{- end }}
          {{- if .Values.tracing.instana.logLevel }}
          - "--tracing.instana.logLevel={{ .Values.tracing.instana.logLevel }}"
          {{- end }}
          {{- if .Values.tracing.instana.enableAutoProfile }}
          - "--tracing.instana.enableAutoProfile={{ .Values.tracing.instana.enableAutoProfile }}"
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.datadog }}
          - "--tracing.datadog=true"
          {{- if .Values.tracing.datadog.localAgentHostPort }}
          - "--tracing.datadog.localAgentHostPort={{ .Values.tracing.datadog.localAgentHostPort }}"
          {{- end }}
          {{- if .Values.tracing.datadog.debug }}
          - "--tracing.datadog.debug=true"
          {{- end }}
          {{- if .Values.tracing.datadog.globalTag }}
          - "--tracing.datadog.globalTag={{ .Values.tracing.datadog.globalTag }}"
          {{- end }}
          {{- if .Values.tracing.datadog.prioritySampling }}
          - "--tracing.datadog.prioritySampling=true"
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.jaeger }}
          - "--tracing.jaeger=true"
          {{- if .Values.tracing.jaeger.samplingServerURL }}
          - "--tracing.jaeger.samplingServerURL={{ .Values.tracing.jaeger.samplingServerURL }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.samplingType }}
          - "--tracing.jaeger.samplingType={{ .Values.tracing.jaeger.samplingType }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.samplingParam }}
          - "--tracing.jaeger.samplingParam={{ .Values.tracing.jaeger.samplingParam }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.localAgentHostPort }}
          - "--tracing.jaeger.localAgentHostPort={{ .Values.tracing.jaeger.localAgentHostPort }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.gen128Bit }}
          - "--tracing.jaeger.gen128Bit={{ .Values.tracing.jaeger.gen128Bit }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.propagation }}
          - "--tracing.jaeger.propagation={{ .Values.tracing.jaeger.propagation }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.traceContextHeaderName }}
          - "--tracing.jaeger.traceContextHeaderName={{ .Values.tracing.jaeger.traceContextHeaderName }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.disableAttemptReconnecting }}
          - "--tracing.jaeger.disableAttemptReconnecting={{ .Values.tracing.jaeger.disableAttemptReconnecting }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.collector }}
          {{- if .Values.tracing.jaeger.collector.endpoint }}
          - "--tracing.jaeger.collector.endpoint={{ .Values.tracing.jaeger.collector.endpoint }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.collector.user }}
          - "--tracing.jaeger.collector.user={{ .Values.tracing.jaeger.collector.user }}"
          {{- end }}
          {{- if .Values.tracing.jaeger.collector.password }}
          - "--tracing.jaeger.collector.password={{ .Values.tracing.jaeger.collector.password }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.zipkin }}
          - "--tracing.zipkin=true"
          {{- if .Values.tracing.zipkin.httpEndpoint }}
          - "--tracing.zipkin.httpEndpoint={{ .Values.tracing.zipkin.httpEndpoint }}"
          {{- end }}
          {{- if .Values.tracing.zipkin.sameSpan }}
          - "--tracing.zipkin.sameSpan={{ .Values.tracing.zipkin.sameSpan }}"
          {{- end }}
          {{- if .Values.tracing.zipkin.id128Bit }}
          - "--tracing.zipkin.id128Bit={{ .Values.tracing.zipkin.id128Bit }}"
          {{- end }}
          {{- if .Values.tracing.zipkin.sampleRate }}
          - "--tracing.zipkin.sampleRate={{ .Values.tracing.zipkin.sampleRate }}"
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.haystack }}
          - "--tracing.haystack=true"
          {{- if .Values.tracing.haystack.localAgentHost }}
          - "--tracing.haystack.localAgentHost={{ .Values.tracing.haystack.localAgentHost }}"
          {{- end }}
          {{- if .Values.tracing.haystack.localAgentPort }}
          - "--tracing.haystack.localAgentPort={{ .Values.tracing.haystack.localAgentPort }}"
          {{- end }}
          {{- if .Values.tracing.haystack.globalTag }}
          - "--tracing.haystack.globalTag={{ .Values.tracing.haystack.globalTag }}"
          {{- end }}
          {{- if .Values.tracing.haystack.traceIDHeaderName }}
          - "--tracing.haystack.traceIDHeaderName={{ .Values.tracing.haystack.traceIDHeaderName }}"
          {{- end }}
          {{- if .Values.tracing.haystack.parentIDHeaderName }}
          - "--tracing.haystack.parentIDHeaderName={{ .Values.tracing.haystack.parentIDHeaderName }}"
          {{- end }}
          {{- if .Values.tracing.haystack.spanIDHeaderName }}
          - "--tracing.haystack.spanIDHeaderName={{ .Values.tracing.haystack.spanIDHeaderName }}"
          {{- end }}
          {{- if .Values.tracing.haystack.baggagePrefixHeaderName }}
          - "--tracing.haystack.baggagePrefixHeaderName={{ .Values.tracing.haystack.baggagePrefixHeaderName }}"
          {{- end }}
          {{- end }}
          {{- if .Values.tracing.elastic }}
          - "--tracing.elastic=true"
          {{- if .Values.tracing.elastic.serverURL }}
          - "--tracing.elastic.serverURL={{ .Values.tracing.elastic.serverURL }}"
          {{- end }}
          {{- if .Values.tracing.elastic.secretToken }}
          - "--tracing.elastic.secretToken={{ .Values.tracing.elastic.secretToken }}"
          {{- end }}
          {{- if .Values.tracing.elastic.serviceEnvironment }}
          - "--tracing.elastic.serviceEnvironment={{ .Values.tracing.elastic.serviceEnvironment }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- if .Values.providers.kubernetesCRD.enabled }}
          - "--providers.kubernetescrd"
          {{- if .Values.providers.kubernetesCRD.labelSelector }}
          - "--providers.kubernetescrd.labelSelector={{ .Values.providers.kubernetesCRD.labelSelector }}"
          {{- end }}
          {{- if .Values.providers.kubernetesCRD.ingressClass }}
          - "--providers.kubernetescrd.ingressClass={{ .Values.providers.kubernetesCRD.ingressClass }}"
          {{- end }}
          {{- if .Values.providers.kubernetesCRD.allowCrossNamespace }}
          - "--providers.kubernetescrd.allowCrossNamespace=true"
          {{- end }}
          {{- if .Values.providers.kubernetesCRD.allowExternalNameServices }}
          - "--providers.kubernetescrd.allowExternalNameServices=true"
          {{- end }}
          {{- if .Values.providers.kubernetesCRD.allowEmptyServices }}
          - "--providers.kubernetescrd.allowEmptyServices=true"
          {{- end }}
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.enabled }}
          - "--providers.kubernetesingress"
          {{- if .Values.providers.kubernetesIngress.allowExternalNameServices }}
          - "--providers.kubernetesingress.allowExternalNameServices=true"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.allowEmptyServices }}
          - "--providers.kubernetesingress.allowEmptyServices=true"
          {{- end }}
          {{- if and .Values.service.enabled .Values.providers.kubernetesIngress.publishedService.enabled }}
          - "--providers.kubernetesingress.ingressendpoint.publishedservice={{ template "providers.kubernetesIngress.publishedServicePath" . }}"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.labelSelector }}
          - "--providers.kubernetesingress.labelSelector={{ .Values.providers.kubernetesIngress.labelSelector }}"
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.ingressClass }}
          - "--providers.kubernetesingress.ingressClass={{ .Values.providers.kubernetesIngress.ingressClass }}"
          {{- end }}
          {{- end }}
          {{- if .Values.experimental.kubernetesGateway.enabled }}
          - "--providers.kubernetesgateway"
          - "--experimental.kubernetesgateway"
          {{- end }}
          {{- with .Values.providers.kubernetesCRD }}
          {{- if (and .enabled (or .namespaces (and $.Values.rbac.enabled $.Values.rbac.namespaced))) }}
          - "--providers.kubernetescrd.namespaces={{ template "providers.kubernetesCRD.namespaces" $ }}"
          {{- end }}
          {{- end }}
          {{- with .Values.providers.kubernetesIngress }}
          {{- if (and .enabled (or .namespaces (and $.Values.rbac.enabled $.Values.rbac.namespaced))) }}
          - "--providers.kubernetesingress.namespaces={{ template "providers.kubernetesIngress.namespaces" $ }}"
          {{- end }}
          {{- end }}
          {{- range $entrypoint, $config := $.Values.ports }}
          {{- if $config }}
            {{- if $config.redirectTo }}
             {{- if eq (typeOf $config.redirectTo) "string" }}
               {{- fail "ERROR: Syntax of `ports.web.redirectTo` has changed to `ports.web.redirectTo.port`. Details in PR #934." }}
             {{- end }}
             {{- $toPort := index $.Values.ports $config.redirectTo.port }}
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.to=:{{ $toPort.exposedPort }}"
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.scheme=https"
             {{- if $config.redirectTo.priority }}
          - "--entrypoints.{{ $entrypoint }}.http.redirections.entryPoint.priority={{ $config.redirectTo.priority }}"
             {{- end }}
            {{- end }}
            {{- if $config.middlewares }}
          - "--entrypoints.{{ $entrypoint }}.http.middlewares={{ join "," $config.middlewares }}"
            {{- end }}
            {{- if $config.tls }}
              {{- if $config.tls.enabled }}
          - "--entrypoints.{{ $entrypoint }}.http.tls=true"
                {{- if $config.tls.options }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.options={{ $config.tls.options }}"
                {{- end }}
                {{- if $config.tls.certResolver }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.certResolver={{ $config.tls.certResolver }}"
                {{- end }}
                {{- if $config.tls.domains }}
                  {{- range $index, $domain := $config.tls.domains }}
                    {{- if $domain.main }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].main={{ $domain.main }}"
                    {{- end }}
                    {{- if $domain.sans }}
          - "--entrypoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].sans={{ join "," $domain.sans }}"
                    {{- end }}
                  {{- end }}
                {{- end }}
                {{- if $config.http3 }}
                  {{- if $config.http3.enabled }}
                    {{- if semverCompare "<3.0.0-0" (include "imageVersion" $)}}
          - "--experimental.http3=true"
                    {{- end }}
                    {{- if semverCompare ">=2.6.0-0" (include "imageVersion" $)}}
          - "--entrypoints.{{ $entrypoint }}.http3"
                    {{- else }}
          - "--entrypoints.{{ $entrypoint }}.enableHTTP3=true"
                    {{- end }}
                    {{- if $config.http3.advertisedPort }}
          - "--entrypoints.{{ $entrypoint }}.http3.advertisedPort={{ $config.http3.advertisedPort }}"
                    {{- end }}
                  {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
            {{- if $config.forwardedHeaders }}
              {{- if $config.forwardedHeaders.trustedIPs }}
          - "--entrypoints.{{ $entrypoint }}.forwardedHeaders.trustedIPs={{ join "," $config.forwardedHeaders.trustedIPs }}"
              {{- end }}
              {{- if $config.forwardedHeaders.insecure }}
          - "--entrypoints.{{ $entrypoint }}.forwardedHeaders.insecure"
              {{- end }}
            {{- end }}
            {{- if $config.proxyProtocol }}
              {{- if $config.proxyProtocol.trustedIPs }}
          - "--entrypoints.{{ $entrypoint }}.proxyProtocol.trustedIPs={{ join "," $config.proxyProtocol.trustedIPs }}"
              {{- end }}
              {{- if $config.proxyProtocol.insecure }}
          - "--entrypoints.{{ $entrypoint }}.proxyProtocol.insecure"
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.logs }}
          {{- if .general.format }}
          - "--log.format={{ .general.format }}"
          {{- end }}
          {{- if ne .general.level "ERROR" }}
          - "--log.level={{ .general.level | upper }}"
          {{- end }}
          {{- if .access.enabled }}
          - "--accesslog=true"
          {{- if .access.format }}
          - "--accesslog.format={{ .access.format }}"
          {{- end }}
          {{- if .access.filePath }}
          - "--accesslog.filepath={{ .access.filePath }}"
          {{- end }}
          {{- if .access.bufferingSize }}
          - "--accesslog.bufferingsize={{ .access.bufferingSize }}"
          {{- end }}
          {{- if .access.filters }}
          {{- if .access.filters.statuscodes }}
          - "--accesslog.filters.statuscodes={{ .access.filters.statuscodes }}"
          {{- end }}
          {{- if .access.filters.retryattempts }}
          - "--accesslog.filters.retryattempts"
          {{- end }}
          {{- if .access.filters.minduration }}
          - "--accesslog.filters.minduration={{ .access.filters.minduration }}"
          {{- end }}
          {{- end }}
          - "--accesslog.fields.defaultmode={{ .access.fields.general.defaultmode }}"
          {{- range $fieldname, $fieldaction := .access.fields.general.names }}
          - "--accesslog.fields.names.{{ $fieldname }}={{ $fieldaction }}"
          {{- end }}
          - "--accesslog.fields.headers.defaultmode={{ .access.fields.headers.defaultmode }}"
          {{- range $fieldname, $fieldaction := .access.fields.headers.names }}
          - "--accesslog.fields.headers.names.{{ $fieldname }}={{ $fieldaction }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- range $resolver, $config := $.Values.certResolvers }}
          {{- range $option, $setting := $config }}
          {{- if kindIs "map" $setting }}
          {{- range $field, $value := $setting }}
          - "--certificatesresolvers.{{ $resolver }}.acme.{{ $option }}.{{ $field }}={{ if kindIs "slice" $value }}{{ join "," $value }}{{ else }}{{ $value }}{{ end }}"
          {{- end }}
          {{- else }}
          - "--certificatesresolvers.{{ $resolver }}.acme.{{ $option }}={{ $setting }}"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.additionalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
        {{- with .Values.env }}
        env:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.envFrom }}
        envFrom:
          {{- toYaml . | nindent 10 }}
        {{- end }}
      {{- if .Values.deployment.additionalContainers }}
        {{- toYaml .Values.deployment.additionalContainers | nindent 6 }}
      {{- end }}
      volumes:
        - name: {{ .Values.persistence.name }}
          {{- if .Values.persistence.enabled }}
          persistentVolumeClaim:
            claimName: {{ default (include "traefik.fullname" .) .Values.persistence.existingClaim }}
          {{- else }}
          emptyDir: {}
          {{- end }}
        - name: tmp
          emptyDir: {}
        {{- $root := . }}
        {{- range .Values.volumes }}
        - name: {{ tpl (.name) $root | replace "." "-" }}
          {{- if eq .type "secret" }}
          secret:
            secretName: {{ tpl (.name) $root }}
          {{- else if eq .type "configMap" }}
          configMap:
            name: {{ tpl (.name) $root }}
          {{- end }}
        {{- end }}
        {{- if .Values.deployment.additionalVolumes }}
          {{- toYaml .Values.deployment.additionalVolumes | nindent 8 }}
        {{- end }}
        {{- if .Values.experimental.plugins.enabled }}
        - name: plugins
          emptyDir: {}
        {{- end }}
      {{- if .Values.affinity }}
      affinity:
        {{- tpl (toYaml .Values.affinity) . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.priorityClassName }}
      priorityClassName: {{ .Values.priorityClassName }}
      {{- end }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.topologySpreadConstraints }}
      {{- if (semverCompare "<1.19.0-0" .Capabilities.KubeVersion.Version) }}
        {{- fail "ERROR: topologySpreadConstraints are supported only on kubernetes >= v1.19" -}}
      {{- end }}
      topologySpreadConstraints:
        {{- tpl (toYaml .Values.topologySpreadConstraints) . | nindent 8 }}
      {{- end }}
{{ end -}}
