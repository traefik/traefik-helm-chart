#!/bin/bash

# Golden tests for hack/changelog.sh. Each case under
# .github/fixtures/artifacthub-changes/ holds a charts/ tree to run against and
# the Chart.yaml it should produce, or an expect-failure marker asserting
# changelog.sh refuses. Refresh the golden files with:
#
#   REGENERATE=1 ./hack/test-changelog.sh

set -uo pipefail

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required."
  exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
fixtures="${root}/.github/fixtures/artifacthub-changes"
workdir="$(mktemp -d)"
blockfile="$(mktemp)"
trap 'rm -rf "${workdir}" "${blockfile}"' EXIT

# Artifact Hub rejects anything else.
valid_kinds="added changed deprecated removed fixed security"

# Golden files are byte comparisons, so a broken annotation stays green once
# regenerated. Parse it too, the way Artifact Hub does. awk unindents the block
# first: extracting it with yq needs -r, which mikefarah yq lacks. python-yq
# then quotes scalars as JSON, hence the tr.
check_annotation() {
  local file="$1" kinds kind

  if ! yq '.' "${file}" >/dev/null 2>&1; then
    echo "  Chart.yaml does not parse"
    return 1
  fi

  awk '/^  artifacthub\.io\/changes:/ { inblock = 1; next }
       inblock && /^    / { sub(/^    /, ""); print; next }
       inblock { exit }' "${file}" >"${blockfile}"

  if [ ! -s "${blockfile}" ]; then
    echo "  artifacthub.io/changes is missing or empty"
    return 1
  fi

  kinds="$(yq '.[].kind' "${blockfile}" 2>&1)"
  if [ $? -ne 0 ]; then
    echo "  artifacthub.io/changes does not parse: ${kinds}"
    return 1
  fi
  kinds="$(echo "${kinds}" | tr -d '"')"

  if [ -z "${kinds}" ]; then
    echo "  artifacthub.io/changes is not a list of kind/description entries"
    return 1
  fi

  for kind in ${kinds}; do
    case " ${valid_kinds} " in
      *" ${kind} "*) ;;
      *)
        echo "  invalid kind '${kind}', expected one of: ${valid_kinds}"
        return 1
        ;;
    esac
  done
}

failed=0

for case_dir in "${fixtures}"/*/; do
  name="$(basename "${case_dir}")"

  rm -rf "${workdir:?}"/*
  cp -r "${case_dir}charts/." "${workdir}/"
  (cd "${workdir}" && "${root}/hack/changelog.sh" >/dev/null 2>&1)
  status=$?

  if [ -f "${case_dir}expect-failure" ]; then
    if [ "${status}" -eq 0 ]; then
      echo "FAIL ${name}: changelog.sh succeeded, expected it to refuse"
      failed=1
    else
      echo "ok   ${name} (refused, as expected)"
    fi
    continue
  fi

  if [ "${status}" -ne 0 ]; then
    echo "FAIL ${name}: changelog.sh exited ${status}"
    failed=1
    continue
  fi

  for chart in "${workdir}"/*/; do
    chart_name="$(basename "${chart}")"
    expected="${case_dir}expected-${chart_name}.yaml"

    if ! check_annotation "${chart}Chart.yaml"; then
      echo "FAIL ${name}/${chart_name}"
      failed=1
      continue
    fi

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
