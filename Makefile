
DIST_DIR ?= $(CURDIR)/dist
CHART_DIR ?= $(CURDIR)/traefik
TMPDIR ?= /tmp
HELM_REPO ?= $(CURDIR)/repo
LINT_USE_DOCKER ?= true
LINT_CMD ?= ct lint --config=ct.yaml
################################## Functionnal targets

# Default Target: run all
all: clean lint build deploy

# Ensure the Helm chart, YAMLs and metadatas are valid

ifeq ($(LINT_USE_DOCKER),true)
lint: docker
else
lint: helm ct
endif
	@echo "== Linting Chart..."
	@git remote add traefik https://github.com/containous/traefik-helm-chart >/dev/null 2>&1 || true
	@git fetch traefik master >/dev/null 2>&1 || true
ifeq ($(LINT_USE_DOCKER),true)
	@docker run --rm -t -v $(CURDIR):/charts -w /charts/test quay.io/helmpack/chart-testing:v3.0.0-beta.1 $(LINT_CMD)
else
	cd $(CURDIR)/test && $(LINT_CMD)
endif
	@echo "== Linting Finished"

# Generates an artefact containing the Helm Chart in the distribution directory
build: helm $(DIST_DIR)
	@echo "== Building Chart..."
	@helm package $(CHART_DIR) --destination=$(DIST_DIR)
	@echo "== Building Finished"

# Prepare the Helm repository with the latest packaged charts
deploy: build $(DIST_DIR) $(HELM_REPO)
	@echo "== Deploying Chart..."
	@cp $(DIST_DIR)/*tgz $(HELM_REPO)/
	@helm repo index $(HELM_REPO)
	@echo "== Deploying Finished"

# Cleanup leftovers and distribution dir
clean:
	@echo "== Cleaning..."
	@rm -rf $(DIST_DIR)
	@echo "== Cleaning Finished"
	
################################## Technical targets

$(DIST_DIR):
	@mkdir -p $(DIST_DIR)


## This directory is git-ignored for now, 
## and should become a worktree on the branch gh-pages in the future
$(HELM_REPO):
	@mkdir -p $(HELM_REPO)

helm:
	@echo "== Checking that helm is available..."
	@command -v helm >/dev/null || ( echo "ERROR: Helm binary not found. Exiting." && exit 1)
	@echo "== helm is ready"

docker:
	@echo "== Checking that docker is available..."
	@command -v docker >/dev/null || ( echo "ERROR: Docker binary not found. Exiting." && exit 1)
	@docker info >/dev/null || ( echo "ERROR: command "docker info" is in error. Exiting." && exit 1)
	@echo "== Docker is ready"

ct:
	@echo "== Checking that ct is available..."
	@command -v helm >/dev/null || ( echo "ERROR: Helm binary not found. Exiting." && exit 1)
	@echo "== ct is ready"


.PHONY: all helm lint build deploy clean docker ct
