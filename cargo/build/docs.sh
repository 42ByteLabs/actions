#!/bin/bash
# Build Rust/Cargo documentation with optional features
set -e

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
  MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

# Determine build scope based on project type
BUILD_SCOPE=()
if [ "$PROJECT_WORKSPACE" = "true" ]; then
  BUILD_SCOPE=(--workspace)
  echo "🏢 Building workspace documentation"
elif [ -n "$PROJECT_CRATE" ]; then
  BUILD_SCOPE=(-p "$PROJECT_CRATE")
  echo "📦 Building documentation for crate: ${PROJECT_CRATE}"
else
  echo "📦 Building documentation for single crate project"
fi

if [ -n "$CARGO_FEATURES" ]; then
  echo "📚 Building docs with features: '${CARGO_FEATURES}'"
  cargo doc "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --no-deps --features "${CARGO_FEATURES}"
else
  echo "📚 Building docs (default)"
  cargo doc "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --no-deps
fi

echo "✅ Docs completed successfully"
