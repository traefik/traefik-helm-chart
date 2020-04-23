# Contributing Guide

This Helm Chart accepts contributions from GitHub pull requests.
You can find help in this document to get your contribution accepted.

## Helm Chart Guidelines

Please read the [Helm Chart Guidelines](./traefik/Guidelines.md) before editing this chart.

## Testing

Please read the [testing guidelines](./TESTING.md) to learn how testing is done with this chart.

## Guidelines

According to the Traefik HelmChart [philosophy](./README.md#philosophy), 
the guidelines for future evolutions are:

* fix bugs
* improve security
* improve HelmChart support
* improve Kubernetes features support
* improve Traefik default configuration

While encouraging contributions, the philosophy leads to avoid introducing:

* specific use cases
* third party CRD
* dashboard exposition tuning
* helm chart variables that shortcuts/expose static or dynamic Traefik configuration