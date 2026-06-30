{{/*
Layered RBAC: one define per feature/provider, composed by what's set under
.Values.traefik.providers.* / .Values.traefik.hub.*. User overrides on
.Values.clusterRole.rules / .Values.role.rules replace wholesale (arrays don't merge).
New provider = add a `traefik.rbacXxxRules` define + a branch in `traefik.rbacAssembledRules`.
*/}}

{{- define "traefik.rbacCoreRules" -}}
- apiGroups: [""]
  resources: [services, secrets, nodes, configmaps]
  verbs: [get, list, watch]
- apiGroups: [""]
  resources: [namespaces]
  verbs: [list, watch]
- apiGroups: [""]
  resources: [pods]
  verbs: [get]
- apiGroups: [discovery.k8s.io]
  resources: [endpointslices]
  verbs: [list, watch]
{{- end -}}

{{- define "traefik.rbacKubernetesCRDRules" -}}
- apiGroups: [traefik.io]
  resources:
    - ingressroutes
    - ingressroutetcps
    - ingressrouteudps
    - middlewares
    - middlewaretcps
    - serverstransports
    - serverstransporttcps
    - tlsoptions
    - tlsstores
    - traefikservices
  verbs: [get, list, watch]
{{- end -}}

{{- define "traefik.rbacKubernetesIngressRules" -}}
- apiGroups: [networking.k8s.io]
  resources: [ingresses, ingressclasses]
  verbs: [get, list, watch]
- apiGroups: [networking.k8s.io]
  resources: [ingresses/status]
  verbs: [update]
{{- end -}}

{{- define "traefik.rbacKubernetesGatewayRules" -}}
- apiGroups: [gateway.networking.k8s.io]
  resources:
    - gatewayclasses
    - gateways
    - httproutes
    - grpcroutes
    - tcproutes
    - tlsroutes
    - udproutes
    - referencegrants
    - backendtlspolicies
  verbs: [get, list, watch]
- apiGroups: [gateway.networking.k8s.io]
  resources:
    - gateways/status
    - httproutes/status
    - grpcroutes/status
    - tcproutes/status
    - tlsroutes/status
    - udproutes/status
  verbs: [update]
{{- end -}}

{{/*
Extra permissions Hub needs once a license token is set (secret write-back,
AI services, lease cleanup), matching the legacy chart. Coalesces with core rules.
*/}}
{{- define "traefik.rbacHubRules" -}}
- apiGroups: [""]
  resources: [secrets]
  verbs: [create, update, delete, deletecollection]
- apiGroups: [""]
  resources: [namespaces]
  verbs: [get]
- apiGroups: [coordination.k8s.io]
  resources: [leases]
  verbs: [get, list, watch, create, update, patch, delete]
- apiGroups: [hub.traefik.io]
  resources: [aiservices]
  verbs: [get, list, watch]
{{- end -}}

{{- define "traefik.rbacHubAPIManagementRules" -}}
- apiGroups: [""]
  resources: [endpoints, pods]
  verbs: [list, watch]
- apiGroups: [hub.traefik.io]
  resources: [aiservices]
  verbs: [get, list, watch]
- apiGroups: [hub.traefik.io]
  resources:
    - accesscontrolpolicies
    - apiauths
    - apibundles
    - apicatalogitems
    - apiplans
    - apiportals
    - apiportalauths
    - apiratelimits
    - apis
    - apiversions
    - managedapplications
    - managedsubscriptions
  verbs: [get, list, watch, create, update, patch, delete]
- apiGroups: [hub.traefik.io]
  resources:
    - apiauths/status
    - apibundles/status
    - apicatalogitems/status
    - apiplans/status
    - apiportalauths/status
    - apiportals/status
    - apis/status
    - apiversions/status
    - managedapplications/status
    - managedsubscriptions/status
  verbs: [get, update, patch]
{{- end -}}

{{/*
Assembles active layers into one rules list.
Args (dict): ctx (root); ns (string; "" → cluster-wide, no filter; non-empty →
keep only layers whose provider lists this ns under traefik.providers.<p>.namespaces).
Hub APIM rules apply to every assembly when enabled (its CRDs are cluster-scoped); not
enforced here so the one composer serves both clusterRole and role.
*/}}
{{- define "traefik.rbacAssembledRules" -}}
{{- $ctx := .ctx -}}
{{- $ns := .ns -}}
{{- $providers := ($ctx.Values.traefik | default dict).providers | default dict -}}
{{- $rules := include "traefik.rbacCoreRules" $ctx | fromYamlArray -}}

{{- if hasKey $providers "kubernetesCRD" -}}
  {{- $providerNs := ($providers.kubernetesCRD | default dict).namespaces | default list -}}
  {{- if or (eq $ns "") (empty $providerNs) (has $ns $providerNs) -}}
    {{- $rules = concat $rules (include "traefik.rbacKubernetesCRDRules" $ctx | fromYamlArray) -}}
  {{- end -}}
{{- end -}}

{{- if hasKey $providers "kubernetesIngress" -}}
  {{- $providerNs := ($providers.kubernetesIngress | default dict).namespaces | default list -}}
  {{- if or (eq $ns "") (empty $providerNs) (has $ns $providerNs) -}}
    {{- $rules = concat $rules (include "traefik.rbacKubernetesIngressRules" $ctx | fromYamlArray) -}}
  {{- end -}}
{{- end -}}

{{- if hasKey $providers "kubernetesGateway" -}}
  {{- $providerNs := ($providers.kubernetesGateway | default dict).namespaces | default list -}}
  {{- if or (eq $ns "") (empty $providerNs) (has $ns $providerNs) -}}
    {{- $rules = concat $rules (include "traefik.rbacKubernetesGatewayRules" $ctx | fromYamlArray) -}}
  {{- end -}}
{{- end -}}

{{- if include "traefik.hubEnabled" $ctx -}}
  {{- $rules = concat $rules (include "traefik.rbacHubRules" $ctx | fromYamlArray) -}}
{{- end -}}

{{- if include "traefik.hubAPIManagementEnabled" $ctx -}}
  {{- $rules = concat $rules (include "traefik.rbacHubAPIManagementRules" $ctx | fromYamlArray) -}}
{{- end -}}

{{- include "traefik.rbacMergeRules" $rules -}}
{{- end -}}

{{/*
Merges overlapping rules so output is clean when layers grant the same resource
(e.g. core pods/get + hubAPIManagement pods/list,watch → one pods/[get,list,watch]).
1. Atomise: one entry per resource keyed by (apiGroups,resource,resourceNames,
   nonResourceURLs); same-key atoms union verbs.
2. Group: atoms sharing (apiGroups,sorted-verbs,resourceNames,nonResourceURLs)
   concat their resources.
3. Emit in first-occurrence order (groups and resources within).
Args: list of rules. Returns: YAML list.
*/}}
{{- define "traefik.rbacMergeRules" -}}
{{- $atoms := dict -}}
{{- $atomOrder := list -}}
{{- range $rule := . -}}
  {{- $apiGroups := $rule.apiGroups | default list -}}
  {{- $resourceNames := $rule.resourceNames | default list -}}
  {{- $nonResourceURLs := $rule.nonResourceURLs | default list -}}
  {{- $verbs := $rule.verbs | default list -}}
  {{- range $res := ($rule.resources | default list) -}}
    {{- $key := mustToJson (dict
        "apiGroups" ($apiGroups | sortAlpha)
        "resource" $res
        "resourceNames" ($resourceNames | sortAlpha)
        "nonResourceURLs" ($nonResourceURLs | sortAlpha)
    ) -}}
    {{- if hasKey $atoms $key -}}
      {{- $existing := index $atoms $key -}}
      {{- $_ := set $existing "verbs" (concat $existing.verbs $verbs | uniq) -}}
    {{- else -}}
      {{- $_ := set $atoms $key (dict
          "apiGroups" $apiGroups
          "resource" $res
          "resourceNames" $resourceNames
          "nonResourceURLs" $nonResourceURLs
          "verbs" ($verbs | uniq)
      ) -}}
      {{- $atomOrder = append $atomOrder $key -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- $groups := dict -}}
{{- $groupOrder := list -}}
{{- range $key := $atomOrder -}}
  {{- $atom := index $atoms $key -}}
  {{- $sig := mustToJson (dict
      "apiGroups" ($atom.apiGroups | sortAlpha)
      "verbs" ($atom.verbs | sortAlpha)
      "resourceNames" ($atom.resourceNames | sortAlpha)
      "nonResourceURLs" ($atom.nonResourceURLs | sortAlpha)
  ) -}}
  {{- if hasKey $groups $sig -}}
    {{- $existing := index $groups $sig -}}
    {{- $_ := set $existing "resources" (append $existing.resources $atom.resource | uniq) -}}
  {{- else -}}
    {{- $copy := dict
        "apiGroups" $atom.apiGroups
        "resources" (list $atom.resource)
        "verbs" $atom.verbs
    -}}
    {{- if not (empty $atom.resourceNames) -}}
      {{- $_ := set $copy "resourceNames" $atom.resourceNames -}}
    {{- end -}}
    {{- if not (empty $atom.nonResourceURLs) -}}
      {{- $_ := set $copy "nonResourceURLs" $atom.nonResourceURLs -}}
    {{- end -}}
    {{- $_ := set $groups $sig $copy -}}
    {{- $groupOrder = append $groupOrder $sig -}}
  {{- end -}}
{{- end -}}

{{- $result := list -}}
{{- range $sig := $groupOrder -}}
  {{- $result = append $result (index $groups $sig) -}}
{{- end -}}
{{- $result | toYaml -}}
{{- end -}}

{{/*
Union of all traefik.providers.<p>.namespaces. Drives Role + RoleBinding
multiplication in namespaced mode. Returns a YAML list (possibly empty).
*/}}
{{- define "traefik.providerNamespaces" -}}
{{- $namespaces := list -}}
{{- $providers := (.Values.traefik | default dict).providers | default dict -}}
{{- range $providers -}}
  {{- if kindIs "map" . -}}
    {{- range .namespaces | default list -}}
      {{- $namespaces = append $namespaces . -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $namespaces | uniq | toYaml -}}
{{- end -}}

{{/*
Default RBAC subjects — the chart's own ServiceAccount in the release namespace.
Used by both ClusterRoleBinding and (cross-namespace) RoleBinding(s).
*/}}
{{- define "traefik.rbacDefaultSubjects" -}}
- kind: ServiceAccount
  name: {{ include "traefik.fullname" . }}
  namespace: {{ include "traefik.namespace" . }}
{{- end -}}

{{/*
ClusterRole rules — user override (replace wholesale) else assembled cluster-wide layers.
*/}}
{{- define "traefik.clusterRoleRules" -}}
{{- $ctx := . -}}
{{- with (.Values.clusterRole | default dict).rules -}}
{{- toYaml . -}}
{{- else -}}
{{- include "traefik.rbacAssembledRules" (dict "ctx" $ctx "ns" "") -}}
{{- end -}}
{{- end -}}

{{/*
Role rules for one namespace — user override (replace wholesale, applied
identically to every Role) else the layers active for this ns.
*/}}
{{- define "traefik.roleRulesForNamespace" -}}
{{- $ctx := .ctx -}}
{{- with ($ctx.Values.role | default dict).rules -}}
{{- toYaml . -}}
{{- else -}}
{{- include "traefik.rbacAssembledRules" (dict "ctx" $ctx "ns" .ns) -}}
{{- end -}}
{{- end -}}

{{/*
ClusterRoleBinding .roleRef — chart default (chart's ClusterRole), JSON-merge-patched by user.
*/}}
{{- define "traefik.clusterRoleBindingRoleRef" -}}
{{- $chartRef := dict
    "apiGroup" "rbac.authorization.k8s.io"
    "kind" "ClusterRole"
    "name" (include "traefik.clusterScopedName" .)
-}}
{{- $userRef := (.Values.clusterRoleBinding | default dict).roleRef | default dict -}}
{{- include "traefik.strategicMerge" (dict "base" $chartRef "patch" $userRef) -}}
{{- end -}}

{{/*
RoleBinding .roleRef — chart default (chart's Role, resolved per-namespace),
JSON-merge-patched by user.
*/}}
{{- define "traefik.roleBindingRoleRef" -}}
{{- $chartRef := dict
    "apiGroup" "rbac.authorization.k8s.io"
    "kind" "Role"
    "name" (include "traefik.fullname" .)
-}}
{{- $userRef := (.Values.roleBinding | default dict).roleRef | default dict -}}
{{- include "traefik.strategicMerge" (dict "base" $chartRef "patch" $userRef) -}}
{{- end -}}

{{/*
ClusterRoleBinding subjects — user array replaces chart default.
*/}}
{{- define "traefik.clusterRoleBindingSubjects" -}}
{{- with (.Values.clusterRoleBinding | default dict).subjects -}}
{{- toYaml . -}}
{{- else -}}
{{- include "traefik.rbacDefaultSubjects" . -}}
{{- end -}}
{{- end -}}

{{/*
RoleBinding subjects — user array replaces chart default.
*/}}
{{- define "traefik.roleBindingSubjects" -}}
{{- with (.Values.roleBinding | default dict).subjects -}}
{{- toYaml . -}}
{{- else -}}
{{- include "traefik.rbacDefaultSubjects" . -}}
{{- end -}}
{{- end -}}
