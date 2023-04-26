# traefik

![Version: 22.3.0](https://img.shields.io/badge/Version-22.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2.10.0](https://img.shields.io/badge/AppVersion-v2.10.0-informational?style=flat-square)

A Traefik based Kubernetes ingress controller

**Homepage:** <https://traefik.io/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| emilevauge | <emile@vauge.com> |  |
| dtomcej | <daniel.tomcej@gmail.com> |  |
| ldez | <ldez@traefik.io> |  |
| mloiseleur | <michel.loiseleur@traefik.io> |  |
| charlie-haley | <charlie.haley@traefik.io> |  |

## Source Code

* <https://github.com/traefik/traefik>
* <https://github.com/traefik/traefik-helm-chart>

## Requirements

Kubernetes: `>=1.16.0-0`

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalArguments | list | `[]` |  |
| additionalVolumeMounts | list | `[]` |  |
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| certResolvers | object | `{}` |  |
| deployment.additionalContainers | list | `[]` | Additional containers (e.g. for metric offloading sidecars) |
| deployment.additionalVolumes | list | `[]` | Additional volumes available for use with initContainers and additionalContainers |
| deployment.annotations | object | `{}` | Additional deployment annotations (e.g. for jaeger-operator sidecar injection) |
| deployment.dnsConfig | object | `{}` | Custom pod DNS policy. Apply if `hostNetwork: true` dnsPolicy: ClusterFirstWithHostNet |
| deployment.enabled | bool | `true` |  |
| deployment.imagePullSecrets | list | `[]` | Additional imagePullSecrets |
| deployment.initContainers | list | `[]` | Additional initContainers (e.g. for setting file permission as shown below) |
| deployment.kind | string | `"Deployment"` | Deployment or DaemonSet |
| deployment.labels | object | `{}` | Additional deployment labels (e.g. for filtering deployment by custom labels) |
| deployment.lifecycle | object | `{}` | Pod lifecycle actions |
| deployment.minReadySeconds | int | `0` | The minimum number of seconds Traefik needs to be up and running before the DaemonSet/Deployment controller considers it available |
| deployment.podAnnotations | object | `{}` | Additional pod annotations (e.g. for mesh injection or prometheus scraping) |
| deployment.podLabels | object | `{}` | Additional Pod labels (e.g. for filtering Pod by custom labels) |
| deployment.replicas | int | `1` | Number of pods of the deployment (only applies when kind == Deployment) |
| deployment.shareProcessNamespace | bool | `false` | Use process namespace sharing |
| deployment.terminationGracePeriodSeconds | int | `60` | Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if Traefik does not shut down |
| env | list | `[]` |  |
| envFrom | list | `[]` |  |
| experimental.kubernetesGateway.enabled | bool | `false` |  |
| experimental.kubernetesGateway.gateway.enabled | bool | `true` |  |
| experimental.plugins.enabled | bool | `false` |  |
| experimental.v3.enabled | bool | `false` |  |
| extraObjects | list | `[]` |  |
| globalArguments[0] | string | `"--global.checknewversion"` |  |
| globalArguments[1] | string | `"--global.sendanonymoususage"` |  |
| hostNetwork | bool | `false` |  |
| hub.enabled | bool | `false` | Enabling Hub will: <ul><li>enable Traefik Hub integration on Traefik</li> <li>add `traefikhub-tunl` endpoint</li> <li>enable Prometheus metrics with addRoutersLabels</li> <li>enable allowExternalNameServices on KubernetesIngress provider</li> <li>enable allowCrossNamespace on KubernetesCRD provider</li> <li>add an internal (ClusterIP) Service, dedicated for Traefik Hub</li> |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"traefik"` |  |
| image.tag | string | `""` |  |
| ingressClass.enabled | bool | `true` |  |
| ingressClass.isDefaultClass | bool | `true` |  |
| ingressRoute.dashboard.annotations | object | `{}` |  |
| ingressRoute.dashboard.enabled | bool | `true` |  |
| ingressRoute.dashboard.entryPoints[0] | string | `"traefik"` |  |
| ingressRoute.dashboard.labels | object | `{}` |  |
| ingressRoute.dashboard.matchRule | string | `"PathPrefix(`/dashboard`) || PathPrefix(`/api`)"` |  |
| ingressRoute.dashboard.middlewares | list | `[]` |  |
| ingressRoute.dashboard.tls | object | `{}` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.initialDelaySeconds | int | `2` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `2` |  |
| logs.access.enabled | bool | `false` |  |
| logs.access.fields.general.defaultmode | string | `"keep"` |  |
| logs.access.fields.general.names | object | `{}` |  |
| logs.access.fields.headers.defaultmode | string | `"drop"` |  |
| logs.access.fields.headers.names | object | `{}` |  |
| logs.access.filters | object | `{}` |  |
| logs.general.level | string | `"ERROR"` |  |
| metrics.prometheus.entryPoint | string | `"metrics"` |  |
| nodeSelector | object | `{}` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.annotations | object | `{}` |  |
| persistence.enabled | bool | `false` |  |
| persistence.name | string | `"data"` |  |
| persistence.path | string | `"/data"` |  |
| persistence.size | string | `"128Mi"` |  |
| podDisruptionBudget.enabled | bool | `false` |  |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| podSecurityContext.runAsGroup | int | `65532` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `65532` |  |
| podSecurityPolicy.enabled | bool | `false` |  |
| ports.metrics.expose | bool | `false` |  |
| ports.metrics.exposedPort | int | `9100` |  |
| ports.metrics.port | int | `9100` |  |
| ports.metrics.protocol | string | `"TCP"` |  |
| ports.traefik.expose | bool | `false` |  |
| ports.traefik.exposedPort | int | `9000` |  |
| ports.traefik.port | int | `9000` |  |
| ports.traefik.protocol | string | `"TCP"` |  |
| ports.web.expose | bool | `true` |  |
| ports.web.exposedPort | int | `80` |  |
| ports.web.port | int | `8000` |  |
| ports.web.protocol | string | `"TCP"` |  |
| ports.websecure.expose | bool | `true` |  |
| ports.websecure.exposedPort | int | `443` |  |
| ports.websecure.http3.enabled | bool | `false` |  |
| ports.websecure.middlewares | list | `[]` |  |
| ports.websecure.port | int | `8443` |  |
| ports.websecure.protocol | string | `"TCP"` |  |
| ports.websecure.tls.certResolver | string | `""` |  |
| ports.websecure.tls.domains | list | `[]` |  |
| ports.websecure.tls.enabled | bool | `true` |  |
| ports.websecure.tls.options | string | `""` |  |
| priorityClassName | string | `""` |  |
| providers.kubernetesCRD.allowCrossNamespace | bool | `false` |  |
| providers.kubernetesCRD.allowEmptyServices | bool | `false` |  |
| providers.kubernetesCRD.allowExternalNameServices | bool | `false` |  |
| providers.kubernetesCRD.enabled | bool | `true` |  |
| providers.kubernetesCRD.namespaces | list | `[]` |  |
| providers.kubernetesIngress.allowEmptyServices | bool | `false` |  |
| providers.kubernetesIngress.allowExternalNameServices | bool | `false` |  |
| providers.kubernetesIngress.enabled | bool | `true` |  |
| providers.kubernetesIngress.namespaces | list | `[]` |  |
| providers.kubernetesIngress.publishedService.enabled | bool | `false` |  |
| rbac.enabled | bool | `true` |  |
| rbac.namespaced | bool | `false` |  |
| readinessProbe.failureThreshold | int | `1` |  |
| readinessProbe.initialDelaySeconds | int | `2` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `2` |  |
| resources | object | `{}` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| service.annotations | object | `{}` |  |
| service.annotationsTCP | object | `{}` |  |
| service.annotationsUDP | object | `{}` |  |
| service.enabled | bool | `true` |  |
| service.externalIPs | list | `[]` |  |
| service.labels | object | `{}` |  |
| service.loadBalancerSourceRanges | list | `[]` |  |
| service.single | bool | `true` |  |
| service.spec | object | `{}` |  |
| service.type | string | `"LoadBalancer"` |  |
| serviceAccount.name | string | `""` |  |
| serviceAccountAnnotations | object | `{}` |  |
| tlsOptions | object | `{}` |  |
| tlsStore | object | `{}` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| tracing | object | `{}` |  |
| updateStrategy.rollingUpdate.maxSurge | int | `1` |  |
| updateStrategy.rollingUpdate.maxUnavailable | int | `0` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |
| volumes | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
