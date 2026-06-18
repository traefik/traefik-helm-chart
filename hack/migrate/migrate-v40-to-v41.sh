#!/usr/bin/env sh
# Migrate Traefik Helm chart user values from v40 to v41 (PR #1887).
# Renames logs.* -> log.* / accessLog.* and camelCases the affected keys.
#
# Runs yq via Docker, so no local tool install is required.
#
# Usage:
#   ./migrate-v40-to-v41.sh myvalues.yaml          # dry-run, prints migrated YAML to stdout
#   ./migrate-v40-to-v41.sh myvalues.yaml -i       # rewrite myvalues.yaml in place (backup: myvalues.yaml.bak)
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

usage() { echo "usage: $0 <values.yaml> [-i|--in-place]" >&2; exit 2; }

FILE=""
INPLACE=0
for arg in "$@"; do
  case "$arg" in
    -i|--in-place) INPLACE=1 ;;
    -h|--help) usage ;;
    -*) echo "unknown option: $arg" >&2; usage ;;
    *) FILE="$arg" ;;
  esac
done
[ -n "$FILE" ] || usage
[ -f "$FILE" ] || { echo "file not found: $FILE" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "error: Docker is required." >&2; exit 1; }

FILE_DIR=$(CDPATH= cd -- "$(dirname -- "$FILE")" && pwd)
FILE_NAME=$(basename -- "$FILE")

run_yq() { # mounts the expression dir (/x) and the values file dir (/w)
  docker run --rm -v "$SCRIPT_DIR":/x -v "$FILE_DIR":/w -w /w mikefarah/yq:4 "$@"
}

# Warn on breaking change #2: providers.file.content string -> object (not auto-migrated).
CONTENT_TYPE=$(run_yq '.providers.file.content | type' "$FILE_NAME" 2>/dev/null || echo "null")
if [ "$CONTENT_TYPE" = "!!str" ]; then
  echo "WARNING: providers.file.content is a string. In v41 it must be an object." >&2
  echo "         This script does NOT convert it. Migrate it manually." >&2
  echo "         See https://github.com/traefik/traefik-helm-chart/pull/1887" >&2
fi

if [ "$INPLACE" = "1" ]; then
  cp -- "$FILE" "$FILE.bak"
  run_yq --from-file /x/v40-to-v41.yq -i "$FILE_NAME"
  echo "migrated in place: $FILE (backup: $FILE.bak)" >&2
else
  run_yq --from-file /x/v40-to-v41.yq "$FILE_NAME"
fi
