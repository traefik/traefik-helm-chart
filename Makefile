.PHONY: lint test

IMAGE_CHART_TESTING=quay.io/helmpack/chart-testing:v3.14.0
IMAGE_HELM_CHANGELOG=ghcr.io/traefik/helm-changelog:v0.3.0
IMAGE_HELM_DOCS=jnorwood/helm-docs:v1.14.2
IMAGE_HELM_UNITTEST=docker.io/helmunittest/helm-unittest:3.19.0-1.0.3

traefik/tests/__snapshot__:
	@mkdir traefik/tests/__snapshot__
	@mkdir traefik-crds/tests/__snapshot__

test: traefik/tests/__snapshot__
	docker run --platform linux/arm64 ${DOCKER_ARGS} --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts $(IMAGE_HELM_UNITTEST) /charts/hack/test.sh

test-ns:
	./hack/check-ns.sh

test-crds-consistency:
	./hack/check-crds-consistency.sh

lint:
	docker run ${DOCKER_ARGS} --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh lint

docs:
	docker run --rm -v "$(CURDIR):/helm-docs" $(IMAGE_HELM_DOCS) -o VALUES.md

test-%:
	docker run ${DOCKER_ARGS} --network=host --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -v $(HOME)/.kube:/root/.kube -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh $*

# Requires to install schema generation plugin beforehand
# $ helm plugin install https://github.com/losisin/helm-values-schema-json.git
schema:
	cd traefik && helm schema --use-helm-docs
	cd traefik-crds && helm schema

changelog:
	@echo "== Updating Changelogs..."
	@docker run -it --rm -v $(CURDIR):/data $(IMAGE_HELM_CHANGELOG)
	@./hack/changelog.sh
	@echo "== Updating finished"


helm upgrade --install --dry-run --namespace traefik traefik ./traefik \
  --set hub.token=traefik-hub-license
  --set hub.apimanagement.enabled=true \
  --set hub.platformUrl=https://api-preview.hub.traefik.io/agent --set image.registry=europe-west9-docker.pkg.dev/traefiklabs --set image.repository=traefik-hub/traefik-hub --set image.tag=latest-v3 --set image.pullPolicy=Always