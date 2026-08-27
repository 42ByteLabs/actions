#!/bin/bash
# Run Cargo benchmarks with optional features and benchmark target selection.
set -e

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
  MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

BUILD_SCOPE=()
if [ -n "${PROJECT_CRATE:-}" ]; then
  BUILD_SCOPE=(-p "$PROJECT_CRATE")
  echo "📦 Benchmarking specific crate: ${PROJECT_CRATE}"
elif [ "${PROJECT_WORKSPACE:-}" = "true" ]; then
  BUILD_SCOPE=(--workspace)
  echo "🏢 Benchmarking workspace project"
else
  echo "📦 Benchmarking single crate project"
fi

FEATURE_ARGS=()
if [ -n "${CARGO_FEATURES:-}" ]; then
  FEATURE_ARGS=(--features "$CARGO_FEATURES")
  echo "⚡ Features: '${CARGO_FEATURES}'"
fi

BENCH_TARGET=()
if [ -n "${BENCH_NAME:-}" ]; then
  BENCH_TARGET=(--bench "$BENCH_NAME")
  echo "🏃 Running benchmark target: '${BENCH_NAME}'"
fi

NO_RUN_ARGS=()
if [ "${CARGO_NO_RUN:-false}" = "true" ]; then
  NO_RUN_ARGS=(--no-run)
  echo "🔨 Compiling benchmarks without running them"
fi

HARNESS_ARGS=()
if [ -n "${BENCH_ARGS:-}" ] && [ "${CARGO_NO_RUN:-false}" != "true" ]; then
  # Split simple harness args such as "--save-baseline main". Quoted sub-args are not preserved.
  read -r -a HARNESS_ARGS <<< "$BENCH_ARGS"
  echo "🧪 Benchmark harness args: '${BENCH_ARGS}'"
fi

if [ "${#HARNESS_ARGS[@]}" -gt 0 ]; then
  cargo bench "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" "${FEATURE_ARGS[@]}" "${BENCH_TARGET[@]}" "${NO_RUN_ARGS[@]}" -- "${HARNESS_ARGS[@]}"
else
  cargo bench "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" "${FEATURE_ARGS[@]}" "${BENCH_TARGET[@]}" "${NO_RUN_ARGS[@]}"
fi

echo "✅ Benchmarks completed successfully"
