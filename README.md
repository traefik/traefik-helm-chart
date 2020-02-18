# Traefik

[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer made to deploy
microservices with ease.

**NOTE: THIS CHART IS IN INCUBATOR STATUS, DO NOT USE IN A PRODUCTION ENVIRONMENT**

## Introduction

This chart bootstraps Traefik version 2 as a Kubernetes ingress controller,
using Custom Resources `IngressRoute`: <https://docs.traefik.io/providers/kubernetes-crd/>.

## Installing

### Prerequisites

With the command `helm version`, make sure that you have:
- Helm v2 [installed](https://helm.sh/docs/using_helm/#installing-helm)

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

## Contributing

If you want to contribute to this chart, please read the [Contributing Guide](./CONTRIBUTING.md).
