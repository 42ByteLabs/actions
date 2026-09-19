# Cargo Setup Action

Install Rust with `rustup` using the official installer script and a SHA-256 checksum check before execution.

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
  with:
    rust-toolchain: "nightly"
    targets: "wasm32-unknown-unknown"
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `rust-toolchain` | `stable` | Toolchain to install, such as `stable`, `nightly`, `1.80.0`, or `nightly-2026-09-01` |
| `targets` | `""` | Optional Rust targets separated by commas, spaces, or new lines |
| `components` | `""` | Optional Rust components separated by commas, spaces, or new lines |
| `rustup-url` | `https://sh.rustup.rs` | URL for the rustup installer script |
| `rustup-sha256` | `7d0ea0f8eba7fa1ebfe998091cd7ec4501e33ec5ca6b884eb4d894d7da5170af` | Expected SHA-256 hash of the downloaded installer script |

## Outputs

| Output | Description |
|--------|-------------|
| `rust-toolchain` | Installed Rust toolchain |

## What It Does

1. Downloads the rustup installer script with TLS 1.2 or newer.
2. Verifies the downloaded script using `sha256sum`.
3. Installs rustup with the minimal profile and no default toolchain.
4. Runs `rustup toolchain install <toolchain>` with optional `--target` and `--component` values.
5. Sets the installed toolchain as the default.

## Examples

### Stable

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
```

### Nightly

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
  with:
    rust-toolchain: "nightly"
```

### Pinned Version

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
  with:
    rust-toolchain: "1.80.0"
```

### Specific Target

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
  with:
    rust-toolchain: "nightly"
    targets: "wasm32-unknown-unknown,x86_64-unknown-linux-musl"
```

### Components

```yaml
- uses: 42ByteLabs/actions/cargo/setup@<full-commit-sha> # vX.Y.Z
  with:
    components: "clippy,rustfmt"
```

## Updating The Installer Hash

If `https://sh.rustup.rs` changes upstream, update `rustup-sha256` to the new expected script hash after reviewing the downloaded script.
