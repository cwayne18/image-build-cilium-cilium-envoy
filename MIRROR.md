# ⚠️ MIRRORED UPSTREAM IMAGE (not yet source-hardened)

The published `ghcr.io/cwayne18/hardened-cilium-cilium-envoy` image is currently a
**manifest-preserving mirror of the upstream image**, produced by
[`.github/workflows/mirror.yml`](./.github/workflows/mirror.yml):

| | |
|---|---|
| **Source** | `quay.io/cilium/cilium-envoy:v1.36.6-1778235340-b87d1e32f522b33bd51701c6476d199326f01496` |
| **Target** | `ghcr.io/cwayne18/hardened-cilium-cilium-envoy:v1.36.6-1778235340-b87d1e32f522b33bd51701c6476d199326f01496` |
| **Method** | `docker buildx imagetools create` (preserves the full multi-arch manifest: `linux/amd64` + `linux/arm64`) |

## Why this is a mirror, not a from-source hardened build

`cilium-envoy` is a Bazel-built C++ fork of Envoy Proxy. A from-source hardened rebuild
needs tens of GB of RAM/disk and multiple hours, which exceeds GitHub-hosted runner limits
(see [BLOCKER.md](./BLOCKER.md)). Per maintainer decision, the image is mirrored from
upstream so the `rke2-cilium` PRIME chart can resolve it under `ghcr.io/cwayne18`, pending a
real source-hardened build.

## What this means

- The bits are **identical to upstream** `quay.io/cilium/cilium-envoy` — no additional
  hardening, minimization, or FIPS/BoringCrypto rebuild has been applied yet.
- The `Dockerfile`, `Makefile`, and `release.yml` in this repo describe the eventual
  **from-source** hardened build; they are not what currently publishes the image.
- Nothing here pushes to Docker Hub — GHCR only.

To re-run the mirror: **Actions → Mirror upstream image → Run workflow**.
