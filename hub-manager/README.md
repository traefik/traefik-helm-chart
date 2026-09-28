# Hub Manager

`hub-manager` is the self-hosted control plane for [Traefik Hub](https://traefik.io/traefik-hub/). It replaces the Traefik SaaS platform: instead of reaching out to `platform.hub.traefik.io`, your Traefik instances connect to a `hub-manager` you run inside your own cluster.

## Introduction

`hub-manager` stores its state in PostgreSQL and is reached by Traefik through a Kubernetes _Service_. Linking the two requires an **offline** license token, shared by both sides.

A full setup is made of two charts:

1. **`hub-manager`** — the control plane (this chart).
2. **`traefik`** — the proxy, configured with Traefik Hub pointing at `hub-manager`.

## Installing

### Prerequisites

1. Kubernetes (server) version **v1.25.0 or higher**: `kubectl version`
1. Helm **v3.9.0 or higher** [installed](https://helm.sh/docs/using_helm/#installing-helm): `helm version`
1. Traefik's chart repository: `helm repo add traefik https://traefik.github.io/charts`
1. A reachable **PostgreSQL** database.
1. An **offline** Traefik Hub license token.

### 1. Create the Secret

`hub-manager` reads its sensitive configuration from a single _Secret_. Create the namespace and a _Secret_ that holds the license token, the PostgreSQL connection string and an encryption key:

```bash
kubectl create namespace hub

kubectl create secret generic hub-manager-config -n hub \
  --from-literal=token='<offline-license-token>' \
  --from-literal=postgres-uri='postgres://user:password@host:5432/hub' \
  --from-literal=postgres-encryption-key="$(openssl rand -base64 32)"
```

### 2. Install the `hub-manager` chart

Reference the _Secret_ from your values and install the chart:

```yaml
token: hub-manager-config

postgres:
  uri: hub-manager-config
  encryptionKey: hub-manager-config
```

```bash
helm install hub-manager traefik/hub-manager -n hub -f values.yaml
```

or, to install from the OCI registry:

```bash
helm install hub-manager oci://ghcr.io/traefik/helm/hub-manager -n hub -f values.yaml
```

For complete documentation on all available parameters, check the [default values file](./values.yaml) or [VALUES.md](./VALUES.md).

### 3. Connect Traefik to `hub-manager`

Install the `traefik` chart in the same `hub` namespace so it can reuse the _Secret_ created above, with Traefik Hub pointing at the `hub-manager` _Service_ instead of the SaaS platform:

```yaml
hub:
  # Reuse the Secret created above: its 'token' key holds the same offline license token
  token: hub-manager-config
  offline: true
  apimanagement:
    enabled: true

additionalArguments:
  - "--hub.platformurl=http://hub-manager.hub.svc.cluster.local/agent"
```

```bash
helm install traefik traefik/traefik -n hub -f traefik-values.yaml
```

The platform URL follows the `hub-manager` _Service_ as `http://<release>.<namespace>.svc.cluster.local/agent` — here `hub-manager` in the `hub` namespace.

> [!NOTE]
> The URL **must end with `/agent`**, otherwise Traefik Hub cannot reach the control plane. `--hub.platformurl` is also only honoured with an offline license, so `hub.offline` must be `true` on the Traefik side.
