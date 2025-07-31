#!/bin/bash

set -e

# Helper functions
build_ks() { kustomize build "${1}"; }
sanitize_ks() { grep -v '#' "${1}/kustomization.yaml" | sed -r 's/crds-files\/(gatewayAPI|hub|traefik)\///g'; }
sanitize_ks_exclude_experimental() { sanitize_ks "${1}" | grep -v 'gateway-experimental-install.yaml'; }
get_gateway_version() { grep -o "gateway.networking.k8s.io/bundle-version: v[0-9.]*" "${1}" | head -1 | cut -d' ' -f2; }

# Create temp directories and compare CRDs (excluding experimental from traefik-crds)
gen_ks_traefik=$(mktemp -d)
gen_ks_traefikcrds=$(mktemp -d)
sanitize_ks traefik/crds/ >"${gen_ks_traefik}/kustomization.yaml"
sanitize_ks_exclude_experimental traefik-crds/ >"${gen_ks_traefikcrds}/kustomization.yaml"

diff -Naur "${gen_ks_traefik}" "${gen_ks_traefikcrds}" || {
  echo "❌ Standard CRDs are not consistent between traefik and traefik-crds charts." && exit 1
}

# Check experimental CRDs exist
[ -f "traefik-crds/crds-files/gatewayAPI/gateway-experimental-install.yaml" ] || {
  echo "❌ Experimental Gateway API CRDs missing from traefik-crds chart." && exit 1
}

# Check Gateway API version consistency
standard_version=$(get_gateway_version "traefik/crds/gateway-standard-install.yaml")
experimental_version=$(get_gateway_version "traefik-crds/crds-files/gatewayAPI/gateway-experimental-install.yaml")
traefik_crds_standard_version=$(get_gateway_version "traefik-crds/crds-files/gatewayAPI/gateway-standard-install.yaml")

if [ "$standard_version" = "$experimental_version" ] && [ "$standard_version" = "$traefik_crds_standard_version" ]; then
  echo "✅ Gateway API versions consistent: $standard_version"
  echo "✅ Experimental Gateway API CRDs available in traefik-crds chart (gatewayAPIExperimental: true)"
  echo "✅ CRDs are consistent."
else
  echo "❌ Gateway API versions inconsistent: traefik($standard_version) vs experimental($experimental_version) vs traefik-crds($traefik_crds_standard_version)"
  exit 1
fi

rm -rf "${gen_ks_traefik}" "${gen_ks_traefikcrds}"
