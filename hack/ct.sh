#!/bin/bash

ACTION=$1

git config --global --add safe.directory /charts

case "${ACTION}" in
install-with-crds)
  ACTION="install"
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik-crds/
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/  --helm-extra-args '--skip-crds'
  ;;
install)
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
*)
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik-crds/
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
esac
