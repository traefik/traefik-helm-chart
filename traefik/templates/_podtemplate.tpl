{{- define "traefik.podTemplate" }}
  {{- $version := include "proxyVersion" $ }}
    metadata:
      annotations:
      {{- if .Values.deployment.podAnnotations }}
        {{- tpl (toYaml .Values.deployment.podAnnotations) . | nindent 8 }}
      {{- end }}
      {{- if .Values.metrics }}
      {{- if and (.Values.metrics.prometheus) (not (.Values.metrics.prometheus.serviceMonitor).enabled) }}
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
      automountServiceAccountToken: true
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
      {{- with .Values.deployment.hostAliases }}
      hostAliases: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.deployment.initContainers }}
      initContainers:
      {{- toYaml . | nindent 6 }}
      {{- end }}
      {{- if .Values.deployment.shareProcessNamespace }}
      shareProcessNamespace: true
      {{- end }}
      {{- with .Values.deployment.runtimeClassName }}
      runtimeClassName: {{ . }}
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
        {{- $healthchecksHost := (default (.Values.ports.traefik).hostIP .Values.deployment.healthchecksHost) }}
        {{- $healthchecksScheme := (default "HTTP" .Values.deployment.healthchecksScheme) }}
        {{- $readinessPath := (default "/ping" .Values.deployment.readinessPath) }}
        {{- $livenessPath := (default "/ping" .Values.deployment.livenessPath) }}
        readinessProbe:
          httpGet:
            {{- with $healthchecksHost }}
            host: {{ . }}
            {{- end }}
            path: {{ $readinessPath }}
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml .Values.readinessProbe | nindent 10 }}
        livenessProbe:
          httpGet:
            {{- with $healthchecksHost }}
            host: {{ . }}
            {{- end }}
            path: {{ $livenessPath }}
            port: {{ $healthchecksPort }}
            scheme: {{ $healthchecksScheme }}
          {{- toYaml .Values.livenessProbe | nindent 10 }}
        {{- with .Values.startupProbe}}
        startupProbe:
          {{- toYaml . | nindent 10 }}
        {{- end }}
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
        - name: {{ include "traefik.portname" $name }}
          containerPort: {{ default $config.port $config.containerPort }}
          {{- if $config.hostPort }}
          hostPort: {{ $config.hostPort }}
          {{- end }}
          {{- if $config.hostIP }}
          hostIP: {{ $config.hostIP }}
          {{- end }}
          protocol: {{ default "TCP" $config.protocol }}
          {{- if ($config.http3).enabled }}
        - name: {{ printf "%s-http3" $name | include "traefik.portname" }}
          containerPort: {{ $config.port }}
           {{- if $config.hostPort }}
          hostPort: {{ default $config.hostPort $config.http3.advertisedPort }}
           {{- end }}
          protocol: UDP
          {{- end }}
         {{- end }}
        {{- end }}
        {{- if .Values.hub.token }}
          {{- $listenAddr := default ":9943" .Values.hub.apimanagement.admission.listenAddr }}
        - name: admission
          containerPort: {{ last (mustRegexSplit ":" $listenAddr 2) }}
          protocol: TCP
          {{- if .Values.hub.apimanagement.enabled }}
        - name: apiportal
          containerPort: 9903
          protocol: TCP
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
          {{- if and (gt (len .Values.experimental.plugins) 0) (ne (include "traefik.hasPluginsVolume" .Values.deployment.additionalVolumes) "true") }}
          - name: plugins
            mountPath: "/plugins-storage"
          {{- end }}
          {{- if .Values.providers.file.enabled }}
          - name: traefik-extra-config
            mountPath: "/etc/traefik/dynamic"
          {{- end }}
          {{- if .Values.additionalVolumeMounts }}
            {{- tpl (toYaml .Values.additionalVolumeMounts) . | nindent 10 }}
          {{- end }}
        args:
          {{- with .Values.globalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
          {{- range $name, $config := .Values.ports }}
           {{- if $config }}
          - "--entryPoints.{{$name}}.address={{ $config.hostIP }}:{{ $config.port }}/{{ default "tcp" $config.protocol | lower }}"
            {{- with $config.asDefault }}
          - "--entryPoints.{{$name}}.asDefault={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}
          - "--api.dashboard=true"
          - "--ping=true"

          {{- with .Values.core }}
           {{- with .defaultRuleSyntax }}
          - "--core.defaultRuleSyntax={{ . }}"
           {{- end }}
          {{- end }}

          {{- if .Values.metrics }}
          {{- if .Values.metrics.addInternals }}
          - "--metrics.addinternals"
          {{- end }}
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
          {{- if .Values.metrics.prometheus.headerLabels }}
          {{- range $label, $headerKey := .Values.metrics.prometheus.headerLabels }}
          - "--metrics.prometheus.headerlabels.{{ $label }}={{ $headerKey }}"
          {{- end }}
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

          {{- with .Values.metrics.otlp }}
          {{- if .enabled }}
          - "--metrics.otlp=true"
           {{- if ne .addEntryPointsLabels nil }}
            {{- with .addEntryPointsLabels | toString }}
          - "--metrics.otlp.addEntryPointsLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addRoutersLabels nil }}
            {{- with .addRoutersLabels | toString }}
          - "--metrics.otlp.addRoutersLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- if ne .addServicesLabels nil }}
            {{- with .addServicesLabels | toString }}
          - "--metrics.otlp.addServicesLabels={{ . }}"
            {{- end }}
           {{- end }}
           {{- with .explicitBoundaries }}
          - "--metrics.otlp.explicitBoundaries={{ join "," . }}"
           {{- end }}
           {{- with .pushInterval }}
          - "--metrics.otlp.pushInterval={{ . }}"
           {{- end }}
           {{- with .http }}
            {{- if .enabled }}
          - "--metrics.otlp.http=true"
             {{- with .endpoint }}
          - "--metrics.otlp.http.endpoint={{ . }}"
             {{- end }}
             {{- range $name, $value := .headers }}
          - "--metrics.otlp.http.headers.{{ $name }}={{ $value }}"
             {{- end }}
             {{- with .tls }}
              {{- with .ca }}
          - "--metrics.otlp.http.tls.ca={{ . }}"
              {{- end }}
              {{- with .cert }}
          - "--metrics.otlp.http.tls.cert={{ . }}"
              {{- end }}
              {{- with .key }}
          - "--metrics.otlp.http.tls.key={{ . }}"
              {{- end }}
              {{- with .insecureSkipVerify }}
          - "--metrics.otlp.http.tls.insecureSkipVerify={{ . }}"
              {{- end }}
             {{- end }}
            {{- end }}
           {{- end }}
           {{- with .grpc }}
            {{- if .enabled }}
          - "--metrics.otlp.grpc=true"
             {{- with .endpoint }}
          - "--metrics.otlp.grpc.endpoint={{ . }}"
             {{- end }}
             {{- with .insecure }}
          - "--metrics.otlp.grpc.insecure={{ . }}"
             {{- end }}
             {{- range $name, $value := .headers }}
          - "--metrics.otlp.grpc.headers.{{ $name }}={{ $value }}"
             {{- end }}
             {{- with .tls }}
              {{- with .ca }}
          - "--metrics.otlp.grpc.tls.ca={{ . }}"
              {{- end }}
              {{- with .cert }}
          - "--metrics.otlp.grpc.tls.cert={{ . }}"
              {{- end }}
              {{- with .key }}
          - "--metrics.otlp.grpc.tls.key={{ . }}"
              {{- end }}
              {{- with .insecureSkipVerify }}
          - "--metrics.otlp.grpc.tls.insecureSkipVerify={{ . }}"
              {{- end }}
             {{- end }}
            {{- end }}
           {{- end }}
          {{- end }}
          {{- end }}

          {{- if .Values.tracing.addInternals }}
          - "--tracing.addinternals"
          {{- end }}

          {{- with .Values.tracing }}
            {{- with .sampleRate }}
          - "--tracing.sampleRate={{ . }}"
            {{- end }}

            {{- with .serviceName }}
          - "--tracing.serviceName={{ . }}"
            {{- end }}

            {{- range $name, $value := .resourceAttributes }}
          - "--tracing.resourceAttributes.{{ $name }}={{ $value }}"
            {{- end }}

            {{- if .capturedRequestHeaders }}
          - "--tracing.capturedRequestHeaders={{ .capturedRequestHeaders | join "," }}"
            {{- end }}

            {{- if .capturedResponseHeaders }}
          - "--tracing.capturedResponseHeaders={{ .capturedResponseHeaders | join "," }}"
            {{- end }}

            {{- if .safeQueryParams }}
          - "--tracing.safeQueryParams={{ .safeQueryParams | join "," }}"
            {{- end }}

          {{- end }}

          {{- with .Values.tracing.otlp }}
          {{- if .enabled }}
          - "--tracing.otlp=true"
           {{- with .http }}
            {{- if .enabled }}
          - "--tracing.otlp.http=true"
             {{- with .endpoint }}
          - "--tracing.otlp.http.endpoint={{ . }}"
             {{- end }}
             {{- range $name, $value := .headers }}
          - "--tracing.otlp.http.headers.{{ $name }}={{ $value }}"
             {{- end }}
             {{- with .tls }}
              {{- with .ca }}
          - "--tracing.otlp.http.tls.ca={{ . }}"
              {{- end }}
              {{- with .cert }}
          - "--tracing.otlp.http.tls.cert={{ . }}"
              {{- end }}
              {{- with .key }}
          - "--tracing.otlp.http.tls.key={{ . }}"
              {{- end }}
              {{- with .insecureSkipVerify }}
          - "--tracing.otlp.http.tls.insecureSkipVerify={{ . }}"
              {{- end }}
             {{- end }}
            {{- end }}
           {{- end }}
           {{- with .grpc }}
            {{- if .enabled }}
          - "--tracing.otlp.grpc=true"
             {{- with .endpoint }}
          - "--tracing.otlp.grpc.endpoint={{ . }}"
             {{- end }}
             {{- with .insecure }}
          - "--tracing.otlp.grpc.insecure={{ . }}"
             {{- end }}
             {{- range $name, $value := .headers }}
          - "--tracing.otlp.grpc.headers.{{ $name }}={{ $value }}"
             {{- end }}
             {{- with .tls }}
              {{- with .ca }}
          - "--tracing.otlp.grpc.tls.ca={{ . }}"
              {{- end }}
              {{- with .cert }}
          - "--tracing.otlp.grpc.tls.cert={{ . }}"
              {{- end }}
              {{- with .key }}
          - "--tracing.otlp.grpc.tls.key={{ . }}"
              {{- end }}
              {{- with .insecureSkipVerify }}
          - "--tracing.otlp.grpc.tls.insecureSkipVerify={{ . }}"
              {{- end }}
             {{- end }}
            {{- end }}
           {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.experimental.fastProxy }}
            {{- if .enabled }}
          - "--experimental.fastProxy"
            {{- end }}
            {{- if .debug }}
          - "--experimental.fastProxy.debug"
            {{- end }}
          {{- end }}
          {{- range $pluginName, $plugin := .Values.experimental.plugins }}
          {{- if or (ne (typeOf $plugin) "map[string]interface {}") (not (hasKey $plugin "moduleName")) (not (hasKey $plugin "version")) }}
            {{- fail  (printf "ERROR: plugin %s is missing moduleName/version keys !" $pluginName) }}
          {{- end }}
          - "--experimental.plugins.{{ $pluginName }}.moduleName={{ $plugin.moduleName }}"
          - "--experimental.plugins.{{ $pluginName }}.version={{ $plugin.version }}"
          {{- end }}
          {{- if and (semverCompare ">=v3.3.0-0" $version) (.Values.experimental.abortOnPluginFailure)}}
          - "--experimental.abortonpluginfailure={{ .Values.experimental.abortOnPluginFailure }}"
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
           {{- if ne .Values.providers.kubernetesCRD.allowEmptyServices nil }}
            {{- with .Values.providers.kubernetesCRD.allowEmptyServices | toString }}
          - "--providers.kubernetescrd.allowEmptyServices={{ . }}"
            {{- end }}
           {{- end }}
           {{- if and .Values.rbac.namespaced (semverCompare ">=v3.1.2-0" $version) }}
          - "--providers.kubernetescrd.disableClusterScopeResources=true"
           {{- end }}
           {{- if .Values.providers.kubernetesCRD.nativeLBByDefault }}
          - "--providers.kubernetescrd.nativeLBByDefault=true"
           {{- end }}
          {{- end }}
          {{- if .Values.providers.kubernetesIngress.enabled }}
          - "--providers.kubernetesingress"
           {{- if .Values.providers.kubernetesIngress.allowExternalNameServices }}
          - "--providers.kubernetesingress.allowExternalNameServices=true"
           {{- end }}
           {{- if ne .Values.providers.kubernetesIngress.allowEmptyServices nil }}
            {{- with .Values.providers.kubernetesIngress.allowEmptyServices | toString }}
          - "--providers.kubernetesingress.allowEmptyServices={{ . }}"
            {{- end }}
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
           {{- if .Values.rbac.namespaced }}
            {{- if semverCompare "<v3.1.5-0" $version }}
          - "--providers.kubernetesingress.disableIngressClassLookup=true"
              {{- if semverCompare ">=v3.1.2-0" $version }}
          - "--providers.kubernetesingress.disableClusterScopeResources=true"
              {{- end }}
            {{- else }}
          - "--providers.kubernetesingress.disableClusterScopeResources=true"
            {{- end }}
           {{- end }}
           {{- if .Values.providers.kubernetesIngress.nativeLBByDefault }}
          - "--providers.kubernetesingress.nativeLBByDefault=true"
           {{- end }}
          {{- end }}
          {{- if .Values.experimental.kubernetesGateway.enabled }}
          - "--experimental.kubernetesgateway"
          {{- end }}
          {{- with .Values.providers.kubernetesCRD }}
          {{- if (and .enabled (or .namespaces (and $.Values.rbac.enabled $.Values.rbac.namespaced))) }}
          - "--providers.kubernetescrd.namespaces={{ template "providers.kubernetesCRD.namespaces" $ }}"
          {{- end }}
          {{- end }}
          {{- with .Values.providers.kubernetesGateway }}
           {{- if .enabled }}
          - "--providers.kubernetesgateway"
            {{- with .statusAddress }}
             {{- with .ip }}
          - "--providers.kubernetesgateway.statusaddress.ip={{ . }}"
             {{- end }}
             {{- with .hostname }}
          - "--providers.kubernetesgateway.statusaddress.hostname={{ . }}"
             {{- end }}
             {{- if (and .service.enabled $.Values.service.enabled) }}
          - "--providers.kubernetesgateway.statusaddress.service.name={{ .service.name | default (include "traefik.fullname" $) }}"
          - "--providers.kubernetesgateway.statusaddress.service.namespace={{ .service.namespace | default (include "traefik.namespace" $) }}"
             {{- end }}
            {{- end }}
            {{- if .nativeLBByDefault }}
          - "--providers.kubernetesgateway.nativeLBByDefault=true"
            {{- end }}
            {{- if or .namespaces (and $.Values.rbac.enabled $.Values.rbac.namespaced) }}
          - "--providers.kubernetesgateway.namespaces={{ template "providers.kubernetesGateway.namespaces" $ }}"
            {{- end }}
            {{- if .experimentalChannel }}
          - "--providers.kubernetesgateway.experimentalchannel=true"
            {{- end }}
            {{- with .labelselector }}
          - "--providers.kubernetesgateway.labelselector={{ . }}"
            {{- end }}
           {{- end }}
          {{- end }}
          {{- with .Values.providers.kubernetesIngress }}
          {{- if (and .enabled (or .namespaces (and $.Values.rbac.enabled $.Values.rbac.namespaced))) }}
          - "--providers.kubernetesingress.namespaces={{ template "providers.kubernetesIngress.namespaces" $ }}"
          {{- end }}
          {{- end }}
          {{- with .Values.providers.file }}
          {{- if .enabled }}
          - "--providers.file.directory=/etc/traefik/dynamic"
          {{- if .watch }}
          - "--providers.file.watch=true"
          {{- end }}
          {{- end }}
          {{- end }}
          {{- range $entrypoint, $config := $.Values.ports }}
          {{- if $config }}
            {{- if $config.redirectTo }}
              {{- fail "ERROR: redirectTo syntax has been removed in v34 of this Chart. See Release notes or EXAMPLES.md for new syntax." -}}
            {{- end }}
            {{- if $config.redirections }}
             {{- with $config.redirections.entryPoint }}
              {{- if not (hasKey $.Values.ports .to) }}
                {{- $errorMsg := printf "ERROR: Cannot redirect %s to %s: entryPoint not found" $entrypoint .to }}
                {{- fail $errorMsg }}
              {{- end }}
              {{- $toPort := index $.Values.ports .to }}
              {{- if and (($toPort.tls).enabled) (ne .scheme "https") }}
                {{- $errorMsg := printf "ERROR: Cannot redirect %s to %s without setting scheme to https" $entrypoint .to }}
                {{- fail $errorMsg }}
              {{- end }}
          - "--entryPoints.{{ $entrypoint }}.http.redirections.entryPoint.to=:{{ $toPort.exposedPort }}"
              {{- with .scheme }}
          - "--entryPoints.{{ $entrypoint }}.http.redirections.entryPoint.scheme={{ . }}"
              {{- end }}
              {{- with .priority }}
          - "--entryPoints.{{ $entrypoint }}.http.redirections.entryPoint.priority={{ . }}"
              {{- end }}
              {{- if hasKey . "permanent" }}
          - "--entryPoints.{{ $entrypoint }}.http.redirections.entryPoint.permanent={{ .permanent }}"
              {{- end }}
             {{- end }}
            {{- end }}
            {{- if $config.middlewares }}
          - "--entryPoints.{{ $entrypoint }}.http.middlewares={{ join "," $config.middlewares }}"
            {{- end }}
            {{- if $config.tls }}
              {{- if $config.tls.enabled }}
          - "--entryPoints.{{ $entrypoint }}.http.tls=true"
                {{- if $config.tls.options }}
          - "--entryPoints.{{ $entrypoint }}.http.tls.options={{ $config.tls.options }}"
                {{- end }}
                {{- if $config.tls.certResolver }}
          - "--entryPoints.{{ $entrypoint }}.http.tls.certResolver={{ $config.tls.certResolver }}"
                {{- end }}
                {{- if $config.tls.domains }}
                  {{- range $index, $domain := $config.tls.domains }}
                    {{- if $domain.main }}
          - "--entryPoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].main={{ $domain.main }}"
                    {{- end }}
                    {{- if $domain.sans }}
          - "--entryPoints.{{ $entrypoint }}.http.tls.domains[{{ $index }}].sans={{ join "," $domain.sans }}"
                    {{- end }}
                  {{- end }}
                {{- end }}
                {{- if $config.http3 }}
                  {{- if $config.http3.enabled }}
          - "--entryPoints.{{ $entrypoint }}.http3"
                    {{- if $config.http3.advertisedPort }}
          - "--entryPoints.{{ $entrypoint }}.http3.advertisedPort={{ $config.http3.advertisedPort }}"
                    {{- end }}
                  {{- end }}
                {{- end }}
              {{- end }}
            {{- end }}
            {{- if $config.allowACMEByPass }}
              {{- if (semverCompare "<v3.1.3-0" $version) }}
                {{- fail "ERROR: allowACMEByPass has been introduced with Traefik v3.1.3+" -}}
              {{- end }}
          - "--entryPoints.{{ $entrypoint }}.allowACMEByPass=true"
            {{- end }}
            {{- if $config.forwardedHeaders }}
              {{- if $config.forwardedHeaders.trustedIPs }}
          - "--entryPoints.{{ $entrypoint }}.forwardedHeaders.trustedIPs={{ join "," $config.forwardedHeaders.trustedIPs }}"
              {{- end }}
              {{- if $config.forwardedHeaders.insecure }}
          - "--entryPoints.{{ $entrypoint }}.forwardedHeaders.insecure"
              {{- end }}
            {{- end }}
            {{- if $config.proxyProtocol }}
              {{- if $config.proxyProtocol.trustedIPs }}
          - "--entryPoints.{{ $entrypoint }}.proxyProtocol.trustedIPs={{ join "," $config.proxyProtocol.trustedIPs }}"
              {{- end }}
              {{- if $config.proxyProtocol.insecure }}
          - "--entryPoints.{{ $entrypoint }}.proxyProtocol.insecure"
              {{- end }}
            {{- end }}
            {{- with $config.transport }}
              {{- with .respondingTimeouts }}
                {{- if and (ne .readTimeout nil) (toString .readTimeout) }}
          - "--entryPoints.{{ $entrypoint }}.transport.respondingTimeouts.readTimeout={{ .readTimeout }}"
                {{- end }}
                {{- if and (ne .writeTimeout nil) (toString .writeTimeout) }}
          - "--entryPoints.{{ $entrypoint }}.transport.respondingTimeouts.writeTimeout={{ .writeTimeout }}"
                {{- end }}
                {{- if and (ne .idleTimeout nil) (toString .idleTimeout) }}
          - "--entryPoints.{{ $entrypoint }}.transport.respondingTimeouts.idleTimeout={{ .idleTimeout }}"
                {{- end }}
              {{- end }}
              {{- with .lifeCycle }}
                {{- if and (ne .requestAcceptGraceTimeout nil) (toString .requestAcceptGraceTimeout) }}
          - "--entryPoints.{{ $entrypoint }}.transport.lifeCycle.requestAcceptGraceTimeout={{ .requestAcceptGraceTimeout }}"
                {{- end }}
                {{- if and (ne .graceTimeOut nil) (toString .graceTimeOut) }}
          - "--entryPoints.{{ $entrypoint }}.transport.lifeCycle.graceTimeOut={{ .graceTimeOut }}"
                {{- end }}
              {{- end }}
              {{- if and (ne .keepAliveMaxRequests nil) (toString .keepAliveMaxRequests) }}
          - "--entryPoints.{{ $entrypoint }}.transport.keepAliveMaxRequests={{ .keepAliveMaxRequests }}"
              {{- end }}
              {{- if and (ne .keepAliveMaxTime nil) (toString .keepAliveMaxTime) }}
          - "--entryPoints.{{ $entrypoint }}.transport.keepAliveMaxTime={{ .keepAliveMaxTime }}"
              {{- end }}
            {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.logs }}
            {{- if and .general.format (not (has .general.format (list "common" "json"))) }}
              {{- fail "ERROR: .Values.logs.general.format must be either common or json"  }}
            {{- end }}
            {{- with .general.format }}
          - "--log.format={{ . }}"
            {{- end }}
            {{- with .general.filePath }}
          - "--log.filePath={{ . }}"
            {{- end }}
            {{- if and (or (eq .general.format "common") (not .general.format)) (eq .general.noColor true) }}
          - "--log.noColor={{ .general.noColor }}"
            {{- end }}
            {{- with .general.level }}
          - "--log.level={{ . | upper }}"
            {{- end }}
            {{- if .access.enabled }}
          - "--accesslog=true"
              {{- with .access.format }}
          - "--accesslog.format={{ . }}"
              {{- end }}
              {{- with .access.filePath }}
          - "--accesslog.filepath={{ . }}"
              {{- end }}
              {{- if .access.addInternals }}
          - "--accesslog.addinternals"
              {{- end }}
              {{- with .access.bufferingSize }}
          - "--accesslog.bufferingsize={{ . }}"
              {{- end }}
              {{- with .access.filters }}
                {{- with .statuscodes }}
          - "--accesslog.filters.statuscodes={{ . }}"
                {{- end }}
                {{- if .retryattempts }}
          - "--accesslog.filters.retryattempts"
                {{- end }}
                {{- with .minduration }}
          - "--accesslog.filters.minduration={{ . }}"
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
          {{- include "traefik.yaml2CommandLineArgs" (dict "path" "certificatesresolvers" "content" $.Values.certificatesResolvers) | nindent 10 }}
          {{- with .Values.additionalArguments }}
          {{- range . }}
          - {{ . | quote }}
          {{- end }}
          {{- end }}
          {{- with .Values.hub }}
           {{- if .token }}
          - "--hub.token=$(HUB_TOKEN)"
            {{- if and (not .apimanagement.enabled) ($.Values.hub.apimanagement.admission.listenAddr) }}
               {{- fail "ERROR: Cannot configure admission without enabling hub.apimanagement" }}
            {{- end }}
            {{- with .apimanagement }}
             {{- if .enabled }}
              {{- $listenAddr := default ":9943" .admission.listenAddr }}
          - "--hub.apimanagement"
          - "--hub.apimanagement.admission.listenAddr={{ $listenAddr }}"
              {{- with .admission.secretName }}
          - "--hub.apimanagement.admission.secretName={{ . }}"
              {{- end }}
              {{- if .openApi.validateRequestMethodAndPath }}
          - "--hub.apiManagement.openApi.validateRequestMethodAndPath=true"
              {{- end }}
             {{- end }}
            {{- end }}
            {{- if .experimental.aigateway }}
          - "--hub.experimental.aigateway"
            {{- end -}}
            {{- with .platformUrl }}
          - "--hub.platformUrl={{ . }}"
            {{- end -}}
            {{- range $field, $value := .redis }}
             {{- if has $field (list "cluster" "database" "endpoints" "username" "password" "timeout") -}}
              {{- with $value }}
          - "--hub.redis.{{ $field }}={{ $value }}"
              {{- end }}
             {{- end }}
            {{- end }}
            {{- range $field, $value := .redis.sentinel }}
             {{- if has $field (list "masterset" "password" "username") -}}
              {{- with $value }}
          - "--hub.redis.sentinel.{{ $field }}={{ $value }}"
              {{- end }}
             {{- end }}
            {{- end }}
            {{- range $field, $value := .redis.tls }}
             {{- if has $field (list "ca" "cert" "insecureSkipVerify" "key") -}}
              {{- with $value }}
          - "--hub.redis.tls.{{ $field }}={{ $value }}"
              {{- end }}
             {{- end }}
            {{- end }}
            {{- with .sendlogs }}
          - "--hub.sendlogs={{ . }}"
            {{- end }}
            {{- if and $.Values.tracing.otlp.enabled .tracing.additionalTraceHeaders.enabled }}
              {{- include "traefik.yaml2CommandLineArgs" (dict "path" "hub.tracing.additionalTraceHeaders.traceContext" "content" $.Values.hub.tracing.additionalTraceHeaders.traceContext) | nindent 10 }}
            {{- end }}
            {{- if .providers.consulCatalogEnterprise.enabled }}
              {{- include "traefik.yaml2CommandLineArgs" (dict "path" "hub.providers.consulCatalogEnterprise" "content" (omit $.Values.hub.providers.consulCatalogEnterprise "enabled")) | nindent 10 }}
            {{- end }}
            {{- if .providers.microcks.enabled }}
              {{- include "traefik.yaml2CommandLineArgs" (dict "path" "hub.providers.microcks" "content" (omit $.Values.hub.providers.microcks "enabled")) | nindent 10 }}
            {{- end }}
          {{- end }}
         {{- end }}
        env:
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          {{- if ($.Values.resources.limits).cpu }}
          - name: GOMAXPROCS
            valueFrom:
              resourceFieldRef:
                resource: limits.cpu
                divisor: '1'
          {{- end }}
          {{- if ($.Values.resources.limits).memory }}
          - name: GOMEMLIMIT
            valueFrom:
              resourceFieldRef:
                resource: limits.memory
                divisor: '1'
          {{- end }}
          {{- with .Values.hub.token }}
          - name: HUB_TOKEN
            valueFrom:
              secretKeyRef:
                name: {{ . }}
                key: token
          {{- end }}
        {{- with .Values.env }}
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
        {{- if and (gt (len .Values.experimental.plugins) 0) (ne (include "traefik.hasPluginsVolume" .Values.deployment.additionalVolumes) "true") }}
        - name: plugins
          emptyDir: {}
        {{- end }}
        {{- if .Values.providers.file.enabled }}
        - name: traefik-extra-config
          configMap:
            name: {{ template "traefik.fullname" . }}-file-provider
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
      {{- if (semverCompare "<v1.19.0-0" .Capabilities.KubeVersion.Version) }}
        {{- fail "ERROR: topologySpreadConstraints are supported only on kubernetes >= v1.19" -}}
      {{- end }}
      topologySpreadConstraints:
        {{- tpl (toYaml .Values.topologySpreadConstraints) . | nindent 8 }}
      {{- end }}
{{ end -}}
