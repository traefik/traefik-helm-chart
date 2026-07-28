# Migrate values

Some chart releases rename or restructure values. This directory holds one migration
per breaking release, each expressed as a single
[mikefarah `yq` v4](https://github.com/mikefarah/yq) expression. Run it against **your
override file** (the one you pass with `helm -f`), not the chart's `values.yaml`.

## Requirements

Either a local `yq` v4, or just Docker (`mikefarah/yq:4` image, nothing to install).

Back up first, since `-i` rewrites in place:

```sh
cp myvalues.yaml myvalues.yaml.bak
```

## v40 to v41

Chart **v41.0.0** renamed the logging keys to match upstream Traefik
([PR #1887](https://github.com/traefik/traefik-helm-chart/pull/1887)). The mapping lives
in [`v40-to-v41.yq`](./v40-to-v41.yq).

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

It also converts `providers.file.content` from a string to an object.

### Usage

**With a local `yq`**

```sh
yq --from-file v40-to-v41.yq myvalues.yaml       # dry-run: prints migrated YAML
yq --from-file v40-to-v41.yq -i myvalues.yaml    # rewrite in place
```

**With Docker** (no local install, only Docker required)

```sh
docker run --rm -v "$PWD":/w -w /w mikefarah/yq:4 \
  --from-file /w/v40-to-v41.yq myvalues.yaml      # add -i after --from-file to rewrite in place
```

### Known limitations

- Comments are preserved by `yq`, but comments attached to keys that move
  (`logs.*`) may shift. Review the diff before applying with `-i`.
- The expression is idempotent: running it on an already-migrated file is a no-op.

### Fixtures

- [`sample-v40-values.yaml`](./sample-v40-values.yaml) — input, exercises every mapped key.
- [`expected-v41-values.yaml`](./expected-v41-values.yaml) — expected output. Regenerate after
  changing `v40-to-v41.yq`, do not hand-edit.

Regression check (output must match the golden file):

```sh
docker run --rm -v "$PWD":/w -w /w mikefarah/yq:4 \
  --from-file /w/v40-to-v41.yq sample-v40-values.yaml | diff - expected-v41-values.yaml
```
