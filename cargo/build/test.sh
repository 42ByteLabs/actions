#!/bin/bash
# Run Cargo tests with optional features
set -e

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
  MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

# Determine build scope based on project type
BUILD_SCOPE=()
if [ "$PROJECT_WORKSPACE" = "true" ]; then
  BUILD_SCOPE=(--workspace)
  echo "🏢 Testing workspace project"
elif [ -n "$PROJECT_CRATE" ]; then
  BUILD_SCOPE=(-p "$PROJECT_CRATE")
  echo "📦 Testing specific crate: ${PROJECT_CRATE}"
else
  echo "📦 Testing single crate project"
fi

if [ -n "$CARGO_FEATURES" ]; then
  echo "🧪 Running tests with features: '${CARGO_FEATURES}'"
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --features "${CARGO_FEATURES}"
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --examples --features "${CARGO_FEATURES}"
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --bins --features "${CARGO_FEATURES}"
else
  echo "🧪 Running tests (default)"
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}"
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --examples
  cargo test "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --bins
fi

echo "✅ Tests completed successfully"
