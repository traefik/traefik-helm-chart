#!/bin/bash

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
