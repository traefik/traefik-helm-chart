#!/bin/bash

set -euo pipefail

# The customManagers:helmChartYamlAppVersions preset only updates appVersion when a
# "# renovate: image=" comment sits right above it. Rewriting Chart.yaml drops it silently.
rc=0

for chart in traefik hub-manager; do
  if ! grep -B1 '^appVersion:' "${chart}/Chart.yaml" | grep -q '^# renovate: image='; then
    echo "Error: ${chart}/Chart.yaml misses '# renovate: image=' above appVersion. Restore it,"
    echo "       or Renovate stops updating appVersion."
    rc=1
  fi
done

exit "${rc}"
