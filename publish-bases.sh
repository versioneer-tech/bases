#!/usr/bin/env bash
set -euo pipefail
# Copyright 2025, EOX (https://eox.at) and Versioneer (https://versioneer.at)
# SPDX-License-Identifier: Apache-2.0

IMAGE="${IMAGE:-ghcr.io/versioneer-tech/bases}"
OWNER="${OWNER:-versioneer-tech}"
DRY_RUN=false
NO_SKIP=false
SINCE_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=true; shift ;;
    --no-skip)    NO_SKIP=true; shift ;;
    --since)      SINCE_REF="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

command -v flux >/dev/null || { echo "flux not found"; exit 1; }
command -v git  >/dev/null || { echo "git not found"; exit 1; }

ROOT_DIR="$(pwd)"
COMMIT_SHA="$(git rev-parse HEAD)"
SOURCE_URL="$(git config --get remote.origin.url || true)"

if [[ -n "$SINCE_REF" ]]; then
  PREV="$SINCE_REF"
elif git rev-parse HEAD^ >/dev/null 2>&1; then
  PREV="HEAD^"
else
  PREV=""
fi

changed() {
  local path="$1"
  if [[ -z "$PREV" || "$NO_SKIP" == "true" ]]; then
    return 0
  fi
  ! git diff --quiet "$PREV"..HEAD -- "$path"
}

while IFS= read -r -d '' dir; do
  comp="$(basename "$dir")"

    krel=""
  if [[ -f "$dir/default/kustomization.yaml" ]]; then
    krel="default/kustomization.yaml"
  elif [[ -f "$dir/default/kustomization.yml" ]]; then
    krel="default/kustomization.yml"
  else
      continue
  fi

  if ! changed "$dir"; then
    echo "skip unchanged: $comp"
    continue
  fi

  TAG="${comp}-${COMMIT_SHA:0:12}"
  REF="oci://${IMAGE}:${TAG}"

  if $DRY_RUN; then
    echo "cd $dir"
    echo "  # Detected: $krel"
    echo "flux push artifact ${REF} --path . --source \"${SOURCE_URL}\" --revision \"${COMMIT_SHA}\""
    echo "cd - >/dev/null"
  else
    pushd "$dir" >/dev/null
    flux push artifact "${REF}" \
      --path "." \
      --source "${SOURCE_URL}" \
      --revision "${COMMIT_SHA}"
    popd >/dev/null
    echo "pushed ${REF}"
  fi
done < <(find . -mindepth 1 -maxdepth 1 -type d -print0)
