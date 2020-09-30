# Traefik Helm Chart

## Prerequisites

With the command `helm version`, make sure that you have:
- Helm v2 [installed](https://helm.sh/docs/using_helm/#installing-helm)

Add Traefik's chart repository to Helm:

```bash
helm repo add traefik https://helm.traefik.io/traefik
```

You can update the chart repository by running:

```bash
helm repo update
```

## Deploy Traefik

### Deploy Traefik with Default Config

```bash
helm install traefik traefik/traefik
```
