# CLAUDE.md - Rust Project

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Replace "my-crate" with your actual crate name -->
<!-- TODO: Set your Rust edition (2021 or 2024) -->
<!-- TODO: Set crate type: binary (src/main.rs), library (src/lib.rs), or both -->
<!-- TODO: Set your async runtime (tokio, async-std, or none) -->
<!-- TODO: Update Cargo workspace members if this is a multi-crate workspace -->

## Project Overview

This is a Rust project built with the 2021 edition targeting stable Rust. The codebase follows standard Rust idioms and prioritizes safety, performance, and clear error handling. All code must pass clippy pedantic lints, formatting checks, and security audits before merge.

## Project Structure

```
project-root/
  src/
    main.rs              # Binary entrypoint (keep minimal)
    lib.rs               # Library root
    bin/                 # Additional binaries
    config.rs            # Configuration types
    error.rs             # Error types
    models/              # Data models and types
    services/            # Business logic
    api/                 # HTTP handlers or gRPC services
  tests/
    integration_test.rs  # Integration tests (public API only)
    common/mod.rs        # Shared test utilities
  benches/benchmarks.rs  # Criterion benchmarks
  fuzz/fuzz_targets/     # cargo-fuzz targets
  examples/              # Runnable examples
  supply-chain/          # cargo-vet audit data
  Cargo.toml
  Cargo.lock             # Committed for binaries, not for libraries
  clippy.toml
  rustfmt.toml
  deny.toml              # cargo-deny configuration
  Containerfile
```

Layout rules: commit `Cargo.lock` for binaries only. Keep `main.rs` minimal: parse args, init tracing, call into library code. One file per logical unit, not one file per type.

## Workspace Management

```toml
# Root Cargo.toml
[workspace]
members = ["crates/my-core", "crates/my-cli", "crates/my-server"]
resolver = "2"

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
tracing = "0.1"
thiserror = "2"
anyhow = "1"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
pedantic = { level = "warn", priority = -1 }
```

Reference shared deps with `workspace = true` in each member. Inherit lints with `[lints] workspace = true`.

**Feature unification caveat:** Cargo unifies features across the workspace during builds. If crate A uses `tokio/net` and crate B uses `tokio/fs`, both get both features when built together. This masks missing feature declarations. Build each crate in isolation during CI: `cargo check -p my-core`.

**Publishing order:** Publish in dependency order (leaves first). Use `cargo-release` with `shared-version = true` to automate this across workspace members.

## Cargo Conventions

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"
license = "Apache-2.0"

[features]
default = []
openssl-tls = ["reqwest/native-tls"]
rustls-tls = ["reqwest/rustls-tls"]
```

Feature flag rules: keep defaults minimal. Gate heavy deps behind features. Document every flag. Test with `--no-default-features` and each flag individually in CI.

## Code Conventions

**Naming:** `snake_case` for functions/variables/modules. `PascalCase` for types/traits/enum variants. `SCREAMING_SNAKE_CASE` for constants. Short lifetimes (`'a`) for simple cases, descriptive (`'conn`) for complex.

**Formatting:** Use `rustfmt` with the project's `rustfmt.toml` (edition 2021, max_width 100). Never override in code.

**Documentation:** All public items get doc comments. Include `# Examples`, `# Errors`, and `# Panics` sections. Doc comment examples are doc tests; use `# ` to hide setup lines.

## Error Handling

**Library crates: `thiserror`.** Define explicit error types so callers can match on variants:

```rust
#[derive(Debug, thiserror::Error)]
pub enum ServiceError {
    #[error("resource not found: {id}")]
    NotFound { id: String, kind: &'static str },
    #[error("database error")]
    Database(#[from] sqlx::Error),
    #[error("validation failed: {0}")]
    Validation(String),
    #[error("request timed out after {duration_ms}ms")]
    Timeout { duration_ms: u64 },
}

// Nested error types for layered subsystems
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("service layer failure")]
    Service(#[from] ServiceError),
    #[error("configuration error")]
    Config(#[from] ConfigError),
}
```

**Binary crates: `anyhow`.** Use `.context()` to add information at each call site:

```rust
use anyhow::{Context, Result};

fn load_config(path: &Path) -> Result<Config> {
    let contents = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read config file: {}", path.display()))?;
    let config: Config = toml::from_str(&contents)
        .context("failed to parse config as TOML")?;
    config.validate()
        .context("config validation failed")?;
    Ok(config)
}

fn main() -> Result<()> {
    let config = load_config(Path::new("/etc/myapp/config.toml"))
        .context("failed to initialize application")?;
    // ...
    Ok(())
}
```

**Binary crates: `color-eyre`.** Use for color-coded backtraces with tracing span traces during development:

```rust
use color_eyre::eyre::{self, WrapErr, Result};

fn main() -> Result<()> {
    color_eyre::install()?;  // call once, before any errors
    tracing_subscriber::fmt::init();

    let config = load_config()
        .wrap_err("application startup failed")?;
    run_server(config).await
}
```

**Context layering:** Each layer adds information the layer below does not have. Low level: the file path. Mid level: "failed to parse config." High level: "failed to initialize application."

**`Box<dyn Error>` vs concrete types:** Libraries always use concrete types. Binaries use `anyhow::Error`. Use `Box<dyn Error + Send + Sync + 'static>` in trait object APIs as a last resort.

**Rules:** Never `.unwrap()` in library code without a proof comment. Use `?` for propagation. Implement `From` or `#[from]` for error conversion. Keep `source()` chains intact.

## Async Patterns with Tokio

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> { /* ... */ }
```

For libraries, do not choose a runtime. Accept a generic `Future`.

**Graceful shutdown with CancellationToken:**

```rust
use tokio_util::sync::CancellationToken;

async fn run_server(token: CancellationToken) -> anyhow::Result<()> {
    let listener = TcpListener::bind("0.0.0.0:8080").await?;
    loop {
        tokio::select! {
            accepted = listener.accept() => {
                let (stream, addr) = accepted?;
                let child_token = token.child_token();
                tokio::spawn(handle_connection(stream, addr, child_token));
            }
            _ = token.cancelled() => {
                tracing::info!("shutdown signal received, stopping accept loop");
                break;
            }
        }
    }
    Ok(())
}

// In main: wire up ctrl-c
let token = CancellationToken::new();
let shutdown_token = token.clone();
tokio::spawn(async move {
    tokio::signal::ctrl_c().await.ok();
    shutdown_token.cancel();
});
```

**Structured concurrency with TaskTracker:**

```rust
use tokio_util::task::TaskTracker;

let tracker = TaskTracker::new();
let token = CancellationToken::new();

for item in work_items {
    let token = token.child_token();
    tracker.spawn(async move {
        tokio::select! {
            result = process(item) => { result }
            _ = token.cancelled() => { Ok(()) }
        }
    });
}

// Signal no more tasks, then wait for all in-flight work
tracker.close();
tracker.wait().await;
tracing::info!("all tasks completed cleanly");
```

**Backpressure with bounded channels:**

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<WorkItem>(1024);  // bounded!

// Producer: send() awaits if the channel is full
tokio::spawn(async move {
    for item in items {
        tx.send(item).await.expect("receiver dropped");
    }
});

// Consumer: process at its own pace
while let Some(item) = rx.recv().await {
    process(item).await;
}
```

**Tower Service and Layer pattern:**

```rust
use tower::{Service, ServiceBuilder, ServiceExt};
use std::time::Duration;

// Compose layers declaratively
let service = ServiceBuilder::new()
    .timeout(Duration::from_secs(30))
    .rate_limit(100, Duration::from_secs(1))
    .concurrency_limit(50)
    .layer(TraceLayer::new_for_http())
    .service(MyHandler);

// Custom Layer: add a request ID header
#[derive(Clone)]
struct RequestIdLayer;

impl<S> tower::Layer<S> for RequestIdLayer {
    type Service = RequestIdService<S>;
    fn layer(&self, inner: S) -> Self::Service {
        RequestIdService { inner }
    }
}

#[derive(Clone)]
struct RequestIdService<S> { inner: S }

impl<S, B> Service<http::Request<B>> for RequestIdService<S>
where
    S: Service<http::Request<B>>,
{
    type Response = S::Response;
    type Error = S::Error;
    type Future = S::Future;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, mut req: http::Request<B>) -> Self::Future {
        req.headers_mut().insert("x-request-id",
            uuid::Uuid::new_v4().to_string().parse().unwrap());
        self.inner.call(req)
    }
}
```

**Connection pooling:** Use `deadpool` or `bb8` for async connection pools to databases and other services.

**Cancellation safety:** `select!` cancels unfinished branches. Use cancellation-safe methods. Use `tokio::sync::Mutex` only when holding locks across `.await`; prefer `std::sync::Mutex` for synchronous critical sections.

**Send/Sync pitfalls:** Spawned futures must be `Send`. Holding a `std::sync::MutexGuard` across `.await` can make the future `!Send`. `Rc<T>` is `!Send` (use `Arc<T>`). `Cell`/`RefCell` are `!Sync` (use `Mutex`/`RwLock`). If you see "future cannot be sent between threads safely," check what non-Send type lives across an await point.

## Tracing and Observability

Use `tracing`, not `log`. It supports structured fields, span hierarchies, and async-aware instrumentation.

```rust
use tracing_subscriber::{fmt, EnvFilter, prelude::*};

tracing_subscriber::registry()
    .with(fmt::layer().with_target(true))
    .with(EnvFilter::from_default_env())
    .init();
```

Control levels via `RUST_LOG=my_crate=debug,tower_http=trace`.

**Instrument functions** with `#[instrument(skip(db), fields(user_id = %id))]`. Use `skip` for sensitive or large args. Spans nest automatically into structured trace trees.

```rust
use tracing::{info, warn, instrument, Span};

#[instrument(skip(db), fields(user_id = %user_id))]
async fn get_user(db: &Pool, user_id: i64) -> Result<User> {
    info!("fetching user from database");
    let user = db.fetch_one(query).await
        .map_err(|e| {
            warn!(error = %e, "database query failed");
            e
        })?;
    // Record a field after the fact
    Span::current().record("email", &user.email.as_str());
    Ok(user)
}
```

**OpenTelemetry setup:** Export traces to an OTLP collector using `tracing-opentelemetry` and `opentelemetry-otlp`:

```rust
use opentelemetry::trace::TracerProvider;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::{runtime, trace as sdktrace, Resource};
use tracing_opentelemetry::OpenTelemetryLayer;
use tracing_subscriber::{fmt, EnvFilter, prelude::*};

fn init_tracing() -> anyhow::Result<()> {
    let exporter = opentelemetry_otlp::SpanExporter::builder()
        .with_tonic()
        .with_endpoint("http://localhost:4317")
        .build()?;

    let provider = sdktrace::SdkTracerProvider::builder()
        .with_batch_exporter(exporter)
        .with_resource(Resource::builder()
            .with_service_name("my-service")
            .build())
        .build();

    let tracer = provider.tracer("my-service");

    tracing_subscriber::registry()
        .with(fmt::layer().with_target(true))
        .with(EnvFilter::from_default_env())
        .with(OpenTelemetryLayer::new(tracer))
        .init();

    Ok(())
}
```

**Metrics:** Use the `metrics` crate for counters, gauges, and histograms. Track request counts and latency at handler boundaries.

## Clippy Configuration

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
unwrap_used = "warn"
expect_used = "warn"
```

## Security

**Unsafe code** is forbidden by default. If absolutely necessary: isolate in a dedicated module with a safe public API, add `// SAFETY:` comments on every unsafe block, require two-reviewer approval, and exercise boundary conditions in tests.

**Miri** detects undefined behavior in unsafe code (use-after-free, out-of-bounds, data races, provenance violations):

```bash
# Run all tests under Miri
cargo +nightly miri test

# Strict mode: catches alignment and provenance issues
MIRIFLAGS="-Zmiri-symbolic-alignment-check -Zmiri-strict-provenance" cargo +nightly miri test

# Run a specific test under Miri
cargo +nightly miri test -- my_unsafe_test

# Miri with isolation disabled (needed for file I/O in tests)
MIRIFLAGS="-Zmiri-disable-isolation" cargo +nightly miri test
```

Miri cannot test FFI calls or inline assembly. Write pure-Rust wrappers around unsafe operations and test those wrappers under Miri.

**Fuzzing** with cargo-fuzz for any code that parses untrusted input:

```bash
# One-time setup
cargo install cargo-fuzz
cargo fuzz init
cargo fuzz add parse_input
```

```rust
// fuzz/fuzz_targets/parse_input.rs
#![no_main]
use libfuzzer_sys::fuzz_target;
fuzz_target!(|data: &[u8]| {
    if let Ok(s) = std::str::from_utf8(data) {
        let _ = my_crate::parse(s);
    }
});
```

For structured fuzzing, derive `Arbitrary` on input types:

```rust
// fuzz/fuzz_targets/parse_structured.rs
#![no_main]
use libfuzzer_sys::fuzz_target;
use arbitrary::Arbitrary;

#[derive(Arbitrary, Debug)]
struct FuzzInput {
    name: String,
    count: u32,
    enabled: bool,
}

fuzz_target!(|input: FuzzInput| {
    let _ = my_crate::process_request(input.name, input.count, input.enabled);
});
```

```bash
# Run for 5 minutes
cargo +nightly fuzz run parse_input -- -max_total_time=300

# Run with a corpus directory
cargo +nightly fuzz run parse_input corpus/parse_input/

# Minimize a crashing input
cargo +nightly fuzz tmin parse_input artifacts/parse_input/crash-abc123
```

**Supply chain security with cargo-vet:**

```bash
# Initialize vet for your project (creates supply-chain/ directory)
cargo vet init

# Check all dependencies against audit records
cargo vet check

# Certify a crate you have reviewed
cargo vet certify serde 1.0.197

# Import audits from trusted organizations
cargo vet trust --all mozilla

# When updating deps, see what needs review
cargo vet suggest
```

**RUSTSEC advisories:** Run `cargo audit --deny warnings` in CI. The `cargo deny check advisories` command covers this too if you use cargo-deny.

## Performance

**Release profile:**

```toml
[profile.release]
lto = "fat"
codegen-units = 1
strip = "symbols"
panic = "abort"

[profile.release-with-debug]
inherits = "release"
strip = false
debug = true
```

**Benchmarking with Criterion:**

```rust
// benches/benchmarks.rs
use criterion::{black_box, criterion_group, criterion_main, BenchmarkId, Criterion};

fn bench_parse(c: &mut Criterion) {
    let mut group = c.benchmark_group("parse");

    for size in [64, 256, 1024, 4096] {
        let input = generate_input(size);
        group.bench_with_input(
            BenchmarkId::new("json", size),
            &input,
            |b, input| b.iter(|| my_crate::parse_json(black_box(input))),
        );
        group.bench_with_input(
            BenchmarkId::new("toml", size),
            &input,
            |b, input| b.iter(|| my_crate::parse_toml(black_box(input))),
        );
    }
    group.finish();
}

criterion_group!(benches, bench_parse);
criterion_main!(benches);
```

```bash
# Run benchmarks and save a baseline
cargo bench -- --save-baseline main

# Run again after changes and compare
cargo bench -- --baseline main
```

Never optimize without measuring. Use `BenchmarkGroup` for parameterized benchmarks across input sizes.

**Profiling:** Use `cargo flamegraph` to generate flamegraphs from binaries or benchmarks. Build with `release-with-debug` profile for useful stack traces.

**Allocation tracking with DHAT:**

```toml
# Cargo.toml
[features]
dhat-heap = ["dhat"]

[dependencies]
dhat = { version = "0.3", optional = true }
```

```rust
// src/main.rs
#[cfg(feature = "dhat-heap")]
#[global_allocator]
static ALLOC: dhat::Alloc = dhat::Alloc;

fn main() {
    #[cfg(feature = "dhat-heap")]
    let _profiler = dhat::Profiler::new_heap();

    // ... rest of main
}
```

```bash
# Run with allocation tracking, then open dhat-heap.json in a viewer
cargo run --features dhat-heap
# Open https://nnethercote.github.io/dh_view/dh_view.html and load the JSON
```

**Zero-copy patterns:** Accept `&str` over `String` and `&[u8]` over `Vec<u8>` in parameters. Use `Cow<'_, str>` when allocation is sometimes needed. Use `bytes::Bytes` for networking. Use `zerocopy` or `bytemuck` for binary format deserialization. Prefer `&[T]` slices over `&Vec<T>`.

**SIMD:** Profile before reaching for manual SIMD. The compiler auto-vectorizes simple slice loops more than you expect. Check output with `cargo asm` or Godbolt. For explicit SIMD, use `std::simd` (nightly) or `wide` (stable).

## Testing

**Unit tests** live in `#[cfg(test)] mod tests` in the same file. They test internal logic and private functions.

**Integration tests** live in `tests/`. Each file compiles as a separate crate and tests the public API only.

**Doc tests** run from `///` examples automatically. Use `# ` to hide setup lines. End with `# Ok::<(), Box<dyn std::error::Error>>(())` for fallible examples.

**Shared utilities:** Place helpers in `tests/common/mod.rs`. Include test config factories and test server spawning helpers.

**Mocking with mockall:**

```rust
use mockall::automock;

#[cfg_attr(test, automock)]
pub trait UserRepository {
    fn find_by_id(&self, id: i64) -> Result<User, RepoError>;
    fn save(&self, user: &User) -> Result<(), RepoError>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;

    #[test]
    fn test_user_service_returns_not_found() {
        let mut mock_repo = MockUserRepository::new();
        mock_repo
            .expect_find_by_id()
            .with(eq(42))
            .times(1)
            .returning(|_| Err(RepoError::NotFound));

        let service = UserService::new(Box::new(mock_repo));
        let result = service.get_user(42);
        assert!(matches!(result, Err(ServiceError::NotFound { .. })));
    }

    #[test]
    fn test_user_service_saves_normalized_email() {
        let mut mock_repo = MockUserRepository::new();
        mock_repo
            .expect_save()
            .withf(|user| user.email == "test@example.com")
            .times(1)
            .returning(|_| Ok(()));

        let service = UserService::new(Box::new(mock_repo));
        service.create_user("Test@Example.COM").unwrap();
    }
}
```

**Snapshot testing with insta:**

```rust
#[cfg(test)]
mod tests {
    use insta::{assert_snapshot, assert_json_snapshot};

    #[test]
    fn test_error_display() {
        let err = ServiceError::NotFound {
            id: "abc-123".into(),
            kind: "document",
        };
        assert_snapshot!(err.to_string(), @"resource not found: abc-123");
    }

    #[test]
    fn test_api_response_shape() {
        let response = build_user_response(&test_user());
        assert_json_snapshot!(response, {
            ".created_at" => "[timestamp]",
            ".id" => "[uuid]",
        });
    }
}
```

Review pending snapshots with `cargo insta review`. Commit the `snapshots/` directory.

**Property testing with proptest:**

```rust
#[cfg(test)]
mod tests {
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn roundtrip_serialization(input in any::<MyStruct>()) {
            let serialized = serde_json::to_string(&input).unwrap();
            let deserialized: MyStruct = serde_json::from_str(&serialized).unwrap();
            assert_eq!(input, deserialized);
        }

        #[test]
        fn parser_never_panics(s in "\\PC{0,256}") {
            // Parser may return Err, but it must never panic
            let _ = my_crate::parse(&s);
        }

        #[test]
        fn bounded_values_stay_in_range(val in 0u32..1000) {
            let result = my_crate::clamp_and_scale(val);
            assert!(result <= 100);
        }
    }
}
```

**Async testing with tokio:**

```rust
#[cfg(test)]
mod tests {
    use tokio::sync::oneshot;

    #[tokio::test]
    async fn test_async_handler() {
        let pool = setup_test_db().await;
        let response = handle_request(&pool, test_request()).await.unwrap();
        assert_eq!(response.status(), 200);
    }

    #[tokio::test]
    async fn test_with_timeout() {
        let result = tokio::time::timeout(
            Duration::from_secs(5),
            slow_operation(),
        ).await;
        assert!(result.is_ok(), "operation should complete within 5 seconds");
    }
}
```

**Coverage:** Use `cargo llvm-cov --html --open` for reports. Use `--fail-under-lines 80` in CI to enforce thresholds.

## FFI Patterns

**Generating bindings:** Use `bindgen` in `build.rs` to generate Rust bindings from C headers. Always wrap raw bindings in a safe Rust API.

**Generating C headers:** Use `cbindgen` with a `cbindgen.toml` to generate headers from `#[no_mangle] pub extern "C"` functions. Prefix all exported symbols (e.g., `mycrate_parse`).

**Panics across FFI:** Unwinding across FFI is undefined behavior. Wrap FFI entry points in `std::panic::catch_unwind` and convert the result to an error code.

**Memory across FFI:** When Rust allocates for C, provide explicit free functions. Every `mycrate_create_*` needs a matching `mycrate_free_*`. Document ownership transfer in header comments. Use `std::mem::forget` to prevent Rust from dropping memory that C will own.

## Common Pitfalls

**Ownership:** Do not `.clone()` to satisfy the borrow checker without understanding why. Fix the ownership issue. Accept `&str` over `String` when you do not need ownership.

**Lifetime elision surprises:** With multiple reference params, the return lifetime ties to the first argument only. With `&self` methods, return ties to `&self`. Be explicit when the default is wrong.

**Pin and Unpin:** `Pin<P>` prevents moves. Most async futures are self-referential and need pinning. Most concrete types are `Unpin` so `Pin` has no effect. Use `Box::pin()` or `tokio::pin!()` when needed.

**Orphan rule:** You cannot impl a foreign trait for a foreign type. Use the newtype pattern (wrap in your own struct) or define extension traits.

**Deref coercion:** Method resolution follows the deref chain, which can shadow methods. Do not implement `Deref` for non-pointer types; use `AsRef` instead.

**Turbofish:** Goes on the function, not the type: `s.parse::<i32>()`, not `s.parse<i32>()`.

**Trait objects vs generics:** Use generics (static dispatch, zero-cost) by default. Switch to `dyn Trait` (dynamic dispatch, vtable) for heterogeneous collections, plugin interfaces, or to reduce compile time. Trait objects cannot use associated types or return `Self`.

**Drop order:** Struct fields drop top-to-bottom. Locals drop in reverse declaration order. Use explicit `drop()` if ordering matters for correctness.

**Iterator invalidation:** Rust prevents this at compile time via borrowing, but watch for logical issues: draining a collection mid-iteration, reusing stale indices, or collecting into the source collection.

**General:** Treat warnings as errors in CI (`-D warnings`). Use `tracing`, not `println!`. Never commit `target/`. Do not use em dashes in comments or documentation.

## CI/CD Patterns

```yaml
# .github/workflows/ci.yml (adapt for your CI system)
name: CI
on: [push, pull_request]

env:
  CARGO_TERM_COLOR: always
  RUSTFLAGS: "-D warnings"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: "rustfmt, clippy" }
      - uses: Swatinem/rust-cache@v2
      - run: cargo fmt -- --check
      - run: cargo clippy --all-targets --all-features

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        features:
          - "--no-default-features"
          - "--all-features"
          - "--features openssl-tls"
          - "--features rustls-tls"
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test ${{ matrix.features }}
      - run: cargo test --doc ${{ matrix.features }}

  msrv:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with: { toolchain: "1.75" }
      - uses: Swatinem/rust-cache@v2
      - run: cargo check --all-features

  cross:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target:
          - x86_64-unknown-linux-gnu
          - aarch64-unknown-linux-gnu
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { targets: "${{ matrix.target }}" }
      - uses: Swatinem/rust-cache@v2
      - run: cargo check --target ${{ matrix.target }} --all-features

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo install cargo-audit cargo-deny
      - run: cargo audit --deny warnings
      - run: cargo deny check advisories licenses bans sources
      - run: cargo vet check
```

**Cross-compilation:** Test `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu`, `x86_64-apple-darwin`, and `aarch64-apple-darwin` in a matrix. For macOS targets, use `runs-on: macos-latest`.

**Feature flag matrix:** Test `--no-default-features`, each individual feature, and `--all-features` in a CI matrix. This catches missing feature gates and accidental feature unification.

**MSRV policy:** Declare `rust-version` in `Cargo.toml`. Test against it in CI. Bump deliberately and note it in the changelog.

**Changelog:** Use `git-cliff` with conventional commits to generate changelogs. Configure commit parsers for feat/fix/perf/refactor groups.

**Release:** Use `cargo release --execute patch` (or minor/major). Dry run first with `--dry-run`. It bumps versions, commits, tags, and publishes.

## Dependency Management

```toml
# deny.toml
[advisories]
vulnerability = "deny"
unmaintained = "warn"
yanked = "warn"

[licenses]
allow = ["MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Unicode-3.0"]

[bans]
multiple-versions = "warn"
wildcards = "deny"

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```

Prefer well-maintained crates. Check download counts and recent activity. Use `cargo tree -d` to find duplicate deps. Avoid heavy frameworks when smaller crates work.

## Container Image

```dockerfile
FROM registry.access.redhat.com/ubi9/ubi:latest AS builder
RUN dnf install -y gcc make && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
RUN cargo build --release

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
COPY --from=builder /app/target/release/my-crate /usr/local/bin/my-crate
USER 1001
ENTRYPOINT ["/usr/local/bin/my-crate"]
```

## Common Commands

```bash
cargo build                                              # debug build
cargo build --release                                    # release build
cargo test --all-features                                # all tests
cargo test -- --nocapture                                # tests with stdout
cargo clippy --all-targets --all-features -- -D warnings # lint
cargo fmt -- --check                                     # format check
cargo doc --open                                         # generate docs
cargo audit                                              # security audit
cargo deny check                                         # licenses and advisories
cargo vet check                                          # supply chain audit
cargo bench                                              # benchmarks
cargo llvm-cov --html --open                             # coverage
cargo flamegraph --bin my-crate                          # profiling
cargo +nightly fuzz run parse_input                      # fuzzing
cargo +nightly miri test                                 # unsafe verification
cargo tree -d                                            # duplicate deps
podman build -t my-crate:latest .                        # container
```

## Review Checklist

- [ ] All tests pass (`cargo test --all-features`)
- [ ] Clippy clean (`cargo clippy --all-targets --all-features -- -D warnings`)
- [ ] Code formatted (`cargo fmt -- --check`)
- [ ] No new `unsafe` without safety comments and two-reviewer approval
- [ ] Public API has doc comments with examples
- [ ] Errors use `thiserror` (library) or `anyhow` (binary)
- [ ] `cargo deny check` and `cargo audit` pass
- [ ] New deps audited (`cargo vet check`)
- [ ] No hardcoded config values
- [ ] `Cargo.lock` committed (binary crates only)
- [ ] Benchmarks run if perf-critical code changed
- [ ] Tracing spans added for new async operations
- [ ] MSRV not accidentally bumped
- [ ] Container image builds and runs
