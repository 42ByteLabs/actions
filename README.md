# 42ByteLabs Actions

Reusable GitHub Actions for 42ByteLab projects.

## Available Actions

| Action | Description |
|--------|-------------|
| [cargo build](./cargo/build/) | Build and test with formatting, linting, and security checks |
| [cargo examples](./cargo/examples/) | Run Cargo examples |
| [cargo publish](./cargo/publish/) | Publish to crates.io with version checking |
| [cargo security](./cargo/security/) | Security audit with cargo-audit and cargo-deny |
| [cargo project](./cargo/project/) | Extract Cargo.toml metadata |

## Quick Start

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    rust-toolchain: "stable"
    features: "my-feature"
```

## Example Workflow

```yaml
name: CI

on: [push, pull_request]

permissions:
  contents: read
  security-events: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: 42ByteLabs/actions/cargo/build@main
```

## License

MIT - see [LICENSE](LICENSE) file.

