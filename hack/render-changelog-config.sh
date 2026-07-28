#!/bin/bash

# Render the changelog-builder configuration for a given chart.
#
# Usage: hack/render-changelog-config.sh <chart_dir>
# Env:
#   REGEXP    required — category matcher injected into the JSON template
#   DATE      optional — defaults to today (YYYY-MM-DD)
#   OUTPUT    optional — defaults to /tmp/changelog.json
#
# If <chart_dir>/Chart.yaml declares traefik.io/{proxy,hub}-{min,max}-version
# annotations, a "Traefik version support" block is appended to the release
# notes; otherwise VERSION_SUPPORT is left empty (used by the CRDs chart).

set -eu

if [ $# -lt 1 ]; then
  echo "usage: $0 <chart_dir>" >&2
  exit 1
fi
if [ -z "${REGEXP:-}" ]; then
  echo "REGEXP must be set" >&2
  exit 1
fi

CHART_DIR="$1"
CHART_YAML="${CHART_DIR}/Chart.yaml"
OUTPUT="${OUTPUT:-/tmp/changelog.json}"
DATE="${DATE:-$(date +%F)}"
export DATE REGEXP

PROXY_MIN=$(awk '/traefik.io\/proxy-min-version:/{print $2}' "${CHART_YAML}")
PROXY_MAX=$(awk '/traefik.io\/proxy-max-version:/{print $2}' "${CHART_YAML}")
HUB_MIN=$(awk '/traefik.io\/hub-min-version:/{print $2}' "${CHART_YAML}")
HUB_MAX=$(awk '/traefik.io\/hub-max-version:/{print $2}' "${CHART_YAML}")

if [ -n "${PROXY_MIN}" ] && [ -n "${PROXY_MAX}" ] && [ -n "${HUB_MIN}" ] && [ -n "${HUB_MAX}" ]; then
  VERSION_SUPPORT="## 👌 Traefik version support\n\n* Traefik Proxy: ${PROXY_MIN} -> ${PROXY_MAX} (default)\n* Traefik Hub: ${HUB_MIN} -> ${HUB_MAX}"
else
  VERSION_SUPPORT=""
fi
export VERSION_SUPPORT

envsubst <.github/workflows/changelog.json >"${OUTPUT}"
cat "${OUTPUT}"
