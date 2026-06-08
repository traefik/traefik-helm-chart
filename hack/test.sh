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

# NB: --color is intentionally omitted. Helm v4 introduced a global --color <mode>
# persistent flag that shadows the helm-unittest boolean --color flag, breaking the
# invocation. Color is auto-detected from the tty instead.
helm unittest ./traefik
