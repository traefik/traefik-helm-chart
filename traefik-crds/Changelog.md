# Change Log

## 1.8.1  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-05-23

* fix(CRDs): validation check on RootCA for both servertransport
* chore(release): :rocket: publish v35.4.0 and CRDs v1.8.1


## 1.8.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-05-19

* feat: azure marketplace integration
* feat(CRDs): ✨ update CRDs for Traefik Proxy v3.4.x
* chore: update maintainers
* chore(release): :rocket: publish v35.3.0 and CRDs v1.8.0

### Default value changes

```diff
diff --git a/traefik-crds/values.yaml b/traefik-crds/values.yaml
index aaa56c8..1240977 100644
--- a/traefik-crds/values.yaml
+++ b/traefik-crds/values.yaml
@@ -4,7 +4,7 @@
 
 # -- Global values
 # This definition is only here as a placeholder such that it is included in the json schema.
-global: {} # @schema additionalProperties: true
+global: {}  # @schema additionalProperties: true
 # -- Field that can be used as a condition when this chart is a dependency.
 # This definition is only here as a placeholder such that it is included in the json schema.
 # See https://helm.sh/docs/chart_best_practices/dependencies/#conditions-and-tags for more info.
```

## 1.7.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-04-25

* feat(CRDs): remove APIAccess resource
* chore(release): :rocket: publish v35.1.0 and CRDs v1.7.0


## 1.6.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-03-31

* feat(CRDs): 🔧 update Traefik Hub CRDs to v1.17.2
* chore(release): 🚀 publish crds 1.6.0 and traefik 34.5.0


## 1.5.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-03-04

* fix(chart): reorder source urls annotations
* feat(CRDs-schema): add `global` and `enabled` placeholders for subchart/dependency
* chore(CRDs-release): 🔧 publish v1.5.0

### Default value changes

```diff
diff --git a/traefik-crds/values.yaml b/traefik-crds/values.yaml
index 6aca6cb..aaa56c8 100644
--- a/traefik-crds/values.yaml
+++ b/traefik-crds/values.yaml
@@ -2,6 +2,13 @@
 # This is a YAML-formatted file.
 # Declare variables to be passed into templates
 
+# -- Global values
+# This definition is only here as a placeholder such that it is included in the json schema.
+global: {} # @schema additionalProperties: true
+# -- Field that can be used as a condition when this chart is a dependency.
+# This definition is only here as a placeholder such that it is included in the json schema.
+# See https://helm.sh/docs/chart_best_practices/dependencies/#conditions-and-tags for more info.
+enabled: true
 # -- Install Traefik CRDs by default
 traefik: true
 # -- Set it to true to install GatewayAPI CRDs.
```

## 1.4.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-02-19

* fix(traefik-crds): remove unnecessary annotations
* feat(CRDs): update Traefik Hub CRDs to v1.17.0
* chore(release): 🚀 publish v34.4.0 and CRDs v1.4.0


## 1.3.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-02-07

* feat(deps): update traefik docker tag to v3.3.3
* chore: update CRDs to v1.14.1
* chore: release 34.3.0 and 1.3.0


## 1.2.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-01-15

* feat(Traefik Hub): add OAS validateRequestMethodAndPath - CRDs update
* chore(release): publish v34.1.0


## 1.1.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-01-13

* feat(CRDs): update CRDs for Traefik Proxy v3.3.x
* chore(release): publish v34.0.0 and CRDs v1.1.0


## 1.0.0  ![Kubernetes: >=1.22.0-0](https://img.shields.io/static/v1?label=Kubernetes&message=%3E%3D1.22.0-0&color=informational&logo=kubernetes) ![Helm: v3](https://img.shields.io/static/v1?label=Helm&message=v3&color=informational&logo=helm)

**Release date:** 2025-01-10

* feat(Chart): :package: add optional separated chart for CRDs

### Default value changes

```diff
# Default values for Traefik CRDs
# This is a YAML-formatted file.
# Declare variables to be passed into templates

# -- Install Traefik CRDs by default
traefik: true
# -- Set it to true to install GatewayAPI CRDs.
# Needed if you set providers.kubernetesGateway.enabled to true in main chart
gatewayAPI: false
# -- Set it to true to install Traefik Hub CRDs.
# Needed if you set hub.enabled to true in main chart
hub: false
# -- Set it to true if you want to uninstall CRDs when uninstalling this chart.
# By default, CRDs will be kept so your custom resources will not be deleted accidentally.
deleteOnUninstall: false
```

---
Autogenerated from Helm Chart and git history using [helm-changelog](https://github.com/mogensen/helm-changelog)
