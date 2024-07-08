.PHONY: lint test

IMAGE_CHART_TESTING=quay.io/helmpack/chart-testing:v3.11.0
IMAGE_HELM_CHANGELOG=ghcr.io/traefik/helm-changelog:v0.3.0
IMAGE_HELM_DOCS=jnorwood/helm-docs:v1.14.2
IMAGE_HELM_UNITTEST=docker.io/helmunittest/helm-unittest:3.15.2-0.5.1

traefik/tests/__snapshot__:
	@mkdir traefik/tests/__snapshot__

test: traefik/tests/__snapshot__
	docker run ${DOCKER_ARGS} --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts $(IMAGE_HELM_UNITTEST) /charts/hack/test.sh

lint:
	docker run ${DOCKER_ARGS} --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh lint

docs:
	docker run --rm -v "$(CURDIR):/helm-docs" $(IMAGE_HELM_DOCS) -o VALUES.md

test-install:
	docker run ${DOCKER_ARGS} --network=host --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -v $(HOME)/.kube:/root/.kube -w /charts $(IMAGE_CHART_TESTING) /charts/hack/ct.sh install

changelog:
	@echo "== Updating Changelogs..."
	@docker run -it --rm -v $(CURDIR):/data $(IMAGE_HELM_CHANGELOG)
	@./hack/changelog.sh
	@echo "== Updating finished"
