# traefik

![Version: 23.0.1](https://img.shields.io/badge/Version-23.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v2.10.1](https://img.shields.io/badge/AppVersion-v2.10.1-informational?style=flat-square)

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
| additionalArguments | list | `[]` | Additional arguments to be passed at Traefik's binary All available options available on https://docs.traefik.io/reference/static-configuration/cli/ # Use curly braces to pass values: `helm install --set="additionalArguments={--providers.kubernetesingress.ingressclass=traefik-internal,--log.level=DEBUG}"` |
| additionalVolumeMounts | list | `[]` | Additional volumeMounts to add to the Traefik container |
| affinity | object | `{}` | on nodes where no other traefik pods are scheduled. It should be used when hostNetwork: true to prevent port conflicts |
| autoscaling.enabled | bool | `false` |  |
| certResolvers | object | `{}` | Certificates resolvers configuration |
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
| deployment.podAnnotations | object | `{}` | Additional pod annotations (e.g. for mesh injection or prometheus scraping) |
| deployment.podLabels | object | `{}` | Additional Pod labels (e.g. for filtering Pod by custom labels) |
| deployment.replicas | int | `1` | Number of pods of the deployment (only applies when kind == Deployment) |
| deployment.shareProcessNamespace | bool | `false` | Use process namespace sharing |
| deployment.terminationGracePeriodSeconds | int | `60` | Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if Traefik does not shut down |
| env | list | `[]` | Environment variables to be passed to Traefik's binary |
| envFrom | list | `[]` |  |
| experimental | object | `{"kubernetesGateway":{"enabled":false,"gateway":{"enabled":true}},"plugins":{"enabled":false},"v3":{"enabled":false}}` | Enable experimental features |
| extraObjects | list | `[]` | Extra objects to deploy (value evaluated as a template)  In some cases, it can avoid the need for additional, extended or adhoc deployments. See #595 for more details and traefik/tests/values/extra.yaml for example. |
| globalArguments[0] | string | `"--global.checknewversion"` |  |
| globalArguments[1] | string | `"--global.sendanonymoususage"` |  |
| hostNetwork | bool | `false` | If hostNetwork is true, runs traefik in the host network namespace To prevent unschedulabel pods due to port collisions, if hostNetwork=true and replicas>1, a pod anti-affinity is recommended and will be set if the affinity is left as default. |
| hub | object | `{"enabled":false}` | Add additional label to all resources commonLabels:   key: value  Traefik Hub integration   |
| hub.enabled | bool | `false` | Enabling Hub will: <ul><li>enable Traefik Hub integration on Traefik</li> <li>add `traefikhub-tunl` endpoint</li> <li>enable Prometheus metrics with addRoutersLabels</li> <li>enable allowExternalNameServices on KubernetesIngress provider</li> <li>enable allowCrossNamespace on KubernetesCRD provider</li> <li>add an internal (ClusterIP) Service, dedicated for Traefik Hub</li> |
| image.pullPolicy | string | `"IfNotPresent"` | Traefik image pull policy |
| image.registry | string | `"docker.io"` | Traefik image host registry |
| image.repository | string | `"traefik"` | Traefik image repository |
| image.tag | string | `""` | defaults to appVersion |
| ingressClass | object | `{"enabled":true,"isDefaultClass":true}` | Create a default IngressClass for Traefik |
| ingressRoute | object | `{"dashboard":{"annotations":{},"enabled":true,"entryPoints":["traefik"],"labels":{},"matchRule":"PathPrefix(`/dashboard`) || PathPrefix(`/api`)","middlewares":[],"tls":{}}}` | Create an IngressRoute for the dashboard |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.initialDelaySeconds | int | `2` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `2` |  |
| logs.access.enabled | bool | `false` | To enable access logs |
| logs.access.fields.general.defaultmode | string | `"keep"` |  |
| logs.access.fields.general.names | object | `{}` |  |
| logs.access.fields.headers.defaultmode | string | `"drop"` |  |
| logs.access.fields.headers.names | object | `{}` |  |
| logs.access.filters | object | `{}` |  |
| logs.general.level | string | `"ERROR"` | Alternative logging levels are DEBUG, PANIC, FATAL, ERROR, WARN, and INFO. |
| metrics.prometheus.entryPoint | string | `"metrics"` |  |
| nodeSelector | object | `{}` | nodeSelector is the simplest recommended form of node selection constraint. |
| persistence | object | `{"accessMode":"ReadWriteOnce","annotations":{},"enabled":false,"name":"data","path":"/data","size":"128Mi"}` | It can be used to store TLS certificates, see `storage` in certResolvers |
| podDisruptionBudget | object | `{"enabled":false}` | Pod disruption budget |
| podSecurityContext.fsGroupChangePolicy | string | `"OnRootMismatch"` | be an issue when storing sensitive content like TLS Certificates /!\ fsGroup: 65532 |
| podSecurityContext.runAsGroup | int | `65532` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `65532` |  |
| podSecurityPolicy | object | `{"enabled":false}` | Enable to create a PodSecurityPolicy and assign it to the Service Account via RoleBinding or ClusterRoleBinding |
| ports | object | `{"metrics":{"expose":false,"exposedPort":9100,"port":9100,"protocol":"TCP"},"traefik":{"expose":false,"exposedPort":9000,"port":9000,"protocol":"TCP"},"web":{"expose":true,"exposedPort":80,"port":8000,"protocol":"TCP"},"websecure":{"expose":true,"exposedPort":443,"http3":{"enabled":false},"middlewares":[],"port":8443,"protocol":"TCP","tls":{"certResolver":"","domains":[],"enabled":true,"options":""}}}` | Configure ports |
| ports.metrics.expose | bool | `false` | You may not want to expose the metrics port on production deployments. If you want to access it from outside of your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.metrics.exposedPort | int | `9100` | The exposed port for this service |
| ports.metrics.port | int | `9100` | When using hostNetwork, use another port to avoid conflict with node exporter: https://github.com/prometheus/prometheus/wiki/Default-port-allocations |
| ports.metrics.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.traefik | object | `{"expose":false,"exposedPort":9000,"port":9000,"protocol":"TCP"}` | liveness probes, but you can adjust its config to your liking |
| ports.traefik.expose | bool | `false` | You SHOULD NOT expose the traefik port on production deployments. If you want to access it from outside of your cluster, use `kubectl port-forward` or create a secure ingress |
| ports.traefik.exposedPort | int | `9000` | The exposed port for this service |
| ports.traefik.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| ports.websecure.middlewares | list | `[]` | /!\ It introduces here a link between your static configuration and your dynamic configuration /!\ It follows the provider naming convention: https://doc.traefik.io/traefik/providers/overview/#provider-namespace middlewares:   - namespace-name1@kubernetescrd   - namespace-name2@kubernetescrd |
| priorityClassName | string | `""` | Priority indicates the importance of a Pod relative to other Pods. |
| providers | object | `{"kubernetesCRD":{"allowCrossNamespace":false,"allowEmptyServices":false,"allowExternalNameServices":false,"enabled":true,"namespaces":[]},"kubernetesIngress":{"allowEmptyServices":false,"allowExternalNameServices":false,"enabled":true,"namespaces":[],"publishedService":{"enabled":false}}}` | Configure providers  |
| rbac | object | `{"enabled":true,"namespaced":false}` | Whether Role Based Access Control objects like roles and rolebindings should be created |
| readinessProbe | object | `{"failureThreshold":1,"initialDelaySeconds":2,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":2}` | Customize liveness and readiness probe values. |
| resources | object | `{}` |  |
| securityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | To run the container with ports below 1024 this will need to be adjust to run as root |
| service | object | `{"annotations":{},"annotationsTCP":{},"annotationsUDP":{},"enabled":true,"externalIPs":[],"labels":{},"loadBalancerSourceRanges":[],"single":true,"spec":{},"type":"LoadBalancer"}` | Options for the main traefik service, where the entrypoints traffic comes from. |
| service.annotations | object | `{}` | Additional annotations applied to both TCP and UDP services (e.g. for cloud provider specific config) |
| service.annotationsTCP | object | `{}` | Additional annotations for TCP service only |
| service.annotationsUDP | object | `{}` | Additional annotations for UDP service only |
| service.labels | object | `{}` | Additional service labels (e.g. for filtering Service by custom labels) |
| service.spec | object | `{}` | Cannot contain type, selector or ports entries. |
| serviceAccount | object | `{"name":""}` | The service account the pods will use to interact with the Kubernetes API |
| serviceAccountAnnotations | object | `{}` | Additional serviceAccount annotations (e.g. for oidc authentication) |
| tlsOptions | object | `{}` | TLS Options are created as TLSOption CRDs https://doc.traefik.io/traefik/https/tls/#tls-options When using `labelSelector`, you'll need to set labels on tlsOption accordingly. Example: tlsOptions:   default:     labels: {}     sniStrict: true     preferServerCipherSuites: true   customOptions:     labels: {}     curvePreferences:       - CurveP521       - CurveP384 |
| tlsStore | object | `{}` | TLS Store are created as TLSStore CRDs. This is useful if you want to set a default certificate https://doc.traefik.io/traefik/https/tls/#default-certificate Example: tlsStore:   default:     defaultCertificate:       secretName: tls-cert |
| tolerations | list | `[]` | Tolerations allow the scheduler to schedule pods with matching taints. |
| topologySpreadConstraints | list | `[]` | You can use topology spread constraints to control  how Pods are spread across your cluster among failure-domains. |
| tracing | object | `{}` | https://doc.traefik.io/traefik/observability/tracing/overview/ |
| updateStrategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Customize updateStrategy of traefik pods |
| volumes | list | `[]` | Add volumes to the traefik pod. The volume name will be passed to tpl. This can be used to mount a cert pair or a configmap that holds a config.toml file. After the volume has been mounted, add the configs into traefik by using the `additionalArguments` list below, eg: `additionalArguments: - "--providers.file.filename=/config/dynamic.toml" - "--ping" - "--ping.entrypoint=web"` |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
