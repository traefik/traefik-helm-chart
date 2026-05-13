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
