# Traefik

[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer made to deploy
microservices with ease.

## Introduction

### Philosophy

The Traefik Helm chart is focused on Traefik deployment configuration.

To keep this Helm chart as generic as possible we tend
to avoid integrating any third party solutions nor any specific use cases.

Accordingly, the encouraged approach to fulfill your needs:

1. Override the default Traefik configuration
   values ([yaml file or cli](https://helm.sh/docs/chart_template_guide/values_files/))
2. Append your own configurations (`kubectl apply -f myconf.yaml`)

[Examples](https://github.com/traefik/traefik-helm-chart/blob/master/EXAMPLES.md) of common usage are provided.

If needed, one may use [`extraObjects`](./traefik/tests/values/extra.yaml) or extend this
Helm chart [as a subchart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/).

### Major changes

Starting with v28.x, this chart now bootstraps Traefik Proxy version 3 as a Kubernetes ingress controller,
using Custom Resources [`IngressRoute`](https://doc.traefik.io/traefik/v3.0/routing/providers/kubernetes-crd/).
For upgrading from chart versions prior to v28.x (using Traefik Proxy version 2), see
- [Migration guide from v2 to v3](https://doc.traefik.io/traefik/v3.0/migration/v2-to-v3/)
- upgrade notes in the [`README` on the v27 branch](https://github.com/traefik/traefik-helm-chart/tree/v27).

Starting with v34.x, to work
around [Helm caveats](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations),
it's possible to use an additional Chart dedicated to CRDs: **traefik-crds**.
See also the [deploy instructions below](#an-installation-with-additional-crds-chart).

### Support for Traefik Proxy v2

It's possible to use this chart with Traefik Proxy v2 using chart version v27.x.
This chart support policy is aligned
with [upstream support policy](https://doc.traefik.io/traefik/deprecation/releases/) of Traefik Proxy.
You can check the [`README` on the v27 branch](https://github.com/traefik/traefik-helm-chart/tree/v27)
for compatibility, installation instructions and older upgrade notes.

## Installing

### Prerequisites

1. Kubernetes (server) version **v1.22.0 or higher**: `kubectl version`
1. Helm **v3.9.0 or higher** [installed](https://helm.sh/docs/using_helm/#installing-helm): `helm version`
1. Traefik's chart repository: `helm repo add traefik https://traefik.github.io/charts`

### Deploying

#### The standard way

```bash
helm install traefik traefik/traefik
```

or:

```bash
helm install traefik oci://ghcr.io/traefik/helm/traefik
```

You can customize the install with a `values` file. There are some [EXAMPLES](./EXAMPLES.md) provided.
Complete documentation on all available parameters is in the [default file](./traefik/values.yaml).

```bash
helm install -f myvalues.yaml traefik traefik/traefik
```

#### With additional CRDs chart

The CRD chart is an additional and optional Chart.
When using it, the CRDs of regular Traefik Chart are not required.
See [here](./CONTRIBUTING.md#about-crds) for more details

```bash
helm install traefik-crds traefik/traefik-crds
helm install traefik traefik/traefik --skip-crds
helm list # should display two charts installed
```

## Upgrading

One can check what has changed in the [Changelog](./traefik/Changelog.md).

New major version indicates that there is an incompatible breaking change.
> [!WARNING]
> Please read carefully release notes of this chart before upgrading.

### Upgrade Traefik standalone chart

When using Helm native management for CRDs, user **MUST** upgrade CRDs before calling _helm upgrade_ command.
CRDs are **not** updated by Helm. See [HIP-0011](https://github.com/helm/community/blob/main/hips/hip-0011.md) for
details.

```bash
# Update repository
helm repo update
# See current Chart & Traefik version
helm search repo traefik/traefik
# Update CRDs
helm show crds traefik/traefik | kubectl apply --server-side --force-conflicts -f -
# Upgrade Traefik
helm upgrade traefik traefik/traefik
```

### Upgrade from Traefik chart to Traefik and opt-in CRDs charts

> [!WARNING]
> When upgrading from standard installation to the one with additional CRDs chart,
> you **have** to change ownership on CRDs **before** installing CRDs chart

```bash
# Update repository
helm repo update
# Update CRDs ownership
kubectl get customresourcedefinitions.apiextensions.k8s.io -o name | grep traefik.io | xargs kubectl patch --type='json' -p='[{"op": "add", "path": "/metadata/labels", "value": {"app.kubernetes.io/managed-by":"Helm"}},{"op": "add", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value":"traefik-crds"},{"op": "add", "path": "/metadata/annotations/meta.helm.sh~1release-namespace", "value":"default"}]'
# If you use gateway API, you might also want to change Gateway API ownership
kubectl get customresourcedefinitions.apiextensions.k8s.io -o name | grep gateway.networking.k8s.io | xargs kubectl patch --type='json' -p='[{"op": "add", "path": "/metadata/labels", "value": {"app.kubernetes.io/managed-by":"Helm"}},{"op": "add", "path": "/metadata/annotations/meta.helm.sh~1release-name", "value":"traefik-crds"},{"op": "add", "path": "/metadata/annotations/meta.helm.sh~1release-namespace", "value":"default"}]'
# Deploy optional CRDs chart
helm install traefik-crds traefik/traefik-crds
# Upgrade Traefik
helm upgrade traefik traefik/traefik
```

### Upgrade traefik and opt-in CRDs charts

```bash
# Update repository
helm repo update
# See current Chart & Traefik version
helm search repo traefik/traefik
# Update CRDs (Traefik Proxy v3 CRDs)
helm upgrade traefik-crds traefik/traefik
# Upgrade Traefik
helm upgrade traefik traefik/traefik
```

## Contributing

If you want to contribute to this chart, please read the [Contributing Guide](./CONTRIBUTING.md).

Thanks to all the people who have already contributed!

<a href="https://github.com/traefik/traefik-helm-chart/graphs/contributors">
  <img src="https://contributors-img.web.app/image?repo=traefik/traefik-helm-chart" />
</a>
