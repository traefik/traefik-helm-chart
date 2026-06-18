# Migrate values from chart v40 to v41

Chart **v41.0.0** renamed the logging keys to match upstream Traefik
([PR #1887](https://github.com/traefik/traefik-helm-chart/pull/1887)). This helper
rewrites your own `values.yaml` override accordingly.

| Before (v40) | After (v41) |
|---|---|
| `logs.general.*` | `log.*` |
| `logs.access.*` | `accessLog.*` |
| `logs.access.filters.statuscodes` | `accessLog.filters.statusCodes` |
| `logs.access.filters.retryattempts` | `accessLog.filters.retryAttempts` |
| `logs.access.filters.minduration` | `accessLog.filters.minDuration` |
| `logs.access.fields.general.defaultmode` | `accessLog.fields.defaultMode` |
| `logs.access.fields.general.names` | `accessLog.fields.names` |
| `logs.access.fields.headers.defaultmode` | `accessLog.fields.headers.defaultMode` |
| `logs.access.fields.queryParameters.defaultmode` | `accessLog.fields.queryParameters.defaultMode` |

## Usage

Run against **your override file** (the one you pass with `helm -f`), not the chart's `values.yaml`.

**macOS / Linux / WSL / Git Bash**
```sh
./migrate-v40-to-v41.sh myvalues.yaml        # dry-run: prints migrated YAML
./migrate-v40-to-v41.sh myvalues.yaml -i     # rewrite in place (backup: myvalues.yaml.bak)
```

**Windows (PowerShell)**
```powershell
.\migrate-v40-to-v41.ps1 myvalues.yaml
.\migrate-v40-to-v41.ps1 myvalues.yaml -InPlace
```

The launchers run [mikefarah `yq` v4](https://github.com/mikefarah/yq) via
`docker run mikefarah/yq:4` — Docker is the only requirement, no other local install.
All mapping logic lives in a single file, [`v40-to-v41.yq`](./v40-to-v41.yq).

## Known limitations

- **`providers.file.content`** changed from a string to an object in v41. That is a
  type change, not a rename — the script **warns** but does not convert it. Migrate by
  hand (inline your routers/services as YAML under `providers.file`).
- Comments are preserved by `yq`, but comments attached to keys that move
  (`logs.*`) may shift. Review the diff before applying with `-i`.
- The script is idempotent: running it on an already-migrated file is a no-op.

Test fixture: [`sample-v40-values.yaml`](./sample-v40-values.yaml) exercises every mapped key.
