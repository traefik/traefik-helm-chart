#!/bin/bash

set -e

if ! command -v helm >/dev/null 2>&1; then
  echo "Error: helm is not installed. See https://helm.sh/docs/intro/install/" >&2
  exit 1
fi

if ! helm plugin list 2>/dev/null | awk 'NR>1 && $1=="unittest"{found=1} END{exit !found}'; then
  echo "Error: helm-unittest plugin is not installed." >&2
  echo "Install: helm plugin install https://github.com/helm-unittest/helm-unittest --version 1.1.0" >&2
  exit 1
fi

# Helm v4 introduced a global --color <mode> persistent flag (never|auto|always) that
# shadows the boolean --color flag of helm-unittest, breaking `helm unittest --color`.
# So we only force color on Helm v3; on Helm v4+ color is auto-detected from the tty.
HELM_MAJOR="$(helm version --template '{{.Version}}' 2>/dev/null | grep -oE '[0-9]+' | head -n1)"
COLOR_FLAG="--color"
if [ "${HELM_MAJOR:-0}" -ge 4 ]; then
  COLOR_FLAG=""
fi

helm unittest ${COLOR_FLAG} ./traefik
