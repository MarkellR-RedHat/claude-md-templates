# CLAUDE.md - Rust Project

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Replace "my-crate" with your actual crate name -->
<!-- TODO: Set your Rust edition (2021 or 2024) -->
<!-- TODO: Set crate type: binary (src/main.rs), library (src/lib.rs), or both -->
<!-- TODO: Set your async runtime (tokio, async-std, or none) -->
<!-- TODO: Update Cargo workspace members if this is a multi-crate workspace -->

## Project Overview

This is a Rust project. It follows standard Rust idioms and emphasizes safety, performance, and clear error handling. The crate is built with the Rust 2021 edition and targets stable Rust.

## Project Structure

```
project-root/
  src/
    main.rs              # Binary entrypoint (if applicable)
    lib.rs               # Library root (if applicable)
    bin/
      secondary.rs       # Additional binaries
    config.rs            # Configuration types
    error.rs             # Error types
    models/              # Data models and types
      mod.rs
    services/            # Business logic
      mod.rs
    api/                 # HTTP handlers or gRPC services
      mod.rs
  tests/
    integration_test.rs  # Integration tests
    common/
      mod.rs             # Shared test utilities
  benches/
    benchmarks.rs        # Criterion benchmarks
  examples/
    basic_usage.rs       # Runnable examples
  Cargo.toml
  Cargo.lock             # Committed for binaries, not for libraries
  clippy.toml
  rustfmt.toml
  deny.toml              # cargo-deny configuration
  Containerfile
  .gitignore
```

### Layout rules:
- For binaries, commit `Cargo.lock`. For libraries, do not commit it.
- Keep `main.rs` minimal. It should parse arguments, load configuration, and call into library code.
- Use the module system to organize code. One file per logical unit, not one file per type.
- Place integration tests in `tests/`. They test the public API of your crate.
- Place benchmarks in `benches/` using Criterion.

### Workspace layout (multi-crate projects):
```toml
# Root Cargo.toml
[workspace]
members = [
    "crates/my-core",
    "crates/my-cli",
    "crates/my-server",
]
resolver = "2"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
```

Share dependencies across workspace members using `[workspace.dependencies]` and reference them with `workspace = true` in each member's `Cargo.toml`.

## Cargo Conventions

### Cargo.toml metadata:
```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"
description = "Short description of this crate"
license = "Apache-2.0"
repository = "https://github.com/your-org/your-repo"

[features]
default = []
openssl-tls = ["reqwest/native-tls"]
rustls-tls = ["reqwest/rustls-tls"]
```

### Feature flags:
- Define feature flags for optional functionality. Keep the default feature set minimal.
- Use feature flags to gate heavy dependencies (TLS backends, serialization formats, async runtimes).
- Document every feature flag in `Cargo.toml` with comments and in the crate-level docs.
- Test with `--no-default-features` and with each feature flag individually in CI.

## Code Conventions

### Naming
- Functions and variables: `snake_case`
- Types, traits, and enum variants: `PascalCase`
- Constants and statics: `SCREAMING_SNAKE_CASE`
- Modules and crate names: `snake_case`
- Lifetime parameters: short lowercase, typically `'a`, `'b`. Use descriptive names for complex cases: `'input`, `'conn`.
- Type parameters: single uppercase letter (`T`, `E`) for simple cases. Use descriptive names for complex generics: `Item`, `Error`.

### Formatting
- Use `rustfmt` with the project's `rustfmt.toml`. Do not override formatting in code.
- Configure `rustfmt.toml`:
  ```toml
  edition = "2021"
  max_width = 100
  use_field_init_shorthand = true
  ```

### Documentation
- All public items must have doc comments (`///` for items, `//!` for module-level).
- Include examples in doc comments. These double as doc tests.
- Use `# Examples`, `# Errors`, and `# Panics` sections in doc comments where applicable:
  ```rust
  /// Parses a configuration file from the given path.
  ///
  /// # Errors
  ///
  /// Returns `ConfigError::NotFound` if the file does not exist.
  /// Returns `ConfigError::Parse` if the file content is invalid TOML.
  ///
  /// # Examples
  ///
  /// ```
  /// let config = my_crate::parse_config("config.toml")?;
  /// assert_eq!(config.port, 8080);
  /// ```
  pub fn parse_config(path: &str) -> Result<Config, ConfigError> {
      // ...
  }
  ```

## Error Handling

### Library crates: use `thiserror`
Define explicit error types for library code. Callers can match on specific variants.

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ServiceError {
    #[error("resource not found: {0}")]
    NotFound(String),

    #[error("permission denied for user {user}")]
    PermissionDenied { user: String },

    #[error("database error")]
    Database(#[from] sqlx::Error),

    #[error("configuration error")]
    Config(#[from] ConfigError),
}
```

### Application (binary) crates: use `anyhow`
For binaries and CLI tools, use `anyhow` for convenient error propagation with context.

```rust
use anyhow::{Context, Result};

fn main() -> Result<()> {
    let config = load_config("config.toml")
        .context("failed to load application configuration")?;

    let db = connect_database(&config.database_url)
        .context("failed to connect to the database")?;

    run_server(config, db)?;
    Ok(())
}
```

### Error handling rules:
- Never use `.unwrap()` or `.expect()` in library code unless you can prove the value is always `Some` or `Ok`. Add a comment explaining why.
- In binary code, prefer `.context("message")?` over `.unwrap()`.
- Use `?` for error propagation. Do not write manual `match` on `Result` unless you need to handle the error differently.
- When converting between error types, implement `From` or use `#[from]` in `thiserror`.

## Async Patterns with Tokio

### Runtime setup:
```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Application code here
    Ok(())
}
```

For libraries, do not choose a runtime. Accept a generic `Future` or let the caller provide the runtime.

### Spawning tasks:
```rust
use tokio::task;

// Use spawn for independent background work
let handle = task::spawn(async move {
    process_item(item).await
});

// Use join to wait for multiple tasks
let (result_a, result_b) = tokio::join!(task_a(), task_b());

// Use try_join for tasks that return Result
let (a, b) = tokio::try_join!(fetch_users(), fetch_orders())?;
```

### Select for racing futures:
```rust
use tokio::select;
use tokio::signal;

select! {
    result = server.serve() => {
        result.context("server exited with error")?;
    }
    _ = signal::ctrl_c() => {
        println!("Received shutdown signal");
    }
}
```

### Cancellation safety:
- Be aware that `select!` cancels the unfinished branches. Use cancellation-safe methods or wrap non-cancellation-safe futures in `tokio::pin!`.
- Prefer `tokio::sync::mpsc` over `std::sync::mpsc` in async code.
- Use `tokio::sync::Mutex` only when you need to hold the lock across `.await` points. For synchronous critical sections, use `std::sync::Mutex` even in async code (it is faster).

## Clippy Configuration

### Cargo.toml lints:
```toml
[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
enum_glob_use = "deny"
pedantic = { level = "warn", priority = -1 }
cast_possible_truncation = "allow"
module_name_repetitions = "allow"
must_use_candidate = "allow"
missing_errors_doc = "warn"
missing_panics_doc = "warn"
undocumented_unsafe_blocks = "deny"
```

### Useful lints to enable:
- `clippy::pedantic` as a baseline (with selective allows for noisy lints).
- `clippy::undocumented_unsafe_blocks` to require safety comments on all unsafe blocks.
- `clippy::missing_errors_doc` to require documentation of error conditions.
- `clippy::missing_panics_doc` to require documentation of panic conditions.
- `clippy::enum_glob_use` to prevent `use MyEnum::*` imports.

### clippy.toml:
```toml
too-many-arguments-threshold = 8
type-complexity-threshold = 300
```

## Testing

### Unit tests (same file):
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_input() {
        let result = parse("valid input");
        assert_eq!(result, expected_output());
    }

    #[test]
    fn test_parse_empty_input_returns_error() {
        let result = parse("");
        assert!(result.is_err());
        assert!(matches!(result, Err(ParseError::EmptyInput)));
    }

    #[tokio::test]
    async fn test_async_operation() {
        let result = fetch_data("http://example.com").await;
        assert!(result.is_ok());
    }
}
```

### Integration tests (tests/ directory):
```rust
// tests/integration_test.rs
use my_crate::Config;

#[test]
fn test_full_workflow() {
    let config = Config::default();
    let app = my_crate::App::new(config);
    let result = app.run_workflow("input.json");
    assert!(result.is_ok());
}
```

### Doc tests:
Every code example in doc comments (`///`) runs as a test automatically. Use `# ` to hide setup lines in doc tests:
```rust
/// ```
/// # use my_crate::Config;
/// let config = Config::from_file("config.toml")?;
/// assert_eq!(config.port, 8080);
/// # Ok::<(), Box<dyn std::error::Error>>(())
/// ```
```

### Property testing with proptest:
```rust
#[cfg(test)]
mod tests {
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn test_roundtrip_serialization(input in "\\PC{1,100}") {
            let encoded = encode(&input);
            let decoded = decode(&encoded).unwrap();
            assert_eq!(input, decoded);
        }

        #[test]
        fn test_parse_never_panics(input in ".*") {
            let _ = parse(&input);  // should not panic
        }
    }
}
```

## Common Commands

```bash
# Build the project
cargo build

# Build in release mode
cargo build --release

# Run all tests
cargo test

# Run tests with output visible
cargo test -- --nocapture

# Run a specific test
cargo test test_parse_valid_input

# Run Clippy lints
cargo clippy -- -D warnings

# Format code
cargo fmt

# Check formatting without modifying files
cargo fmt -- --check

# Generate and open documentation
cargo doc --open

# Audit dependencies for known vulnerabilities
cargo audit

# Check dependency licenses and advisories
cargo deny check

# Run benchmarks
cargo bench

# Build container image
podman build -t my-crate:latest .
```

## Unsafe Code Policy

- Unsafe code is forbidden by default (enforced via `#[forbid(unsafe_code)]` or the `unsafe_code = "forbid"` lint in `Cargo.toml`).
- If unsafe code is absolutely necessary, it must:
  1. Be isolated in a dedicated module with a safe public API.
  2. Have a `// SAFETY:` comment on every unsafe block explaining why the invariants are upheld.
  3. Be reviewed by at least two team members.
  4. Have tests that exercise the boundary conditions (including Miri where applicable).
- Run `cargo +nightly miri test` on any module containing unsafe code to detect undefined behavior.

## Dependency Management

### cargo-deny (deny.toml):
```toml
[advisories]
db-path = "~/.cargo/advisory-db"
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"

[licenses]
allow = [
    "MIT",
    "Apache-2.0",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Unicode-3.0",
]
confidence-threshold = 0.8

[bans]
multiple-versions = "warn"
wildcards = "deny"

[sources]
unknown-registry = "deny"
unknown-git = "deny"
allow-git = []
```

Run `cargo deny check` in CI to catch license violations and known vulnerabilities.

### General dependency rules:
- Prefer crates from well-known, actively maintained projects.
- Check download counts, recent release dates, and open issues before adding a dependency.
- Use `cargo tree` to inspect the full dependency graph.
- Avoid pulling in heavy frameworks when a smaller crate will do the job.

## Container Image

Use multi-stage builds with Red Hat Universal Base Image:

```dockerfile
# Build stage
FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

RUN dnf install -y gcc make && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src/ src/

RUN cargo build --release

# Runtime stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /app/target/release/my-crate /usr/local/bin/my-crate

USER 1001
ENTRYPOINT ["/usr/local/bin/my-crate"]
```

## .gitignore

```
# Build artifacts
/target/

# IDE files
.idea/
.vscode/
*.swp

# Debug symbols
*.pdb
*.dSYM/

# OS files
.DS_Store
Thumbs.db

# Environment
.env
```

## Common Mistakes to Avoid

- Do not use `.clone()` to satisfy the borrow checker without understanding why. Fix the ownership issue instead.
- Do not use `String` where `&str` would work. Accept borrowed data in function parameters when you do not need ownership.
- Do not ignore compiler warnings. Treat them as errors in CI with `-D warnings`.
- Do not use `println!` for logging in production code. Use the `tracing` or `log` crate.
- Do not use `Box<dyn Error>` in library code. Define explicit error types with `thiserror`.
- Do not use em dashes in comments or documentation. Use commas, periods, or "and" instead.
- Do not commit the `target/` directory.

## Review Checklist

Before merging:

- [ ] All tests pass (`cargo test`)
- [ ] Clippy reports no warnings (`cargo clippy -- -D warnings`)
- [ ] Code is formatted (`cargo fmt -- --check`)
- [ ] No new `unsafe` code without safety comments and review
- [ ] Public API has doc comments with examples
- [ ] Error types use `thiserror` (library) or `anyhow` (binary)
- [ ] `cargo deny check` passes (licenses and advisories)
- [ ] `cargo audit` reports no vulnerabilities
- [ ] No hardcoded configuration values
- [ ] `Cargo.lock` is committed (for binary crates)
- [ ] Container image builds and runs successfully
