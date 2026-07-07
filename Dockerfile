# syntax=docker/dockerfile:1
#
# Hardened build for cilium-envoy (github.com/cilium/proxy).
#
# !!! KNOWN BLOCKER — see BLOCKER.md !!!
# cilium-envoy is a Bazel-built C++ fork of Envoy. A from-source build:
#   * requires the upstream builder image quay.io/cilium/cilium-envoy-builder
#     (LLVM/Clang C++ toolchain, ~several GB),
#   * uses bazel with `--jobs=HOST_CPUS*.5` and a large disk cache,
#   * needs tens of GB of RAM/disk and multiple hours to compile Envoy.
# This does NOT fit on standard GitHub-hosted runners (4 vCPU / 16 GB RAM /
# ~14 GB disk / 6h job cap). Cilium's own CI uses large self-hosted runners
# and a remote Bazel cache.
#
# The stage below reflects the intended source-build approach and is retained
# so the repo can be wired to a self-hosted/large runner (or a Bazel remote
# cache) later. It will NOT complete on a default GitHub runner.

ARG BUILDER_BASE=quay.io/cilium/cilium-envoy-builder:6.1.0-latest
ARG BCI_IMAGE=registry.suse.com/bci/bci-base:15.7

FROM --platform=$BUILDPLATFORM ${BUILDER_BASE} AS builder
WORKDIR /cilium/proxy
ARG PKG
ARG TAG
ARG TARGETARCH
ENV TARGETARCH=$TARGETARCH
RUN git clone --depth=1 https://${PKG}.git /cilium/proxy && \
    git fetch --all --tags --prune && git checkout tags/${TAG} -b ${TAG} || true
# Heavy: builds the Envoy fork from source with Bazel. Requires a large runner.
RUN BAZEL_BUILD_OPTS="--disk_cache=/tmp/bazel-cache" PKG_BUILD=1 DESTDIR=/tmp/install \
        make bazel-bin/cilium-envoy-starter bazel-bin/cilium-envoy

# Hardened runtime stage on a minimal SLE BCI base.
FROM ${BCI_IMAGE} AS hardened-cilium-cilium-envoy
LABEL org.opencontainers.image.description="Cilium Envoy (hardened) — see BLOCKER.md"
COPY --from=builder /cilium/proxy/bazel-bin/cilium-envoy /usr/bin/cilium-envoy
COPY --from=builder /cilium/proxy/bazel-bin/cilium-envoy-starter /usr/bin/cilium-envoy-starter
ENTRYPOINT ["/usr/bin/cilium-envoy-starter"]
