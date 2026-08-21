#!/usr/bin/env bash
#
# Fail if experimental/crds/ has drifted from the stable chart's
# traefik/crds/. The experimental chart hand-copies its CRDs from the
# stable chart (Helm installs crds/ as-is, with no templating), so this
# gate keeps the two in lockstep — a CRD added or changed in the stable
# chart must be mirrored here.
#
# `kustomization.yaml` lives in the stable crds/ dir but is a kustomize
# artifact, not a CRD, so it is excluded from the comparison.
#
# Run from the experimental/ chart dir (default paths assume that); the
# locations are overridable for CI flexibility.
set -euo pipefail

STABLE="${STABLE_CRDS:-../traefik/crds}"
EXPERIMENTAL="${EXPERIMENTAL_CRDS:-crds}"

if [ ! -d "${STABLE}" ]; then
  echo "❌ stable CRDs dir not found: ${STABLE} (run from experimental/, or set STABLE_CRDS)" >&2
  exit 2
fi

status=0

# Every stable CRD must exist, byte-identical, in the experimental chart.
for f in "${STABLE}"/*.yaml; do
  name="$(basename "${f}")"
  [ "${name}" = "kustomization.yaml" ] && continue
  if [ ! -f "${EXPERIMENTAL}/${name}" ]; then
    echo "❌ missing in experimental/crds: ${name}"
    status=1
    continue
  fi
  if ! diff -q "${f}" "${EXPERIMENTAL}/${name}" >/dev/null; then
    echo "❌ drift in ${name}:"
    diff -u "${f}" "${EXPERIMENTAL}/${name}" || true
    status=1
  fi
done

# Conversely, the experimental chart must not carry CRDs the stable chart
# has dropped (an orphan we would otherwise keep installing).
for f in "${EXPERIMENTAL}"/*.yaml; do
  name="$(basename "${f}")"
  if [ ! -f "${STABLE}/${name}" ]; then
    echo "❌ extra in experimental/crds (not in stable chart): ${name}"
    status=1
  fi
done

if [ "${status}" -eq 0 ]; then
  echo "✅ experimental/crds in sync with the stable chart"
fi
exit "${status}"
