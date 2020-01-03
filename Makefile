
DIST_DIR ?= $(CURDIR)/dist
CHART_DIR ?= $(CURDIR)/traefik
TMPDIR ?= /tmp
HELM_REPO ?= $(CURDIR)/repo

################################## Functionnal targets

# Default Target: run all
all: clean lint build deploy

# Ensure the Helm chart and its metadata are valid
lint: helm
	@echo "== Linting Chart..."
	@docker run --rm -ti -v $(CURDIR):/charts -w /charts quay.io/helmpack/chart-testing:v3.0.0-beta.1 \
		ct lint --chart-dirs=$(CURDIR) --debug
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
	@command -v helm >/dev/null || ( echo "ERROR: Helm binary not found. Exiting." && exit 1)
	@helm init --client-only

.PHONY: all helm lint build deploy clean
