.PHONY: lint test

test:
	docker run ${DOCKER_ARGS} --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts quintush/helm-unittest:3.10.1-0.2.10 /charts/hack/test.sh

lint:
	docker run ${DOCKER_ARGS} --env GIT_SAFE_DIR="true" --entrypoint /bin/sh --rm -v $(CURDIR):/charts -w /charts quay.io/helmpack/chart-testing:v3.7.1 /charts/hack/lint.sh

changelog:
	@echo "== Updating Changelogs..."
	@docker run -it --rm -v $(CURDIR):/data mogensen/helm-changelog:latest
	@./hack/changelog.sh
	@echo "== Updating finished"
