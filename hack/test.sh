#!/bin/bash

set -e

if ! command -v helm >/dev/null 2>&1; then
  echo "Error: helm is not installed. See https://helm.sh/docs/intro/install/" >&2
  exit 1
fi

if ! helm plugin list 2>/dev/null | awk 'NR>1 && $1=="unittest"{found=1} END{exit !found}'; then
  echo "Error: helm-unittest plugin is not installed." >&2
  echo "Install: helm plugin install https://github.com/helm-unittest/helm-unittest --version 1.0.1" >&2
  exit 1
fi

# Pin version-support annotations so tests stay decoupled from the real
# supported ranges shipped with releases. Restore on exit.
cp traefik/Chart.yaml /tmp/traefik-Chart.yaml.bak
trap 'mv /tmp/traefik-Chart.yaml.bak traefik/Chart.yaml' EXIT
sed -i \
  -e 's|traefik.io/proxy-min-version:.*|traefik.io/proxy-min-version: v3.6.0|' \
  -e 's|traefik.io/proxy-max-version:.*|traefik.io/proxy-max-version: v3.6.12|' \
  -e 's|traefik.io/hub-min-version:.*|traefik.io/hub-min-version: v3.19.3|' \
  -e 's|traefik.io/hub-max-version:.*|traefik.io/hub-max-version: v3.20.0-ea.1|' \
  traefik/Chart.yaml

helm unittest --color ./traefik
helm unittest --color ./traefik-crds
