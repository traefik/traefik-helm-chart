#!/bin/bash

if ! sed --version 2>/dev/null | grep -q "GNU sed"; then
  echo "Error: GNU sed is required. On macOS, install it with: brew install gnu-sed"
  echo "Then either add it to your PATH or use: PATH=\"\$(brew --prefix gnu-sed)/libexec/gnubin:\$PATH\" $0"
  exit 1
fi

for chart in "./traefik" "./traefik-crds"; do
  version=$(yq -r '.version' <"${chart}/Chart.yaml")
  changelog="$(sed -e "1,/^## ${version}/d" -e "/^##/,\$d" -e '/^$/d' -e 's/^* /- /' -e 's/^/    /' ${chart}/Changelog.md | grep '^    - ' | sed -e 's/\ *$//g' | sed 's/    - \(.*\)/    - "\1"/g')"

  echo "${version}"
  echo "${changelog}"

  sed -i -r 's/^annotations: \{\}/annotations:/g' ${chart}/Chart.yaml
  sed -i -e '/^  artifacthub.io\/changes: |/,$d' ${chart}/Chart.yaml
  echo "  artifacthub.io/changes: |" >>${chart}/Chart.yaml
  echo "${changelog}" >>${chart}/Chart.yaml
done
