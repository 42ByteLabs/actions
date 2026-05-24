# Cargo Actions

GitHub Actions for Rust/Cargo projects.

## Actions

| Action | Description | Key Inputs |
|--------|-------------|------------|
| [build](./build/) | Build, test, format, lint, security audit | `features`, `rust-toolchain`, `cache`, `clippy`, `tests`, `security` |
| [examples](./examples/) | Run Cargo examples | `cargo` |
| [publish](./publish/) | Publish to crates.io | `crate`, `cargo-token`, `crates` |
| [security](./security/) | cargo-audit and cargo-deny checks | `cargo-audit`, `cargo-deny` |
| [project](./project/) | Extract metadata from Cargo.toml | `cargo` |

## Build Action

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    features: "my-feature"
    rust-toolchain: "stable"  # stable, beta, nightly
    clippy: "true"
    tests: "true"
    security: "true"
```

**Permissions:**
```yaml
permissions:
  contents: read
  security-events: write  # For Clippy SARIF upload
```

## Publish Action

```yaml
- uses: 42ByteLabs/actions/cargo/publish@main
  with:
    crate: "my-crate"
    cargo-token: ${{ secrets.CARGO_TOKEN }}
    crates: "core,utils,cli"  # For workspaces - publishes in order
```

**Permissions:**
```yaml
permissions:
  contents: write  # For creating GitHub releases
```

## Security Action

```yaml
- uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo-audit: "true"
    cargo-deny: "true"
```

## Examples Action

```yaml
- uses: 42ByteLabs/actions/cargo/examples@main
  with:
    cargo: "./Cargo.toml"
```

## Complete Workflow

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
  release:
    types: [created]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: 42ByteLabs/actions/cargo/build@main

  publish:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: 42ByteLabs/actions/cargo/publish@main
        with:
          crate: "my-crate"
          cargo-token: ${{ secrets.CARGO_TOKEN }}

  binaries:
    if: github.event_name == 'release'
    strategy:
      matrix:
        include:
          - platform: macos
            os: macos-latest
          - platform: linux
            os: ubuntu-latest
          - platform: windows
            os: windows-latest
    runs-on: ${{ matrix.os }}
    permissions:
      contents: write
      attestations: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: 42ByteLabs/actions/cargo/binaries@main
        with:
          platform: ${{ matrix.platform }}
          create-package: true
```

## Notes

- **Caching**: Build action handles Cargo caching automatically (saves on push to main)
- **Cache key**: `${{ runner.os }}-${{ inputs.rust-toolchain }}-cargo`
- **Clippy SARIF**: Only generated on stable Rust, uploads to GitHub Code Scanning
- **Version checking**: Publish action checks crates.io before publishing (skips if version exists)
- **Multi-crate publishing**: 30-second delay between each crate publication
- **Binary naming**: `{crate}-{version}-{arch}.{ext}` (e.g., `myapp-1.0.0-x86_64.deb`)
