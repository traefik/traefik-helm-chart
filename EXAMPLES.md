# Install as a DaemonSet

Default install is using a `Deployment` but it's possible to use `DaemonSet`

```yaml
deployment:
  kind: DaemonSet
```

# Install in a dedicated namespace, with limited RBAC

Default install is using Cluster-wide RBAC but it can be restricted to target namespace.

```yaml
rbac:
  namespaced: true
```

# Install with auto-scaling

When enabling [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
to adjust replicas count according to CPU Usage, it's recommended to nullify replicas.
```yaml
deployment:
  replicas: null
autoscaling:
  enabled: true
  maxReplicas: 2
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
```

# Access Traefik dashboard without exposing it

This HelmChart does not expose the Traefik dashboard by default, for security concerns.
Thus, there are multiple ways to expose the dashboard.
For instance, the dashboard access could be achieved through a port-forward :

```bash
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

Accessible with the url: http://127.0.0.1:9000/dashboard/

# Publish and protect Traefik Dashboard with basic Auth

To expose the dashboard in a secure way as [recommended](https://doc.traefik.io/traefik/operations/dashboard/#dashboard-router-rule)
in the documentation, it may be useful to override the router rule to specify
a domain to match, or accept requests on the root path (/) in order to redirect
them to /dashboard/.

```yaml
# Create an IngressRoute for the dashboard
ingressRoute:
  dashboard:
    enabled: true
    # Custom match rule with host domain
    matchRule: Host(`traefik-dashboard.example.com`)
    entryPoints: ["websecure"]
    # Add custom middlewares : authentication and redirection
    middlewares:
      - name: traefik-dashboard-auth

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

  - apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-dashboard-auth
    spec:
      basicAuth:
        secret: traefik-dashboard-auth-secret
```

# Publish and protect Traefik Dashboard with an Ingress

To expose the dashboard without IngressRoute, it's more complicated and less
secure. You'll need to create an internal Service exposing Traefik API with
special _traefik_ entrypoint.

You'll need to double check:
1. Service selector with your setup.
2. Middleware annotation on the ingress, _default_ should be replaced with traefik's namespace

```yaml
ingressRoute:
  dashboard:
    enabled: false
additionalArguments:
- "--api.insecure=true"
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
        targetPort: 9000
        protocol: TCP

  - apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-auth-secret
    type: kubernetes.io/basic-auth
    stringData:
      username: admin
      password: changeme

  - apiVersion: traefik.containo.us/v1alpha1
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


# Install on AWS

It can use [native AWS support](https://kubernetes.io/docs/concepts/services-networking/service/#aws-nlb-support) on Kubernetes

```yaml
service:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

Or if [AWS LB controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/#legacy-cloud-provider) is installed :
```yaml
service:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb-ip
```

# Install on GCP

A [regional IP with a Service](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip#use_a_service) can be used
```yaml
service:
  spec:
    loadBalancerIP: "1.2.3.4"
```

Or a [global IP on Ingress](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip#use_an_ingress)
```yaml
service:
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

# Install on Azure

A [static IP on a resource group](https://learn.microsoft.com/en-us/azure/aks/static-ip) can be used:

```yaml
service:
  spec:
    loadBalancerIP: "1.2.3.4"
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: myResourceGroup
```

# Use HTTP3

By default, it will use a Load balancers with mixed protocols on `websecure`
entrypoint. They are available since v1.20 and in beta as of Kubernetes v1.24.
Availability may depend on your Kubernetes provider.

When using TCP and UDP with a single service, you may encounter [this issue](https://github.com/kubernetes/kubernetes/issues/47249#issuecomment-587960741) from Kubernetes.
If you want to avoid this issue, you can set `ports.websecure.http3.advertisedPort`
to an other value than 443

```yaml
ports:
  websecure:
    http3:
      enabled: true
```

# Use ProxyProtocol on Digital Ocean

PROXY protocol is a protocol for sending client connection information, such as origin IP addresses and port numbers, to the final backend server, rather than discarding it at the load balancer.

```yaml
service:
  enabled: true
  type: LoadBalancer
  annotations:
    # This will tell DigitalOcean to enable the proxy protocol.
    service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol: "true"
  spec:
    # This is the default and should stay as cluster to keep the DO health checks working.
    externalTrafficPolicy: Cluster

additionalArguments:
  # Tell Traefik to only trust incoming headers from the Digital Ocean Load Balancers.
  - "--entryPoints.web.proxyProtocol.trustedIPs=127.0.0.1/32,10.120.0.0/16"
  - "--entryPoints.websecure.proxyProtocol.trustedIPs=127.0.0.1/32,10.120.0.0/16"
  # Also whitelist the source of headers to trust,  the private IPs on the load balancers displayed on the networking page of DO.
  - "--entryPoints.web.forwardedHeaders.trustedIPs=127.0.0.1/32,10.120.0.0/16"
  - "--entryPoints.websecure.forwardedHeaders.trustedIPs=127.0.0.1/32,10.120.0.0/16"
```

# Use Traefik Let's Encrypt Integration with CloudFlare

It needs a CloudFlare token in a Kubernetes `Secret` and a working Storage Class

```yaml
persistence:
  enabled: true
  storageClass: xxx
certResolvers:
  letsencrypt:
    dnsChallenge:
      provider: cloudflare
    storage: /data/acme.json
env:
  - name: CF_DNS_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: yyy
        key: zzz
```

# Provide default certificate with cert-manager and CloudFlare DNS

Setup:

* cert-manager installed in `cert-manager` namespace
* A cloudflare account on a DNS Zone

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
            email: email@example.com
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

If needed, logs of cert-manager pod can give you more information

**Step 4**: Use it on the TLS Store in **values.yaml** file for this Helm Chart
```yaml
tlsStore:
  default:
    defaultCertificate:
      secretName: wildcard-example-com-tls
```

**Step 5**: Enjoy. All your `IngressRoute` use this certificate by default now. 

They should use websecure entrypoint like this:
```yaml
apiVersion: traefik.containo.us/v1alpha1
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

