# Kustomize Bases as OCI Artifacts

This repository packages curated Kustomize components as **OCI artifacts** in GHCR using the Flux CLI.  
Each component is published as a versioned, immutable package and can be reconciled directly by Flux.

## Why OCI for Kustomize?

- **Immutable & reproducible** – every tag embeds the commit SHA  
- **Registry-native** – compatible with any OCI registry (e.g., GHCR)  
- **Kustomize-friendly** – artifacts contain the exact files as shipped  
- **GitOps-ready** – consumed by Flux via `OCIRepository` + `Kustomization`  
- **Efficient CI** – only changed components are published per commit

## Currently vendored components

- `csi-rclone`
- `educates`

### Repository layout

Each component folder represents a deployable **Kustomize base**, optionally containing one or more **overlays**:

```
csi-rclone/
  default/
    kustomization.yaml # needs ${NAMESPACE}
    manifest.yaml
  custom-kubelet/
    kustomization.yaml # needs ${NAMESPACE} ${KUBELET_PATH}
educates/
  default/
    kustomization.yaml # needs ${NAMESPACE} ${CLUSTER_INGRESS_DOMAIN} ${CLUSTER_INGRESS_CLASS} ${TLS_CERTIFICATE_REF_NAMESPACE} ${TLS_CERTIFICATE_REF_NAME}
```

Each `kustomization.yaml` defines a shared label to identify its component:

For example:

```yaml
commonLabels:
  bases.internal: csi-rclone
```

## Consuming with Flux (**substitute** method)

Each overlay uses placeholders like **`${NAMESPACE}`** inside patches (for example, to set RBAC `subjects[].namespace`).  
Flux injects real values **after** Kustomize renders via `postBuild.substitute`.

**1) OCIRepository**
```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: csi-rclone
  namespace: workspace
spec:
  url: oci://ghcr.io/versioneer-tech/bases
  ref:
    tag: csi-rclone-<sha12>
  interval: 5m
```

**2) Kustomization (points to overlay, substitutes values)**
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: csi-rclone
  namespace: workspace
spec:
  interval: 10m
  prune: true
  wait: true
  timeout: 5m
  targetNamespace: workspace
  sourceRef:
    kind: OCIRepository
    name: csi-rclone
    namespace: workspace
  path: ./default
  postBuild:
    substitute:
      NAMESPACE: workspace
```

> **Argo CD note (Oct 2025):** Argo CD does not provide a Flux-style `postBuild.substitute`; use standard Kustomize variable replacement instead.

You can still use regular Kustomize patches in both FluxCD and Argo CD—for example, to add a `nodeSelector`:

```yaml
patches:
  - target:
      group: apps
      version: v1
      kind: DaemonSet
      name: csi-rclone-nodeplugin
    patch: |
      apiVersion: apps/v1
      kind: DaemonSet
      metadata:
        name: csi-rclone-nodeplugin
      spec:
        template:
          spec:
            nodeSelector:
              pool-name: general
  - target:
      group: apps
      version: v1
      kind: StatefulSet
      name: csi-rclone-controller
    patch: |
      apiVersion: apps/v1
      kind: StatefulSet
      metadata:
        name: csi-rclone-controller
      spec:
        template:
          spec:
            nodeSelector:
              pool-name: general
```
## Development

### Requirements

- Flux CLI (`flux`)  
- `git`  
- Auth to `ghcr.io` (e.g., `docker login ghcr.io` with a token that has `read/write:packages`)

### Manual inspection

Fetch an artifact locally and inspect its contents:

```bash
flux pull artifact oci://ghcr.io/versioneer-tech/bases:csi-rclone-<sha12> --output out
tree out
```

### Publishing (as OCI artifacts)

Use the script to detect changed components (folders that contain a `kustomization.yaml`) and push them as OCI artifacts tagged `<component>-<sha12>`:

```bash
./publish-bases.sh
```

Options:

- `--dry-run` – print commands without pushing  
- `--no-skip` – publish all components regardless of changes  
- `--since <ref>` – diff against a specific Git ref instead of `HEAD^`

Environment:

- `IMAGE` (default: `ghcr.io/versioneer-tech/bases`)

**Example (dry run):**
```bash
./publish-bases.sh --dry-run --no-skip
```

## License

[Apache 2.0](LICENSE)  
(Apache License Version 2.0, January 2004)  
https://www.apache.org/licenses/LICENSE-2.0
