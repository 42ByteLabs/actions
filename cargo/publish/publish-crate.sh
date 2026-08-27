#!/bin/bash
# Publish crate(s) to crates.io
set -e

if [ -z "$CARGO_REGISTRY_TOKEN" ]; then
  echo "Error: CARGO_REGISTRY_TOKEN environment variable not set"
  exit 1
fi

# Check if dry run mode is enabled
if [ "$DRY_RUN" = "true" ]; then
  echo "🧪 DRY RUN MODE - No actual publishing will occur"
  DRY_RUN_FLAG=(--dry-run)
else
  DRY_RUN_FLAG=()
fi

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
  MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

PUBLISHED="false"

version_is_newer() {
  local local_version="$1"
  local remote_version="$2"

  if [ -z "$remote_version" ] || [ "$remote_version" = "null" ]; then
    return 0
  fi

  if [ "$local_version" = "$remote_version" ]; then
    return 1
  fi

  newest=$(printf '%s\n%s\n' "$remote_version" "$local_version" | sort -V | tail -n 1)
  [ "$newest" = "$local_version" ]
}

local_version_for() {
  local crate="$1"

  if [ -n "$crate" ]; then
    cargo metadata "${MANIFEST_ARGS[@]}" --no-deps --format-version 1 | jq -r ".packages[] | select(.name == \"$crate\") | .version" | head -n 1
  else
    cargo metadata "${MANIFEST_ARGS[@]}" --no-deps --format-version 1 | jq -r '.packages[0].version'
  fi
}

remote_version_for() {
  local crate="$1"
  local remote_version

  remote_version=$(cargo search "$crate" --limit 1 2>/dev/null | grep "^$crate = " | sed -E 's/.*= "([^"]+)".*/\1/' || echo "")
  if [ -z "$remote_version" ] || [ "$remote_version" = "null" ]; then
    remote_version=$(curl -s "https://crates.io/api/v1/crates/$crate/versions" 2>/dev/null | jq -r '.versions[0].num' 2>/dev/null || echo "")
  fi

  echo "$remote_version"
}

publish_one() {
  local crate="$1"
  local local_version
  local remote_version

  local_version=$(local_version_for "$crate")
  if [ -z "$local_version" ] || [ "$local_version" = "null" ]; then
    echo "Error: Could not determine local version for crate '$crate'"
    exit 1
  fi

  if [ -z "$crate" ]; then
    crate=$(cargo metadata "${MANIFEST_ARGS[@]}" --no-deps --format-version 1 | jq -r '.packages[0].name')
  fi

  remote_version=$(remote_version_for "$crate")
  if ! version_is_newer "$local_version" "$remote_version"; then
    echo "📦 Crate '$crate' does not need publishing: local=$local_version remote=$remote_version"
    return 0
  fi

  echo "🚀 Publishing crate '$crate' version '$local_version'..."
  if [ -n "$remote_version" ] && [ "$remote_version" != "null" ]; then
    echo "📦 crates.io latest is '$remote_version'"
  else
    echo "📦 Crate '$crate' is not published yet"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "🧪 [DRY RUN] Would publish: cargo publish -p '$crate' --allow-dirty"
  fi

  cargo publish "${MANIFEST_ARGS[@]}" -p "$crate" --allow-dirty "${DRY_RUN_FLAG[@]}" || {
    if [ "$(remote_version_for "$crate")" = "$local_version" ]; then
      echo "📦 Crate '$crate' version '$local_version' is already published, skipping..."
      return 0
    fi
    exit 1
  }

  PUBLISHED="true"
}

# Publish multiple crates in order (workspace members)
if [ -n "$CRATES" ]; then
  IFS=',' read -r -a elements <<< "$CRATES"
  for index in "${!elements[@]}"; do
    element="${elements[$index]}"
    publish_one "$element"

    if [ "$PUBLISHED" = "true" ] && [ "$index" -lt "$((${#elements[@]} - 1))" ]; then
      echo "⏳ Waiting 30 seconds for crates.io propagation..."
      sleep 30
    fi
  done
# Publish specific crate
elif [ -n "$PROJECT_CRATE" ]; then
  publish_one "$PROJECT_CRATE"
# Publish default crate
else
  publish_one ""
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "published=$PUBLISHED" >>"$GITHUB_OUTPUT"
fi

if [ "$DRY_RUN" = "true" ]; then
  echo "✅ Dry run completed successfully (no actual publishing)"
elif [ "$PUBLISHED" = "true" ]; then
  echo "✅ Publishing completed successfully"
else
  echo "✅ No crates needed publishing"
fi
