#!/bin/bash

set -uo pipefail

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  echo "Then either add it to your PATH or use: PATH=\"\$(brew --prefix gnu-sed)/libexec/gnubin:\$PATH\" $0"
  exit 1
fi

repo="https://github.com/traefik/traefik-helm-chart"

# Commit line -> Artifact Hub kind. No breaking kind exists, so ! means changed.
kind_for() {
  case "$1" in
    feat\!:*|feat\(*\)\!:*|fix\!:*|fix\(*\)\!:*) echo "changed" ;;
    feat*) echo "added" ;;
    fix*) echo "fixed" ;;
    *) echo "changed" ;;
  esac
}

# Chart -> git tag prefix, so release links resolve for both charts.
tag_prefix_for() {
  case "$1" in
    *hub-manager) echo "hub-manager_v" ;;
    *) echo "v" ;;
  esac
}

for chart in "./traefik" "./hub-manager"; do
  # A chart without any release yet has nothing to extract.
  if [ ! -f "${chart}/Changelog.md" ]; then
    echo "Skipping ${chart}: no Changelog.md"
    continue
  fi

  # sed, not yq: mikefarah yq has no -r and python-yq is not on the runner.
  version=$(sed -nE 's/^version:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/p' "${chart}/Chart.yaml" | head -1)
  # A release bumps Chart.yaml, so helm-changelog titles the top section with it.
  # Anything else on top means no release here: keep the published annotation.
  top_section=$(sed -nE '/^## /{s/^## //; s/[[:space:]]*!\[.*//; s/[[:space:]]+$//; p; q}' "${chart}/Changelog.md")
  if [ "${top_section}" != "${version}" ]; then
    echo "Skipping ${chart}: ${version} already released, top section is '${top_section}'"
    # helm-changelog opens a "Next Release" section on every chart it touched.
    # No-op in the golden tests, which run outside a work tree.
    git checkout -- "${chart}/Changelog.md" 2>/dev/null || true
    continue
  fi
  # A chart's first release is X.0.0 without being breaking.
  release_count=$(grep -c '^## ' "${chart}/Changelog.md")

  if [[ "${version}" =~ ^[0-9]+\.0\.0$ ]] && [ "${release_count}" -gt 1 ]; then
    # Major: one entry to the upgrade notes. The tag lands at publish, which is
    # before Artifact Hub scrapes.
    changelog="$(
      printf '    - kind: changed\n'
      printf '      description: "This is a major release with breaking changes. Read the upgrade notes before upgrading."\n'
      printf '      links:\n'
      printf '        - name: Upgrade Notes\n'
      printf '          url: %s/releases/tag/%s%s\n' "${repo}" "$(tag_prefix_for "${chart}")" "${version}"
    )"
  else
    # Patch/minor: per-kind entries, without the release commit. Shortcodes are
    # stripped only where gitmoji sits, sparing a colon pair in a URL. Rendered
    # gitmoji stays, Artifact Hub displays it fine.
    rawlist="$(sed -e "1,/^## ${version}/d" -e "/^##/,\$d" -e '/^$/d' ${chart}/Changelog.md |
      grep '^\* ' |
      sed -E -e 's/^\* //' \
        -e 's/^(:[a-z0-9_]+:[[:space:]]*)+//' \
        -e 's/^([a-z]+(\([^)]*\))?!?:[[:space:]]*)(:[a-z0-9_]+:[[:space:]]*)+/\1/' \
        -e 's/[[:space:]]*$//' |
      grep -viE '^chore(\([^)]*\))?:[[:space:]]*([^[:alnum:][:space:]]+[[:space:]]+)?(release|publish)\b')"
    changelog="$(
      while IFS= read -r line; do
        [ -z "${line}" ] && continue
        esc="${line//\\/\\\\}"
        esc="${esc//\"/\\\"}"
        printf '    - kind: %s\n' "$(kind_for "${line}")"
        printf '      description: "%s"\n' "${esc}"
      done <<<"${rawlist}"
    )"
  fi

  # Empty means no section for this version, or nothing but the release commit.
  # Both are a desync: no release is changeless.
  if [ -z "${changelog}" ]; then
    echo "Error: no changes found for ${chart} ${version}. Run 'make changelog' first."
    exit 1
  fi

  echo "${version}"
  echo "${changelog}"

  sed -i -r 's/^annotations: \{\}/annotations:/g' "${chart}/Chart.yaml"
  # Drop only the previous block, so an annotation sitting after it survives.
  awk '/^  artifacthub\.io\/changes:/ { skip = 1; next }
       skip && /^    / { next }
       { skip = 0; print }' "${chart}/Chart.yaml" >"${chart}/Chart.yaml.tmp"
  mv "${chart}/Chart.yaml.tmp" "${chart}/Chart.yaml"
  {
    echo "  artifacthub.io/changes: |"
    echo "${changelog}"
  } >>"${chart}/Chart.yaml"
done
