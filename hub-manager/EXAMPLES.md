# EXAMPLES

## Minimal installation

Minimal setup for a single `hub-manager` instance backed by PostgreSQL.

This example assumes a Secret named `hub-manager-config` already exists and contains:
- `token`
- `postgres-uri`
- `postgres-encryption-key`

<details>

<summary>Example for creating the secret</summary>

```bash
kubectl create secret generic hub-manager-config \
  -n hub-manager \
  --from-literal=token='<YOUR_TOKEN>' \
  --from-literal=postgres-uri='<YOUR_POSTGRES_URI>' \
  --from-literal=postgres-encryption-key='<YOUR_POSTGRES_ENCRYPTION_KEY>'
```

</details>

```yaml
token: hub-manager-config

postgres:
    uri: hub-manager-config
    encryptionKey: hub-manager-config
```
