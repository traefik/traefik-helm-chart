#!/bin/bash

dirpairs=(
    "traefik/crds:traefik/crds/kustomization.yaml"
    "traefik-crds/crds-files:traefik-crds/kustomization.yaml"
)

for pair in "${dirpairs[@]}"; do
    crddir="${pair%%:*}"
    kustom="${pair##*:}"

    if [ ! -f "$kustom" ]; then
        echo "⚠️  Kustomization file not found in $crddir, skipping..."
        continue
    fi

    dircrd=$(mktemp)
    kustomcrd=$(mktemp)

    find "${crddir}" -type f -name '*.yaml' ! -name 'kustomization.yaml' | xargs -n1 basename | sort >"${dircrd}"
    grep '^[[:space:]]*-[[:space:]]*' "${kustom}" | sed 's/^[[:space:]]*-[[:space:]]*//' | grep -E '\.ya?ml$' | xargs -n1 basename | sort >"${kustomcrd}"

    diff -Naur "${dircrd}" "${kustomcrd}" >/dev/null 2>&1
    exitcode=$?
    rm -f "${dircrd}" "${kustomcrd}"

    if [ $exitcode -ne 0 ]; then
        echo "⚠️  CRDs in $crddir are inconsistent with kustomization.yaml!"
        exit 1
    fi
done

echo "✅ CRDs in $crddir are consistent with kustomization.yaml."
exit 0
