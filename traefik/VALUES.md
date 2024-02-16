# traefik

![Version: 26.1.0](https://img.shields.io/badge/Version-26.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2.11.0](https://img.shields.io/badge/AppVersion-v2.11.0-informational?style=flat-square)

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

Kubernetes: `>=1.16.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalArguments | list | `[]` | Additional arguments to be passed at Traefik's binary All available options available on https://docs.traefik.io/reference/static-configuration/cli/ # Use curly braces to pass values: `helm install --set="additionalArguments={--providers.kubernetesingress.ingressclass=traefik-internal,--log.level=DEBUG}"` |
| additionalVolumeMounts | list | `[]` | Additional volumeMounts to add to the Traefik container |
| affinity | object | `{}` | on nodes where no other traefik pods are scheduled. It should be used when hostNetwork: true to prevent port conflicts |
| autoscaling.enabled | bool | `false` | Create HorizontalPodAutoscaler object. |
| certResolvers | object | `{}` | Certificates resolvers configuration |
| commonLabels | object | `{}` | Add additional label to all resources |
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
| env | list | `[{"name":"POD_NAME","valueFrom":{"fieldRef":{"fieldPath":"metadata.name"}}},{"name":"POD_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}}]` | Environment variables to be passed to Traefik's binary |
| envFrom | list | `[]` | Environment variables to be passed to Traefik's binary from configMaps or secrets |
| experimental.kubernetesGateway.enabled | bool | `false` | Enable traefik experimental GatewayClass CRD |
| experimental.plugins | object | `{}` | Enable traefik experimental plugins |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template)  In some cases, it can avoid the need for additional, extended or adhoc deployments. See #595 for more details and traefik/tests/values/extra.yaml for example. |
| globalArguments | list | `["--global.checknewversion","--global.sendanonymoususage"]` | Global command arguments to be passed to all traefik's pods |
| hostNetwork | bool | `false` | If hostNetwork is true, runs traefik in the host network namespace To prevent unschedulabel pods due to port collisions, if hostNetwork=true and replicas>1, a pod anti-affinity is recommended and will be set if the affinity is left as default. |
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
| livenessProbe.failureThreshold | int | `3` | The number of consecutive failures allowed before considering the probe as failed. |
| livenessProbe.initialDelaySeconds | int | `2` | The number of seconds to wait before starting the first probe. |
| livenessProbe.periodSeconds | int | `10` | The number of seconds to wait between consecutive probes. |
| livenessProbe.successThreshold | int | `1` | The minimum consecutive successes required to consider the probe successful. |
| livenessProbe.timeoutSeconds | int | `2` | The number of seconds to wait for a probe response before considering it as failed. |
| logs.access.enabled | bool | `false` | To enable access logs |
| logs.access.fields.general.defaultmode | string | `"keep"` | Available modes: keep, drop, redact. |
| logs.access.fields.general.names | object | `{}` | Names of the fields to limit. |
| logs.access.fields.headers.defaultmode | string | `"drop"` | Available modes: keep, drop, redact. |
| logs.access.fields.headers.names | object | `{}` | Names of the headers to limit. |
| logs.access.filters | object | `{}` | https://docs.traefik.io/observability/access-logs/#filtering |
| logs.general.level | string | `"ERROR"` | Alternative logging levels are DEBUG, PANIC, FATAL, ERROR, WARN, and INFO. |
| metrics.prometheus.entryPoint | string | `"metrics"` | Entry point used to expose metrics. |
| nodeSelector | object | `{}` | nodeSelector is the simplest recommended form of node selection constraint. |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.annotations | object | `{}` |  |
| persistence.enabled | bool | `false` | Enable persistence using Persistent Volume Claims ref: http://kubernetes.io/docs/user-guide/persistent-volumes/ It can be used to store TLS certificates, see `storage` in certResolvers |
| persistence.name | string | `"data"` |  |
| persistence.path | string | `"/data"` |  |
| persistence.size | string | `"128Mi"` |  |
| podDisruptionBudget | object | `{"enabled":false}` | Pod disruption budget |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | Specifies the policy for changing ownership and permissions of volume contents to match the fsGroup. |
| podSecurityContext.runAsGroup | int | `65532` | The ID of the group for all containers in the pod to run as. |
| podSecurityContext.runAsNonRoot | bool | `true` | Specifies whether the containers should run as a non-root user. |
| podSecurityContext.runAsUser | int | `65532` | The ID of the user for all containers in the pod to run as. |
| podSecurityPolicy | object | `{"enabled":false}` | Enable to create a PodSecurityPolicy and assign it to the Service Account via RoleBinding or ClusterRoleBinding |
| ports.metrics.expose | bool | `false` | You may not want to expose the metrics port on production deployments. If you want to access it from outside your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.metrics.exposeInternal | bool | `false` | Defines whether the port is exposed on the internal service; note that ports exposed on the default service are exposed on the internal service by default as well. |
| ports.metrics.exposedPort | int | `9100` | The exposed port for this service |
| ports.metrics.port | int | `9100` | When using hostNetwork, use another port to avoid conflict with node exporter: https://github.com/prometheus/prometheus/wiki/Default-port-allocations |
| ports.metrics.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.traefik.expose | bool | `false` | You SHOULD NOT expose the traefik port on production deployments. If you want to access it from outside your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.traefik.exposeInternal | bool | `false` | Defines whether the port is exposed on the internal service; note that ports exposed on the default service are exposed on the internal service by default as well. |
| ports.traefik.exposedPort | int | `9000` | The exposed port for this service |
| ports.traefik.port | int | `9000` |  |
| ports.traefik.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.web.expose | bool | `true` |  |
| ports.web.exposeInternal | bool | `false` | Defines whether the port is exposed on the internal service; note that ports exposed on the default service are exposed on the internal service by default as well. |
| ports.web.exposedPort | int | `80` |  |
| ports.web.port | int | `8000` |  |
| ports.web.protocol | string | `"TCP"` |  |
| ports.websecure.expose | bool | `true` |  |
| ports.websecure.exposeInternal | bool | `false` | Defines whether the port is exposed on the internal service; note that ports exposed on the default service are exposed on the internal service by default as well. |
| ports.websecure.exposedPort | int | `443` |  |
| ports.websecure.http3.enabled | bool | `false` |  |
| ports.websecure.middlewares | list | `[]` | /!\ It introduces here a link between your static configuration and your dynamic configuration /!\ It follows the provider naming convention: https://doc.traefik.io/traefik/providers/overview/#provider-namespace middlewares:   - namespace-name1@kubernetescrd   - namespace-name2@kubernetescrd |
| ports.websecure.port | int | `8443` |  |
| ports.websecure.protocol | string | `"TCP"` |  |
| ports.websecure.tls.certResolver | string | `""` |  |
| ports.websecure.tls.domains | list | `[]` |  |
| ports.websecure.tls.enabled | bool | `true` |  |
| ports.websecure.tls.options | string | `""` |  |
| priorityClassName | string | `""` | Priority indicates the importance of a Pod relative to other Pods. |
| providers.file.content | string | `""` | File content (YAML format, go template supported) (see https://doc.traefik.io/traefik/providers/file/) |
| providers.file.enabled | bool | `false` | Create a file provider |
| providers.file.watch | bool | `true` | Allows Traefik to automatically watch for file changes |
| providers.kubernetesCRD.allowCrossNamespace | bool | `false` | Allows IngressRoute to reference resources in namespace other than theirs |
| providers.kubernetesCRD.allowEmptyServices | bool | `false` | Allows to return 503 when there is no endpoints available |
| providers.kubernetesCRD.allowExternalNameServices | bool | `false` | Allows to reference ExternalName services in IngressRoute |
| providers.kubernetesCRD.enabled | bool | `true` | Load Kubernetes IngressRoute provider |
| providers.kubernetesCRD.namespaces | list | `[]` | Array of namespaces to watch. If left empty, Traefik watches all namespaces. |
| providers.kubernetesIngress.allowEmptyServices | bool | `false` | Allows to return 503 when there is no endpoints available |
| providers.kubernetesIngress.allowExternalNameServices | bool | `false` | Allows to reference ExternalName services in Ingress |
| providers.kubernetesIngress.enabled | bool | `true` | Load Kubernetes Ingress provider |
| providers.kubernetesIngress.namespaces | list | `[]` | Array of namespaces to watch. If left empty, Traefik watches all namespaces. |
| providers.kubernetesIngress.publishedService.enabled | bool | `false` |  |
| rbac | object | `{"enabled":true,"namespaced":false}` | Whether Role Based Access Control objects like roles and rolebindings should be created |
| readinessProbe.failureThreshold | int | `1` | The number of consecutive failures allowed before considering the probe as failed. |
| readinessProbe.initialDelaySeconds | int | `2` | The number of seconds to wait before starting the first probe. |
| readinessProbe.periodSeconds | int | `10` | The number of seconds to wait between consecutive probes. |
| readinessProbe.successThreshold | int | `1` | The minimum consecutive successes required to consider the probe successful. |
| readinessProbe.timeoutSeconds | int | `2` | The number of seconds to wait for a probe response before considering it as failed. |
| resources | object | `{}` | The resources parameter defines CPU and memory requirements and limits for Traefik's containers. |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | To run the container with ports below 1024 this will need to be adjusted to run as root |
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
| startupProbe | string | `nil` | Define Startup Probe for container: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes eg. `startupProbe:   exec:     command:       - mycommand       - foo   initialDelaySeconds: 5   periodSeconds: 5` |
| tlsOptions | object | `{}` | TLS Options are created as TLSOption CRDs https://doc.traefik.io/traefik/https/tls/#tls-options When using `labelSelector`, you'll need to set labels on tlsOption accordingly. Example: tlsOptions:   default:     labels: {}     sniStrict: true     preferServerCipherSuites: true   custom-options:     labels: {}     curvePreferences:       - CurveP521       - CurveP384 |
| tlsStore | object | `{}` | TLS Store are created as TLSStore CRDs. This is useful if you want to set a default certificate https://doc.traefik.io/traefik/https/tls/#default-certificate Example: tlsStore:   default:     defaultCertificate:       secretName: tls-cert |
| tolerations | list | `[]` | Tolerations allow the scheduler to schedule pods with matching taints. |
| topologySpreadConstraints | list | `[]` | You can use topology spread constraints to control how Pods are spread across your cluster among failure-domains. |
| tracing | object | `{}` | https://doc.traefik.io/traefik/observability/tracing/overview/ |
| updateStrategy.rollingUpdate.maxSurge | int | `1` |  |
| updateStrategy.rollingUpdate.maxUnavailable | int | `0` |  |
| updateStrategy.type | string | `"RollingUpdate"` | Customize updateStrategy: RollingUpdate or OnDelete |
| volumes | list | `[]` | Add volumes to the traefik pod. The volume name will be passed to tpl. This can be used to mount a cert pair or a configmap that holds a config.toml file. After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg: `additionalArguments: - "--providers.file.filename=/config/dynamic.toml" - "--ping" - "--ping.entrypoint=web"` |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)
