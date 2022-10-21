# Traefik

[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer made to deploy
microservices with ease.

## Introduction

This chart bootstraps Traefik version 2 as a Kubernetes ingress controller,
using Custom Resources `IngressRoute`: <https://docs.traefik.io/providers/kubernetes-crd/>.

### Philosophy

The Traefik HelmChart is focused on Traefik deployment configuration.

To keep this HelmChart as generic as possible we tend
to avoid integrating any third party solutions nor any specific use cases.

Accordingly, the encouraged approach to fulfill your needs:

1. override the default Traefik configuration values ([yaml file or cli](https://helm.sh/docs/chart_template_guide/values_files/))
2. append your own configurations (`kubectl apply -f myconf.yaml`)
3. extend this HelmChart ([as a Subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/))

## Installing

### Prerequisites

With the command `helm version`, make sure that you have:

- Helm v3 [installed](https://helm.sh/docs/using_helm/#installing-helm)

Add Traefik's chart repository to Helm:

```bash
helm repo add traefik https://helm.traefik.io/traefik
```

### Kubernetes Version Support

Due to changes in CRD version support, the following versions of the chart are usable and supported on the following Kubernetes versions:

|                         |  Kubernetes v1.15 and below | Kubernetes v1.16-v1.21 | Kubernetes v1.22 and above |
|-------------------------|-----------------------------|------------------------|----------------------------|
| Chart v9.20.2 and below | [x]                         | [x]                    |                            |
| Chart 10.0.0 and above  |                             | [x]                    | [x]                        |

### Deploying Traefik

```bash
helm install traefik traefik/traefik
```

You can customize the install with a `values` file. Documentation on all parameters is in the [default file](./traefik/values.yaml).

```bash
helm install -f myvalues.yaml traefik traefik/traefik
```

#### Warning

Helm v2 support was removed in the chart version 10.0.0.

### Exposing the Traefik dashboard

This HelmChart does not expose the Traefik dashboard by default, for security concerns.
Thus, there are multiple ways to expose the dashboard.
For instance, the dashboard access could be achieved through a port-forward :

```bash
kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
```

Accessible with the url: http://127.0.0.1:9000/dashboard/

Another way would be to apply your own configuration, for instance,
by defining and applying an IngressRoute CRD (`kubectl apply -f dashboard.yaml`):

```yaml
# dashboard.yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: dashboard
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`traefik.localhost`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
```

Accessible with the url: http://traefik.localhost/dashboard/

## Upgrading

One can check what has changed in the [Changelog](./traefik/Changelog.md).

```bash
# Update repository
helm repo update
# See current Chart & Traefik version
helm search repo traefik/traefik
# Upgrade Traefik
helm upgrade traefik traefik/traefik
```

New major version indicates that there is an incompatible breaking change.

### Upgrading CRDs

With Helm v3, CRDs created by this chart can not be updated, cf the [Helm Documentation on CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions). Please read carefully release notes of this chart before upgrading CRDs.

```bash
kubectl apply --server-side --force-conflicts -k https://github.com/traefik/traefik-helm-chart/traefik/crds/
```

Note: You can replace `master` with a specific version of this chart, according to your need.

### Upgrading 17.x to 18.x

Since v18.x, this chart by default merges TCP and UDP ports into a single (LoadBalancer) service.
Load balancers with mixed protocols are in [beta as of Kubernetes v1.24](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancers-with-mixed-protocol-types).
Availability may depend on your Kubernetes provider.

To retain the old default behavior, set `service.single` to `false` in your values.

To support HTTP/3 with a single service, the default exposed port was changed,
as a service cannot have two ports with same port number but different protocols [due to a bug in Kubernetes](https://github.com/kubernetes/kubernetes/issues/39188).

If you were previously using HTTP/3, you should update your values as follows:
  - replace the old value (`true`) of `ports.websecure.http3` with a key `expose: true`
  - if you use a separate UDP service and want to retain the old (exposed) port, set `ports.websecure.http3.exposedPort` to `443`

## Contributing

If you want to contribute to this chart, please read the [Contributing Guide](./CONTRIBUTING.md).
