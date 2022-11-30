#!/bin/bash

chart="./traefik"

version="$(awk '/^version:/ { print $2} ' ${chart}/Chart.yaml)"
changelog="$(sed -e "1,/^## ${version}/d" -e "/^###/,\$d" -e '/^$/d' -e 's/^* /- /' -e 's/^/    /' ${chart}/Changelog.md | grep '^    - ' | sed -e 's/\ *$//g' | sed 's/    - \(.*\)/    - "\1"/g')"
sed -i -e '/^  artifacthub.io\/changes: |/,$d' ${chart}/Chart.yaml
echo "  artifacthub.io/changes: |" >> ${chart}/Chart.yaml
echo "${changelog}" >> ${chart}/Chart.yaml
