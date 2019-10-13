# Traefik

[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer made to deploy
microservices with ease.

## Introduction

This chart bootstraps Traefik version 2 as a Kubernetes ingress controller

## Prerequisites

- Kubernetes 1.10+
- You are deploying the chart to a cluster with a cloud provider capable of provisioning an
external load balancer (e.g. AWS or GKE)
- You control DNS for the domain(s) you intend to route through Traefik

NOTE: THIS CHART IS IN INCUBATOR STATUS, DO NOT USE IN A PRODUCTION ENVIRONMENT

## Configuration

The following table lists the configurable parameters of the Traefik chart and their default values.
| Parameter                              | Description                                                                                                                  | Default                                           |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `service.annotations`                  |  Extra parameters to manage cloud load balancers. More [details](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/#aws) |             []               |
