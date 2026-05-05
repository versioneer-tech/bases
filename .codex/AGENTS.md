---
agent: codex
type: helm, oci
disclaimer: never ever change this frontmatter header - only edit content below
---

## Explicit Permission First

- Do not commit or push to any git repository unless the user explicitly asks for it.
- The user has approved read/query access to the `k` Kubernetes cluster via `config-k` for this repo. Always check and state the active kubecontext before any cluster operation.
- Prefer read-only Kubernetes commands while comparing desired and live state. Ask before applying, deleting, restarting, or otherwise mutating cluster resources.
- If the user provides a new general repo rule or policy, ask whether it should be added to `.codex/AGENTS.md`.
- Record durable repo-specific learnings in `.codex/LOGBOOK.md`.

## Repo Policies

- This repo packages Kustomize bases as OCI artifacts for Flux consumption. Component folders currently include `csi-rclone/` and `educates/`.
- Component manifests should match the desired versions used by the `k` cluster GitOps repo at `~/github/versioneer-inc/flux-k`. The user has approved read-only traversal of that repo for comparisons.
- This repo is the source of truth for generating the reusable Educates base. Do not keep Educates generation owned by `~/github/versioneer-inc/flux-k`; that repo should consume and patch the published base for the `k` cluster.
- Educates manifests are generated with `./scripts/generate-educates.sh` from `educates/default/educates-config.yaml`. If the user updates the local `educates` CLI to a new target version such as `3.7.1`, regenerate the base here and review the manifest/CRD diff before publishing or changing Flux consumers.
- When an Educates base update requires a user-side local CLI update, explicitly remind the user to perform that update before regenerating. The user owns local Educates CLI version changes.
- Keep component pins explicit and reproducible. Avoid `latest`, mutable tags, or prerelease versions unless the user explicitly asks for them.
- When changing vendored component manifests, update the matching base/overlay files together and verify with `kustomize build` or `kubectl kustomize` for each affected overlay.
- Preserve Flux substitution placeholders such as `${NAMESPACE}`, `${CLUSTER_INGRESS_DOMAIN}`, and `${KUBELET_PATH}` unless changing the consuming contract intentionally.
- Publish OCI artifacts only when explicitly asked. Local dry-runs are fine for validation.
