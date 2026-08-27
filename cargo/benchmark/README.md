# Cargo Benchmark Action

Run Rust benchmarks with optional crate, feature, and benchmark target selection.

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/benchmark@<full-commit-sha> # vX.Y.Z
  with:
    bench: "parser"
    features: "simd"
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `crate` | - | Crate name (optional) |
| `features` | `""` | Comma-separated features |
| `cargo` | `./Cargo.toml` | Path to Cargo.toml |
| `rust-toolchain` | `stable` | stable, beta, or nightly |
| `cache` | `true` | Use GitHub Actions cache |
| `bench` | `""` | Specific benchmark target to run with `--bench` |
| `bench-args` | `""` | Arguments passed after `--` to the benchmark harness |
| `no-run` | `false` | Compile benchmarks without running them |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | Package name |
| `version` | Package version |
| `rust-version` | MSRV |
| `workspace` | `true` if workspace |
| `workspace-members` | Comma-separated member names |

## What It Does

1. **Load project metadata** using cargo/project action
2. **Setup Rust toolchain**
3. **Restore cache** (if enabled)
4. **cargo bench** using the `cargo` manifest path, crate/workspace scope, features, and optional `--bench` target
5. **Save cache** on push events (if enabled)

## Build Scope Logic

Scripts use `CARGO_LOCATION`, `PROJECT_WORKSPACE`, and `PROJECT_CRATE` env vars:
- Specific crate: `cargo bench --manifest-path $CARGO_LOCATION -p $PROJECT_CRATE`
- Workspace: `cargo bench --manifest-path $CARGO_LOCATION --workspace`
- Single crate: `cargo bench --manifest-path $CARGO_LOCATION`

## Examples

### All benchmarks
```yaml
- uses: 42ByteLabs/actions/cargo/benchmark@<full-commit-sha> # vX.Y.Z
```

### Specific benchmark target
```yaml
- uses: 42ByteLabs/actions/cargo/benchmark@<full-commit-sha> # vX.Y.Z
  with:
    bench: "parser"
```

### Compile benchmarks only
```yaml
- uses: 42ByteLabs/actions/cargo/benchmark@<full-commit-sha> # vX.Y.Z
  with:
    no-run: "true"
```

### Harness arguments
```yaml
- uses: 42ByteLabs/actions/cargo/benchmark@<full-commit-sha> # vX.Y.Z
  with:
    bench-args: "--save-baseline main"
```

## Testing Scripts Locally

```bash
cd cargo/benchmark

export CARGO_LOCATION="../../Cargo.toml"
export PROJECT_WORKSPACE="true"
export CARGO_FEATURES="my-feature"
./benchmark.sh
```
