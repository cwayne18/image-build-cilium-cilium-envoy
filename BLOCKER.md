# BLOCKER: cilium-envoy cannot be source-built on standard CI

`cilium-envoy` is a Bazel-built C++ fork of Envoy Proxy
(upstream: [github.com/cilium/proxy](https://github.com/cilium/proxy),
pinned to `v1.36.6-1778235340-b87d1e32f522b33bd51701c6476d199326f01496`,
which tracks `envoy-1.37.5`).

## Why it's blocked

- The upstream build uses `make bazel-bin/cilium-envoy` inside the
  `quay.io/cilium/cilium-envoy-builder` image (a large LLVM/Clang C++ toolchain).
- Bazel is invoked with `--jobs=HOST_CPUS*.5` plus a large `--disk_cache`.
- Compiling the Envoy fork from source needs **tens of GB of RAM and disk and
  multiple hours** of build time.
- GitHub-hosted `ubuntu-latest` runners provide ~4 vCPU / 16 GB RAM / ~14 GB
  free disk with a 6-hour job cap — insufficient. Cilium's own CI uses large
  self-hosted runners and a remote Bazel cache.

## Options to unblock (need a decision)

1. **Self-hosted / large runner** — point `release.yml` at a runner with
   enough CPU/RAM/disk (and ideally `BAZEL_REMOTE_CACHE`). The `Dockerfile`
   here already reflects the source-build approach.
2. **Repackage/mirror** — instead of source-building, re-tag the upstream
   `quay.io/cilium/cilium-envoy:<ver>` image under `ghcr.io/cwayne18/hardened-cilium-cilium-envoy`
   (fast, but not a from-source hardened rebuild).
3. **Hardened builder base** — port the build onto a rancher/SLE-based C++
   toolchain image (substantial effort).

`build.yml` is `workflow_dispatch`-only in this repo so it does not auto-fail
on every push. Nothing here pushes to Docker Hub; releases target
`ghcr.io/cwayne18` only.
