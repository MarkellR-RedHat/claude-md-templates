# CLAUDE.md - Go Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Replace "myapp" with your actual binary name -->
<!-- TODO: Set your Go module path (e.g., github.com/yourorg/yourrepo) -->
<!-- TODO: Set your Go version (currently 1.21+) -->
<!-- TODO: Update golangci-lint config to match your .golangci.yml -->
<!-- TODO: Update Makefile targets to match your project -->

## Project Overview

This is a Go project. It follows standard Go conventions and idioms. The codebase prioritizes readability, explicit error handling, and testability.

## Go Version

- Use the Go version specified in `go.mod`. Do not upgrade without updating the CI pipeline to match.
- Minimum supported version: Go 1.21 (or as specified by the project).

## Project Structure

Follow the standard Go project layout:

```
project-root/
  cmd/
    myapp/
      main.go            # Application entrypoint
  internal/
    config/              # Configuration handling
    handler/             # HTTP handlers or gRPC services
    middleware/           # HTTP middleware
    model/               # Data models and types
    service/             # Business logic
    store/               # Data access layer
  pkg/
    client/              # Public client libraries (if applicable)
  api/
    openapi/             # OpenAPI specs
    proto/               # Protobuf definitions
  deploy/
    helm/
    kustomize/
  hack/                  # Development and build scripts
  docs/
  go.mod
  go.sum
  Makefile
  Containerfile
```

### Package layout rules:
- `internal/` is for code that should not be imported by external projects.
- `pkg/` is for code intended to be imported by external consumers. Use it sparingly.
- `cmd/` contains one directory per binary. Each directory should have a `main.go` that does minimal setup and delegates to `internal/` packages.
- Do not put application logic in `main.go`. It should parse flags, load config, and call `Run()`.

## Code Conventions

### Naming
- Follow Go naming conventions. Read [Effective Go](https://go.dev/doc/effective_go) if unfamiliar.
- Use MixedCaps (exported) or mixedCaps (unexported). Never use snake_case for Go identifiers.
- Acronyms should be all caps: `HTTPClient`, `userID`, `apiURL`. Not `HttpClient` or `userId`.
- Interface names should describe behavior, not things: `Reader`, `Closer`, `Validator`. Not `IReader` or `ReaderInterface`.
- Single-method interfaces are preferred and can use the `-er` suffix convention.

### Error Handling
- Always handle errors. Never use `_` to discard an error unless you have a documented reason.
- Wrap errors with context using `fmt.Errorf` and the `%w` verb:
  ```go
  if err != nil {
      return fmt.Errorf("failed to connect to database: %w", err)
  }
  ```
- Use sentinel errors (`var ErrNotFound = errors.New("not found")`) for errors that callers need to check with `errors.Is()`.
- Use custom error types when callers need to extract error details with `errors.As()`.
- Do not use `log.Fatal` or `os.Exit` outside of `main()`. They prevent deferred functions from running and make testing impossible.
- Do not panic for expected error conditions. Panics are for programmer errors, not runtime errors.

### Functions
- Keep functions short and focused. If a function exceeds 50 lines, consider splitting it.
- Prefer returning errors over using output parameters.
- Use functional options for complex constructors:
  ```go
  func NewServer(addr string, opts ...Option) *Server
  ```
- Context should be the first parameter when present: `func DoSomething(ctx context.Context, id string) error`

### Concurrency
- Do not start goroutines without a plan for how they will stop.
- Use `context.Context` for cancellation and timeouts.
- Use `errgroup` from `golang.org/x/sync` for managing groups of goroutines.
- Protect shared state with mutexes or use channels. Prefer channels for coordination and mutexes for protecting data.
- Document which fields are safe for concurrent access.

### Logging
- Use structured logging with `slog` (standard library, Go 1.21+) or `logr`.
- Include relevant context in log messages:
  ```go
  slog.Info("processing request", "requestID", reqID, "userID", userID)
  ```
- Use appropriate log levels: `Debug` for development details, `Info` for normal operations, `Warn` for recoverable issues, `Error` for failures that need attention.
- Do not log and return an error. Do one or the other, not both. Logging and returning causes duplicate log entries up the call stack.

## Dependencies

- Keep dependencies minimal. The Go standard library is extensive. Use it.
- Vet new dependencies before adding them. Check maintenance status, license, and security history.
- Run `go mod tidy` before committing to remove unused dependencies.
- Use `go mod vendor` if the project vendors dependencies. Keep the vendor directory in sync.

### .gitignore essentials

Include these entries in `.gitignore` for Go projects:
```text
# Build output
bin/
dist/

# IDE
.idea/
.vscode/
*.swp

# OS files
.DS_Store
Thumbs.db

# Test artifacts
coverage.out
coverage.html

# Dependency cache (only if not vendoring)
# vendor/

# Generated binaries
*.exe
*.test
*.prof
```

### golangci-lint configuration

Use a `.golangci.yml` file in the project root to configure linting:
```yaml
# .golangci.yml
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
    - typecheck
    - gofmt
    - goimports
    - misspell
    - revive
    - gosec
    - unparam
    - prealloc

linters-settings:
  revive:
    rules:
      - name: exported
        arguments:
          - "checkPrivateReceivers"
  govet:
    enable-all: true
  misspell:
    locale: US

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

### Godoc comment conventions

Follow these conventions for documentation comments:
```go
// Package handler provides HTTP request handling for the API.
//
// Each handler function takes a context and request, validates input,
// delegates to the service layer, and returns a structured response.
package handler

// UserService manages user lifecycle operations including
// creation, authentication, and profile updates.
type UserService struct {
    store Store
    cache Cache
}

// CreateUser registers a new user with the given profile data.
// It returns the created user with a generated ID, or an error
// if validation fails or the email is already registered.
func (s *UserService) CreateUser(ctx context.Context, profile Profile) (*User, error) {
```

Rules for godoc comments:
- Start comments with the name of the thing being documented.
- Use complete sentences with proper punctuation.
- Document exported types, functions, and package-level variables. No exceptions.
- For deprecated items, add `// Deprecated: Use NewFunction instead.` on its own line.

### Dependency injection patterns

Prefer constructor injection over global state. Use interfaces to decouple components:
```go
// Define the interface where it is used, not where it is implemented.
type UserStore interface {
    GetUser(ctx context.Context, id string) (*User, error)
    SaveUser(ctx context.Context, user *User) error
}

// Inject dependencies through the constructor.
func NewUserService(store UserStore, logger *slog.Logger) *UserService {
    return &UserService{
        store:  store,
        logger: logger,
    }
}
```

For complex dependency graphs, consider using [Wire](https://github.com/google/wire) for compile-time dependency injection:
```go
// wire.go
//go:build wireinject

func InitializeApp(cfg Config) (*App, error) {
    wire.Build(
        NewDatabase,
        NewUserStore,
        NewUserService,
        NewHTTPHandler,
        NewApp,
    )
    return nil, nil
}
```

Run `wire ./...` to generate the dependency wiring code. Commit the generated `wire_gen.go` file.

## Testing

### Test organization
- Test files live next to the code they test: `handler.go` and `handler_test.go` in the same directory.
- Use table-driven tests for functions with multiple input/output scenarios:
  ```go
  tests := []struct {
      name    string
      input   string
      want    string
      wantErr bool
  }{
      {"valid input", "hello", "HELLO", false},
      {"empty input", "", "", true},
  }
  for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) {
          got, err := Transform(tt.input)
          if (err != nil) != tt.wantErr {
              t.Errorf("Transform() error = %v, wantErr %v", err, tt.wantErr)
          }
          if got != tt.want {
              t.Errorf("Transform() = %v, want %v", got, tt.want)
          }
      })
  }
  ```
- Use `testify/assert` or `testify/require` if the project already uses testify. For new projects, the standard library `testing` package is sufficient.

### Test practices
- Use `t.Helper()` in test helper functions so error messages point to the right line.
- Use `t.Parallel()` for tests that can run concurrently.
- Use `t.Cleanup()` for teardown instead of `defer` in test functions.
- Mock external dependencies using interfaces. Do not mock things you do not own. Instead, wrap them in an interface you do own.
- For integration tests, use build tags: `//go:build integration`

### Running tests
```bash
# Run all unit tests
go test ./... -v -short

# Run tests with race detection
go test ./... -race

# Run integration tests
go test ./... -v -tags=integration

# Run tests with coverage
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

## Build and CI

```bash
# Build the binary
go build -o bin/myapp ./cmd/myapp

# Run linting
golangci-lint run ./...

# Format code
gofmt -w .

# Vet code
go vet ./...

# Build container image
podman build -t myapp:latest .
```

### Makefile targets
Include these standard targets in the Makefile:
- `make build` - Build the binary
- `make test` - Run unit tests
- `make test-integration` - Run integration tests
- `make lint` - Run linters
- `make fmt` - Format code
- `make clean` - Remove build artifacts
- `make docker-build` or `make container-build` - Build container image

## Container Image

Use Red Hat Universal Base Image as the base:
```dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
COPY --from=builder /app/bin/myapp /usr/local/bin/myapp
USER 1001
ENTRYPOINT ["/usr/local/bin/myapp"]
```

Use multi-stage builds. The build stage uses the Go image, and the final stage uses UBI minimal.

## Common Mistakes to Avoid

- Do not use `init()` functions unless absolutely necessary. They make code harder to test and reason about.
- Do not use global mutable state. Pass dependencies explicitly.
- Do not use em dashes in comments or documentation. Use commas, periods, or "and" instead.
- Do not commit generated files that can be regenerated from source (except `go.sum`, which must be committed).
- Do not use `interface{}` or `any` when a specific type would work.

## Review Checklist

Before merging:

- [ ] All tests pass, including race detection (`go test -race ./...`)
- [ ] `golangci-lint` reports no issues
- [ ] Code is formatted with `gofmt`
- [ ] Error messages include context
- [ ] New public APIs have godoc comments
- [ ] No hardcoded configuration values
- [ ] `go mod tidy` has been run
- [ ] Container image builds and runs successfully
