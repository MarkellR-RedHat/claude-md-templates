# CLAUDE.md - Go Project

<!-- TODO: Replace "myapp" with your actual binary name -->
<!-- TODO: Set your Go module path (e.g., github.com/yourorg/yourrepo) -->
<!-- TODO: Set your Go version (currently 1.21+) -->
<!-- TODO: Update golangci-lint config to match your .golangci.yml -->
<!-- TODO: Update Makefile targets to match your project -->

## Project Overview

This is a Go project. It follows standard Go conventions and idioms. The codebase prioritizes readability, explicit error handling, testability, and safe concurrency.

## Go Version

- Use the Go version specified in `go.mod`. Do not upgrade without updating the CI pipeline to match.
- Minimum supported version: Go 1.21 (or as specified by the project).
- Confirm the `go.mod` version supports any version-gated features (generics, slog, range-over-func) before adding them.

## Project Structure

```
project-root/
  cmd/myapp/main.go          # Application entrypoint
  internal/
    config/                   # Configuration handling
    handler/                  # HTTP handlers or gRPC services
    middleware/                # HTTP middleware
    model/                    # Data models and types
    service/                  # Business logic
    store/                    # Data access layer
    observability/            # Metrics, tracing, logging setup
  pkg/client/                 # Public client libraries (if applicable)
  api/openapi/                # OpenAPI specs
  api/proto/                  # Protobuf definitions
  deploy/helm/
  deploy/kustomize/
  hack/                       # Development and build scripts
  testdata/                   # Test fixtures and golden files
  go.mod, go.sum, Makefile, Containerfile
```

- `internal/` for code that must not be imported externally.
- `pkg/` for code intended for external import. Use sparingly.
- `cmd/` has one directory per binary. `main.go` parses flags, loads config, wires dependencies, and calls `Run()`. No business logic.
- `testdata/` directories are ignored by the Go toolchain. Use them for fixtures, golden files, and test assets.

## Code Conventions

### Naming

- Read [Effective Go](https://go.dev/doc/effective_go). Use MixedCaps/mixedCaps. Never snake_case.
- Acronyms all caps: `HTTPClient`, `userID`, `apiURL`. Not `HttpClient` or `userId`.
- Interfaces describe behavior: `Reader`, `Validator`. Not `IReader` or `ReaderInterface`. Prefer single-method interfaces with `-er` suffix.
- Package names: lowercase, single-word, no parent directory repetition.

### Error Handling

- Always handle errors. Never discard with `_` without a documented reason.
- Wrap with context using `%w`: `return fmt.Errorf("connecting to database: %w", err)`. Never wrap without adding context; `fmt.Errorf("failed: %w", err)` adds nothing.
- Use sentinel errors for `errors.Is()` checks. Use custom error types for `errors.As()`.
- No `log.Fatal` or `os.Exit` outside `main()`. No panics for runtime errors.
- For deferred closes that can error, use named returns:
  ```go
  func writeFile(path string, data []byte) (retErr error) {
      f, err := os.Create(path)
      if err != nil { return fmt.Errorf("creating %s: %w", path, err) }
      defer func() {
          if cerr := f.Close(); cerr != nil && retErr == nil {
              retErr = fmt.Errorf("closing %s: %w", path, cerr)
          }
      }()
      _, err = f.Write(data)
      return err
  }
  ```

### Design Patterns

**Accept interfaces, return structs.** Keep your API concrete while allowing callers to substitute implementations.

**Functional options** for constructors with many configurable fields:
```go
type Option func(*Server)

func WithPort(port int) Option    { return func(s *Server) { s.port = port } }
func WithTimeout(d time.Duration) Option { return func(s *Server) { s.timeout = d } }

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{addr: addr, port: 8080, timeout: 30 * time.Second}
    for _, opt := range opts { opt(s) }
    return s
}
```

For options that need validation, change the signature to `func(*Server) error`.

**Middleware chaining** for composable HTTP behavior:
```go
type Middleware func(http.Handler) http.Handler

func Chain(h http.Handler, mw ...Middleware) http.Handler {
    for i := len(mw) - 1; i >= 0; i-- { h = mw[i](h) }
    return h
}
```

### Concurrency

- Never start a goroutine without a plan for how it stops.
- Use `context.Context` for cancellation. Use `errgroup` from `golang.org/x/sync` for goroutine groups.
- Prefer channels for coordination, mutexes for data protection.
- Always document which fields a mutex guards:
  ```go
  type Cache struct {
      mu    sync.RWMutex
      items map[string]Item // guarded by mu
  }
  ```

### Logging

- Use `slog` (Go 1.21+). Include context: `slog.Info("processing request", "request_id", reqID)`.
- Levels: `Debug` for dev details, `Info` for normal ops, `Warn` for recoverable issues, `Error` for failures.
- Do not log and return an error. One or the other, never both.

## Dependencies and Modules

- Keep dependencies minimal. The standard library is extensive.
- Vet new dependencies: maintenance status, license, security history.
- Run `go mod tidy` before committing. Use `go mod vendor` if the project vendors.

### Private modules

```bash
export GOPRIVATE="github.com/yourorg/*"
export GONOSUMDB="github.com/yourorg/*"
```

### Multi-module repos

Use workspace mode for local development. Do NOT commit `go.work` or `go.work.sum`; add them to `.gitignore`.

### Replace directives

Never ship a `go.mod` with a local filesystem `replace`. Forked dependency pins are acceptable:
```
replace github.com/upstream/pkg => github.com/yourorg/pkg v1.2.3-patched
```

### Version selection

Go uses Minimum Version Selection. Debug with `go mod why -m` and `go mod graph | grep`.

### golangci-lint

```yaml
run:
  timeout: 5m
  go: "1.21"
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - gofmt
    - goimports
    - misspell
    - revive
    - gosec
    - unparam
    - prealloc
    - bodyclose
    - noctx
linters-settings:
  govet:
    enable-all: true
  misspell:
    locale: US
  gosec:
    excludes:
      - G104  # covered by errcheck
issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

### Dependency injection

Define interfaces where they are used, not where implemented. Inject through constructors:
```go
type UserStore interface {
    GetUser(ctx context.Context, id string) (*User, error)
}
func NewUserService(store UserStore, logger *slog.Logger) *UserService {
    return &UserService{store: store, logger: logger}
}
```

For complex graphs, use [Wire](https://github.com/google/wire) for compile-time DI.

## Security

### Input validation

Validate all external input at the boundary. Never trust HTTP requests, message queues, or file uploads:
```go
func (r *CreateUserRequest) Validate() error {
    if len(r.Name) == 0 || len(r.Name) > 255 {
        return errors.New("name must be 1-255 characters")
    }
    if !emailRegex.MatchString(r.Email) {
        return errors.New("invalid email format")
    }
    return nil
}
```

### SQL injection prevention

Always use parameterized queries. Never interpolate user input into SQL:
```go
// CORRECT
row := db.QueryRowContext(ctx, "SELECT id, name FROM users WHERE email = $1", email)
// WRONG: SQL injection
// query := fmt.Sprintf("SELECT id, name FROM users WHERE email = '%s'", email)
```

This applies to `sqlx`, `pgx`, and all other drivers.

### Cryptography

- `crypto/rand` for random values. Never `math/rand` for tokens, keys, or nonces.
- `golang.org/x/crypto/bcrypt` or `argon2` for password hashing. Never MD5 or SHA for passwords.
- `crypto/aes` with GCM mode for symmetric encryption. Never ECB.
- Never roll your own crypto primitives.

### TLS configuration

```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    CurvePreferences: []tls.CurveID{tls.X25519, tls.CurveP256},
}
```

### Secure HTTP headers

```go
func WithSecurityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("Content-Security-Policy", "default-src 'self'")
        w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
        next.ServeHTTP(w, r)
    })
}
```

### Handling gosec findings

Do not blindly suppress findings. Evaluate each one:

- **G101 (hardcoded credentials)**: Usually false positive on variable names. Suppress with `//nolint:gosec // G101: config key name, not a credential`.
- **G104 (unhandled errors)**: Fix the code. Suppress only with justification.
- **G114 (serve without timeout)**: Always set timeouts on `http.Server`. See API Design section.
- **G304 (file path from variable)**: Validate with `filepath.Clean`, verify path stays within expected directory.
- **G401/G501 (weak crypto)**: Switch to a stronger algorithm unless interop requires the weak one.

Always include rule number and rationale in nolint comments.

## Testing

### Conventions

- Test files next to source: `handler.go` and `handler_test.go` in the same directory.
- Table-driven tests for multiple scenarios. Use `t.Helper()`, `t.Parallel()`, `t.Cleanup()`.
- Mock dependencies via interfaces you own. Do not mock things you do not own; wrap them first.

### Golden file testing

For complex outputs (JSON, templates, CLI output), compare against golden files in `testdata/`:
```go
var update = flag.Bool("update", false, "update golden files")

func TestRenderOutput(t *testing.T) {
    got := renderSomething()
    golden := filepath.Join("testdata", t.Name()+".golden")
    if *update {
        os.WriteFile(golden, []byte(got), 0o644)
        return
    }
    want, _ := os.ReadFile(golden)
    if diff := cmp.Diff(string(want), got); diff != "" {
        t.Errorf("mismatch (-want +got):\n%s", diff)
    }
}
```

Regenerate with `go test ./... -update`.

### httptest

Test HTTP handlers without a real server:
```go
func TestGetUser(t *testing.T) {
    handler := NewHandler(&mockUserStore{user: &User{ID: "123", Name: "Alice"}})
    req := httptest.NewRequest(http.MethodGet, "/users/123", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)
    if w.Code != http.StatusOK {
        t.Fatalf("expected 200, got %d", w.Code)
    }
}
```

### testcontainers-go for integration tests

```go
//go:build integration

func TestUserStorePostgres(t *testing.T) {
    ctx := context.Background()
    pg, err := postgres.Run(ctx, "docker.io/postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
    )
    testcontainers.CleanupContainer(t, pg)
    require.NoError(t, err)

    connStr, err := pg.ConnectionString(ctx, "sslmode=disable")
    require.NoError(t, err)
    // Open db, run migrations, test your store.
}
```

### Fuzz testing

Use Go's built-in fuzzing (Go 1.18+) for parsers and transformers:
```go
func FuzzParseConfig(f *testing.F) {
    f.Add([]byte(`{"port": 8080}`))
    f.Add([]byte(`invalid`))
    f.Fuzz(func(t *testing.T, data []byte) {
        cfg, err := ParseConfig(data)
        if err != nil { return }
        if cfg.Port < 0 { t.Errorf("negative port: %d", cfg.Port) }
    })
}
```

Run: `go test -fuzz=FuzzParseConfig -fuzztime=30s ./internal/config/`

### Build constraints for test categories

```go
//go:build integration
```

```bash
go test ./... -short                          # unit tests only
go test ./... -tags=integration -count=1      # integration tests
go test ./... -tags=integration -race -count=1 # all with race detection
```

Use `-count=1` to disable caching for integration tests (they depend on external state).

### Running tests

```bash
go test ./... -v -short                     # unit tests
go test ./... -race                         # race detection
go test ./... -tags=integration -count=1    # integration
go test ./... -coverprofile=coverage.out    # coverage
go tool cover -html=coverage.out
go test -bench=. -benchmem ./...            # benchmarks
```

## Performance

### Profiling with pprof

Import `net/http/pprof` behind a build tag for dev builds:
```go
//go:build debug

import _ "net/http/pprof"
func init() { go http.ListenAndServe("localhost:6060", nil) }
```

Collect profiles:
```bash
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30  # CPU
go tool pprof http://localhost:6060/debug/pprof/heap                # memory
go tool pprof http://localhost:6060/debug/pprof/goroutine           # goroutine leaks
go tool pprof http://localhost:6060/debug/pprof/mutex               # contention
```

Enable mutex/block profiling only when diagnosing (they have overhead):
```go
runtime.SetMutexProfileFraction(5)
runtime.SetBlockProfileRate(1)
```

### Benchmarking

```go
func BenchmarkProcessOrder(b *testing.B) {
    order := makeTestOrder()
    b.ReportAllocs()
    b.ResetTimer()
    for b.Loop() { processOrder(order) }
}
```

Compare before/after with `benchstat`:
```bash
go test -bench=. -benchmem -count=6 ./... > old.txt
# make changes
go test -bench=. -benchmem -count=6 ./... > new.txt
benchstat old.txt new.txt
```

### Reducing allocations

Check escape analysis: `go build -gcflags='-m -m' ./... 2>&1 | grep 'escapes to heap'`

- Preallocate slices: `make([]T, 0, expectedSize)`
- Pointer receivers on large structs
- `strings.Builder` instead of `+` in loops (O(n) vs O(n^2))
- `sync.Pool` for frequently allocated temporaries when profiling shows GC pressure:
  ```go
  var bufPool = sync.Pool{New: func() any { return new(bytes.Buffer) }}
  func process(data []byte) string {
      buf := bufPool.Get().(*bytes.Buffer)
      buf.Reset()
      defer bufPool.Put(buf)
      buf.Write(data)
      return buf.String()
  }
  ```

## API Design Patterns

### Graceful shutdown

Always configure timeouts and handle signals:
```go
func main() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    srv := &http.Server{
        Addr: ":8080", Handler: newRouter(),
        ReadTimeout: 5 * time.Second, WriteTimeout: 10 * time.Second, IdleTimeout: 120 * time.Second,
    }
    go func() {
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            slog.Error("server error", "error", err)
            os.Exit(1)
        }
    }()
    <-ctx.Done()

    shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
    defer cancel()
    srv.Shutdown(shutdownCtx)
}
```

### Health checks

Provide liveness (`/healthz`) and readiness (`/readyz`) for Kubernetes. Liveness returns 200 unconditionally. Readiness checks dependencies (database, cache) with a short timeout.

### Rate limiting

Use `golang.org/x/time/rate`:
```go
func WithRateLimit(rps float64) Middleware {
    limiter := rate.NewLimiter(rate.Limit(rps), int(rps))
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

For per-client limiting, use a map of limiters keyed by IP or API key with periodic stale-entry cleanup.

### Request validation middleware

Enforce content type and body size at the middleware layer using `http.MaxBytesReader`.

### OpenTelemetry instrumentation

```go
var tracer = otel.Tracer("github.com/yourorg/myapp/internal/service")

func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    ctx, span := tracer.Start(ctx, "OrderService.CreateOrder",
        trace.WithAttributes(attribute.String("user_id", req.UserID)),
    )
    defer span.End()
    // Business logic. Instrumented DB drivers and HTTP clients create child spans automatically.
    if err != nil { span.RecordError(err); return nil, err }
    return order, nil
}
```

Use OTLP exporter to send to your collector (Jaeger, Tempo, or OTel Collector).

## Build and CI

### Building with version injection

```bash
go build -ldflags="-s -w \
  -X main.version=$(git describe --tags --always --dirty) \
  -X main.commit=$(git rev-parse HEAD)" \
  -o bin/myapp ./cmd/myapp
```

Declare in `main.go`: `var version, commit = "dev", "unknown"`

Use `-s -w` to strip debug symbols for smaller production binaries.

### Cross-compilation

```bash
GOOS=linux GOARCH=amd64 go build -o bin/myapp-linux-amd64 ./cmd/myapp
GOOS=linux GOARCH=arm64 go build -o bin/myapp-linux-arm64 ./cmd/myapp
```

### CGO considerations

- If CGO is not needed: `CGO_ENABLED=0 go build ...` for a fully static binary.
- If CGO is required (e.g., `go-sqlite3`), you need a C cross-compiler. Consider `zig cc` or building in a container for the target arch.

### Multi-arch container builds

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.21 AS builder
ARG TARGETOS TARGETARCH
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o /app/bin/myapp ./cmd/myapp

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
COPY --from=builder /app/bin/myapp /usr/local/bin/myapp
USER 1001
ENTRYPOINT ["/usr/local/bin/myapp"]
```

Build: `podman build --platform linux/amd64,linux/arm64 -t myapp:latest .`

### Makefile

```makefile
VERSION ?= $(shell git describe --tags --always --dirty)
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.commit=$(shell git rev-parse HEAD)

.PHONY: build test test-integration lint fmt clean container-build bench

build:              ; go build -ldflags="$(LDFLAGS)" -o bin/myapp ./cmd/myapp
test:               ; go test ./... -race -short
test-integration:   ; go test ./... -tags=integration -race -count=1
lint:               ; golangci-lint run ./...
fmt:                ; gofmt -w . && goimports -w .
clean:              ; rm -rf bin/ dist/ coverage.out
container-build:    ; podman build -t myapp:$(VERSION) .
bench:              ; go test -bench=. -benchmem ./...
```

## Common Pitfalls

### Goroutine leaks

A goroutine that blocks forever is a memory leak. Always provide an exit path:
```go
// WRONG: leaks if ctx is never canceled and ch never receives
go func() { val := <-ch; process(val) }()

// CORRECT: exits on cancellation
go func() {
    select {
    case val := <-ch: process(val)
    case <-ctx.Done(): return
    }
}()
```

Detect with the goroutine pprof profile. A steadily increasing count is a leak.

### Deferred calls in loops

`defer` runs at function return, not loop-iteration end. Wrap in a closure:
```go
for _, path := range paths {
    if err := func() error {
        f, err := os.Open(path)
        if err != nil { return err }
        defer f.Close()
        return processFile(f)
    }(); err != nil { return err }
}
```

### Nil interface vs nil pointer

An interface is nil only when both type and value are nil. A nil pointer in an interface is not nil:
```go
func mayFail() error {
    var err *MyError // nil pointer
    return err       // WRONG: non-nil interface holding nil *MyError
}
// Fix: return nil explicitly when err is nil
```

### Slice append and shared backing arrays

```go
original := []int{1, 2, 3, 4, 5}
sub := original[1:3]     // shares backing array
sub = append(sub, 99)    // overwrites original[3]

sub := original[1:3:3]   // full slice expression, capacity = length
sub = append(sub, 99)    // new backing array, original unchanged
```

When returning a small slice from a large one, `copy` into a new slice to release the original.

### Map concurrent access

Concurrent map read+write causes a runtime panic (not just a data race). Protect with `sync.RWMutex` or use `sync.Map` for read-heavy, stable-key workloads.

### time.After leaks in select

`time.After` allocates a timer that lives until it fires. In a loop, this leaks:
```go
// WRONG: leaks a timer per iteration
for { select { case msg := <-ch: process(msg); case <-time.After(5*time.Second): return } }

// CORRECT: reuse a single timer with Stop/Reset
```

### Iota for persisted values

Adding a constant in the middle changes all subsequent values. Use explicit values for anything serialized or stored:
```go
const (
    StatusPending  = 0
    StatusApproved = 1
    StatusRejected = 2
)
```

`iota` is fine for internal-only enumerations that are never persisted.

### Struct field alignment

Order fields largest-to-smallest to minimize padding. Use `fieldalignment` from `golang.org/x/tools` to check. Only worth optimizing for high-allocation types.

### Other mistakes

- No `init()` unless absolutely necessary.
- No global mutable state. Pass dependencies explicitly.
- No em dashes in comments or documentation.
- No `interface{}` or `any` when a specific type works.
- No shadowing the `err` variable in nested scopes.
- No `context.Background()` in library code. Accept and propagate context.
- Do not commit generated files that can be regenerated (except `go.sum`).

## Review Checklist

Before merging:

- [ ] Tests pass with race detection (`go test -race ./...`)
- [ ] `golangci-lint` reports no issues
- [ ] Code formatted with `gofmt`
- [ ] Errors include context about what operation failed
- [ ] New public APIs have godoc comments
- [ ] No hardcoded config values (URLs, ports, credentials)
- [ ] `go mod tidy` run
- [ ] Container image builds and runs
- [ ] Graceful shutdown for long-running processes
- [ ] SQL uses parameterized queries, never string interpolation
- [ ] HTTP servers have read/write/idle timeouts
- [ ] New goroutines have a defined exit path
- [ ] Secure randomness uses `crypto/rand`
- [ ] Health checks present for deployable services
