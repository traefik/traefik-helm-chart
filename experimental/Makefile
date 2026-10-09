HELM ?= helm
CHART := .

.PHONY: help test lint template schema schema-test schema-clean crds-sync
help: ## list targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-10s %s\n",$$1,$$2}'

test: ## run the helm-unittest suite
	$(HELM) unittest $(CHART)

crds-sync: ## fail if crds/ has drifted from the stable chart's traefik/crds/
	./hack/check-crds-sync.sh

lint: ## helm lint
	$(HELM) lint $(CHART)

template: ## render with defaults (sanity check)
	$(HELM) template traefik $(CHART) >/dev/null

schema: ## regenerate values.schema.json (helm schema + k8s OpenAPI; see hack/build_schema.py)
	python3 ./hack/build_schema.py

schema-test: ## unit-test the schema-build transforms
	python3 ./hack/test_build_schema.py

schema-clean:
	rm -f values.schema.json
