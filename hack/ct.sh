#!/bin/bash

git config --global --add safe.directory /charts

ct $1 --config=.github/chart-testing.yaml --charts traefik/
