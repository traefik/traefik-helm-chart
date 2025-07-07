#!/bin/bash

set -e

function build_ks() {
  kustomize build "${1}"
}

function build_ks_file_from_files() {
  pushd .
  cd "${1}" && cat <<EOF
---
kind: Kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
resources:
$(find . -name '*.yaml' -not -name 'kustomization.yaml' -exec basename {} \; | sort | xargs -I {} echo "  - {}")
EOF
  popd || true
}

function sanitize_ks() {
  grep -v '#' "${1}/kustomization.yaml" | sed -r 's/crds-files\/(gatewayAPI|hub|traefik)\///g'
}

gen_ks_traefik=$(mktemp -d)
gen_ks_traefikcrds=$(mktemp -d)
build_ks traefik/crds/ >"${gen_ks_traefik}/crds.yaml"
build_ks traefik-crds/ >"${gen_ks_traefikcrds}/crds.yaml"
build_ks_file_from_files traefik/crds/ >"${gen_ks_traefik}/kustomization.gen.yaml"
build_ks_file_from_files traefik-crds/crds-files/ >"${gen_ks_traefikcrds}/kustomization.gen.yaml"
sanitize_ks traefik/crds/ >"${gen_ks_traefik}/kustomization.yaml"
sanitize_ks traefik-crds/ >"${gen_ks_traefikcrds}/kustomization.yaml"

diff -Naur "${gen_ks_traefik}" "${gen_ks_traefikcrds}" || {
  echo "❌ CRDs are not consistent." && exit 1
}

rm -rf "${gen_ks_traefik}" "${gen_ks_traefikcrds}"

echo "✅ CRDs are consistent."
exit 0
