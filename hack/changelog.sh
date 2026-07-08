#!/bin/bash

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  echo "Then either add it to your PATH or use: PATH=\"\$(brew --prefix gnu-sed)/libexec/gnubin:\$PATH\" $0"
  exit 1
fi

repo="https://github.com/traefik/traefik-helm-chart"

# Commit line -> Artifact Hub change kind.
kind_for() {
  case "$1" in
    feat*) echo "added" ;;
    fix*) echo "fixed" ;;
    *) echo "changed" ;;
  esac
}

for chart in "./traefik" "./hub-manager"; do
  # A chart without any release yet has no Changelog.md to extract changes from.
  if [ ! -f "${chart}/Changelog.md" ]; then
    echo "Skipping ${chart}: no Changelog.md"
    continue
  fi

  version=$(yq -r '.version' <"${chart}/Chart.yaml")

  if [[ "${version}" =~ ^[0-9]+\.0\.0$ ]]; then
    # Major release: collapse to a single entry linking to the upgrade notes, so
    # the breaking-change signal is impossible to miss in a long commit list.
    changelog="$(
      printf '    - kind: changed\n'
      printf '      description: "This is a major release with breaking changes. Read the upgrade notes before upgrading."\n'
      printf '      links:\n'
      printf '        - name: Upgrade Notes\n'
      printf '          url: %s/releases/tag/v%s\n' "${repo}" "${version}"
    )"
  else
    # Patch/minor: structured list so Artifact Hub renders per-kind badges.
    rawlist="$(sed -e "1,/^## ${version}/d" -e "/^##/,\$d" -e '/^$/d' ${chart}/Changelog.md | grep '^\* ' | sed -e 's/^\* //' -e 's/:[a-z0-9_]*: //g' -e 's/[[:space:]]*$//')"
    changelog="$(
      while IFS= read -r line; do
        [ -z "${line}" ] && continue
        esc="${line//\"/\\\"}"
        printf '    - kind: %s\n' "$(kind_for "${line}")"
        printf '      description: "%s"\n' "${esc}"
      done <<<"${rawlist}"
    )"
  fi

  echo "${version}"
  echo "${changelog}"

  sed -i -r 's/^annotations: \{\}/annotations:/g' ${chart}/Chart.yaml
  sed -i -e '/^  artifacthub.io\/changes:/,$d' ${chart}/Chart.yaml
  echo "  artifacthub.io/changes: |" >>${chart}/Chart.yaml
  echo "${changelog}" >>${chart}/Chart.yaml
done
