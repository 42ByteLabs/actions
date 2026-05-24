# Cargo Security Action

Security auditing for Rust/Cargo projects using `cargo-audit` and `cargo-deny`.

## Features

- **cargo-audit**: Checks for known security vulnerabilities in dependencies
- **cargo-deny**: Checks dependencies, licenses, and security advisories
- Configurable to run either or both tools
- Supports custom Cargo.toml paths
- Flexible Rust toolchain selection

## Usage

### Basic Usage

```yaml
- name: Security Audit
  uses: 42ByteLabs/actions/cargo/security@main
```

### Advanced Usage

```yaml
- name: Security Audit
  uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo: "./Cargo.toml"
    cargo-audit: "true"
    cargo-deny: "true"
    rust-toolchain: "stable"
```

### Run Only cargo-audit

```yaml
- name: Security Audit (cargo-audit only)
  uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo-audit: "true"
    cargo-deny: "false"
```

### Run Only cargo-deny

```yaml
- name: Security Audit (cargo-deny only)
  uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo-audit: "false"
    cargo-deny: "true"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `cargo` | Path to Cargo.toml | No | `./Cargo.toml` |
| `cargo-audit` | Run cargo-audit to check for known vulnerabilities | No | `true` |
| `cargo-deny` | Run cargo-deny to check dependencies, licenses, and security advisories | No | `true` |
| `rust-toolchain` | Rust toolchain to use (stable, beta, nightly) | No | `stable` |

## Tools Used

### cargo-audit

[cargo-audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit) is a security auditing tool for Rust that checks for known vulnerabilities in project dependencies using the RustSec Advisory Database.

### cargo-deny

[cargo-deny](https://github.com/EmbarkStudios/cargo-deny) is a cargo plugin for linting dependencies. It can check for:
- Security advisories
- License compliance
- Dependency bans
- Duplicate dependencies

This action uses the pinned version `v2.0.19` of the [cargo-deny-action](https://github.com/EmbarkStudios/cargo-deny-action/tree/v2.0.19).

## Example Workflow

```yaml
name: Security Audit

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    # Run weekly security audits
    - cron: '0 0 * * 0'

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Security Audit
        uses: 42ByteLabs/actions/cargo/security@main
        with:
          cargo-audit: "true"
          cargo-deny: "true"
```

## Configuration

### cargo-deny Configuration

To configure `cargo-deny`, create a `deny.toml` file in your repository root. See the [cargo-deny documentation](https://embarkstudios.github.io/cargo-deny/) for details.

Example `deny.toml`:

```toml
[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"
notice = "warn"

[licenses]
unlicensed = "deny"
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-3-Clause",
]

[bans]
multiple-versions = "warn"
wildcards = "allow"

[sources]
unknown-registry = "warn"
unknown-git = "warn"
```

## License

See the main repository [LICENSE](../../../LICENSE) file.
