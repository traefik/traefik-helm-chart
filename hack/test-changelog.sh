#!/bin/bash

# Golden tests for hack/changelog.sh: each case under
# .github/fixtures/artifacthub-changes/ holds a charts/ tree to run against and
# the Chart.yaml it should produce. Refresh them with:
#
#   REGENERATE=1 ./hack/test-changelog.sh

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
fixtures="${root}/.github/fixtures/artifacthub-changes"
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

failed=0

for case_dir in "${fixtures}"/*/; do
  name="$(basename "${case_dir}")"

  rm -rf "${workdir:?}"/*
  cp -r "${case_dir}charts/." "${workdir}/"
  (cd "${workdir}" && "${root}/hack/changelog.sh" >/dev/null)

  for chart in "${workdir}"/*/; do
    chart_name="$(basename "${chart}")"
    expected="${case_dir}expected-${chart_name}.yaml"

    if [ -n "${REGENERATE:-}" ]; then
      cp "${chart}Chart.yaml" "${expected}"
      echo "regenerated ${name}/${chart_name}"
      continue
    fi

    if [ ! -f "${expected}" ]; then
      echo "FAIL ${name}/${chart_name}: missing ${expected#"${root}/"}"
      failed=1
    elif diff -u --label "expected" "${expected}" --label "actual" "${chart}Chart.yaml"; then
      echo "ok   ${name}/${chart_name}"
    else
      echo "FAIL ${name}/${chart_name}"
      failed=1
    fi
  done
done

if [ "${failed}" -ne 0 ]; then
  echo "Changelog annotation tests KO. Run 'REGENERATE=1 ./hack/test-changelog.sh' if the change is intended."
  exit 1
fi

echo "Changelog annotation tests OK"
