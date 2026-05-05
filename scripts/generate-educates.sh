#!/usr/bin/env bash
set -euo pipefail
# Copyright 2025, EOX (https://eox.at) and Versioneer (https://versioneer.at)
# SPDX-License-Identifier: Apache-2.0

ROOT_DIR="$(git rev-parse --show-toplevel)"
CONFIG_FILE="${CONFIG_FILE:-${ROOT_DIR}/educates/default/educates-config.yaml}"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/educates/default}"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

command -v educates >/dev/null || { echo "educates not found" >&2; exit 1; }
command -v yq >/dev/null || { echo "yq not found" >&2; exit 1; }

mkdir -p "${OUT_DIR}"

educates deploy-platform --config "${CONFIG_FILE}" --dry-run > "${TMP_DIR}/_all.yaml"

yq eval 'select(.kind == "CustomResourceDefinition")' \
  "${TMP_DIR}/_all.yaml" > "${TMP_DIR}/crd.yaml"

yq eval 'select(.kind != "CustomResourceDefinition" and .kind != "Namespace")' \
  "${TMP_DIR}/_all.yaml" > "${TMP_DIR}/manifest.yaml"

strip_annotations() {
  local file=$1
  yq eval '
    .metadata.annotations |= (. // {})
    | .metadata.annotations |= with_entries(select(.key
        | test("^(kapp\\.k14s\\.io/|educates\\.dev/).*") | not))
  ' "${file}" > "${file}.tmp"
  mv "${file}.tmp" "${file}"
}

prepend_license() {
  local source=$1
  local target=$2
  {
    printf '# Copyright 2025, EOX (https://eox.at) and Versioneer (https://versioneer.at)\n'
    printf '# SPDX-License-Identifier: Apache-2.0\n\n'
    cat "${source}"
  } > "${target}"
}

strip_annotations "${TMP_DIR}/crd.yaml"
strip_annotations "${TMP_DIR}/manifest.yaml"

yq eval 'del(.metadata.namespace)' "${TMP_DIR}/manifest.yaml" > "${TMP_DIR}/manifest.yaml.tmp"
mv "${TMP_DIR}/manifest.yaml.tmp" "${TMP_DIR}/manifest.yaml"

sed -E 's/^([[:space:]]*namespace:)[[:space:]]*educates([[:space:]]*(#.*)?)$/\1 ${NAMESPACE}\2/' \
  "${TMP_DIR}/manifest.yaml" > "${TMP_DIR}/manifest.yaml.tmp"
mv "${TMP_DIR}/manifest.yaml.tmp" "${TMP_DIR}/manifest.yaml"

prepend_license "${TMP_DIR}/crd.yaml" "${OUT_DIR}/crd.yaml"
prepend_license "${TMP_DIR}/manifest.yaml" "${OUT_DIR}/manifest.yaml"

echo "generated ${OUT_DIR}/crd.yaml"
echo "generated ${OUT_DIR}/manifest.yaml"
