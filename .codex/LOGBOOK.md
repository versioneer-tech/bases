# Repo Learnings

- `~/github/versioneer-inc/flux-k` is the GitOps repo for the `k` cluster. It consumes `csi-rclone` from `oci://ghcr.io/versioneer-tech/bases` with tag `csi-rclone-1fd2fe4770ce`, and currently keeps Educates as generated manifests under `workspace/educates-generated`.
- Kubernetes access for this repo is through `/home/achtsnits/.kube/config-k`; check the current context first. On 2026-05-05 it was `k`.
- Educates base manifests are generated in this repo with `./scripts/generate-educates.sh` from `educates/default/educates-config.yaml`. The local `educates` CLI was updated to 3.7.1 on 2026-05-05 and regenerated `educates/default/manifest.yaml`; `educates/default/crd.yaml` had no diff.
