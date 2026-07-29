# EXAMPLES

## Minimal installation

Minimal setup for a single `hub-manager` instance backed by PostgreSQL.

```yaml
token: hub-manager-config

postgres:
    uri: hub-manager-config
    encryptionKey: hub-manager-config
```

This example assumes a _Secret_ named `hub-manager-config` already exists and contains:

- `token`
- `postgres-uri`
- `postgres-encryption-key`

    _One can generate an encryption key with the following command:_

    ```bash
    openssl rand -base64 32
    ```

## Connecting Traefik Hub

`hub-manager` is the self-hosted control plane that Traefik Hub connects to instead of the Traefik SaaS platform.
This requires an **offline** license token on both sides.

Install the `traefik` chart with:

```yaml
hub:
  # Name of a Secret with key 'token' set to the same offline license token
  token: traefik-hub-license
  offline: true
  apimanagement:
    enabled: true

additionalArguments:
  - "--hub.platformurl=http://hub-manager.hub-manager.svc.cluster.local/agent"
```

The URL follows the `hub-manager` _Service_, which is named after the release, and **must end with `/agent`**:

```text
http://<release>-hub-manager.<namespace>.svc.cluster.local/agent
```

Without the `/agent` suffix, Traefik Hub keeps failing to reach the control plane:

```text
ERR Failed to wait for an update on the platform error="failed http://…/updates?wait=1m0s with code 404"
```

`--hub.platformurl` is only honoured with an offline license, so `hub.offline` must be `true`.
