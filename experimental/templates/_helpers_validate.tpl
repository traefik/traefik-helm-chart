{{/*
Cross-field validation rules. Helm has no `warn`, so each rule `fail`s at
template time with a message pointing at the right values key. Keep each
rule a self-contained `if` block calling `fail` once.
*/}}
{{- define "traefik.validate" -}}
{{- include "traefik.validate.workload" . -}}
{{- include "traefik.validate.rbac" . -}}
{{- include "traefik.validate.hub" . -}}
{{- include "traefik.validate.service" . -}}
{{- include "traefik.validate.version" . -}}
{{- end -}}

{{/*
Version guard (traefik-helm-chart#1884): hard-fail when the effective image
version is below min or a *major* above max. Minor/patch above max only warns
(see traefik.versionWarning). Non-parseable Proxy tags are skipped.
*/}}
{{- define "traefik.validate.version" -}}
{{- $c := include "traefik.versionContext" . | fromYaml -}}
{{- if not $c.skip -}}
  {{- $product := ternary "Traefik Hub" "Traefik Proxy" $c.isHub -}}
  {{- if semverCompare (printf "<%s-0" $c.min) $c.version -}}
    {{- fail (printf "ERROR: this chart supports %s >= %s, but the image resolves to %s — pin a supported image or upgrade the chart" $product $c.min $c.version) -}}
  {{- end -}}
  {{- if eq (include "traefik.isMajorAboveMax" (dict "version" $c.version "max" $c.max)) "true" -}}
    {{- fail (printf "ERROR: this chart does not support %s %s — a major version above the supported %s (breaking CRD/config changes are likely)" $product $c.version $c.max) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Container ports are named after their traefik.entryPoints entry (plus hub
admission/apiportal), so a named `targetPort` that isn't a defined entryPoint
routes to nothing. Integer targetPorts are left to the user (custom ports).
*/}}
{{- define "traefik.validate.service" -}}
{{- if kindIs "map" .Values.service -}}
  {{- $config := include "traefik.mergedConfig" . | fromYaml -}}
  {{- $valid := dict -}}
  {{- range $ep := keys ($config.entryPoints | default dict) -}}{{- $_ := set $valid $ep true -}}{{- end -}}
  {{- if include "traefik.hubAdmissionEnabled" . -}}{{- $_ := set $valid "admission" true -}}{{- end -}}
  {{- if include "traefik.hubAPIManagementEnabled" . -}}{{- $_ := set $valid "apiportal" true -}}{{- end -}}
  {{- range $name, $entry := .Values.service -}}
    {{- if kindIs "map" $entry -}}
      {{- range $p := ((($entry.spec) | default dict).ports | default list) -}}
        {{- if kindIs "map" $p -}}
          {{- $tp := index $p "targetPort" -}}
          {{- if and (kindIs "string" $tp) (not (hasKey $valid $tp)) -}}
            {{- fail (printf "service.%s: port targetPort %q is not a defined traefik.entryPoints entry (defined: %s) — add the entryPoint or point targetPort at an existing one" $name $tp (keys ($config.entryPoints | default dict) | sortAlpha | join ", ")) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Workload composition rules.
*/}}
{{- define "traefik.validate.workload" -}}

{{/*
deployment and daemonset are mutually exclusive — both target the same
selector labels and would fight over the same pods.
*/}}
{{- if and (kindIs "map" .Values.deployment) (kindIs "map" .Values.daemonset) -}}
  {{- fail "deployment and daemonset are mutually exclusive — set one to null (typically `deployment: null` when enabling daemonset, see EXAMPLES.md \"Install as a DaemonSet\")" -}}
{{- end -}}

{{/*
At least one pod controller must be enabled, else the install is inert
(Services/RBAC with no pod). Catches `deployment: null` typos.
*/}}
{{- if and (not (kindIs "map" .Values.deployment)) (not (kindIs "map" .Values.daemonset)) -}}
  {{- fail "no pod controller would be rendered — set `deployment: {}` (default) or `daemonset: {}` (see EXAMPLES.md \"Install as a DaemonSet\")" -}}
{{- end -}}

{{/*
A PDB needs one of maxUnavailable / minAvailable; with neither, the API
server rejects the object.
*/}}
{{- if kindIs "map" .Values.podDisruptionBudget -}}
  {{- $spec := (.Values.podDisruptionBudget).spec | default dict -}}
  {{- if and (not (hasKey $spec "maxUnavailable")) (not (hasKey $spec "minAvailable")) -}}
    {{- fail "podDisruptionBudget is enabled but neither spec.maxUnavailable nor spec.minAvailable is set — a PDB requires one" -}}
  {{- end -}}
{{- end -}}

{{/*
An HPA needs maxReplicas and scales the Deployment — incompatible with daemonset.
*/}}
{{- if kindIs "map" .Values.autoscaling -}}
  {{- if not (hasKey ((.Values.autoscaling).spec | default dict) "maxReplicas") -}}
    {{- fail "autoscaling is enabled but spec.maxReplicas is not set — an HPA requires it" -}}
  {{- end -}}
  {{- if kindIs "map" .Values.daemonset -}}
    {{- fail "autoscaling scales the Deployment and cannot be used with daemonset — disable one" -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
RBAC pair rules — a Role/ClusterRole without its matching Binding (or vice
versa) is almost always a typo; both halves are needed to grant permissions.
*/}}
{{- define "traefik.validate.rbac" -}}

{{- if and (kindIs "map" .Values.clusterRole) (not (kindIs "map" .Values.clusterRoleBinding)) -}}
  {{- fail "clusterRole is rendered but clusterRoleBinding is null — bindings are required for the ClusterRole to grant permissions" -}}
{{- end -}}
{{- if and (kindIs "map" .Values.clusterRoleBinding) (not (kindIs "map" .Values.clusterRole)) -}}
  {{- fail "clusterRoleBinding is rendered but clusterRole is null — the binding has nothing to point at" -}}
{{- end -}}

{{- if and (kindIs "map" .Values.role) (not (kindIs "map" .Values.roleBinding)) -}}
  {{- fail "role is rendered but roleBinding is null — bindings are required for the Role to grant permissions" -}}
{{- end -}}
{{- if and (kindIs "map" .Values.roleBinding) (not (kindIs "map" .Values.role)) -}}
  {{- fail "roleBinding is rendered but role is null — the binding has nothing to point at" -}}
{{- end -}}

{{/*
Namespaced RBAC derives per-namespace Role/RoleBinding objects from
traefik.providers.<p>.namespaces. Enabling `role` with no provider declaring
`namespaces:` would render zero manifests — fail loudly instead.
*/}}
{{- if kindIs "map" .Values.role -}}
  {{- $providerNs := include "traefik.providerNamespaces" . | fromYamlArray -}}
  {{- if empty $providerNs -}}
    {{- fail "role is enabled but no traefik.providers.<p>.namespaces is set — namespaced RBAC requires at least one provider with a `namespaces:` list (see EXAMPLES.md \"Install in a dedicated namespace, with limited RBAC\")" -}}
  {{- end -}}
{{- end -}}

{{- end -}}

{{/*
Hub composition rules.
*/}}
{{- define "traefik.validate.hub" -}}

{{/*
Hub needs the traefik-hub image (defaulted when traefik.hub.token is set);
fires only if `image:` was overridden with a non-Hub ref (traefik-helm-chart#1885).
*/}}
{{- if include "traefik.hubTokenInline" . -}}
  {{- if not (contains "traefik-hub" (include "traefik.imageName" .)) -}}
    {{- fail "ERROR: Traefik Hub (traefik.hub.token set) requires a traefik-hub image — leave `image` unset to use the default, or point it at a traefik-hub repository" -}}
  {{- end -}}
{{- end -}}

{{/*
API Management requires a license token (the binary refuses to start without
it); failing at template time beats the deferred runtime failure.
*/}}
{{- if include "traefik.hubAPIManagementEnabled" . -}}
  {{- if not (include "traefik.hubTokenInline" .) -}}
    {{- fail "traefik.hub.apimanagement requires a license token: set traefik.hub.token (see EXAMPLES.md \"Install Traefik Hub API Management\")" -}}
  {{- end -}}
{{- end -}}

{{/*
Hub admission webhook needs its k8s objects rendered. If one was null'd while
apimanagement.admission stays enabled, fail early pointing at the missing object.
*/}}
{{- if include "traefik.hubAdmissionEnabled" . -}}
  {{- if not (kindIs "map" (index (.Values.secret | default dict) "hub-admission")) -}}
    {{- fail "traefik.hub.apimanagement.admission requires secret.hub-admission to be rendered (do not set it to null, or BYO Secret + patch admission.secretname)" -}}
  {{- end -}}
  {{- if not (kindIs "map" (index (.Values.service | default dict) "hub-admission")) -}}
    {{- fail "traefik.hub.apimanagement.admission requires service.hub-admission to be rendered (do not set it to null)" -}}
  {{- end -}}
  {{- if not (kindIs "map" .Values.mutatingWebhookConfigurations) -}}
    {{- fail "traefik.hub.apimanagement.admission requires mutatingWebhookConfigurations to be rendered (do not set it to null)" -}}
  {{- end -}}
{{- end -}}

{{- end -}}
