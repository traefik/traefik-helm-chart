# hub-manager

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| address | string | `":80"` | Address to listen on |
| affinity | object | `{}` |  |
| autoscaling.behavior | object | `{}` | behavior configures the scaling behavior of the target in both Up and Down directions (scaleUp and scaleDown fields respectively) |
| autoscaling.enabled | bool | `false` | Create HorizontalPodAutoscaler object |
| autoscaling.maxReplicas | string | `nil` | maxReplicas is the upper limit for the number of pods that can be set by the autoscaler; cannot be smaller than MinReplicas |
| autoscaling.metrics | list | `[]` | metrics contains the specifications for which to use to calculate the desired replica count (the maximum replica count across all metrics will be used) |
| autoscaling.minReplicas | string | `nil` | minReplicas is the lower limit for the number of replicas to which the autoscaler can scale down. It defaults to 1 pod |
| autoscaling.scaleTargetRef | object | `{"apiVersion":"apps/v1","kind":"Deployment","name":"{{ template \"hub-manager.fullname\" . }}"}` | scaleTargetRef points to the target resource to scale, and is used for the pods for which metrics should be collected, as well as to actually change the replica count |
| deployment.annotations | object | `{}` | Additional deployment annotations |
| deployment.imagePullSecrets | list | `[]` | Pull secret for fetching container image |
| deployment.labels | object | `{}` | Additional deployment labels (e.g. for filtering deployment by custom labels) |
| deployment.lifecycle | object | `{}` | Pod lifecycle actions |
| deployment.podAnnotations | object | `{}` | Additional pod annotations (e.g. for mesh injection or prometheus scraping) |
| deployment.podLabels | object | `{}` | Additional Pod labels (e.g. for filtering Pod by custom labels) |
| deployment.replicas | int | `1` | Number of pods of the deployment |
| deployment.revisionHistoryLimit | int | `10` | Number of old history to retain to allow rollback (If not set, default Kubernetes value is set to 10) |
| deployment.terminationGracePeriodSeconds | int | `60` | Amount of time (in seconds) before Kubernetes will send the SIGKILL signal if shut down does not happen |
| fullnameOverride | string | `""` | Overrides the resource name for templates (i.e deployment, service, etc..) |
| hydra.issuerURL | string | `""` | URL of the Hydra issuer |
| hydra.url | string | `""` | URL of the Hydra admin API |
| image.pullPolicy | string | `"IfNotPresent"` | Traefik image pull policy |
| image.registry | string | `"gcr.io"` | Hub-manager image host registry |
| image.repository | string | `"traefiklabs/hub-manager"` | Hub-manager image repository |
| image.tag | string | `nil` | defaults to appVersion. It's used for version checking, even prefixed with experimental- or latest- |
| jwt.cert | string | `""` | Name of Secret with key 'jwt-cert' set to a valid JWT Cert |
| jwt.iss | string | `""` | Name of Secret with key 'jwt-iss' set to a valid JWT Issuer |
| jwt.sub | string | `""` | Name of Secret with key 'jwt-sub' set to a valid JWT Sub |
| livenessProbe.failureThreshold | int | `2` | The number of consecutive failures allowed before considering the probe as failed |
| livenessProbe.httpGet.path | string | `"/live"` |  |
| livenessProbe.httpGet.port | int | `8080` |  |
| livenessProbe.initialDelaySeconds | int | `5` | The number of seconds to wait before starting the first probe |
| livenessProbe.periodSeconds | int | `5` | The number of seconds to wait between consecutive probes |
| logs.format | string | `"json"` | Set logs format |
| logs.level | string | `"INFO"` | Alternative logging levels are TRACE, DEBUG, INFO, WARN, ERROR, FATAL, and PANIC |
| nameOverride | string | `""` | overrides the app.kubernetes.io/name label |
| namespaceOverride | string | `""` | This field overrides the default Release Namespace for Helm |
| nodeSelector | object | `{}` | nodeSelector is the simplest recommended form of node selection constraint |
| ports.http.port | int | `8080` |  |
| ports.http.protocol | string | `"TCP"` | The port protocol (TCP/UDP) |
| postgres.encryptionKey | string | `""` | Name of Secret with key 'postgres-encryption-key' set to a valid encryption key |
| postgres.uri | string | `""` | Name of Secret with key 'postgres-uri' set to a valid Postgres connection string |
| readinessProbe.failureThreshold | int | `2` | The number of consecutive failures allowed before considering the probe as failed |
| readinessProbe.httpGet.path | string | `"/ready"` |  |
| readinessProbe.httpGet.port | int | `8080` |  |
| readinessProbe.initialDelaySeconds | int | `5` | The number of seconds to wait before starting the first probe |
| readinessProbe.periodSeconds | int | `5` | The number of seconds to wait between consecutive probes |
| resources | object | `{}` | [Resources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) for `traefik` container |
| securityContext | object | See _values.yaml_ | [SecurityContext](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#security-context-1) |
| serviceAccount.annotations | object | `{}` | Additional serviceAccount annotations (e.g. for oidc authentication) |
| serviceAccount.automount | bool | `true` | Whether to automatically mount a ServiceAccount's API credentials |
| serviceAccount.name | string | `""` |  |
| services.offerURL | string | `""` | Base URL of the offer service |
| services.traceURL | string | `""` | URL of the trace service |
| services.workspaceURL | string | `""` | Base URL of the workspace service |
| startupProbe | object | `{}` | Define [Startup Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes) |
| token | string | `""` | Name of Secret with key 'token' set to a valid license token |
| tolerations | list | `[]` | Tolerations allow the scheduler to schedule pods with matching taints |
| tracing.address | string | `""` | Address to send traces |
| tracing.insecure | bool | `false` | use HTTP instead of HTTPS |
| tracing.password | string | `""` | Name of Secret with key 'tracing-password' set to a valid password |
| tracing.probability | int | `0` | Probability to send traces |
| tracing.username | string | `""` | Username to connect to tracing address |
| updateStrategy.rollingUpdate.maxSurge | int | `1` |  |
| updateStrategy.rollingUpdate.maxUnavailable | int | `0` |  |
| updateStrategy.type | string | `"RollingUpdate"` | Customize updateStrategy of Deployment |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
