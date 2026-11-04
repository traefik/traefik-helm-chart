{{/*
Merge key for a list field, or "" (wholesale replace) for everything else.
Table is GLOBAL / path-blind — a field with one of these names merges by the
given key anywhere; safe only because these names don't collide across the
chart's specs (revisit if that changes). `ports` keys on `name` (not k8s
`containerPort`/`port`): every chart-rendered port has a unique `name`, so a
user can override one port without redeclaring the list; an unnamed port is appended.
Input: field name. Output: merge key, or "".
*/}}
{{- define "traefik.mergeKeyFor" -}}
{{- $table := dict
    "containers" "name"
    "initContainers" "name"
    "volumes" "name"
    "volumeMounts" "mountPath"
    "env" "name"
    "imagePullSecrets" "name"
    "ports" "name"
-}}
{{- index $table . | default "" -}}
{{- end -}}

{{/*
Strategic Merge Patch (k8s-style) — the chart's single merge for every object
hatch (metadata, spec, roleRef, …). Input: dict "base"/"patch". Output: merged YAML.
Rules: objects deep-merge key-by-key (`key: null` deletes, RFC 7396); lists with
a merge key (traefik.mergeKeyFor) merge element-by-element by that key; lists
without a key and scalars replace; a `{$patch: replace}` element forces wholesale
replace. The `$patch` directive key is never copied into the output.
*/}}
{{- define "traefik.strategicMerge" -}}
{{- $base := deepCopy (.base | default dict) -}}
{{- $patch := .patch | default dict -}}
{{- range $k, $v := $patch -}}
  {{- if eq $k "$patch" -}}
    {{/* directive marker, never an output field */}}
  {{- else if eq (kindOf $v) "invalid" -}}
    {{- $_ := unset $base $k -}}
  {{- else if and (eq (kindOf $v) "map") (hasKey $base $k) (eq (kindOf (index $base $k)) "map") -}}
    {{- $merged := include "traefik.strategicMerge" (dict "base" (index $base $k) "patch" $v) | fromYaml -}}
    {{- if hasKey $merged "Error" -}}{{- fail (printf "strategicMerge %q: %v" $k (index $merged "Error")) -}}{{- end -}}
    {{- $_ := set $base $k $merged -}}
  {{- else if and (eq (kindOf $v) "slice") (hasKey $base $k) (eq (kindOf (index $base $k)) "slice") (ne (include "traefik.mergeKeyFor" $k) "") -}}
    {{- $merged := include "traefik.strategicMergeList" (dict "key" (include "traefik.mergeKeyFor" $k) "base" (index $base $k) "patch" $v) | fromYamlArray -}}
    {{- $_ := set $base $k $merged -}}
  {{- else -}}
    {{- $_ := set $base $k $v -}}
  {{- end -}}
{{- end -}}
{{- $base | toYaml -}}
{{- end -}}

{{/*
Merge two lists of objects by a key. Input: dict "key"/"base"/"patch". Output: YAML list.
A patch element with a matching key value merges into the base element (recursively);
a new key value is appended (base order first); a `{$patch: replace}` element forces
wholesale replace (directive elements dropped from the result).
*/}}
{{- define "traefik.strategicMergeList" -}}
{{- $key := .key -}}
{{- $base := .base -}}
{{- $patch := .patch -}}
{{- $replace := false -}}
{{- range $e := $patch -}}
  {{- if and (eq (kindOf $e) "map") (eq (index $e "$patch") "replace") -}}{{- $replace = true -}}{{- end -}}
{{- end -}}
{{- if $replace -}}
  {{- $out := list -}}
  {{- range $e := $patch -}}
    {{- if not (and (eq (kindOf $e) "map") (hasKey $e "$patch")) -}}{{- $out = append $out $e -}}{{- end -}}
  {{- end -}}
  {{- $out | toYaml -}}
{{- else -}}
  {{- $byKey := dict -}}
  {{- $appends := list -}}
  {{- range $e := $patch -}}
    {{- if and (eq (kindOf $e) "map") (hasKey $e $key) -}}
      {{- $_ := set $byKey (index $e $key | toString) $e -}}
    {{- else -}}
      {{- $appends = append $appends $e -}}
    {{- end -}}
  {{- end -}}
  {{- $result := list -}}
  {{- $consumed := dict -}}
  {{- range $b := $base -}}
    {{- $bk := "" -}}
    {{- if and (eq (kindOf $b) "map") (hasKey $b $key) -}}{{- $bk = index $b $key | toString -}}{{- end -}}
    {{- if and (ne $bk "") (hasKey $byKey $bk) -}}
      {{- $m := include "traefik.strategicMerge" (dict "base" $b "patch" (index $byKey $bk)) | fromYaml -}}
      {{- if hasKey $m "Error" -}}{{- fail (printf "strategicMergeList %q: %v" $key (index $m "Error")) -}}{{- end -}}
      {{- $result = append $result $m -}}
      {{- $_ := set $consumed $bk true -}}
    {{- else -}}
      {{- $result = append $result $b -}}
    {{- end -}}
  {{- end -}}
  {{- range $e := $patch -}}
    {{- if and (eq (kindOf $e) "map") (hasKey $e $key) -}}
      {{- $ek := index $e $key | toString -}}
      {{- if not (hasKey $consumed $ek) -}}{{- $result = append $result $e -}}{{- end -}}
    {{- end -}}
  {{- end -}}
  {{- range $a := $appends -}}{{- $result = append $result $a -}}{{- end -}}
  {{- $result | toYaml -}}
{{- end -}}
{{- end -}}
