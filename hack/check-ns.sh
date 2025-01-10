#!/bin/bash


ns=$(grep -rn .Release.Namespace traefik/templates/ | wc -l)

if [[ ${ns} -ne 1 ]] ; then
  echo "Namespace check KO. Please check an overrideNamespace case has not been missed."
  echo "See https://github.com/traefik/traefik-helm-chart/issues/1289"
  exit 1
fi

echo "Namespace check OK"

exit 0
