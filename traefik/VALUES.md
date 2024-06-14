# traefik

![Version: 28.3.0](https://img.shields.io/badge/Version-28.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v3.0.2](https://img.shields.io/badge/AppVersion-v3.0.2-informational?style=flat-square)

A Traefik based Kubernetes ingress controller

**Homepage:** <https://traefik.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| mloiseleur | <michel.loiseleur@traefik.io> |  |
| charlie-haley | <charlie.haley@traefik.io> |  |
| darkweaver87 | <remi.buisson@traefik.io> |  |
| jnoordsij |  |  |

## Source Code

* <https://github.com/traefik/traefik>
* <https://github.com/traefik/traefik-helm-chart>

## Requirements

Kubernetes: `>=1.22.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalArguments | list | `[]` | Additional arguments to be passed at Traefik's binary See [CLI Reference](https://docs.traefik.io/reference/static-configuration/cli/) Use curly braces to pass values: `helm install --set="additionalArguments={--providers.kubernetesingress.ingressclass=traefik-internal,--log.level=DEBUG}"` |
| additionalVolumeMounts | list | `[]` | Additional volumeMounts to add to the Traefik container |
| affinity | object | `{}` | on nodes where no other traefik pods are scheduled. It should be used when hostNetwork: true to prevent port conflicts |
| autoscaling.enabled | bool | `false` | Create HorizontalPodAutoscaler object. See EXAMPLES.md for more details. |
| certResolvers | object | `{}` | Certificates resolvers configuration. Ref: https://doc.traefik.io/traefik/https/acme/#certificate-resolvers See EXAMPLES.md for more details. |
| commonLabels | object | `{}` | Add additional label to all resources |
| core.defaultRuleSyntax | string | `nil` | Can be used to use globally v2 router syntax See https://doc.traefik.io/traefik/v3.0/migration/v2-to-v3/#new-v3-syntax-notable-changes |
| deployment.additionalContainers | list | `[]` | Additional containers (e.g. for metric offloading sidecars) |
| deployment.additionalVolumes | list | `[]` | Additional volumes available for use with initContainers and additionalContainers |
| deployment.annotations | object | `{}` | Additional deployment annotations (e.g. for jaeger-operator sidecar injection) |
| deployment.dnsConfig | object | `{}` | Custom pod DNS policy. Apply if `hostNetwork: true` dnsPolicy: ClusterFirstWithHostNet |
| deployment.enabled | bool | `true` | Enable deployment |
| deployment.imagePullSecrets | list | `[]` | Additional imagePullSecrets |
| deployment.initContainers | list | `[]` | Additional initContainers (e.g. for setting file permission as shown below) |
| deployment.kind | string | `"Deployment"` | Deployment or DaemonSet |
| deployment.labels | object | `{}` | Additional deployment labels (e.g. for filtering deployment by custom labels) |
| deployment.lifecycle | object | `{}` | Pod lifecycle actions |
| deployment.minReadySeconds | int | `0` | The minimum number of seconds Traefik needs to be up and running before the DaemonSet/Deployment controller considers it available |
| deployment.podAnnotations | object | `{}` | Additional pod annotations (e.g. for mesh injection or prometheus scraping) It supports templating. One can set it with values like traefik/name: '{{ template "traefik.name" . }}' |
| deployment.podLabels | object | `{}` | Additional Pod labels (e.g. for filtering Pod by custom labels) |
| deployment.replicas | int | `1` | Number of pods of the deployment (only applies when kind == Deployment) |
| deployment.runtimeClassName | string | `nil` | Set a runtimeClassName on pod |
| deployment.shareProcessNamespace | bool | `false` | Use process namespace sharing |
| deployment.terminationGracePeriodSeconds | int | `60` | Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if Traefik does not shut down |
| env | list | See _values.yaml_ | Environment variables to be passed to Traefik's binary |
| envFrom | list | `[]` | Environment variables to be passed to Traefik's binary from configMaps or secrets |
| experimental.kubernetesGateway.enabled | bool | `false` | Enable traefik experimental GatewayClass CRD |
| experimental.plugins | object | `{}` | Enable traefik experimental plugins |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template)  In some cases, it can avoid the need for additional, extended or adhoc deployments. See #595 for more details and traefik/tests/values/extra.yaml for example. |
| globalArguments | list | `["--global.checknewversion","--global.sendanonymoususage"]` | Global command arguments to be passed to all traefik's pods |
| hostNetwork | bool | `false` | If hostNetwork is true, runs traefik in the host network namespace To prevent unschedulabel pods due to port collisions, if hostNetwork=true and replicas>1, a pod anti-affinity is recommended and will be set if the affinity is left as default. |
| hub.apimanagement.admission.listenAddr | string | `nil` | WebHook admission server listen address. Default: "0.0.0.0:9943". |
| hub.apimanagement.admission.secretName | string | `nil` | Certificate of the WebHook admission server. Default: "hub-agent-cert". |
| hub.apimanagement.enabled | string | `nil` | Set to true in order to enable API Management. Requires a valid license token. |
| hub.ratelimit.redis.cluster | string | `nil` | Enable Redis Cluster. Default: true. |
| hub.ratelimit.redis.database | string | `nil` | Database used to store information. Default: "0". |
| hub.ratelimit.redis.endpoints | string | `nil` | Endpoints of the Redis instances to connect to. Default: "". |
| hub.ratelimit.redis.password | string | `nil` | The password to use when connecting to Redis endpoints. Default: "". |
| hub.ratelimit.redis.sentinel.masterset | string | `nil` | Name of the set of main nodes to use for main selection. Required when using Sentinel. Default: "". |
| hub.ratelimit.redis.sentinel.password | string | `nil` | Password to use for sentinel authentication (can be different from endpoint password). Default: "". |
| hub.ratelimit.redis.sentinel.username | string | `nil` | Username to use for sentinel authentication (can be different from endpoint username). Default: "". |
| hub.ratelimit.redis.timeout | string | `nil` | Timeout applied on connection with redis. Default: "0s". |
| hub.ratelimit.redis.tls.ca | string | `nil` | Path to the certificate authority used for the secured connection. |
| hub.ratelimit.redis.tls.cert | string | `nil` | Path to the public certificate used for the secure connection. |
| hub.ratelimit.redis.tls.insecureSkipVerify | string | `nil` | When insecureSkipVerify is set to true, the TLS connection accepts any certificate presented by the server. Default: false. |
| hub.ratelimit.redis.tls.key | string | `nil` | Path to the private key used for the secure connection. |
| hub.ratelimit.redis.username | string | `nil` | The username to use when connecting to Redis endpoints. Default: "". |
| hub.sendlogs | string | `nil` |  |
| hub.token | string | `nil` | Name of `Secret` with key 'token' set to a valid license token. It enables API Gateway. |
| image.pullPolicy | string | `"IfNotPresent"` | Traefik image pull policy |
| image.registry | string | `"docker.io"` | Traefik image host registry |
| image.repository | string | `"traefik"` | Traefik image repository |
| image.tag | string | `""` | defaults to appVersion |
| ingressClass | object | `{"enabled":true,"isDefaultClass":true}` | Create a default IngressClass for Traefik |
| ingressRoute.dashboard.annotations | object | `{}` | Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class) |
| ingressRoute.dashboard.enabled | bool | `true` | Create an IngressRoute for the dashboard |
| ingressRoute.dashboard.entryPoints | list | `["traefik"]` | Specify the allowed entrypoints to use for the dashboard ingress route, (e.g. traefik, web, websecure). By default, it's using traefik entrypoint, which is not exposed. /!\ Do not expose your dashboard without any protection over the internet /!\ |
| ingressRoute.dashboard.labels | object | `{}` | Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels) |
| ingressRoute.dashboard.matchRule | string | `"PathPrefix(`/dashboard`) || PathPrefix(`/api`)"` | The router match rule used for the dashboard ingressRoute |
| ingressRoute.dashboard.middlewares | list | `[]` | Additional ingressRoute middlewares (e.g. for authentication) |
| ingressRoute.dashboard.tls | object | `{}` | TLS options (e.g. secret containing certificate) |
| ingressRoute.healthcheck.annotations | object | `{}` | Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class) |
| ingressRoute.healthcheck.enabled | bool | `false` | Create an IngressRoute for the healthcheck probe |
| ingressRoute.healthcheck.entryPoints | list | `["traefik"]` | Specify the allowed entrypoints to use for the healthcheck ingress route, (e.g. traefik, web, websecure). By default, it's using traefik entrypoint, which is not exposed. |
| ingressRoute.healthcheck.labels | object | `{}` | Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels) |
| ingressRoute.healthcheck.matchRule | string | `"PathPrefix(`/ping`)"` | The router match rule used for the healthcheck ingressRoute |
| ingressRoute.healthcheck.middlewares | list | `[]` | Additional ingressRoute middlewares (e.g. for authentication) |
| ingressRoute.healthcheck.tls | object | `{}` | TLS options (e.g. secret containing certificate) |
| instanceLabelOverride | string | `nil` |  |
| livenessProbe.failureThreshold | int | `3` | The number of consecutive failures allowed before considering the probe as failed. |
| livenessProbe.initialDelaySeconds | int | `2` | The number of seconds to wait before starting the first probe. |
| livenessProbe.periodSeconds | int | `10` | The number of seconds to wait between consecutive probes. |
| livenessProbe.successThreshold | int | `1` | The minimum consecutive successes required to consider the probe successful. |
| livenessProbe.timeoutSeconds | int | `2` | The number of seconds to wait for a probe response before considering it as failed. |
| logs.access.addInternals | string | `nil` | Enables accessLogs for internal resources. Default: false. |
| logs.access.bufferingSize | string | `nil` | Set [bufferingSize](https://doc.traefik.io/traefik/observability/access-logs/#bufferingsize) |
| logs.access.enabled | bool | `false` | To enable access logs |
| logs.access.fields.general.defaultmode | string | `"keep"` | Available modes: keep, drop, redact. |
| logs.access.fields.general.names | object | `{}` | Names of the fields to limit. |
| logs.access.fields.headers | object | `{"defaultmode":"drop","names":{}}` | [Limit logged fields or headers](https://doc.traefik.io/traefik/observability/access-logs/#limiting-the-fieldsincluding-headers) |
| logs.access.fields.headers.defaultmode | string | `"drop"` | Available modes: keep, drop, redact. |
| logs.access.filters | object | `{}` | Set [filtering](https://docs.traefik.io/observability/access-logs/#filtering) |
| logs.access.format | string | `nil` | Set [access log format](https://doc.traefik.io/traefik/observability/access-logs/#format) |
| logs.general.format | string | `nil` | Set [logs format](https://doc.traefik.io/traefik/observability/logs/#format) @default common |
| logs.general.level | string | `"INFO"` | Alternative logging levels are DEBUG, PANIC, FATAL, ERROR, WARN, and INFO. |
| metrics.addInternals | string | `nil` |  |
| metrics.otlp.addEntryPointsLabels | string | `nil` | Enable metrics on entry points. Default: true |
| metrics.otlp.addRoutersLabels | string | `nil` | Enable metrics on routers. Default: false |
| metrics.otlp.addServicesLabels | string | `nil` | Enable metrics on services. Default: true |
| metrics.otlp.enabled | bool | `false` | Set to true in order to enable the OpenTelemetry metrics |
| metrics.otlp.explicitBoundaries | string | `nil` | Explicit boundaries for Histogram data points. Default: [.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10] |
| metrics.otlp.grpc.enabled | bool | `false` | Set to true in order to send metrics to the OpenTelemetry Collector using gRPC |
| metrics.otlp.grpc.endpoint | string | `nil` | Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics |
| metrics.otlp.grpc.insecure | string | `nil` | Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol. |
| metrics.otlp.grpc.tls.ca | string | `nil` | The path to the certificate authority, it defaults to the system bundle. |
| metrics.otlp.grpc.tls.cert | string | `nil` | The path to the public certificate. When using this option, setting the key option is required. |
| metrics.otlp.grpc.tls.insecureSkipVerify | string | `nil` | When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers. |
| metrics.otlp.grpc.tls.key | string | `nil` | The path to the private key. When using this option, setting the cert option is required. |
| metrics.otlp.http.enabled | bool | `false` | Set to true in order to send metrics to the OpenTelemetry Collector using HTTP. |
| metrics.otlp.http.endpoint | string | `nil` | Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics |
| metrics.otlp.http.headers | string | `nil` | Additional headers sent with metrics by the reporter to the OpenTelemetry Collector. |
| metrics.otlp.http.tls.ca | string | `nil` | The path to the certificate authority, it defaults to the system bundle. |
| metrics.otlp.http.tls.cert | string | `nil` | The path to the public certificate. When using this option, setting the key option is required. |
| metrics.otlp.http.tls.insecureSkipVerify | string | `nil` | When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers. |
| metrics.otlp.http.tls.key | string | `nil` | The path to the private key. When using this option, setting the cert option is required. |
| metrics.otlp.pushInterval | string | `nil` | Interval at which metrics are sent to the OpenTelemetry Collector. Default: 10s |
| metrics.prometheus.entryPoint | string | `"metrics"` | Entry point used to expose metrics. |
| namespaceOverride | string | `nil` | This field override the default Release Namespace for Helm. It will not affect optional CRDs such as `ServiceMonitor` and `PrometheusRules` |
| nodeSelector | object | `{}` | nodeSelector is the simplest recommended form of node selection constraint. |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.annotations | object | `{}` |  |
| persistence.enabled | bool | `false` | Enable persistence using Persistent Volume Claims ref: http://kubernetes.io/docs/user-guide/persistent-volumes/ It can be used to store TLS certificates, see `storage` in certResolvers |
| persistence.name | string | `"data"` |  |
| persistence.path | string | `"/data"` |  |
| persistence.size | string | `"128Mi"` |  |
| podDisruptionBudget | object | `{"enabled":null,"maxUnavailable":null,"minAvailable":null}` | [Pod Disruption Budget](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/pod-disruption-budget-v1/) |
| podSecurityContext | object | See _values.yaml_ | [Pod Security Context](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context) |
| podSecurityPolicy | object | `{"enabled":false}` | Enable to create a PodSecurityPolicy and assign it to the Service Account via RoleBinding or ClusterRoleBinding |
| ports.metrics.expose | object | `{"default":false}` | You may not want to expose the metrics port on production deployments. If you want to access it from outside your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.metrics.exposedPort | int | `9100` | The exposed port for this service |
| ports.metrics.port | int | `9100` | When using hostNetwork, use another port to avoid conflict with node exporter: https://github.com/prometheus/prometheus/wiki/Default-port-allocations |
| ports.metrics.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.traefik.expose | object | `{"default":false}` | You SHOULD NOT expose the traefik port on production deployments. If you want to access it from outside your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.traefik.exposedPort | int | `9000` | The exposed port for this service |
| ports.traefik.port | int | `9000` |  |
| ports.traefik.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.web.expose.default | bool | `true` |  |
| ports.web.exposedPort | int | `80` |  |
| ports.web.port | int | `8000` |  |
| ports.web.protocol | string | `"TCP"` |  |
| ports.web.transport | object | `{"keepAliveMaxRequests":null,"keepAliveMaxTime":null,"lifeCycle":{"graceTimeOut":null,"requestAcceptGraceTimeout":null},"respondingTimeouts":{"idleTimeout":null,"readTimeout":null,"writeTimeout":null}}` | Set transport settings for the entrypoint; see also https://doc.traefik.io/traefik/routing/entrypoints/#transport |
| ports.websecure.expose.default | bool | `true` |  |
| ports.websecure.exposedPort | int | `443` |  |
| ports.websecure.http3.enabled | bool | `false` |  |
| ports.websecure.middlewares | list | `[]` | /!\ It introduces here a link between your static configuration and your dynamic configuration /!\ It follows the provider naming convention: https://doc.traefik.io/traefik/providers/overview/#provider-namespace middlewares:   - namespace-name1@kubernetescrd   - namespace-name2@kubernetescrd |
| ports.websecure.port | int | `8443` |  |
| ports.websecure.protocol | string | `"TCP"` |  |
| ports.websecure.tls.certResolver | string | `""` |  |
| ports.websecure.tls.domains | list | `[]` |  |
| ports.websecure.tls.enabled | bool | `true` |  |
| ports.websecure.tls.options | string | `""` |  |
| ports.websecure.transport | object | `{"keepAliveMaxRequests":null,"keepAliveMaxTime":null,"lifeCycle":{"graceTimeOut":null,"requestAcceptGraceTimeout":null},"respondingTimeouts":{"idleTimeout":null,"readTimeout":null,"writeTimeout":null}}` | Set transport settings for the entrypoint; see also https://doc.traefik.io/traefik/routing/entrypoints/#transport |
| priorityClassName | string | `""` | [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) |
| providers.file.content | string | `nil` | File content (YAML format, go template supported) (see https://doc.traefik.io/traefik/providers/file/) |
| providers.file.enabled | bool | `false` | Create a file provider |
| providers.file.watch | bool | `true` | Allows Traefik to automatically watch for file changes |
| providers.kubernetesCRD.allowCrossNamespace | bool | `false` | Allows IngressRoute to reference resources in namespace other than theirs |
| providers.kubernetesCRD.allowEmptyServices | bool | `false` | Allows to return 503 when there is no endpoints available |
| providers.kubernetesCRD.allowExternalNameServices | bool | `false` | Allows to reference ExternalName services in IngressRoute |
| providers.kubernetesCRD.enabled | bool | `true` | Load Kubernetes IngressRoute provider |
| providers.kubernetesCRD.namespaces | list | `[]` | Array of namespaces to watch. If left empty, Traefik watches all namespaces. |
| providers.kubernetesIngress.allowEmptyServices | bool | `false` | Allows to return 503 when there is no endpoints available |
| providers.kubernetesIngress.allowExternalNameServices | bool | `false` | Allows to reference ExternalName services in Ingress |
| providers.kubernetesIngress.disableIngressClassLookup | bool | `false` |  |
| providers.kubernetesIngress.enabled | bool | `true` | Load Kubernetes Ingress provider |
| providers.kubernetesIngress.namespaces | list | `[]` | Array of namespaces to watch. If left empty, Traefik watches all namespaces. |
| providers.kubernetesIngress.publishedService.enabled | bool | `false` |  |
| rbac | object | `{"enabled":true,"namespaced":false,"secretResourceNames":[]}` | Whether Role Based Access Control objects like roles and rolebindings should be created |
| readinessProbe.failureThreshold | int | `1` | The number of consecutive failures allowed before considering the probe as failed. |
| readinessProbe.initialDelaySeconds | int | `2` | The number of seconds to wait before starting the first probe. |
| readinessProbe.periodSeconds | int | `10` | The number of seconds to wait between consecutive probes. |
| readinessProbe.successThreshold | int | `1` | The minimum consecutive successes required to consider the probe successful. |
| readinessProbe.timeoutSeconds | int | `2` | The number of seconds to wait for a probe response before considering it as failed. |
| resources | object | `{}` | [Resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for `traefik` container. |
| securityContext | object | See _values.yaml_ | [SecurityContext](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context-1) |
| service.additionalServices | object | `{}` |  |
| service.annotations | object | `{}` | Additional annotations applied to both TCP and UDP services (e.g. for cloud provider specific config) |
| service.annotationsTCP | object | `{}` | Additional annotations for TCP service only |
| service.annotationsUDP | object | `{}` | Additional annotations for UDP service only |
| service.enabled | bool | `true` |  |
| service.externalIPs | list | `[]` |  |
| service.labels | object | `{}` | Additional service labels (e.g. for filtering Service by custom labels) |
| service.loadBalancerSourceRanges | list | `[]` |  |
| service.single | bool | `true` |  |
| service.spec | object | `{}` | Cannot contain type, selector or ports entries. |
| service.type | string | `"LoadBalancer"` |  |
| serviceAccount | object | `{"name":""}` | The service account the pods will use to interact with the Kubernetes API |
| serviceAccountAnnotations | object | `{}` | Additional serviceAccount annotations (e.g. for oidc authentication) |
| startupProbe | string | `nil` | Define [Startup Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) |
| tlsOptions | object | `{}` | TLS Options are created as [TLSOption CRDs](https://doc.traefik.io/traefik/https/tls/#tls-options) When using `labelSelector`, you'll need to set labels on tlsOption accordingly. See EXAMPLE.md for details. |
| tlsStore | object | `{}` | TLS Store are created as [TLSStore CRDs](https://doc.traefik.io/traefik/https/tls/#default-certificate). This is useful if you want to set a default certificate. See EXAMPLE.md for details. |
| tolerations | list | `[]` | Tolerations allow the scheduler to schedule pods with matching taints. |
| topologySpreadConstraints | list | `[]` | You can use topology spread constraints to control how Pods are spread across your cluster among failure-domains. |
| tracing | object | `{"addInternals":null,"otlp":{"enabled":false,"grpc":{"enabled":false,"endpoint":null,"insecure":null,"tls":{"ca":null,"cert":null,"insecureSkipVerify":null,"key":null}},"http":{"enabled":false,"endpoint":null,"headers":null,"tls":{"ca":null,"cert":null,"insecureSkipVerify":null,"key":null}}}}` | https://doc.traefik.io/traefik/observability/tracing/overview/ |
| tracing.addInternals | string | `nil` | Enables tracing for internal resources. Default: false. |
| tracing.otlp.enabled | bool | `false` | See https://doc.traefik.io/traefik/v3.0/observability/tracing/opentelemetry/ |
| tracing.otlp.grpc.enabled | bool | `false` | Set to true in order to send metrics to the OpenTelemetry Collector using gRPC |
| tracing.otlp.grpc.endpoint | string | `nil` | Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics |
| tracing.otlp.grpc.insecure | string | `nil` | Allows reporter to send metrics to the OpenTelemetry Collector without using a secured protocol. |
| tracing.otlp.grpc.tls.ca | string | `nil` | The path to the certificate authority, it defaults to the system bundle. |
| tracing.otlp.grpc.tls.cert | string | `nil` | The path to the public certificate. When using this option, setting the key option is required. |
| tracing.otlp.grpc.tls.insecureSkipVerify | string | `nil` | When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers. |
| tracing.otlp.grpc.tls.key | string | `nil` | The path to the private key. When using this option, setting the cert option is required. |
| tracing.otlp.http.enabled | bool | `false` | Set to true in order to send metrics to the OpenTelemetry Collector using HTTP. |
| tracing.otlp.http.endpoint | string | `nil` | Format: <scheme>://<host>:<port><path>. Default: http://localhost:4318/v1/metrics |
| tracing.otlp.http.headers | string | `nil` | Additional headers sent with metrics by the reporter to the OpenTelemetry Collector. |
| tracing.otlp.http.tls.ca | string | `nil` | The path to the certificate authority, it defaults to the system bundle. |
| tracing.otlp.http.tls.cert | string | `nil` | The path to the public certificate. When using this option, setting the key option is required. |
| tracing.otlp.http.tls.insecureSkipVerify | string | `nil` | When set to true, the TLS connection accepts any certificate presented by the server regardless of the hostnames it covers. |
| tracing.otlp.http.tls.key | string | `nil` | The path to the private key. When using this option, setting the cert option is required. |
| updateStrategy.rollingUpdate.maxSurge | int | `1` |  |
| updateStrategy.rollingUpdate.maxUnavailable | int | `0` |  |
| updateStrategy.type | string | `"RollingUpdate"` | Customize updateStrategy: RollingUpdate or OnDelete |
| volumes | list | `[]` | Add volumes to the traefik pod. The volume name will be passed to tpl. This can be used to mount a cert pair or a configmap that holds a config.toml file. After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg: `additionalArguments: - "--providers.file.filename=/config/dynamic.toml" - "--ping" - "--ping.entrypoint=web"` |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
