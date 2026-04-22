#!/bin/bash

set -e

# Test against a copy of the traefik chart with pinned version-support
# annotations, so tests stay decoupled from the real supported ranges shipped
# with releases without ever touching the committed Chart.yaml. Copying to
# /tmp also avoids permission errors when the helm-unittest container user
# cannot write to the mounted workspace (e.g. in GitHub Actions).
rm -rf /tmp/traefik-test
cp -r traefik /tmp/traefik-test
sed -i \
  -e 's|traefik.io/proxy-min-version:.*|traefik.io/proxy-min-version: v3.6.0|' \
  -e 's|traefik.io/proxy-max-version:.*|traefik.io/proxy-max-version: v3.6.12|' \
  -e 's|traefik.io/hub-min-version:.*|traefik.io/hub-min-version: v3.19.3|' \
  -e 's|traefik.io/hub-max-version:.*|traefik.io/hub-max-version: v3.20.0-ea.1|' \
  /tmp/traefik-test/Chart.yaml

/usr/bin/helm unittest --color /tmp/traefik-test
/usr/bin/helm unittest --color ./traefik-crds
