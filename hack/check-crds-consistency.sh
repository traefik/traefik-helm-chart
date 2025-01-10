#!/bin/bash

nativecrd=$(mktemp)
chartcrd=$(mktemp)

kustomize build traefik/crds > "${nativecrd}"
kustomize build traefik-crds/ > "${chartcrd}"

diff -Naur "${nativecrd}" "${chartcrd}" > /dev/null 2>&1
exitcode=$?
rm -f "${nativecrd}" "${chartcrd}"

if [ $exitcode -ne 0 ] ; then
  echo "⚠️  CRDs are inconsistent between traefik/crds and traefik-crds/ !"
  exit 1
fi

echo "✅ CRDs are consistent."
exit 0
