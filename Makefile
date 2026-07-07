SEVERITIES = HIGH,CRITICAL

UNAME_M = $(shell uname -m)
ifndef TARGET_PLATFORMS
	ifeq ($(UNAME_M), x86_64)
		TARGET_PLATFORMS:=linux/amd64
	else ifeq ($(UNAME_M), aarch64)
		TARGET_PLATFORMS:=linux/arm64
	else
		TARGET_PLATFORMS:=linux/$(UNAME_M)
	endif
endif

REPO ?= ghcr.io/cwayne18
PKG ?= github.com/cilium/proxy
BUILD_META=-build$(shell date +%Y%m%d)
TAG ?= ${GITHUB_ACTION_TAG}

ifeq ($(TAG),)
TAG := v1.36.6-1778235340-b87d1e32f522b33bd51701c6476d199326f01496$(BUILD_META)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG $(TAG) needs to end with build metadata: $(BUILD_META))
endif

.PHONY: build-image
build-image: IMAGE = $(REPO)/hardened-cilium-cilium-envoy:$(TAG)
build-image:
	docker buildx build \
		--platform=$(TARGET_PLATFORMS) \
		--build-arg PKG=$(PKG) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--tag $(IMAGE) \
		--load \
	.

.PHONY: push-image
push-image: IMAGE = $(REPO)/hardened-cilium-cilium-envoy:$(TAG)
push-image:
	docker buildx build \
		$(IID_FILE_FLAG) \
		--sbom=true \
		--attest type=provenance,mode=max \
		--platform=$(TARGET_PLATFORMS) \
		--build-arg PKG=$(PKG) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--tag $(IMAGE) \
		--push \
		.

.PHONY: build-image-all
build-image-all: build-image

.PHONY: push-image-all
push-image-all: push-image

.PHONY: image-scan
image-scan:
	trivy image --severity $(SEVERITIES) --no-progress --ignore-unfixed $(REPO)/hardened-cilium-cilium-envoy:$(TAG)

.PHONY: log
log:
	@echo "TARGET_PLATFORMS=$(TARGET_PLATFORMS)"
	@echo "REPO=$(REPO)"
	@echo "PKG=$(PKG)"
	@echo "TAG=$(TAG:$(BUILD_META)=)"
	@echo "BUILD_META=$(BUILD_META)"
	@echo "UNAME_M=$(UNAME_M)"
