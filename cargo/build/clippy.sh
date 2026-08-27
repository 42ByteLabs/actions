#!/bin/bash
# Run Clippy and generate SARIF output
set -e

echo "🔍 Running Clippy analysis..."

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
  MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

BUILD_SCOPE=()
if [ "${PROJECT_WORKSPACE:-}" = "true" ]; then
  BUILD_SCOPE=(--workspace)
elif [ -n "${PROJECT_CRATE:-}" ]; then
  BUILD_SCOPE=(-p "$PROJECT_CRATE")
fi

FEATURE_ARGS=()
if [ -n "${CARGO_FEATURES:-}" ]; then
  FEATURE_ARGS=(--features "$CARGO_FEATURES")
fi

if ! command -v clippy-sarif &> /dev/null; then
  echo "📦 Installing clippy-sarif and sarif-fmt..."
  cargo install clippy-sarif sarif-fmt
fi

cargo clippy \
  "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" "${FEATURE_ARGS[@]}" --all-targets \
  --message-format=json | clippy-sarif | tee rust-clippy-results.sarif | sarif-fmt

echo "✅ Clippy analysis completed"
