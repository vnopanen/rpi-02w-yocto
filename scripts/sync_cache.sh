#!/usr/bin/env bash
set -euo pipefail

# Load .env if present
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$REPO_ROOT/.env" ]; then
  echo "==> Loading environment variables from $REPO_ROOT/.env"
  # shellcheck disable=SC1091
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

CACHE_DIR="${CACHE_DIR:-$REPO_ROOT/build/sstate-cache}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$REPO_ROOT/build/downloads}"
DRY_RUN="${DRY_RUN:-false}"

# Validate required variables
if [ -z "${R2_BUCKET:-}" ] || [ -z "${R2_ENDPOINT:-}" ]; then
  echo "Error: R2_BUCKET and R2_ENDPOINT environment variables must be set." >&2
  echo "You can set them in $REPO_ROOT/.env or export them in your shell." >&2
  exit 1
fi

EXTRA_SYNC_FLAGS=()
if [ "$DRY_RUN" = "true" ]; then
  EXTRA_SYNC_FLAGS+=(--dryrun)
fi

echo "==> Validating sstate cache in $CACHE_DIR..."
if [ -d "$CACHE_DIR" ]; then
  if [ -f "$REPO_ROOT/openembedded-core/scripts/sstate-cache-management.py" ]; then
    python3 "$REPO_ROOT/openembedded-core/scripts/sstate-cache-management.py" \
      --cache-dir "$CACHE_DIR" \
      --remove-orphans \
      --yes \
      --verbose
  fi

  if [ -f "$REPO_ROOT/scripts/sstate_validate.py" ]; then
    python3 "$REPO_ROOT/scripts/sstate_validate.py" "$CACHE_DIR"
  fi

  mapfile -d '' ARCHIVES < <(find "$CACHE_DIR" -type f -name '*.tar.zst' -print0)
  if ((${#ARCHIVES[@]})); then
    printf '%s\0' "${ARCHIVES[@]}" | xargs -0 -r zstd -q -t
  fi
else
  echo "Warning: Cache directory $CACHE_DIR does not exist. Skipping validation."
fi

echo "==> Syncing downloads to R2..."
if [ -d "$DOWNLOADS_DIR" ]; then
  aws s3 sync "$DOWNLOADS_DIR/" "s3://${R2_BUCKET}/downloads/" \
    --endpoint-url "$R2_ENDPOINT" \
    --exclude "*.lock" \
    --exclude "*.tmp" \
    --exclude "*.done" \
    --exclude "git2/*" \
    --no-progress \
    "${EXTRA_SYNC_FLAGS[@]}"
else
  echo "Info: Downloads directory $DOWNLOADS_DIR not found. Skipping."
fi

echo "==> Syncing sstate-cache to R2..."
if [ -d "$CACHE_DIR" ]; then
  aws s3 sync "$CACHE_DIR/" "s3://${R2_BUCKET}/sstate-cache/" \
    --endpoint-url "$R2_ENDPOINT" \
    --no-progress \
    "${EXTRA_SYNC_FLAGS[@]}"
else
  echo "Info: Sstate-cache directory $CACHE_DIR not found. Skipping."
fi

echo "==> Cache sync complete."
