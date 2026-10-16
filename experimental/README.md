# Traefik chart — experimental

> ⚠️ **EXPERIMENTAL — do NOT use in production.** This is a from-scratch redesign of the
> Traefik Helm chart (a *simplification proposal*). It is **unreleased**, **unsupported**,
> and may change or break at any time. **Use entirely at your own risk.**

## What this is

A leaner Traefik chart built on a different philosophy than the stable `traefik` chart:

- **Traefik config is verbatim.** Everything Traefik itself understands (`entryPoints`,
  `providers`, `api`, `metrics`, `log`, `accessLog`, `tracing`, `certificatesResolvers`,
  `hub`, …) goes **unchanged** under the top-level `traefik:` block — copy-paste straight
  from the [Traefik reference](https://doc.traefik.io/traefik/).
- **The workload is a real PodSpec.** Pod-level settings live under
  `deployment.spec.template.spec.*`, container-level under
  `deployment.spec.template.spec.containers.0.*` — merged onto the `traefik` container **by name**,
  so `containers.0` is the merge anchor, not a positional guarantee.
- **Schema-validated, with editor help.** The chart ships a `values.schema.json` (wired to the
  upstream Kubernetes OpenAPI for the PodSpec fields), so `helm` rejects malformed values and
  editors autocomplete the real Kubernetes surface; the `traefik:` block stays open so any valid
  Traefik config passes through.
- **Presence enables, `null` disables.** Optional objects (`autoscaling`, `persistence`,
  `ingressClass`, and the `service.*` / `secret.*` / `ingressRoute.*` map entries) are switched
  on by being present and off by being set to `null` — deliberately mirroring Traefik's own config,
  where a feature is enabled by the presence of its key (`api: {}`, `metrics.prometheus: {}`, …).
  There is no `enabled:` flag.
- **`null` also deletes a chart default** under strategic merge — e.g. `deployment.spec.replicas: null`
  drops the chart's default replica count so an HPA can own it.
- **Services and Secrets are name-keyed maps**; a **DaemonSet** is `deployment: null` + `daemonset: {}`.

See [`EXAMPLES.md`](./EXAMPLES.md) for recipes, and `values.yaml` for the full surface.

## Feedback wanted

This design only proves itself in real use. Please install it, push your actual Traefik config
and workload tuning through it, and open an issue with where the verbatim/PodSpec model helps or
gets in the way — that feedback is the whole point of shipping it as experimental.

## Install (no release — install from source)

There is no published release. Clone the repository and install the chart from this directory:

```sh
git clone https://github.com/traefik/traefik-helm-chart
cd traefik-helm-chart
helm install traefik ./experimental
# with your own values:
helm install traefik ./experimental -f my-values.yaml
```

## Develop

```sh
cd experimental
make test       # run the helm-unittest suite
make lint       # helm lint
make template   # render with defaults (sanity)
make schema     # regenerate values.schema.json (k8s OpenAPI) — rerun after adding/renaming a PodSpec/Service/etc. field
```

## Demo

A staged, end-to-end walkthrough lives in [`demo/`](./demo/): install the
chart, then `helm upgrade -f demo/0N-*.yaml` step by step through scaling → Gateway
API → extra config → Traefik Hub → API management. See [`demo/README.md`](./demo/README.md).

## Template layout

Helper partials follow a two-prefix naming convention:

- **`_lib_*.tpl`** — generic, pure functions with no chart knowledge (no `.Values`/`.Chart`):
  `_lib_merge.tpl` (strategic-merge engine), `_lib_units.tpl` (k8s quantity → bytes),
  `_lib_semver.tpl` (version predicates). Reusable as-is.
- **`_helpers_*.tpl`** — domain helpers that render or resolve chart-specific things, named after
  the concern/consumer they serve: `_helpers_workload.tpl` (deployment/daemonset),
  `_helpers_configmap.tpl` (Traefik config), `_helpers_image.tpl` (image + version resolution),
  `_helpers_rbac.tpl`, `_helpers_hub.tpl`, `_helpers_notes.tpl`, etc. The cross-cutting
  `_helpers_chart.tpl` (naming), `_helpers_meta.tpl` and `_helpers_labels.tpl` are used by every
  manifest, so they stay shared rather than mapping to one file.

When adding a helper: a pure function goes in `_lib_`; anything reading `.Values`/`.Chart` goes in
the `_helpers_` file matching where it's used.

## values.schema.json

The schema is **generated**, not hand-written: `make schema` (see [`hack/build_schema.py`](./hack/build_schema.py))
runs `helm schema` over the `# @schema` annotations in `values.yaml`, then injects the upstream
**Kubernetes OpenAPI** (`$ref`s for `deployment.spec`, `service.*.spec`, RBAC, HPA, PDB, …) so the
chart-managed surface validates against the real Kubernetes types. The `traefik:` block is left open
(`additionalProperties: true`) so any valid Traefik config passes; wiring an official Traefik
static-config schema there is a planned follow-up — ideally with the Traefik Proxy/Hub teams — once a
version-pinned public schema is available. Rerun `make schema` after changing a field.

## CRDs

The chart bundles the Traefik and Traefik Hub CRDs in [`crds/`](./crds/). Per Helm's CRD handling they are
**installed once and never upgraded or deleted** by `helm upgrade`/`uninstall` (same limitation as the stable
chart) — manage CRD upgrades out of band. They are a copy of the stable chart's CRDs; `make crds-sync`
(also run in CI) fails if they drift from `traefik/crds/`, so a stable-chart CRD change must be mirrored here.
