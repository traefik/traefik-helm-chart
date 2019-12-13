
DIST_DIR ?= $(CURDIR)/dist
TMPDIR ?= /tmp
SHIM_DIR ?= $(TMPDIR)/traefik
HELM_REPO ?= $(CURDIR)/repo

################################## Functionnal targets

# Default Target: run all
all: clean lint build deploy

# Ensure the Helm chart and its metadata are valid
lint: helm $(SHIM_DIR)
	@echo "== Linting Chart..."
	@helm lint $(SHIM_DIR)
	@echo "== Linting Finished"

# Generates an artefact containing the Helm Chart in the distribution directory
build: helm $(DIST_DIR) $(SHIM_DIR)
	@echo "== Building Chart..."
	@helm package $(SHIM_DIR) --destination=$(DIST_DIR)
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
	@unlink $(SHIM_DIR) >/dev/null 2>&1 || true
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

# This target is phony to ensure there is no conflict with other dir named "traefik"
$(SHIM_DIR):
	@## Helm v2 require directory to have the same name as the chart
	@[ -L $(SHIM_DIR) ] && unlink $(SHIM_DIR) || true
	@ln -s $(CURDIR) $(SHIM_DIR) || ( echo "ERROR: cannot link $(CURDIR) to $(SHIM_DIR). Exiting." && exit 1)

.PHONY: all helm lint build deploy clean $(SHIM_DIR)
