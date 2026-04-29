# EXAMPLES

## Minimal installation

Minimal setup for a single `hub-manager` instance backed by PostgreSQL.

This example assumes a Secret named `hub-manager-config` already exists and contains:
- `token`
- `postgres-uri`
- `postgres-encryption-key`

```yaml
token: hub-manager-config

postgres:
    uri: hub-manager-config
    encryptionKey: hub-manager-config
```
