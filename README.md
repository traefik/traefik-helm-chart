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
helm repo add traefik https://containous.github.io/traefik-helm-chart
```

You can update the chart repository by running:

```bash
helm repo update
```

### Deploying Traefik

```bash
helm install traefik traefik/traefik
```

#### Warning

If you are using Helm v2

You have to deploy CRDs manually with the following command:

```
kubectl apply -f traefik/crds
```

### Exposing the Traefik dashboard

This Helm Chart does not expose the Traefik dashboard by default, for security concerns.
To expose the Traefik dashboard you need to configure it on `values.yaml`:

```yaml
# values.yaml
ports:
  traefik:
    expose: true
```

Traefik dashboard will be protected using basic auth by default using basic auth with the credential admin:password.
To change default credential you can generate credential using `htpasswd -nb <user> <password>` and put the result in `values.yaml`:

```yaml
# values.yaml
ingressRoute:
  dashboard:
    userData: admin:$apr1$xTMExMm7$KlDuMHTGK7VvRHn3mgCKx.
```

## Contributing

If you want to contribute to this chart, please read the [Contributing Guide](./CONTRIBUTING.md).
