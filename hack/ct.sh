#!/bin/bash

ACTION=$1

git config --global --add safe.directory /charts

case "${ACTION}" in
install-with-crds)
  ACTION="install"

  # deleting existing CRDs
  kubectl get customresourcedefinitions.apiextensions.k8s.io -o name | grep traefik.io | xargs kubectl delete crd
  ct "${ACTION}" --namespace traefik --config=.github/chart-testing.yaml --charts traefik-crds/
  ct "${ACTION}" --namespace traefik --config=.github/chart-testing.yaml --charts traefik/
  ;;
install)
  kubectl create namespace traefik
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
*)
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik-crds/
  ct "${ACTION}" --config=.github/chart-testing.yaml --charts traefik/
  ;;
esac
