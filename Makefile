## Workflow for "building" the Helm chart
DIST_DIR ?= $(CURDIR)/dist
SHIM_DIR ?= $(TMPDIR)/traefik

all: lint build #test deploy # Future targets

lint: helm $(SHIM_DIR)
	@helm lint $(TMPDIR)/traefik

build: helm $(DIST_DIR) $(SHIM_DIR)
	@helm package $(SHIM_DIR) --destination=$(DIST_DIR)

$(DIST_DIR):
	@mkdir -p $(DIST_DIR)

helm:
	@command -v helm >/dev/null || ( echo "ERROR: Helm binary not found. Exiting." && exit 1)

# This target is phony to ensure there is no conflict with other dir named "traefik"
$(SHIM_DIR):
	@## Helm v2 require directory to have the same name as the chart
	@unlink $(SHIM_DIR) || ( echo "ERROR: $(SHIM_DIR) already exists. Exiting." && exit 1)
	@ln -s $(CURDIR) $(SHIM_DIR) || ( echo "ERROR: cannot link $(CURDIR) to $(SHIM_DIR). Exiting." && exit 1)

.PHONY: all helm lint build $(SHIM_DIR)
