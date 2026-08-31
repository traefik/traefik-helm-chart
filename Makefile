.PHONY: lint test snapshots test-changelog check-renovate

IMAGE_CHART_TESTING=quay.io/helmpack/chart-testing:v3.14.0
IMAGE_HELM_CHANGELOG=ghcr.io/traefik/helm-changelog:v1.0.0
IMAGE_HELM_DOCS=jnorwood/helm-docs:v1.14.2

snapshots:
	@mkdir -p hub-manager/tests/__snapshot__
	@mkdir -p traefik/tests/__snapshot__

test: snapshots
	./hack/test.sh

test-ns:
	./hack/check-ns.sh

test-changelog:
	./hack/test-changelog.sh

check-renovate:
	./hack/check-renovate-hints.sh

lint:
	docker run ${DOCKER_ARGS} --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh lint

docs:
	docker run --rm -v "$(CURDIR):/helm-docs" $(IMAGE_HELM_DOCS) -o VALUES.md

# $ helm plugin install https://github.com/helm-unittest/helm-unittest.git
# To launch only one test
# $ helm unittest -f 'tests/oci-config_test.yaml' traefik
test-%:
	docker run ${DOCKER_ARGS} --network=host --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -v $(HOME)/.kube:/root/.kube -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh $*

# Requires to install schema generation plugin beforehand
# $ helm plugin install https://github.com/losisin/helm-values-schema-json.git
schema:
	cd hub-manager && helm schema --use-helm-docs
	cd traefik && helm schema --use-helm-docs

changelog:
	@echo "== Updating Changelogs..."
	@docker run -it --rm -v $(CURDIR):/data $(IMAGE_HELM_CHANGELOG) /app/helm-changelog --update
# helm-changelog rewrites every chart under /data, golden test fixtures included.
	@git checkout -- .github/fixtures
	@./hack/changelog.sh
	@echo "== Updating finished"
