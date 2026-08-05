#!/bin/bash

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  echo "Then either add it to your PATH or use: PATH=\"\$(brew --prefix gnu-sed)/libexec/gnubin:\$PATH\" $0"
  exit 1
fi

repo="https://github.com/traefik/traefik-helm-chart"

# Commit line -> Artifact Hub change kind. Nothing maps to deprecated/security.
kind_for() {
  case "$1" in
    # No breaking kind either, so a breaking marker falls back to changed.
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
  # A chart without any release yet has no Changelog.md to extract changes from.
  if [ ! -f "${chart}/Changelog.md" ]; then
    echo "Skipping ${chart}: no Changelog.md"
    continue
  fi

  version=$(yq -r '.version' <"${chart}/Chart.yaml")
  # A chart's first release is X.0.0 without being breaking.
  release_count=$(grep -c '^## ' "${chart}/Changelog.md")

  if [[ "${version}" =~ ^[0-9]+\.0\.0$ ]] && [ "${release_count}" -gt 1 ]; then
    # Major: one entry pointing at the upgrade notes, impossible to miss.
    changelog="$(
      printf '    - kind: changed\n'
      printf '      description: "This is a major release with breaking changes. Read the upgrade notes before upgrading."\n'
      printf '      links:\n'
      printf '        - name: Upgrade Notes\n'
      printf '          url: %s/releases/tag/%s%s\n' "${repo}" "$(tag_prefix_for "${chart}")" "${version}"
    )"
  else
    # Patch/minor: per-kind entries. Drop the release commit (own changelog
    # noise) and gitmoji shortcodes, which Artifact Hub shows verbatim. Only
    # strip them where gitmoji sits, to spare a colon pair in a URL or a
    # description. Rendered gitmoji is kept: Artifact Hub displays it fine.
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

  # An empty annotation is not valid for artifact hub, and skipping the rewrite
  # would leave the previous version's changes advertised on this one.
  if [ -z "${changelog}" ]; then
    changelog="$(printf '    - kind: changed\n      description: "Release %s"' "${version}")"
  fi

  echo "${version}"
  echo "${changelog}"

  sed -i -r 's/^annotations: \{\}/annotations:/g' ${chart}/Chart.yaml
  sed -i -e '/^  artifacthub.io\/changes:/,$d' ${chart}/Chart.yaml
  echo "  artifacthub.io/changes: |" >>${chart}/Chart.yaml
  echo "${changelog}" >>${chart}/Chart.yaml
done
