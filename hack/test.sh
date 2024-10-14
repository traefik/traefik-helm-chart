#!/bin/bash

/usr/bin/helm unittest --color ./traefik;
/usr/bin/helm unittest --color ./traefik-crds;
