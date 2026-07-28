#!/bin/bash

ACTION=$1

git config --global --add safe.directory /charts

case "${ACTION}" in
install)
  kubectl create namespace traefik
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
*)
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
esac
