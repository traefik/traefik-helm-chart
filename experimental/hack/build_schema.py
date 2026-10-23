#!/usr/bin/env python3
#
# Build values.schema.json in two passes:
#   1. `helm schema` emits the chart surface from `# @schema` annotations.
#   2. This script inlines the Kubernetes OpenAPI as `definitions` and $refs
#      them onto every chart-rendered metadata/spec field.
#
# `required` is stripped and every field made nullable: chart specs are partial
# JSON Merge Patches, so upstream's required clauses would reject valid input.
#
# Inputs:  K8S_VERSION (default v1.32.0), CHART_DIR (default ".").
# Output:  <CHART_DIR>/values.schema.json.
#
import json
import os
import subprocess
import sys
import urllib.request

K8S_VERSION = os.environ.get("K8S_VERSION", "v1.32.0")
K8S_BASE = (
    "https://raw.githubusercontent.com/kubernetes/kubernetes/"
    f"refs/tags/{K8S_VERSION}/api/openapi-spec/v3"
)
K8S_FILES = [
    "apis__apps__v1_openapi.json",
    "api__v1_openapi.json",
    "apis__rbac.authorization.k8s.io__v1_openapi.json",
    "apis__admissionregistration.k8s.io__v1_openapi.json",
    "apis__policy__v1_openapi.json",
    "apis__networking.k8s.io__v1_openapi.json",
    "apis__autoscaling__v2_openapi.json",
]

CHART_DIR = os.environ.get("CHART_DIR", ".")
OUT = os.path.join(CHART_DIR, "values.schema.json")


def log(msg):
    print(msg, flush=True)


def ref(name):
    return {"$ref": f"#/definitions/{name}"}


# $ref fragments reused across the field-path injection below. Shared object
# references are fine: json.dump serializes each occurrence as an independent
# copy, and nothing mutates them after injection.
META = ref("io.k8s.apimachinery.pkg.apis.meta.v1.ObjectMeta")
RES = ref("io.k8s.api.core.v1.ResourceRequirements")
DEPLOY_SPEC = ref("io.k8s.api.apps.v1.DeploymentSpec")
DAEMON_SPEC = ref("io.k8s.api.apps.v1.DaemonSetSpec")
PDB_SPEC = ref("io.k8s.api.policy.v1.PodDisruptionBudgetSpec")
INGRESSCLASS_SPEC = ref("io.k8s.api.networking.v1.IngressClassSpec")
HPA_SPEC = ref("io.k8s.api.autoscaling.v2.HorizontalPodAutoscalerSpec")
PVC_SPEC = ref("io.k8s.api.core.v1.PersistentVolumeClaimSpec")
LOOSE_SPEC = {"type": "object", "additionalProperties": True}
RULES = {"type": "array", "items": ref("io.k8s.api.rbac.v1.PolicyRule")}
ROLE_REF = ref("io.k8s.api.rbac.v1.RoleRef")
SUBJECTS = {"type": "array", "items": ref("io.k8s.api.rbac.v1.Subject")}
PULL_SECRETS = {"type": "array", "items": ref("io.k8s.api.core.v1.LocalObjectReference")}

# Singleton chart-rendered objects → their metadata/spec/shortcut sub-fields.
SINGLETONS = {
    "deployment": {"resources": RES, "metadata": META, "spec": DEPLOY_SPEC},
    "daemonset": {"resources": RES, "metadata": META, "spec": DAEMON_SPEC},
    "podDisruptionBudget": {"metadata": META, "spec": PDB_SPEC},
    "ingressClass": {"metadata": META, "spec": INGRESSCLASS_SPEC},
    "autoscaling": {"metadata": META, "spec": HPA_SPEC},
    "gatewayClass": {"metadata": META, "spec": LOOSE_SPEC},
    "gateway": {"metadata": META, "spec": LOOSE_SPEC},
    "persistence": {
        "metadata": META,
        "spec": PVC_SPEC,
        "existingClaim": {"type": ["string", "null"]},
        "mountPath": {"type": ["string", "null"]},
        "subPath": {"type": ["string", "null"]},
    },
    "serviceAccount": {"metadata": META},
    "clusterRole": {"metadata": META, "rules": RULES},
    "clusterRoleBinding": {"metadata": META, "roleRef": ROLE_REF, "subjects": SUBJECTS},
    "role": {"metadata": META, "rules": RULES},
    "roleBinding": {"metadata": META, "roleRef": ROLE_REF, "subjects": SUBJECTS},
}

# Schema for each map-of-named-entries: applied to every existing entry and as
# additionalProperties (user-added entries).
SERVICE_ENTRY = {
    "type": ["object", "null"],
    "additionalProperties": False,
    "properties": {"metadata": META, "spec": ref("io.k8s.api.core.v1.ServiceSpec")},
}
INGRESSROUTE_ENTRY = {
    "type": ["object", "null"],
    "additionalProperties": False,
    "properties": {"metadata": META, "spec": {"type": "object", "additionalProperties": True}},
}
MWC_ENTRY = {
    "type": ["object", "null"],
    "additionalProperties": False,
    "properties": {
        "metadata": META,
        "webhooks": {
            "type": "array",
            "items": ref("io.k8s.api.admissionregistration.v1.MutatingWebhook"),
        },
    },
}
SECRET_ENTRY = {  # the chart fills `data`; the user owns metadata
    "type": ["object", "null"],
    "additionalProperties": False,
    "properties": {"metadata": META},
}


def walk(node, f):
    """Post-order traversal mirroring jq's `walk`: transform children, then f."""
    if isinstance(node, dict):
        for k in list(node.keys()):
            node[k] = walk(node[k], f)
        return f(node)
    if isinstance(node, list):
        return f([walk(x, f) for x in node])
    return f(node)


# --- the five definition transforms (one walk each, in this order) --------
def strip_required(n):
    if isinstance(n, dict):
        n.pop("required", None)
    return n


def add_additional_props_false(n):
    # catch unknown fields (typos at depth) at install time
    if isinstance(n, dict) and "properties" in n and "additionalProperties" not in n:
        n["additionalProperties"] = False
    return n


def add_patch_directive(n):
    # `{$patch: replace}` opts a list/object back into wholesale replace
    if isinstance(n, dict) and "properties" in n:
        n["properties"]["$patch"] = {"type": "string", "enum": ["replace"]}
    return n


def make_nullable(n):
    # Merge Patch uses `key: null` to delete, so null is legal at any level
    if isinstance(n, dict) and "type" in n:
        t = n["type"]
        if isinstance(t, str) and t != "null":
            n["type"] = [t, "null"]
        elif isinstance(t, list) and "null" not in t:
            n["type"] = t + ["null"]
    return n


def rewrite_ref(n):
    if isinstance(n, dict) and "$ref" in n:
        n["$ref"] = n["$ref"].replace("#/components/schemas/", "#/definitions/", 1)
    return n


def traefik_open(n):
    # traefik: is a verbatim passthrough — open every object so helm schema's
    # default-inferred closures don't reject valid Traefik config. A real
    # static-config schema goes here once an official, version-pinned one exists.
    if isinstance(n, dict) and n.get("type") in ("object", ["object", "null"]):
        n["additionalProperties"] = True
    return n


def build_definitions():
    log(f"  [2/3] fetching + transforming upstream Kubernetes schemas (k8s {K8S_VERSION})")
    defs = {}
    for name in sorted(K8S_FILES):
        with urllib.request.urlopen(f"{K8S_BASE}/{name}") as resp:
            data = json.load(resp)
        defs.update(data.get("components", {}).get("schemas", {}) or {})
    for transform in (strip_required, add_additional_props_false, add_patch_directive, make_nullable, rewrite_ref):
        defs = walk(defs, transform)
    # Sort by key for a deterministic, environment-independent order.
    return {k: defs[k] for k in sorted(defs)}


def inject_refs(schema, defs):
    log("  [3/3] inlining definitions + injecting $ref at chart-rendered field paths")
    props = schema["properties"]

    schema["definitions"] = defs
    props["traefik"] = walk(props["traefik"], traefik_open)

    # nameOverride: non-null default ("traefik") makes helm schema drop the
    # annotated null; re-assert [string, null].
    props["nameOverride"]["type"] = ["string", "null"]

    props["imagePullSecrets"] = PULL_SECRETS
    # extraObjects: arbitrary user-supplied manifests, tpl-evaluated.
    props["extraObjects"] = {"type": ["array", "null"], "items": {"type": ["object", "string"]}}

    for name, sub in SINGLETONS.items():
        props[name]["properties"] = sub

    # Maps of named entries: entry schema on each existing entry + as additionalProperties.
    def apply_entry(key, entry, with_props=True):
        node = props[key]
        if with_props:
            node["properties"] = {name: entry for name in (node.get("properties") or {})}
        node["additionalProperties"] = entry

    apply_entry("service", SERVICE_ENTRY)
    apply_entry("secret", SECRET_ENTRY)
    apply_entry("ingressRoute", INGRESSROUTE_ENTRY)
    apply_entry("tlsOptions", INGRESSROUTE_ENTRY, with_props=False)
    apply_entry("tlsStore", INGRESSROUTE_ENTRY, with_props=False)
    apply_entry("mutatingWebhookConfigurations", MWC_ENTRY)
    return schema


def main():
    log("  [1/3] generating chart-surface schema from values.yaml @schema annotations")
    subprocess.run(
        ["helm", "schema", "--no-additional-properties"],
        cwd=CHART_DIR,
        check=True,
        stdout=subprocess.DEVNULL,
    )

    with open(OUT, encoding="utf-8") as fh:
        schema = json.load(fh)

    schema = inject_refs(schema, build_definitions())

    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(schema, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    log(f"  done — {OUT} ({os.path.getsize(OUT) // 1024}K)")


if __name__ == "__main__":
    sys.exit(main())
