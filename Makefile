DOCKER?=docker

# Base directories
BASE_BUILD_DIR := $(CURDIR)/build
REPRODUCIBLE_BUILD_DIR := $(CURDIR)/reproducible-build
REVISION?=$(shell git rev-parse HEAD)

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: image-base
image-base: prepare-dirs ### Build a TDX general purpose base image, by default outputs to reproducile-build/artifacts-base
	$(DOCKER) build -t yocto-builder:base \
		--build-arg MANIFEST=tdx-base.xml \
		--build-arg REVISION=$(REVISION) \
		--build-arg ENTROPY_TSS_BINARY_URI=$(ENTROPY_TSS_BINARY_URI) \
		--build-arg GITHUB_TOKEN=$(GITHUB_TOKEN) \
		$(REPRODUCIBLE_BUILD_DIR)
	$(DOCKER) run --rm --env-file yocto-build-config.env \
		-v $(REPRODUCIBLE_BUILD_DIR)/artifacts-base:/artifacts \
		-v $(BASE_BUILD_DIR)/base:/build \
		yocto-builder:base
	chmod 0755 $(BASE_BUILD_DIR)/base $(REPRODUCIBLE_BUILD_DIR)/artifacts-base

.PHONY: measurements-base
measurements-base: measurements-image image-base ### Generates measurements for base image. The measurements can be found in reproducible-build/artifacts-base/measurement-<image>.json.
	chmod 0777 $(REPRODUCIBLE_BUILD_DIR)/artifacts-base
	$(DOCKER) run --rm \
		-v $(REPRODUCIBLE_BUILD_DIR)/artifacts-base:/artifacts \
		-v $(BASE_BUILD_DIR)/base:/build \
		yocto-measurements:latest
	chmod 0755 $(REPRODUCIBLE_BUILD_DIR)/artifacts-base

.PHONY: measurements-image
measurements-image: ### Internal target preparing measurements image
	$(DOCKER) build -t yocto-measurements:latest -f reproducible-build/measurements.Dockerfile $(REPRODUCIBLE_BUILD_DIR)

.PHONY: prepare-dirs
prepare-dirs: ### Internal target preparing artifact directories
	mkdir -p $(BASE_BUILD_DIR)/base
	mkdir -p $(REPRODUCIBLE_BUILD_DIR)/artifacts-base
	chmod 0777 $(BASE_BUILD_DIR)/base \
		$(REPRODUCIBLE_BUILD_DIR)/artifacts-base

.PHONY: clean
clean: ### Remove build cache and artifacts
	rm -rf $(BASE_BUILD_DIR) $(REPRODUCIBLE_BUILD_DIR)/artifacts-*
