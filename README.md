# Traefik

[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer made to deploy
microservices with ease.

**NOTE: THIS CHART IS IN INCUBATOR STATUS, DO NOT USE IN A PRODUCTION ENVIRONMENT**

## Introduction

This chart bootstraps Traefik version 2 as a Kubernetes ingress controller

## Prerequisites

- Kubernetes 1.10+
- You are deploying the chart to a cluster with a cloud provider capable of provisioning an
external load balancer (e.g. AWS or GKE)
- You control DNS for the domain(s) you intend to route through Traefik
