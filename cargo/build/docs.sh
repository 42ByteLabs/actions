#!/bin/bash
# Build Rust/Cargo documentation with optional features
set -e

# Determine build scope based on project type
if [ "$PROJECT_WORKSPACE" = "true" ]; then
  BUILD_SCOPE="--workspace"
  echo "🏢 Building workspace documentation"
elif [ -n "$PROJECT_CRATE" ]; then
  BUILD_SCOPE="-p ${PROJECT_CRATE}"
  echo "📦 Building documentation for crate: ${PROJECT_CRATE}"
else
  BUILD_SCOPE=""
  echo "📦 Building documentation for single crate project"
fi

if [ -n "$CARGO_FEATURES" ]; then
  echo "📚 Building docs with features: '${CARGO_FEATURES}'"
  cargo doc ${BUILD_SCOPE} --no-deps --features "${CARGO_FEATURES}"
else
  echo "📚 Building docs (default)"
  cargo doc ${BUILD_SCOPE} --no-deps
fi

echo "✅ Docs completed successfully"
