# Cargo Security Action

Security auditing for Rust projects using cargo-audit and cargo-deny.

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/security@main
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `cargo` | `./Cargo.toml` | Path to Cargo.toml |
| `cargo-audit` | `true` | Check for known vulnerabilities |
| `cargo-deny` | `true` | Check dependencies, licenses, advisories |
| `rust-toolchain` | `stable` | Rust toolchain version |

## What It Does

1. **Setup Rust toolchain**
2. **Install cargo-audit** (if enabled)
3. **Run cargo-audit** - Checks RustSec Advisory Database for known vulnerabilities
4. **Run cargo-deny** - Checks dependencies, licenses, and advisories using [cargo-deny-action](https://github.com/EmbarkStudios/cargo-deny-action) v2.0.19

## Tools

### cargo-audit
Checks dependencies against [RustSec Advisory Database](https://rustsec.org/).

### cargo-deny
Lints dependencies for:
- Security advisories
- License compliance
- Dependency bans
- Duplicate dependencies

Configure with `deny.toml` in repo root.

## Examples

### Both tools (default)
```yaml
- uses: 42ByteLabs/actions/cargo/security@main
```

### Only cargo-audit
```yaml
- uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo-audit: "true"
    cargo-deny: "false"
```

### Only cargo-deny
```yaml
- uses: 42ByteLabs/actions/cargo/security@main
  with:
    cargo-audit: "false"
    cargo-deny: "true"
```

### Scheduled audits
```yaml
name: Security Audit

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: 42ByteLabs/actions/cargo/security@main
```

## Configuration

Create `deny.toml` in repo root to configure cargo-deny:

```toml
[advisories]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"

[licenses]
unlicensed = "deny"
allow = ["MIT", "Apache-2.0", "BSD-3-Clause"]

[bans]
multiple-versions = "warn"

[sources]
unknown-registry = "warn"
```

See [cargo-deny docs](https://embarkstudios.github.io/cargo-deny/) for full configuration options.
