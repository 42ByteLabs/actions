#!/usr/bin/env bash
set -euo pipefail

if [ -z "${RUST_TOOLCHAIN:-}" ]; then
  echo "rust-toolchain input must not be empty" >&2
  exit 1
fi

if [ -z "${RUSTUP_SHA256:-}" ]; then
  echo "rustup-sha256 input must not be empty" >&2
  exit 1
fi

if [ -z "${RUSTUP_URL:-}" ]; then
  echo "rustup-url input must not be empty" >&2
  exit 1
fi

RUST_TARGETS="${RUST_TARGETS:-}"
RUST_COMPONENTS="${RUST_COMPONENTS:-}"

installer="${RUNNER_TEMP:-/tmp}/rustup-init.sh"

curl --proto '=https' --tlsv1.2 -fsSL "${RUSTUP_URL}" -o "${installer}"
read -r actual_sha256 _ < <(sha256sum "${installer}")
if [ "${actual_sha256}" != "${RUSTUP_SHA256}" ]; then
  echo "rustup installer checksum mismatch" >&2
  echo "expected: ${RUSTUP_SHA256}" >&2
  echo "actual:   ${actual_sha256}" >&2
  exit 1
fi

export RUSTUP_INIT_SKIP_PATH_CHECK=yes
sh "${installer}" -y --no-modify-path --profile minimal --default-toolchain none

cargo_bin="${CARGO_HOME:-${HOME}/.cargo}/bin"
export PATH="${cargo_bin}:${PATH}"

if [ -n "${GITHUB_PATH:-}" ]; then
  printf '%s\n' "${cargo_bin}" >> "${GITHUB_PATH}"
fi

install_args=("${RUST_TOOLCHAIN}" --profile minimal)

if [ -n "${RUST_TARGETS}" ]; then
  normalized_targets="${RUST_TARGETS//$'\n'/ }"
  normalized_targets="${normalized_targets//,/ }"
  for target in ${normalized_targets}; do
    install_args+=(--target "${target}")
  done
fi

if [ -n "${RUST_COMPONENTS}" ]; then
  normalized_components="${RUST_COMPONENTS//$'\n'/ }"
  normalized_components="${normalized_components//,/ }"
  for component in ${normalized_components}; do
    install_args+=(--component "${component}")
  done
fi

rustup toolchain install "${install_args[@]}"
rustup default "${RUST_TOOLCHAIN}"
rustup show
