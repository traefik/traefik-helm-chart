# EXAMPLES

This is the example catalog for the **experimental Traefik chart**. It mirrors the
recipes from the stable chart's `EXAMPLES.md`, expressed in this chart's shape. Plain
Kubernetes / Traefik CRD manifests are used verbatim.

> **New to the chart's conventions?** The idioms these examples rely on — verbatim
> `traefik:` config, the real-PodSpec hatch (`containers.0` merge anchor), presence-enables /
> `null`-disables (and `null`-deletes-a-default), name-keyed Service/Secret maps — are described
> in [`README.md`](./README.md#what-this-is). `values.yaml` documents the full surface.

## Install as a DaemonSet

Default install is using a `Deployment` but it's possible to use a `DaemonSet`.

The new chart selects the pod controller by **presence**: set `deployment: null`
to turn the Deployment off and `daemonset: {}` to turn the DaemonSet on (the two
are mutually exclusive). The DaemonSet rollout strategy lives under
`daemonset.spec.updateStrategy`.

The chart's pod-spec helper is identical between the two — same container,
ports, probes, volumes, RBAC. Only the manifest kind/apiVersion at the root
differs. The minimal switch is:

```yaml
deployment: null
daemonset: {}
```

And with a custom rollout strategy:

```yaml
deployment: null
daemonset:
  spec:
    # The update strategy needs to be changed accordingly
    # See https://kubernetes.io/docs/tasks/manage-daemon/update-daemon-set/ for details
    updateStrategy:
      rollingUpdate:
        maxUnavailable: 1
```

## Configure Traefik Pod parameters

### Extending /etc/hosts records

In some specific cases, you'll need to add extra records to the `/etc/hosts` file for the Traefik containers.
You can configure it using [hostAliases](https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/):

```yaml
deployment:
  spec:
    template:
      spec:
        hostAliases:
          - ip: "127.0.0.1" # this is an example
            hostnames:
              - "foo.local"
              - "bar.local"
```

## Extending DNS config

To configure additional DNS servers for your traefik pod, you can use the `dnsConfig` option:

```yaml
deployment:
  spec:
    template:
      spec:
        dnsConfig:
          nameservers:
            - 192.0.2.1 # this is an example
          searches:
            - ns1.svc.cluster-domain.example
            - my.dns.search.suffix
          options:
            - name: ndots
              value: "2"
            - name: edns0
```

## Install in a dedicated namespace, with limited RBAC

The default install is using cluster-wide RBAC but it can be restricted to the target namespace.

In the new chart, namespaced RBAC is opt-in by **presence**: null the cluster-scoped
objects and enable the namespaced ones. The chart renders one `Role` + `RoleBinding`
per namespace listed under `traefik.providers.<p>.namespaces`, so at least one provider
namespace **must** be set or the render fails validation.

```yaml
clusterRole: null
clusterRoleBinding: null
role: {}
roleBinding: {}

traefik:
  providers:
    kubernetesCRD:
      namespaces:
        - my-namespace
```

### Multi-namespace, multi-provider setup

The chart computes the namespace set as the union of
`traefik.providers.<p>.namespaces` across providers, then applies precision:
each rendered Role only grants the layers whose provider watches that specific
namespace. With asymmetric provider scoping —

```
kubernetesCRD:     watches `apps-modern` + `apps-mixed`
kubernetesIngress: watches `apps-legacy` + `apps-mixed`
```

— 3 Role/RoleBinding pairs are rendered:

```
ns `apps-modern`  → core + traefik.io CRDs
ns `apps-legacy`  → core + networking.k8s.io ingresses
ns `apps-mixed`   → core + traefik.io CRDs + networking.k8s.io ingresses
```

Subjects on every RoleBinding point at the chart ServiceAccount in the release
namespace (cross-namespace binding).

```yaml
clusterRole: null
clusterRoleBinding: null
role: {}
roleBinding: {}

traefik:
  providers:
    kubernetesCRD:
      namespaces:
        - apps-modern
        - apps-mixed
    kubernetesIngress:
      namespaces:
        - apps-legacy
        - apps-mixed
```

Install it (release namespace `traefik-system`; watched namespaces must
pre-exist or be created separately):

```shell
helm install traefik ./traefik -n traefik-system --create-namespace \
  -f your-namespaced-values.yaml
```

> [!NOTE]
> A namespaced Role cannot grant access to cluster-scoped resources (nodes,
> namespaces, ingressclasses). The chart's core + kubernetesIngress layers
> still list them; trim via `role.rules` (replaces wholesale, applied to every
> rendered Role) if your cluster's admission policies reject them.
>
> Hub API Management requires cluster-wide RBAC (its CRDs are cluster-scoped).
> Don't combine `traefik.hub.apimanagement` with `role: {}` — keep the default
> cluster-wide setup for that.

## Install Traefik Hub (Gateway)

Hub Gateway gets you the `traefik-hub` binary connected to the Hub control plane
via your license token. From there you can enable any Hub feature (MCP gateway,
AI gateway, extra providers, Redis backend, tracing, …) by adding keys under
`traefik.hub.*` — they pass through verbatim into `traefik.yaml`.

When `traefik.hub.token` is set, the chart auto-defaults `image:` to
`ghcr.io/traefik/traefik-hub:<traefik.io/hub-max-version>` (annotation in
`Chart.yaml`). Override `image:` to pin a specific version or registry.

The inline token is managed for you: the chart creates a Secret, mounts it, and
sets `tokenfilepath` so the rendered `traefik.yaml` never contains the token.
Replace it via `--set` or a separate values file.

```yaml
traefik:
  hub:
    token: "REPLACE-WITH-LICENSE-TOKEN"

    # Limit the namespaces Hub watches. When unset, Hub watches all.
    # namespaces:
    #   - default

    # Send logs to Hub control plane (default true).
    # sendlogs: true

    # Enable MCP gateway.
    # mcpgateway: {}

    # Enable AI gateway.
    # aigateway: {}

    # Enable Hub-managed tracing.
    # tracing: {}

    # Redis backend for shared state across replicas.
    # redis:
    #   endpoints: redis.redis.svc.cluster.local:6379
```

```shell
helm install traefik ./traefik \
  -f your-hub-gateway-values.yaml \
  --set 'traefik.hub.token=<your-license-token>'
```

## Install Traefik Hub API Management

Builds on the Hub Gateway install (token + auto-defaulted image) and adds API
Management: admission webhook, mutating webhook configurations, and the API
portal Service. The chart renders all five Hub k8s objects automatically when
`traefik.hub.apimanagement` is present.

```yaml
traefik:
  hub:
    token: "REPLACE-WITH-LICENSE-TOKEN"
    apimanagement:
      admission: {}
```

```shell
helm install traefik ./traefik \
  -f your-hub-apimanagement-values.yaml \
  --set 'traefik.hub.token=<your-license-token>'
```

## Install with auto-scaling

When enabling [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
to adjust the replicas count according to CPU Usage, you'll need to set resources and nullify replicas.

```yaml
deployment:
  resources:
    requests:
      cpu: "100m"
      memory: "50Mi"
    limits:
      cpu: "300m"
      memory: "150Mi"
  spec:
    replicas: null
autoscaling:
  spec:
    maxReplicas: 2
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 80
```

## Install with an external scaler (KEDA)

When an external controller like [KEDA](https://keda.sh/) brings its own
`ScaledObject` (and HPA), the chart's HPA stays disabled and `spec.replicas` must
be omitted. Otherwise a GitOps tool like Argo CD reconciles the Deployment back to
the chart value, fighting the scaler.

In the new chart the HPA is disabled by leaving `autoscaling` unset (it is `null` by
default), so the only thing to do is nullify the replica count.

```yaml
deployment:
  spec:
    replicas: null
```

## Install with Argo Rollouts

When using [ArgoCD Rollouts](https://argoproj.github.io/rollouts/), one can delegate replica management to a `Rollout` resource, enabling progressive delivery strategies like canary and blue-green deployments.
To delegate replica management, `deployment.spec.replicas` should be set to `0` and the `Rollout` resource can be defined in a separate YAML or in `extraObjects`.

```yaml
deployment:
  spec:
    replicas: 0
autoscaling:
  spec:
    minReplicas: 5
    maxReplicas: 50
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 80
    scaleTargetRef:
      apiVersion: argoproj.io/v1alpha1
      kind: Rollout
extraObjects:
  - apiVersion: argoproj.io/v1alpha1
    kind: Rollout
    metadata:
      name: "{{ template \"traefik.fullname\" . }}"
    spec:
      workloadRef:
        apiVersion: apps/v1
        kind: Deployment
        name: "{{ template \"traefik.fullname\" . }}"
      strategy:
        canary:
          steps:
          - setWeight: 10
          - pause:
              duration: 5m
```
## Access Traefik dashboard without exposing it

This Chart does not expose the Traefik local dashboard by default. It's explained in upstream [documentation](https://doc.traefik.io/traefik/operations/api/) why:

> Enabling the API in production is not recommended, because it will expose all configuration elements, including sensitive data.

It says also:

> In production, it should be at least secured by authentication and authorizations.

Thus, there are multiple ways to expose the dashboard. For instance, after enabling the creation of the dashboard `IngressRoute` in the values:

```yaml
ingressRoute:
  dashboard:
    spec:
      entryPoints:
        - traefik
      routes:
        - kind: Rule
          match: PathPrefix(`/dashboard`) || PathPrefix(`/api`)
          services:
            - kind: TraefikService
              name: api@internal
```

The traefik admin port can be forwarded locally. Assuming the default `traefik` namespace is used:

```bash
NAMESPACE=traefik
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -n $NAMESPACE) 8080:8080 -n $NAMESPACE
```

This command makes the dashboard accessible locally on [127.0.0.1:8080/dashboard/](http://127.0.0.1:8080/dashboard/)

> [!IMPORTANT]
> Note that the slash is required.

## Redirect permanently traffic from http to https

It's possible to redirect all incoming requests on an entrypoint to another entrypoint.

```yaml
traefik:
  entryPoints:
    web:
      http:
        redirections:
          entryPoint:
            permanent: true
            scheme: https
            to: ":443"
```

> [!IMPORTANT]
> Use the **publicly-reachable port** (`to: ":443"`), not the entryPoint *name*
> (`to: websecure`). The chart runs `websecure` on the internal `:8443` (exposed as
> `443` by the Service), and Traefik resolves a bare entryPoint name to that internal
> port — so `to: websecure` would redirect users to `https://host:8443`, which isn't
> reachable behind the LoadBalancer.

## Publish and protect the Traefik Dashboard with basic Auth

To expose the dashboard securely as [recommended](https://doc.traefik.io/traefik/operations/dashboard/#dashboard-router-rule)
in the documentation, it may be useful to override the router rule to specify
a domain to match, or accept requests on the root path (/) to redirect them to /dashboard/.

```yaml
# Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    spec:
      entryPoints:
        - websecure
      routes:
        - kind: Rule
          # Custom match rule with host domain
          match: Host(`traefik-dashboard.example.com`)
          # Add custom middlewares : authentication and redirection
          middlewares:
            - name: traefik-dashboard-auth
          services:
            - kind: TraefikService
              name: api@internal

# Create the custom middlewares used by the IngressRoute dashboard (can also be created in another way).
# /!\ Yes, you need to replace "changeme" password with a better one. /!\
extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-auth-secret
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: changeme

  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-auth
    spec:
      basicAuth:
        secret: traefik-dashboard-auth-secret
```

## Use Go template expressions in IngressRoute annotations and labels

The new chart does **not** template object metadata: an IngressRoute declared under the
`ingressRoute` values key has its `metadata` (annotations/labels) emitted verbatim, so any
`{{ ... }}` expression there is passed through literally and is **not** evaluated. If you need
Go-template evaluation in the annotations/labels (e.g. to inject `{{ .Release.Name }}` /
`{{ .Release.Namespace }}` for tools that discover services via annotations), ship the
IngressRoute through the `extraObjects` escape hatch — `extraObjects` entries are the only
manifests the chart runs through `tpl`, so their `{{ ... }}` expressions are evaluated at
render time.

```yaml
# extraObjects entries are processed through tpl, so {{ ... }} is evaluated.
extraObjects:
  - |
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: '{{ template "traefik.fullname" . }}-dashboard'
      namespace: '{{ .Release.Namespace }}'
      annotations:
        gethomepage.dev/enabled: "true"
        gethomepage.dev/group: Infrastructure
        gethomepage.dev/name: Traefik
        gethomepage.dev/widget.url: 'http://{{ .Release.Name }}.{{ .Release.Namespace }}:8080'
      labels:
        app.kubernetes.io/instance: '{{ .Release.Name }}'
    spec:
      entryPoints:
        - websecure
      routes:
        - kind: Rule
          match: Host(`traefik-dashboard.example.com`)
          services:
            - kind: TraefikService
              name: api@internal
```

## Publish and protect the Traefik Dashboard with an Ingress

To expose the dashboard without IngressRoute, it's more complicated and less
secure. You'll need to create an internal Service exposing the Traefik API with
special _traefik_ entrypoint. This internal Service can be created from another tool,
with the `extraObjects` section or using [custom services](#add-custom-internal-services).

You'll need to double-check:

1. Service selector with your setup.
2. Middleware annotation on the ingress, _default_ should be replaced with Traefik's namespace

```yaml
# Do not create the dashboard IngressRoute (leave `ingressRoute` empty / unset).
traefik:
  api:
    insecure: true
# Create the service, middleware and Ingress used to expose the dashboard (can also be created in another way).
# /!\ Yes, you need to replace "changeme" password with a better one. /!\
extraObjects:
  - apiVersion: v1
    kind: Service
    metadata:
      name: traefik-api
    spec:
      type: ClusterIP
      selector:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik-default
      ports:
      - port: 8080
        name: traefik
        targetPort: 8080
        protocol: TCP

  - apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-auth-secret
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: changeme

  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-auth
    spec:
      basicAuth:
        secret: traefik-dashboard-auth-secret

  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: traefik-dashboard
      annotations:
        traefik.ingress.kubernetes.io/router.entrypoints: websecure
        traefik.ingress.kubernetes.io/router.middlewares: default-traefik-dashboard-auth@kubernetescrd
    spec:
      rules:
      - host: traefik-dashboard.example.com
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: traefik-api
                port:
                  name: traefik
```
## Publish Traefik Dashboard in Rancher UI

To expose the dashboard with the Rancher UI some path modifications are required.
`basePath` needs to be changed and a `Middleware` needs to be used for URL rewriting.

```yaml
traefik:
  # Configure the basePath
  api:
    basePath: "/api/v1/namespaces/traefik/services/https:traefik:443/proxy/"

# Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    spec:
      entryPoints:
        - websecure
      routes:
        # Custom match rule with host domain
        - kind: Rule
          match: PathPrefix(`/dashboard`) || PathPrefix(`/api`)
          # Add custom middleware : this makes the path matching the internal Go router
          middlewares:
            - name: traefik-dashboard-basepath
          services:
            - kind: TraefikService
              name: api@internal

# Create the custom middlewares used by the IngressRoute dashboard (can also be created from an other source).
extraObjects:
  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-basepath
    spec:
      addPrefix:
        prefix: "/api/v1/namespaces/traefik/services/https:traefik:443/proxy"
```

## Install on AWS

It can use [native AWS support](https://kubernetes.io/docs/concepts/services-networking/service/#aws-nlb-support) on Kubernetes

```yaml
service:
  default:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

Or if [AWS LB controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/#legacy-cloud-provider) is installed :

```yaml
service:
  default:
    metadata:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb-ip
```

## Install on GCP

A [regional IP with a Service](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip#use_a_service) can be used

```yaml
service:
  default:
    spec:
      loadBalancerIP: "1.2.3.4"
```

Or a [global IP on Ingress](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip#use_an_ingress)

```yaml
service:
  default:
    spec:
      type: NodePort
extraObjects:
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: traefik
      annotations:
        kubernetes.io/ingress.global-static-ip-name: "myGlobalIpName"
    spec:
      defaultBackend:
        service:
          name: traefik
          port:
            number: 80
```

Or a [global IP on a Gateway](https://cloud.google.com/kubernetes-engine/docs/how-to/deploying-gateways) with continuous HTTPS encryption.

```yaml
service:
  default:
    spec:
      type: ClusterIP
      # The chart's default ports are rebuilt here so the websecure port can
      # carry the appProtocol hint for the Google L7 load balancer.
      ports:
        - name: web
          port: 80
          targetPort: web
        - name: websecure
          port: 443
          targetPort: websecure
          appProtocol: HTTPS # Hint for Google L7 load balancer
extraObjects:
- apiVersion: gateway.networking.k8s.io/v1beta1
  kind: Gateway
  metadata:
    name: traefik
    annotations:
      networking.gke.io/certmap: "myCertificateMap"
  spec:
    gatewayClassName: gke-l7-global-external-managed
    addresses:
    - type: NamedAddress
      value: "myGlobalIPName"
    listeners:
    - name: https
      protocol: HTTPS
      port: 443
- apiVersion: gateway.networking.k8s.io/v1beta1
  kind: HTTPRoute
  metadata:
    name: traefik
  spec:
    parentRefs:
    - kind: Gateway
      name: traefik
    rules:
    - backendRefs:
      - name: traefik
        port: 443
- apiVersion: networking.gke.io/v1
  kind: HealthCheckPolicy
  metadata:
    name: traefik
  spec:
    default:
      config:
        type: HTTP
        httpHealthCheck:
          port: 8080
          requestPath: /ping
    targetRef:
      group: ""
      kind: Service
      name: traefik
```

## Install on Azure

A [static IP on a resource group](https://learn.microsoft.com/en-us/azure/aks/static-ip) can be used:

```yaml
service:
  default:
    spec:
      loadBalancerIP: "1.2.3.4"
    metadata:
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-resource-group: myResourceGroup
```

Here is a more complete example, using the native Let's Encrypt feature of Traefik Proxy with Azure DNS:

```yaml
persistence:
  spec:
    resources:
      requests:
        storage: 128Mi
traefik:
  certificatesResolvers:
    letsencrypt:
      acme:
        email: "{{ letsencrypt_email }}"
        #caServer: https://acme-v02.api.letsencrypt.org/directory # Production server
        caServer: https://acme-staging-v02.api.letsencrypt.org/directory # Staging server
        dnsChallenge:
          provider: azuredns
        storage: /data/acme.json
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            env:
              - name: AZURE_CLIENT_ID
                value: "{{ azure_dns_challenge_application_id }}"
              - name: AZURE_CLIENT_SECRET
                valueFrom:
                  secretKeyRef:
                    name: azuredns-secret
                    key: client-secret
              - name: AZURE_SUBSCRIPTION_ID
                value: "{{ azure_subscription_id }}"
              - name: AZURE_TENANT_ID
                value: "{{ azure_tenant_id }}"
              - name: AZURE_RESOURCE_GROUP
                value: "{{ azure_resource_group }}"
        initContainers:
          - name: volume-permissions
            image: busybox:latest
            command: ["sh", "-c", "ls -la /; touch /data/acme.json; chmod -v 600 /data/acme.json"]
            volumeMounts:
              - mountPath: /data
                name: data
        # podSecurityContext maps to the pod-level securityContext
        securityContext:
          fsGroup: 65532
          fsGroupChangePolicy: "OnRootMismatch"
service:
  default:
    spec:
      type: LoadBalancer
    metadata:
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-resource-group: "{{ azure_node_resource_group }}"
        service.beta.kubernetes.io/azure-pip-name: "{{ azure_resource_group }}"
        service.beta.kubernetes.io/azure-dns-label-name: "{{ azure_resource_group }}"
        service.beta.kubernetes.io/azure-allowed-ip-ranges: "{{ ip_range | join(',') }}"
extraObjects:
  - apiVersion: v1
    kind: Secret
    metadata:
      name: azuredns-secret
      namespace: traefik
    type: Opaque
    stringData:
      client-secret: "{{ azure_dns_challenge_application_secret }}"
```

## Install on Azure behind an Application Gateway (AGIC)

When using the [Application Gateway Ingress Controller (AGIC)](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview),
health probes need to reach Traefik's `/ping` endpoint.
Enable the built-in healthcheck IngressRoute so that `/ping` is served on the `web` entrypoint,
and create an Ingress with the AGIC health probe annotations:

```yaml
ingressRoute:
  healthcheck:
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: PathPrefix(`/ping`)
          services:
            - kind: TraefikService
              name: ping@internal

extraObjects:
  - apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: traefik
      annotations:
        appgw.ingress.kubernetes.io/health-probe-path: "/ping"
        appgw.ingress.kubernetes.io/health-probe-port: "8000"
        appgw.ingress.kubernetes.io/backend-protocol: "http"
    spec:
      ingressClassName: azure-application-gateway
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: '{{ template "traefik.fullname" . }}'
                    port:
                      number: 80
```

## Install on Azure with Load Balancer health probes

When using the Azure Load Balancer directly (without AGIC), configure the health probes to use Traefik's `/ping` endpoint. Enable the built-in healthcheck IngressRoute so that `/ping` is served on the `web` entrypoint (port 80) — this avoids exposing the management port (8080) on the Load Balancer:

```yaml
ingressRoute:
  healthcheck:
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: PathPrefix(`/ping`)
          services:
            - kind: TraefikService
              name: ping@internal

service:
  default:
    spec:
      externalTrafficPolicy: Local
    metadata:
      annotations:
        service.beta.kubernetes.io/port_80_health-probe_protocol: "http"
        service.beta.kubernetes.io/port_80_health-probe_request-path: "/ping"
        service.beta.kubernetes.io/port_443_health-probe_protocol: "http"
        service.beta.kubernetes.io/port_443_health-probe_request-path: "/ping"
```

## Use ServiceMonitor on AKS (Azure Monitor / managed Prometheus)

Enable a ServiceMonitor so managed Prometheus can scrape Traefik metrics on AKS. In
the new chart, the `ServiceMonitor`/`PrometheusRule` CRDs are no longer chart objects
(there is no `metrics.prometheus.serviceMonitor` knob); ship them through the
`extraObjects` escape hatch instead. Traefik already exposes Prometheus metrics on the
`metrics` entryPoint (port `9100`, path `/metrics`) — add a dedicated `metrics` Service
to the `service` map as the scrape target, then point the ServiceMonitor at it. Override
the CRD `apiVersion` (e.g. `azmonitoring.coreos.com/v1`) if Azure Monitor requires it.

```yaml
traefik:
  metrics:
    prometheus:
      entryPoint: metrics

# Dedicated scrape Service exposing the metrics entryPoint (port 9100). The chart
# only auto-fills the selector for the default/hub Service entries, so a custom
# scrape Service must declare its own selector matching the Traefik pods.
service:
  metrics:
    spec:
      type: ClusterIP
      selector:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik   # = your release name
      ports:
        - name: metrics
          port: 9100
          targetPort: metrics
          protocol: TCP

# Ship the ServiceMonitor and PrometheusRule as raw manifests, each as a YAML
# string block (- |) so the chart runs them through tpl and the helper includes
# render as real maps. Set the apiVersion to azmonitoring.coreos.com/v1 for Azure
# Monitor managed Prometheus.
extraObjects:
  - |
    apiVersion: azmonitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: '{{ template "traefik.fullname" . }}-metrics'
      namespace: '{{ .Release.Namespace }}'
      labels:
        {{- include "traefik.labels" . | nindent 8 }}
    spec:
      jobLabel: '{{ .Release.Name }}'
      endpoints:
        - targetPort: metrics
          path: /metrics
      namespaceSelector:
        matchNames:
          - '{{ .Release.Namespace }}'
      selector:
        matchLabels:
          {{- include "traefik.selectorLabels" . | nindent 10 }}
  - |
    apiVersion: azmonitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: '{{ template "traefik.fullname" . }}-rules'
      namespace: '{{ .Release.Namespace }}'
      labels:
        {{- include "traefik.labels" . | nindent 8 }}
    spec:
      groups: []
```

## Use an IngressClass

Unlike the legacy chart (where the `IngressClass` was opt-in via `ingressClass.enabled`),
the new chart **ships an `IngressClass` enabled by default**, registered as the cluster's
default class. It is wired to the chart's `kubernetesIngress` provider, so plain Kubernetes
`Ingress` objects (without an explicit `ingressClassName`) are picked up out of the box.

The default looks like this (already present in `values.yaml`):

```yaml
ingressClass:
  metadata:
    annotations:
      ingressclass.kubernetes.io/is-default-class: "true"
```

To make it a **non-default** class (Traefik only handles `Ingress` objects that explicitly
reference it), drop the default-class annotation. An empty `annotations: {}` map cannot
clear it (Helm deep-merges values onto the defaults, so an empty map adds nothing and the
pre-set annotation persists) — set the specific key to `null` to remove it:

```yaml
ingressClass:
  metadata:
    annotations:
      ingressclass.kubernetes.io/is-default-class: null
```

To **disable** the `IngressClass` entirely, set it to `null`:

```yaml
ingressClass: null
```

If you also want Traefik to honour an `IngressClass` (or a legacy `kubernetes.io/ingress.class`
annotation) on the **CRD** and **Ingress** providers, set it in the Traefik static configuration:

```yaml
traefik:
  providers:
    kubernetesCRD:
      ingressClass: traefik
    kubernetesIngress:
      ingressClass: traefik
```

## Use HTTP3

By default, it will use a Load balancers with mixed protocols on `websecure`
entrypoint. They have been available since v1.20 and in beta as of Kubernetes v1.24.
Availability may depend on your Kubernetes provider.

When using TCP and UDP with a single service, you may encounter [this issue](https://github.com/kubernetes/kubernetes/issues/47249#issuecomment-587960741) from Kubernetes.
If you want to avoid this issue, you can set `traefik.entryPoints.websecure.http3.advertisedPort`
to another value than 443

```yaml
traefik:
  entryPoints:
    websecure:
      http3:
        enabled: true
```

You can also create two `Service`, one for TCP and one for UDP.

```yaml
traefik:
  entryPoints:
    websecure:
      http3:
        enabled: true
```

## Use PROXY protocol on Digital Ocean

PROXY protocol is a protocol for sending client connection information, such as origin IP addresses and port numbers, to the final backend server, rather than discarding it at the load balancer.

```yaml
traefik:
  entryPoints:
    web:
      forwardedHeaders:
        trustedIPs: &trustedIPs
          - 127.0.0.1/32
          # IP range Load Balancer is on
          - 10.0.0.0/8
          # IP range of private (VPC) interface - CHANGE THIS TO YOUR NETWORK SETTINGS
          # This is needed when "externalTrafficPolicy: Cluster" is specified, as inbound traffic from the load balancer to a Traefik instance could be redirected from another cluster node on the way through.
          - 172.16.0.0/12
      proxyProtocol:
        trustedIPs: *trustedIPs
    websecure:
      forwardedHeaders:
        trustedIPs: *trustedIPs
      proxyProtocol:
        trustedIPs: *trustedIPs
service:
  default:
    metadata:
      annotations:
        # This will tell DigitalOcean to enable the proxy protocol.
        # Note that only REGIONAL type loadbalancers are supported.
        # service.beta.kubernetes.io/do-loadbalancer-type: "REGIONAL"
        service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
    spec:
      type: LoadBalancer
      # This is the default and should stay as cluster to keep the DO health checks working.
      externalTrafficPolicy: Cluster
```

## Using plugins

Traefik downloads and builds remote plugins at startup into `/plugins-storage`. The chart
runs as non-root with a **read-only root filesystem**, and — unlike the legacy chart — it
ships **no plugin machinery**, so it does **not** auto-provision that directory. You must add
a writable volume at `/plugins-storage` yourself. `traefik.experimental.plugins` itself is
native Traefik static config and is passed through verbatim.

Here is an example with the [CrowdSec](https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin/blob/main/examples/kubernetes/README.md) plugin:

```yaml
traefik:
  experimental:
    plugins:
      demo:
        moduleName: github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin
        version: v1.3.5
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: plugins
                mountPath: /plugins-storage
        volumes:
          - name: plugins
            emptyDir: {}
```

To persist the built plugins across restarts, replace the `emptyDir` with a PVC:

```yaml
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: plugins
                mountPath: /plugins-storage
        volumes:
          - name: plugins
            persistentVolumeClaim:
              claimName: my-plugins-vol
extraObjects:
  - kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: my-plugins-vol
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

## Local Plugins

To develop or test plugins without pushing them to a registry, Traefik reads local plugin
source from `/plugins-local/src/<moduleName>`.

> [!IMPORTANT]
> The legacy chart's `localPlugins.<name>.{type, source, hostPath, mountPath, volumeName,
> subPath}` keys were **chart machinery** — the chart built ConfigMaps/volumes/mounts from
> them. The new chart has **no plugin machinery**: only `traefik.experimental.localPlugins.<name>.moduleName`
> (and any native plugin settings) reach Traefik. You wire the source volume yourself under
> `deployment.spec.template.spec` and mount it at `/plugins-local/src/<moduleName>`. The three
> legacy `type`s become ordinary Kubernetes volumes:

### Host-path source (legacy `type: hostPath`)

Mount the plugin source from a node path. `hostPath` ties the pod to a node and is a security
risk — prefer a ConfigMap (inline) or a PVC/CSI volume below.

```yaml
traefik:
  experimental:
    localPlugins:
      local-demo:
        moduleName: github.com/traefik/localplugindemo
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: local-demo
                mountPath: /plugins-local/src/github.com/traefik/localplugindemo
        volumes:
          - name: local-demo
            hostPath:
              path: /path/to/plugin-source
```

### Inline source via a ConfigMap (legacy `type: inlinePlugin`)

Ship the plugin source in a ConfigMap (here via `extraObjects`) and mount it. A ConfigMap is
limited to ~1 MiB, so this suits small/medium plugins; for larger ones use a PVC/CSI volume.

```yaml
traefik:
  experimental:
    localPlugins:
      helloworld-plugin:
        moduleName: github.com/example/helloworldplugin
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: helloworld-plugin
                mountPath: /plugins-local/src/github.com/example/helloworldplugin
        volumes:
          - name: helloworld-plugin
            configMap:
              name: helloworld-plugin-src
extraObjects:
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: helloworld-plugin-src
    data:
      go.mod: |
        module github.com/example/helloworldplugin

        go 1.23
      .traefik.yml: |
        displayName: Hello World Plugin
        type: middleware

        import: github.com/example/helloworldplugin

        summary: |
          This is a simple plugin that prints "Hello, World!" to the response.

        testData:
          message: "Hello, World!"
      main.go: |
        package helloworldplugin

        import (
          "context"
          "net/http"
        )

        type Config struct{}

        func CreateConfig() *Config {
          return &Config{}
        }

        type HelloWorld struct {
          next http.Handler
        }

        func New(ctx context.Context, next http.Handler, config *Config, name string) (http.Handler, error) {
          return &HelloWorld{next: next}, nil
        }

        func (h *HelloWorld) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
          rw.Write([]byte("Hello, World!"))
          h.next.ServeHTTP(rw, req)
        }
```

> **Advantages**: secure (no host filesystem access), portable, version-controlled with your
> Helm values.

### Volume-backed source — PVC / CSI (legacy `type: localPath`)

Back the plugin source with any Kubernetes volume (PVC, or a CSI driver for S3/blob/NFS). The
optional `subPath` selects a sub-directory within the volume.

```yaml
traefik:
  experimental:
    localPlugins:
      s3-plugin:
        moduleName: github.com/example/s3plugin
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: plugin-storage
                mountPath: /plugins-local/src/github.com/example/s3plugin
                subPath: plugins/s3plugin   # optional sub-directory within the volume
        volumes:
          - name: plugin-storage
            persistentVolumeClaim:
              claimName: plugin-storage-pvc
          # Or a CSI driver for S3/blob storage:
          # - name: plugin-storage
          #   csi:
          #     driver: s3.csi.aws.com
          #     volumeAttributes:
          #       bucketName: my-plugin-bucket
```

> **Advantages**:
>
> - **Flexible**: supports any Kubernetes volume type (PVC, CSI, NFS, …).
> - **Secure**: works with CSI drivers for cloud storage (S3, Azure Blob, GCS).
> - **Scalable**: centralized plugin storage, no per-node requirements.
## Using Traefik-Hub with private plugin registries

With Traefik Hub, it's possible to use plugins deployed on both public or private registries.
Each registry source requires a base module name (domain) and authentication credentials.
This can be achieved this way:

> [!NOTE]
> The chart requires a Hub image >= v3.19.0 (the version gate rejects older tags). As with
> any plugin configuration, Traefik builds the plugins into `/plugins-storage` at startup, and
> the chart's read-only root filesystem means you must add a writable volume there yourself
> (see [Using plugins](#using-plugins)).

```yaml
image: ghcr.io/traefik/traefik-hub:v3.19.4

traefik:
  hub:
    pluginRegistry:
      sources:
        noop:
          baseModuleName: "github.com"
          github:
            token: "<your-github-pat>"
  experimental:
    plugins:
      noop:
        moduleName: github.com/traefik-contrib/noop
        version: v0.1.0

# Writable volume for the plugins Traefik builds at startup (read-only root fs).
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: plugins
                mountPath: /plugins-storage
        volumes:
          - name: plugins
            emptyDir: {}

extraObjects:
  - apiVersion: traefik.io/v1alpha1
    kind: Middleware
    metadata:
      name: noop
    spec:
      plugin:
        noop:
          responseCode: 204
  - apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: demo
    spec:
      entryPoints:
        - web
      routes:
        - kind: Rule
          match: Host(`demo.localhost`)
          services:
            - name: noop@internal
              kind: TraefikService
          middlewares:
            - name: noop
```

> [!NOTE]  
> This code is only written for demonstration purpose.
> The prefered way of configuration either Github or Gitlab credentials is to use an URN like `urn:k8s:secret:github-token:access-token`.

## Use Traefik native Let's Encrypt integration, without cert-manager

In Traefik Proxy, ACME certificates are stored in a JSON file.

This file needs to have 0600 permissions, meaning, only the owner of the file has full read and write access to it.
By default, Kubernetes recursively changes ownership and permissions for the content of each volume.

=> An initContainer can be used to avoid an issue on this sensitive file.
See [#396](https://github.com/traefik/traefik-helm-chart/issues/396) for more details.

Once the provider is ready, it can be used in an `IngressRoute`:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: [...]
spec:
  entryPoints: [...]
  routes: [...]
  tls:
    certResolver: letsencrypt
```

:information_source: Change `apiVersion` to `traefik.containo.us/v1alpha1` for charts prior to v28.0.0

See [the list of supported providers](https://doc.traefik.io/traefik/https/acme/#providers) for others.

## Example with Cloudflare

This example needs a Cloudflare token in a Kubernetes `Secret` and a working `StorageClass`.

**Step 1**: Create `Secret` with Cloudflare token:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare
type: Opaque
stringData:
  token: {{ SET_A_VALID_TOKEN_HERE }}
```

**Step 2**:

```yaml
traefik:
  certificatesResolvers:
    letsencrypt:
      acme:
        dnsChallenge:
          provider: cloudflare
        storage: /data/acme.json

persistence:
  spec:
    storageClassName: xxx

deployment:
  spec:
    template:
      spec:
        # ACME DNS-challenge credentials, injected into the traefik container.
        containers:
          - name: traefik
            env:
              - name: CF_DNS_API_TOKEN
                valueFrom:
                  secretKeyRef:
                    name: cloudflare
                    key: token
        # Fix ownership/permissions of the acme.json file (see #396).
        initContainers:
          - name: volume-permissions
            image: busybox:latest
            command: ["sh", "-c", "touch /data/acme.json; chmod -v 600 /data/acme.json"]
            volumeMounts:
              - mountPath: /data
                name: data
        securityContext:
          fsGroup: 65532
          fsGroupChangePolicy: "OnRootMismatch"
```

>[!NOTE]
> With [Traefik Hub](https://traefik.io/traefik-hub/), certificates can be stored as a `Secret` on Kubernetes with `distributedAcme` resolver.

## Provide default certificate with cert-manager and CloudFlare DNS

Setup:

- cert-manager installed in `cert-manager` namespace
- A Cloudflare account on a DNS Zone

**Step 1**: Create `Secret` and `Issuer` needed by `cert-manager` with your API Token.
See [cert-manager documentation](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/)
for creating this token with needed rights:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare
  namespace: traefik
type: Opaque
stringData:
  api-token: XXX
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cloudflare
  namespace: traefik
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: email@example.com
    privateKeySecretRef:
      name: cloudflare-key
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare
              key: api-token
```

**Step 2**: Create `Certificate` in traefik namespace

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-example-com
  namespace: traefik
spec:
  secretName: wildcard-example-com-tls
  dnsNames:
    - "example.com"
    - "*.example.com"
  issuerRef:
    name: cloudflare
    kind: Issuer
```

**Step 3**: Check that it's ready

```bash
kubectl get certificate -n traefik
```

If needed, logs of the cert-manager pod can give you more information

**Step 4**: Use it on the TLS Store in **values.yaml** file for this Helm Chart

```yaml
tlsStore:
  default:
    spec:
      defaultCertificate:
        secretName: wildcard-example-com-tls
```

**Step 5**: Enjoy. All your `IngressRoute` use this certificate by default now.

They should use a websecure entrypoint like this:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: example-com-tls
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`test.example.com`)
    kind: Rule
    services:
    - name: XXXX
      port: 80
```

## Add custom (internal) services

In some cases, you might want to have more than one Traefik service within your cluster,
e.g. a default (external) one and a service that is only exposed internally to pods within your cluster.

In the new chart, `service` is a **map of name → Service body**. The `service.default` entry is
the main (external) Service the chart manages — the chart owns its `selector` and ships its
`ports` (web on 80, websecure on 443). To add another Service, add a sibling entry under
`service`; each extra entry is rendered as `<release-fullname>-<entry>` and **must provide its
own `spec`** (the chart only fills the `selector`/`ports` for `default` and the Hub-managed
entries). For example, to add an internal `ClusterIP` Service:

```yaml
service:
  internal:
    metadata:
      labels:
        traefik-service-label: internal
    spec:
      type: ClusterIP
      selector:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik-traefik
      ports:
        # Sensitive data should not be exposed on the internet
        # => only expose the traefik API port on this internal Service.
        - port: 8080
          name: traefik
          targetPort: traefik
          protocol: TCP
```

This will then provide an additional Service manifest, looking like this:

```yaml
---
# Source: traefik/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik-internal
  namespace: traefik
[...]
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: traefik
    app.kubernetes.io/instance: traefik-traefik
  ports:
  - port: 8080
    name: traefik
    targetPort: traefik
    protocol: TCP
```
## Use this Chart as a dependency of your own chart

First, let's create a default Helm Chart, with Traefik as a dependency.

```bash
helm create foo
cd foo
echo "
dependencies:
  - name: traefik
    version: "0.1.0"
    repository: "https://traefik.github.io/charts"
" >> Chart.yaml
```

Second, let's tune some values like enabling HPA. The new chart has no
`autoscaling.enabled` toggle — autoscaling is enabled by presence of a `spec:`
with at least `maxReplicas`:

```bash
cat <<-EOF >> values.yaml
traefik:
  autoscaling:
    spec:
      maxReplicas: 3
EOF
```

Third, one can see if it works as expected:

```bash
helm dependency update
helm dependency build
helm template . | grep -A 14 -B 3 Horizontal
```

It should produce this output:

```yaml
---
# Source: foo/charts/traefik/templates/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: release-name-traefik
  namespace: flux-system
  labels:
    app.kubernetes.io/name: traefik
    app.kubernetes.io/instance: release-name-flux-system
    helm.sh/chart: traefik-0.1.0
    app.kubernetes.io/managed-by: Helm
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: release-name-traefik
  maxReplicas: 3
```

## Use this Chart with FluxCD

This chart is published to an OCI registry at `oci://ghcr.io/traefik/helm`.
Here is how to deploy it with [FluxCD](https://fluxcd.io/).

Create a `HelmRepository` resource pointing to the OCI registry:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: traefik
  namespace: flux-system
spec:
  type: oci
  interval: 5m
  url: oci://ghcr.io/traefik/helm
```

Then create a `HelmRelease` referencing it:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: traefik
  namespace: traefik
spec:
  interval: 10m
  chart:
    spec:
      chart: traefik
      version: "0.1.0"
      sourceRef:
        kind: HelmRepository
        name: traefik
        namespace: flux-system
  values:
    # Your Traefik values here
    image: docker.io/traefik:v3.6.12
```

> [!NOTE]
> The `url` in `HelmRepository` should be `oci://ghcr.io/traefik/helm` (the registry path **without** the chart name). The chart name is specified in `HelmRelease.spec.chart.spec.chart`.

> [!TIP]
> Pin the chart `version` to avoid unexpected upgrades. FluxCD supports [semver ranges](https://fluxcd.io/flux/components/source/helmrepositories/#semver-example) like `">=0.1.0 <0.2.0"`.

## Configure TLS

The [TLS options](https://doc.traefik.io/traefik/https/tls/#tls-options) allow one to configure some parameters of the TLS connection.

In the new chart, `tlsOptions` is a top-level map of name → `{metadata, spec}`:
each entry's `labels`/`annotations` move under `metadata`, the rest under `spec`.

```yaml
tlsOptions:
  default:
    metadata:
      labels: {}
    spec:
      sniStrict: true
  custom-options:
    metadata:
      labels: {}
    spec:
      curvePreferences:
        - CurveP521
        - CurveP384
```

## Use the latest build of Traefik v3 from master

An experimental build of Traefik Proxy is available on a specific community repository: `traefik/traefik`.

The tag does not follow semver. The new chart carries the tag in the single
`image:` string, so there is no separate `versionOverride` (it is dropped):

```yaml
image: traefik/traefik:experimental-v3.4
```

## Use Prometheus Operator

The new chart does not ship the legacy `metrics.prometheus.{service,serviceMonitor,prometheusRule,headerLabels,disableAPICheck}`
helpers — `traefik.metrics` accepts only **native** Traefik static config. The
Prometheus Operator integration is therefore rebuilt from chart primitives:

- the native Prometheus exporter stays under `traefik.metrics.prometheus` (it is
  already enabled by default, exposed on the `metrics` entryPoint);
- the **scrape Service** becomes an entry in the `service` map, exposing the
  `metrics` entryPoint container port;
- the **ServiceMonitor** and **PrometheusRule** (Prometheus Operator CRDs) are
  shipped verbatim via `extraObjects`.

```yaml
traefik:
  # Native Traefik Prometheus exporter (enabled by default on the `metrics`
  # entryPoint). headerLabels become native `headerLabels` on the exporter.
  metrics:
    prometheus:
      entryPoint: metrics
      headerLabels:
        user_id: X-User-Id
        tenant: X-Tenant

# Scrape Service exposing the `metrics` entryPoint (legacy
# metrics.prometheus.service.enabled: true). The chart only auto-fills the
# selector for the default/hub Service entries, so a custom scrape Service must
# declare its own selector matching the Traefik pods.
service:
  metrics:
    spec:
      type: ClusterIP
      selector:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik   # = your release name
      ports:
        - name: metrics
          port: 9100
          targetPort: metrics
          protocol: TCP

# Prometheus Operator CRDs, shipped verbatim as YAML string blocks (- |) so the
# chart runs them through tpl and the `traefik.labels` include renders as a real
# map (legacy serviceMonitor / prometheusRule helpers are gone from the chart).
extraObjects:
  - |
    apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: '{{ template "traefik.fullname" . }}'
      namespace: '{{ .Release.Namespace }}'
      labels:
        {{- include "traefik.labels" . | nindent 8 }}
    spec:
      jobLabel: traefik
      selector:
        matchLabels:
          app.kubernetes.io/name: '{{ template "traefik.name" . }}'
          app.kubernetes.io/instance: '{{ .Release.Name }}-{{ .Release.Namespace }}'
      namespaceSelector:
        matchNames:
          - '{{ .Release.Namespace }}'
      endpoints:
        - port: metrics
          path: /metrics
          interval: 30s
          honorLabels: true
          metricRelabelings:
            - sourceLabels: [__name__]
              separator: ;
              regex: ^fluentd_output_status_buffer_(oldest|newest)_.+
              replacement: $1
              action: drop
          relabelings:
            - sourceLabels: [__meta_kubernetes_pod_node_name]
              separator: ;
              regex: ^(.*)$
              targetLabel: nodename
              replacement: $1
              action: replace
  - |
    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      name: '{{ template "traefik.fullname" . }}'
      namespace: '{{ .Release.Namespace }}'
      labels:
        {{- include "traefik.labels" . | nindent 8 }}
    spec:
      groups:
        - name: traefik
          rules:
            - alert: TraefikDown
              expr: up{job="traefik"} == 0
              for: 5m
              labels:
                context: traefik
                severity: warning
              annotations:
                summary: "Traefik Down"
                description: "{{`{{ $labels.pod }}`}} on {{`{{ $labels.nodename }}`}} is down"
```

## Use Kubernetes Gateway API

One can use the new stable Kubernetes gateway API provider by setting the following _values_:

```yaml
traefik:
  providers:
    kubernetesGateway:
      enabled: true
# Render the GatewayClass + a Gateway with at least one listener. A Gateway with
# no listeners accepts no traffic, so HTTPRoutes never attach.
gatewayClass: {}
gateway:
  spec:
    listeners:
      - name: web
        port: 8000
        protocol: HTTP
```

and deploy Gateway API CRDs:

```sh
# Install Gateway API CRDs from the Standard channel.
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
```

<details>

<summary>With those values, a whoami service can be exposed with an HTTPRoute</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami

---
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  selector:
    app: whoami
  ports:
    - protocol: TCP
      port: 80

---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: whoami
spec:
  parentRefs:
    - name: traefik   # = <fullname>, the Gateway name the chart renders
  hostnames:
    - whoami.docker.localhost
  rules:
    - matches:
        - path:
            type: Exact
            value: /

      backendRefs:
        - name: whoami
          port: 80
          weight: 1
```

Once it's applied, whoami should be accessible on [whoami.docker.localhost](http://whoami.docker.localhost/)

</details>

:information_source: In this example, `Deployment` and `HTTPRoute` should be deployed in the same namespace as the Traefik Gateway: Chart namespace.

## Use Kubernetes Gateway API with cert-manager

One can use the new stable Kubernetes Gateway API provider with automatic TLS certificate delivery (with cert-manager) by setting the following _values_:

```yaml
traefik:
  providers:
    kubernetesGateway:
      enabled: true
gateway:
  metadata:
    annotations:
      cert-manager.io/issuer: selfsigned-issuer
  spec:
    listeners:
      - name: websecure
        hostname: whoami.docker.localhost
        port: 8443
        protocol: HTTPS
        tls:
          certificateRefs:
            - name: whoami-tls
```

Install cert-manager:

```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm upgrade --install \
cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version v1.15.1 \
--set crds.enabled=true \
--set "extraArgs={--enable-gateway-api}"
```

<details>

<summary>With those values, a whoami service can be exposed with HTTPRoute on both HTTP and HTTPS</summary>

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami

---
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  selector:
    app: whoami
  ports:
    - protocol: TCP
      port: 80

---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: whoami
spec:
  parentRefs:
    - name: traefik   # = <fullname>, the Gateway name the chart renders
  hostnames:
    - whoami.docker.localhost
  rules:
    - matches:
        - path:
            type: Exact
            value: /

      backendRefs:
        - name: whoami
          port: 80
          weight: 1

---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

Once it's applied, whoami should be accessible on https://whoami.docker.localhost

</details>
## Use Kubernetes Ingress NGINX Provider

Starting with Traefik Proxy v3.6.2, one can use the Kubernetes Ingress NGINX provider by setting the following _values_:

```yaml
traefik:
  providers:
    kubernetesIngressNGINX:
      enabled: true
```

This provider allows Traefik to consume Kubernetes Ingress resources with NGINX-specific annotations. This is particularly useful when migrating from NGINX Ingress Controller to Traefik.

<details>

<summary>This example demonstrates a seamless migration from NGINX Ingress Controller to Traefik</summary>

where the same Ingress resource continues to work without modification.<br>

**Step 1**: Install NGINX Ingress Controller and deploy the whoami application

```bash
# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Deploy the application:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: traefik/whoami
          ports:
            - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  selector:
    app: whoami
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami
  annotations:
    nginx.ingress.kubernetes.io/affinity: cookie
    nginx.ingress.kubernetes.io/affinity-mode: persistent
spec:
  ingressClassName: nginx
  rules:
    - host: whoami.docker.localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami
                port:
                  number: 80
```

**Step 2**: Test that the application works with NGINX

```bash
# Port-forward to NGINX
kubectl port-forward -n ingress-nginx deployment/ingress-nginx-controller 8000:80 &

# Test with NGINX
curl http://whoami.docker.localhost:8000 -c /tmp/cookies.txt -b /tmp/cookies.txt
```

You should see the whoami response with your request details.

**Step 3**: Install Traefik with the Kubernetes Ingress NGINX provider enabled (alongside NGINX)

```bash
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set traefik.providers.kubernetesIngressNGINX.enabled=true
```

Or using a values file:

```yaml
traefik:
  providers:
    kubernetesIngressNGINX:
      enabled: true
```

**Step 4**: Test that the application now also works with Traefik

Both NGINX and Traefik are now running in parallel, each serving the same Ingress thanks to the Traefik NGINX provider !

```bash
# Port-forward to Traefik
kubectl port-forward -n traefik deployment/traefik 8001:8000 &

# Test with Traefik (adjust the URL based on your setup)
curl http://whoami.docker.localhost:8001 -c /tmp/cookies.txt -b /tmp/cookies.txt
```

The same Ingress resource is now served by **both** NGINX and Traefik! You can verify which one is responding by checking the response headers or the service endpoints.

> :warning:
> **Important note about NGINX**: When uninstalling the NGINX Ingress Controller helm chart, it removes the `nginx` IngressClass.
> Traefik needs this IngressClass to detect and serve Ingress resources that use `ingressClassName: nginx`. Before uninstalling NGINX, it's recommended to ensure that an IngressClass like this will stay:
>
> ```yaml
> ---
> apiVersion: networking.k8s.io/v1
> kind: IngressClass
> metadata:
>   name: nginx
> spec:
>   controller: k8s.io/ingress-nginx
> ```

> :information_source:
> The Kubernetes Ingress NGINX provider supports most common NGINX Ingress annotations, allowing for a **seamless migration** from NGINX Ingress Controller to Traefik **without modifying existing Ingress resources**.

## Use Knative Provider

Starting with Traefik Proxy v3.6, one can use the Knative provider (_experimental_) by setting the following _values_:

```yaml
traefik:
  experimental:
    knative: true
  providers:
    knative:
      enabled: true
```

> :warning:
> You must first have Knative deployed. With Proxy v3.6, v1.19 of Knative is supported.
> Knative 1.19 requires Kubernetes v1.32+

> :information_source:
> If you want to test it using k3d, you'll need to set the image accordingly, for instance: `--image rancher/k3s:v1.34.1-k3s1`

Finish configuring Knative:

```shell
# 1. Install/update the Knative CRDs
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.19.0/serving-crds.yaml
# 2. Install the Knative Serving core components
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.19.0/serving-core.yaml
# 3. Update the config-network configuration to use the Traefik ingress class
kubectl patch configmap/config-network -n knative-serving --type merge \
  -p '{"data":{"ingress.class":"traefik.ingress.networking.knative.dev"}}'
# Add a custom domain to Knative configuration (in this example, docker.localhost)
kubectl patch configmap config-domain -n knative-serving --type='merge' \
  -p='{"data":{"docker.localhost":""}}'
```

With that done and the specified values set, a Knative Service can now be deployed:

```yaml
---
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: whoami
spec:
  template:
    spec:
      containers:
        - name: whoami
          image: traefik/whoami
          ports:
            - containerPort: 80
```

Once it's applied, we can check the URLs:

```shell
# 1. List Knative services
kubectl get ksvc
# 2. Test URLs
curl http://whoami.default.docker.localhost
curl -k -H "Host: whoami.default.docker.localhost" https://localhost/
```

</details>

## Use templating for additionalVolumeMounts

This example demonstrates how to use templating for the volume mount configuration to dynamically set the `subPath` parameter based on a variable.

In the new chart, container volume mounts live under `deployment.spec.template.spec.containers[0].volumeMounts` (folded onto the `traefik` container by name). Helm templating in values is preserved verbatim:

```yaml
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: plugin-volume
                mountPath: /plugins
                subPath: "{{ .Values.pluginVersion }}"
```

In your `values.yaml` file, you can specify the `pluginVersion` variable:

```yaml
pluginVersion: "v1.2.3"
```

This configuration will mount the `plugin-volume` at `/plugins` with the `subPath` set to `v1.2.3`.

## Use a custom certificate for Traefik Hub webhooks

Some CD tools may regenerate Traefik Hub mutating webhooks continuously, when using helm template.
This example demonstrates how to generate and use a custom certificate for Hub admission webhooks.

First, generate a self-signed certificate:

```bash
# this generates a self-signed certificate with a 2048 bits key, valid for 10 years, on admission.traefik.svc DNS name
openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -keyout /tmp/hub.key -out /tmp/hub.crt \
            -subj '/CN=admission.traefik.svc' -addext "subjectAltName=DNS:admission.traefik.svc" \
            -addext basicConstraints=critical,CA:FALSE -addext "keyUsage = digitalSignature, keyEncipherment" -addext "extendedKeyUsage = serverAuth, clientAuth"
cat /tmp/hub.crt | base64 -w0 > /tmp/hub.crt.b64
cat /tmp/hub.key | base64 -w0 > /tmp/hub.key.b64
```

By default the chart ships the admission certificate as the `secret.hub-admission`
entry — a self-signed cert in the Secret `<release>-hub-admission-cert`, kept stable
across upgrades via Helm `lookup`. To use **your own** certificate, disable the
chart's Secret with `secret.hub-admission: null` and create that Secret yourself
under the name the chart expects (`<release>-hub-admission-cert`). The chart's
`lookup` then reads it and wires its CA into the MutatingWebhookConfiguration
`caBundle` automatically:

```bash
kubectl create secret tls traefik-hub-admission-cert --namespace traefik --cert=/tmp/hub.crt --key=/tmp/hub.key
```

```yaml
traefik:
  hub:
    token: <your-license-token>
    apimanagement: {}
secret:
  hub-admission: null   # you own the admission cert Secret (traefik-hub-admission-cert)
```

> [!NOTE]
> The legacy `apimanagement.admission.{customWebhookCertificate,selfManagedCertificate,secretName}`
> keys were **chart machinery** and are **not** implemented in the new chart — passed through
> they would sit inertly in `traefik.yaml`. The native, design-aligned replacement is the pair
> shown here: `secret.hub-admission: null` to own the cert Secret, plus the
> `mutatingWebhookConfigurations.<name>` hatch (next example) to patch the webhooks'
> `caBundle`/annotations.

> [!TIP]
> Prefer cert-manager? Point a `Certificate` at `secretName: traefik-hub-admission-cert`
> and let it manage the admission cert — see the next example.

## Injecting CA data from a certificate resource

It is also possible to use the [CA injector](https://cert-manager.io/docs/concepts/ca-injector/) of cert-manager with annotations on the webhook.

First, you can create the certificate with a self-signed issuer:

```yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: admission
  namespace: traefik
spec:
  secretName: traefik-hub-admission-cert   # the name the chart's admission server reads
  dnsNames:
  - admission.traefik.svc
  issuerRef:
    name: selfsigned

---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned
  namespace: traefik
spec:
  selfSigned: {}
```

cert-manager writes the serving cert to `traefik-hub-admission-cert` (so the chart's
admission server uses it) and its [CA injector](https://cert-manager.io/docs/concepts/ca-injector/)
fills the webhooks' `caBundle` from the `Certificate` via an annotation. Disable the
chart's own Secret and add the annotation through the `mutatingWebhookConfigurations.<name>`
hatch (the chart ships two entries, `hub-acp` and `hub-api`):

```yaml
traefik:
  hub:
    token: <your-license-token>
    apimanagement: {}
secret:
  hub-admission: null   # cert-manager owns the admission cert Secret
mutatingWebhookConfigurations:
  hub-acp:
    metadata:
      annotations:
        cert-manager.io/inject-ca-from: traefik/admission   # <namespace>/<Certificate name>
  hub-api:
    metadata:
      annotations:
        cert-manager.io/inject-ca-from: traefik/admission
```

> [!NOTE]
> The chart still renders a static `caBundle` (from the looked-up Secret) in each webhook;
> cert-manager's injector overrides it at runtime. The legacy `selfManagedCertificate`/
> `secretName`/`annotations` keys are not implemented — this MWC-annotation hatch is the
> native equivalent.

## Use a custom certificate for Traefik Hub webhooks from an existing secret

Some CD tools may regenerate Traefik Hub mutating webhooks continuously, when using helm template.
This example demonstrates how to generate and use a custom certificate stored in a managed secret for Hub admission webhooks.

First, generate a self-signed certificate:

```bash
# this generates a self-signed certificate with a 2048 bits key, valid for 10 years, on admission.traefik.svc DNS name
openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -keyout tls.key -out tls.crt \
            -subj '/CN=admission.traefik.svc' -addext "subjectAltName=DNS:admission.traefik.svc" \
            -addext basicConstraints=critical,CA:FALSE -addext "keyUsage = digitalSignature, keyEncipherment" -addext "extendedKeyUsage = serverAuth, clientAuth"
```

Create the Secret under the name the chart's admission server reads
(`<release>-hub-admission-cert`):

```bash
kubectl create secret tls traefik-hub-admission-cert --namespace traefik --cert=tls.crt --key=tls.key
```

Then disable the chart's own admission Secret so yours is used (its CA is picked up
for the webhook `caBundle` via `lookup`) — same mechanism as *Use a custom certificate
for Traefik Hub webhooks* above:

```yaml
traefik:
  hub:
    token: <your-license-token>
    apimanagement: {}
secret:
  hub-admission: null
```

> [!NOTE]
> The new chart requires `traefik.hub.token` whenever `traefik.hub.apimanagement` is set, or the render fails validation. The legacy `apimanagement.admission.selfManagedCertificate` flag is not implemented; `secret.hub-admission: null` is its native equivalent.

## Mount datadog DSD socket directly into the Traefik container (i.e. no more socat sidecar)

This example demonstrates how to directly mount Datadog APM socket into Traefik container, thus avoiding the need for a socat sidecar container.

```yaml
traefik:
  metrics:
    datadog:
      address: unix:///var/run/datadog/dsd.socket # https://doc.traefik.io/traefik/observability/metrics/datadog/#address
deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            volumeMounts:
              - name: ddsocketdir
                mountPath: /var/run/datadog
                readOnly: false
        volumes:
          - name: ddsocketdir
            hostPath:
              path: /var/run/datadog/
```

## Use Traefik Hub AI Gateway

This example demonstrates how to enable AI Gateway in Traefik Hub and set a maxRequestBodySize of 10 MiB.

```yaml
traefik:
  hub:
    token: # <=== Set your token here
    aigateway:
      enabled: true
      maxRequestBodySize: 10485760 # optional, default to 1MiB
```
## Deploy multiple Gateways with a single Traefik Deployment/DaemonSet

This example exposes two Gateways (e.g., `internal` and `external`) from a single Traefik installation.

In the new chart, the legacy `ports` map becomes entryPoint addresses under `traefik.entryPoints`, and the per-Gateway exposure that the legacy chart drove via `ports.*.expose` / `service.additionalServices` is recreated as a **named entry under the `service` map** (the new chart has one Service per `service` entry — there is no per-named-Service `expose` toggle anymore). The chart owns the `default` Service's `selector`; any extra Service entry just needs its own `spec`.

The chart owns the Gateway's name (`<fullname>`), so the legacy `gateway.name: traefik-internal` is dropped — the managed Gateway below is the `internal` one. The second (`external`) Gateway is a plain Gateway API manifest deployed verbatim (here via `extraObjects`, or apply it separately).

```yaml
traefik:
  entryPoints:
    # entryPoints for the external gateway (the chart-default web/websecure
    # entryPoints still exist; these are added alongside them)
    web-ext:
      address: ":9080/tcp"
    websecure-ext:
      address: ":9443/tcp"
  providers:
    kubernetesGateway:
      enabled: true
      statusAddress:
        service:
          enabled: false

# The chart-managed (internal) Gateway. The chart owns its name (<fullname>)
# and gatewayClassName.
gateway: {}
gatewayClass: {}

# Recreate the external exposure as a named Service entry (replaces the
# legacy ports.*.expose.external + service.additionalServices.external).
# This Service targets the same workload; map its ports to the web-ext /
# websecure-ext entryPoint container ports by name. The chart only auto-fills
# the selector for the default/hub Service entries, so this extra entry must
# declare its own selector matching the Traefik pods.
service:
  external:
    spec:
      type: LoadBalancer
      selector:
        app.kubernetes.io/name: traefik
        app.kubernetes.io/instance: traefik   # = your release name
      ports:
        - name: web-ext
          port: 80
          targetPort: web-ext
          protocol: TCP
        - name: websecure-ext
          port: 443
          targetPort: websecure-ext
          protocol: TCP
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik-external
spec:
  gatewayClassName: traefik
  listeners:
    - name: web-ext
      protocol: HTTP
      port: 9080
      allowedRoutes:
        namespaces:
          from: All
    # Comment out if you have a valid TLS certificate
    # - name: websecure-ext
    #   protocol: HTTPS
    #   port: 9443
    #   allowedRoutes:
    #     namespaces:
    #       from: All
    #   tls:
    #     mode: Terminate
    #     certificateRefs:
    #       - group: ""
    #         kind: Secret
    #         name: some-tls-cert
```

## Set externalTrafficPolicy Local for Traefik Service

```yaml
service:
  default:
    spec:
      externalTrafficPolicy: Local
```

## Use Multi-Cluster Provider

This example shows how to configure multi-cluster traffic with a parent cluster and a child cluster.

> [!WARNING]
> This feature is experimental and requires Traefik Hub with a specific subscription.

### Child cluster

Enable the Multi-Cluster provider on the child, create an uplink entryPoint, and advertise a workload (_this example uses the file provider for simplicity_).

The legacy `ports.multicluster.uplink: true` flag IS a native Traefik Hub concept: it maps to an **uplink entryPoint** under `traefik.hub.uplinkEntryPoints.<name>` (the legacy chart rendered it under `hub.uplinkEntryPoints` rather than `entryPoints` precisely when `uplink: true`). Declare the uplink entryPoint there — not under `traefik.entryPoints` — so the inter-cluster traffic gets the uplink (mTLS) treatment. The file-provider `http.uplinks.<name>` is a separate thing: it binds an advertised workload to the uplink, it does not by itself make the entryPoint an uplink. Finally, the child's Service must expose the uplink port (9443) so the parent can reach it.

```yaml
traefik:
  hub:
    token: hub-token
    # Uplink entryPoint: the native equivalent of legacy `uplink: true`.
    uplinkEntryPoints:
      multicluster:
        address: ":9443/tcp"
    providers:
      multicluster:
        enabled: true
  providers:
    file:
      enabled: true
      content:
        http:
          uplinks:
            whoami:
              entryPoints:
                - multicluster

          routers:
            backend:
              rule: PathPrefix(`/`)
              service: backend
              uplinks:
                - whoami

          services:
            backend:
              loadBalancer:
                servers:
                  - url: http://whoami.example.svc.cluster.local:80

# Expose the uplink port on the child's Service so the parent can reach it.
# Uplink entryPoints do not get a named container port from the chart, so the
# Service targetPort references the port number (9443) directly.
service:
  default:
    spec:
      ports:
        - name: multicluster
          port: 9443
          targetPort: 9443
          protocol: TCP
```

### Parent cluster

Configure the parent multi-cluster provider with the child's uplink entryPoint address:

```yaml
traefik:
  hub:
    token: hub-token
    providers:
      multicluster:
        enabled: true
        children:
          child1:
            address: "http://child1.example.svc.cluster.local:9443"
            serversTransport:
              insecureSkipVerify: true
```

For an uplink named `whoami`, the parent exposes:

- `whoami@multicluster` (weighted across all children)
- `whoami-child1@multicluster` (direct to a specific child)

## Bind to privileged ports (80 and 443)

By default, Traefik listens on high ports (8000/8443) because binding to ports below 1024 requires extra privileges. To bind directly to ports 80 and 443, add the `NET_BIND_SERVICE` capability and set the entryPoint addresses to the privileged ports.

There are two distinct port settings in the new chart, and this example touches both:

- **`traefik.entryPoints.{web,websecure}.address`** — the port Traefik listens on **inside the container** (the entryPoint address, e.g. `:80/tcp`). Binding these below 1024 is what requires `NET_BIND_SERVICE`.
- **`service.default.spec.ports`** — the ports the Kubernetes **Service** exposes (and their `targetPort`, which references the entryPoint container port by name). These are unrelated to in-container privilege; they only define cluster-facing exposure.

The `NET_BIND_SERVICE` capability goes on the traefik **container's** securityContext, under `deployment.spec.template.spec.containers[0].securityContext` (the chart strategic-merges it onto the traefik container by name — no container redeclaration needed).

```yaml
traefik:
  entryPoints:
    web:
      address: ":80/tcp"
    websecure:
      address: ":443/tcp"

deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            securityContext:
              capabilities:
                drop: [ALL]
                add: [NET_BIND_SERVICE]
              readOnlyRootFilesystem: true
              allowPrivilegeEscalation: false

service:
  default:
    spec:
      ports:
        - name: web
          port: 80
          targetPort: web
          protocol: TCP
        - name: websecure
          port: 443
          targetPort: websecure
          protocol: TCP
```

This keeps the container running as a non-root user while allowing it to bind to privileged ports. No changes to the pod-level securityContext (`deployment.spec.template.spec.securityContext`) are needed.

If you also want the host to listen on ports 80 and 443 directly (bypassing the Service), add `hostPort` to the traefik container's port entries:

```yaml
traefik:
  entryPoints:
    web:
      address: ":80/tcp"
    websecure:
      address: ":443/tcp"

deployment:
  spec:
    template:
      spec:
        containers:
          - name: traefik
            ports:
              - name: web
                containerPort: 80
                hostPort: 80
              - name: websecure
                containerPort: 443
                hostPort: 443
```

> [!NOTE]
> When using `hostPort`, you typically want to deploy Traefik as a `DaemonSet` (see the DaemonSet example above) so that each node binds the ports.

<details>
<summary>Running on privileged ports with host network</summary>

If you need to run Traefik on host network and on privileged ports you'll need extra capabilities set on the `traefik` binary itself (cf. https://github.com/traefik/traefik/pull/12902#issuecomment-4160942102). Here's an init container approach that helps you achieve this:

```yaml
deployment:
  spec:
    template:
      spec:
        hostNetwork: true
        # pod-level securityContext (was legacy `podSecurityContext`)
        securityContext:
          runAsGroup: 65532
          runAsNonRoot: false
          runAsUser: 65532
          seccompProfile:
            type: RuntimeDefault
        initContainers:
          - name: copy-binary
            image: traefik:v3.6.12
            command: ["cp", "/usr/local/bin/traefik", "/shared/traefik"]
            volumeMounts:
              - name: traefik-bin
                mountPath: /shared
          - name: setcap
            image: alpine:3.21
            command:
              - sh
              - -c
              - apk add --no-cache libcap && setcap cap_net_bind_service=+ep /shared/traefik
            securityContext:
              runAsUser: 0
              runAsNonRoot: false
            volumeMounts:
              - name: traefik-bin
                mountPath: /shared
        containers:
          - name: traefik
            # container-level securityContext (was legacy `securityContext`)
            securityContext:
              runAsNonRoot: true
              runAsUser: 65532
              allowPrivilegeEscalation: true
              capabilities:
                drop: [ALL]
                add: [NET_BIND_SERVICE]
            volumeMounts:
              - name: traefik-bin
                mountPath: /usr/local/bin
        volumes:
          - name: traefik-bin
            emptyDir: {}

# Disable the chart-managed Service (was legacy `service.enabled: false`)
service: null
```

</details>
