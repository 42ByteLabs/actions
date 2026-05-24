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
  DRY_RUN_FLAG="--dry-run"
else
  DRY_RUN_FLAG=""
fi

# Publish multiple crates in order (workspace members)
if [ -n "$CRATES" ]; then
  IFS=',' read -r -a elements <<< "$CRATES"
  for element in "${elements[@]}"
  do
    echo "🚀 Publishing crate '$element'..."
    if [ "$DRY_RUN" = "true" ]; then
      echo "🧪 [DRY RUN] Would publish: cargo publish -p '$element' --allow-dirty"
      cargo publish -p "$element" --allow-dirty $DRY_RUN_FLAG
    else
      cargo publish -p "$element" --allow-dirty || {
        if [[ $? -eq 0 ]] || cargo search "$element" --limit 1 | grep -q "$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[] | select(.name == \"$element\") | .version")"; then
          echo "📦 Crate '$element' already published, skipping..."
        else
          exit 1
        fi
      }
    fi
  done
# Publish specific crate
elif [ -n "$PROJECT_CRATE" ]; then
  echo "🚀 Publishing crate '$PROJECT_CRATE'..."
  if [ "$DRY_RUN" = "true" ]; then
    echo "🧪 [DRY RUN] Would publish: cargo publish -p '$PROJECT_CRATE' --allow-dirty"
    cargo publish -p "$PROJECT_CRATE" --allow-dirty $DRY_RUN_FLAG
  else
    cargo publish -p "$PROJECT_CRATE" --allow-dirty || {
      if [[ $? -eq 0 ]] || cargo search "$PROJECT_CRATE" --limit 1 | grep -q "$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[] | select(.name == \"$PROJECT_CRATE\") | .version")"; then
        echo "📦 Crate '$PROJECT_CRATE' already published, skipping..."
      else
        exit 1
      fi
    }
  fi
# Publish default crate
else
  echo "🚀 Publishing crate..."
  if [ "$DRY_RUN" = "true" ]; then
    echo "🧪 [DRY RUN] Would publish: cargo publish --allow-dirty"
    cargo publish --allow-dirty $DRY_RUN_FLAG
  else
    cargo publish --allow-dirty || {
      if [[ $? -eq 0 ]] || cargo search "$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')" --limit 1 | grep -q "$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].version')"; then
        echo "📦 Crate already published, skipping..."
      else
        exit 1
      fi
    }
  fi
fi

if [ "$DRY_RUN" = "true" ]; then
  echo "✅ Dry run completed successfully (no actual publishing)"
else
  echo "✅ Publishing completed successfully"
fi
