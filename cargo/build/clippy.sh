#!/bin/bash
# Run Clippy and generate SARIF output
set -e

echo "🔍 Running Clippy analysis..."

if ! command -v clippy-sarif &> /dev/null; then
  echo "📦 Installing clippy-sarif and sarif-fmt..."
  cargo install clippy-sarif sarif-fmt
fi

cargo clippy \
  --all-features --all-targets \
  --message-format=json | clippy-sarif | tee rust-clippy-results.sarif | sarif-fmt

echo "✅ Clippy analysis completed"
