.PHONY: lint test

traefik/tests/__snapshot__:
	@mkdir traefik/tests/__snapshot__

test: traefik/tests/__snapshot__
	docker run ${DOCKER_ARGS} --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts helmunittest/helm-unittest:3.11.2-0.3.1 /charts/hack/test.sh

lint:
	docker run ${DOCKER_ARGS} --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts quay.io/helmpack/chart-testing:v3.7.1 /charts/hack/lint.sh

docs:
	docker run --rm -v "$(CURDIR):/helm-docs" jnorwood/helm-docs:latest
	mv "$(CURDIR)/traefik/README.md" "$(CURDIR)/traefik/VALUES.md"

changelog:
	@echo "== Updating Changelogs..."
	@docker run -it --rm -v $(CURDIR):/data ghcr.io/mloiseleur/helm-changelog:v0.0.2
	@./hack/changelog.sh
	@echo "== Updating finished"
