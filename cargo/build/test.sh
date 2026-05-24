#!/bin/bash
# Run Cargo tests with optional features
set -e

if [ -n "$CARGO_FEATURES" ]; then
  echo "🧪 Running tests with features: '${CARGO_FEATURES}'"
  cargo test --workspace --features "${CARGO_FEATURES}"
  cargo test --workspace --examples --features "${CARGO_FEATURES}"
  cargo test --workspace --bins --features "${CARGO_FEATURES}"
else
  echo "🧪 Running tests (default)"
  cargo test --workspace
  cargo test --workspace --examples
  cargo test --workspace --bins
fi

echo "✅ Tests completed successfully"
