#!/bin/bash
# Run Cargo tests with optional features
set -e

# Determine build scope based on project type
if [ "$PROJECT_WORKSPACE" = "true" ]; then
  BUILD_SCOPE="--workspace"
  echo "🏢 Testing workspace project"
elif [ -n "$PROJECT_CRATE" ]; then
  BUILD_SCOPE="-p ${PROJECT_CRATE}"
  echo "📦 Testing specific crate: ${PROJECT_CRATE}"
else
  BUILD_SCOPE=""
  echo "📦 Testing single crate project"
fi

if [ -n "$CARGO_FEATURES" ]; then
  echo "🧪 Running tests with features: '${CARGO_FEATURES}'"
  cargo test ${BUILD_SCOPE} --features "${CARGO_FEATURES}"
  cargo test ${BUILD_SCOPE} --examples --features "${CARGO_FEATURES}"
  cargo test ${BUILD_SCOPE} --bins --features "${CARGO_FEATURES}"
else
  echo "🧪 Running tests (default)"
  cargo test ${BUILD_SCOPE}
  cargo test ${BUILD_SCOPE} --examples
  cargo test ${BUILD_SCOPE} --bins
fi

echo "✅ Tests completed successfully"
