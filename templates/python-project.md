# CLAUDE.md - Python Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Replace "mypackage" with your actual package name -->
<!-- TODO: Set your Python version (currently 3.11) -->
<!-- TODO: Update the ruff config to match your pyproject.toml -->
<!-- TODO: Update test commands to match your Makefile targets -->
<!-- TODO: Set your CI tool (GitHub Actions, Tekton, Jenkins) -->

## Project Overview

This is a Python project. It follows modern Python conventions with an emphasis on type safety, testability, clear dependency management, and production readiness.

## Python Version

- Target Python 3.11+ unless the project specifies otherwise.
- Use the version specified in `pyproject.toml` or `.python-version`.
- Do not use features deprecated in the target Python version.
- When writing version-specific code, guard it:
  ```python
  import sys
  if sys.version_info >= (3, 12):
      from typing import override
  else:
      from typing_extensions import override
  ```

## Project Structure

```
project-root/
  src/
    mypackage/
      __init__.py
      __main__.py          # Entry point for `python -m mypackage`
      main.py              # Application bootstrap and startup
      config.py            # Configuration and settings
      models.py            # Data models (Pydantic, dataclasses)
      exceptions.py        # Custom exception hierarchy
      services/            # Business logic
      api/                 # API routes and handlers
      utils/               # Utility functions (keep this thin)
  tests/
    unit/
      test_models.py
      test_services.py
    integration/
      test_api.py
    conftest.py            # Shared fixtures
  pyproject.toml
  requirements.txt         # Or use uv.lock / poetry.lock
  Containerfile
  Makefile
  .python-version
```

### Layout rules

- Use the `src/` layout. This prevents accidentally importing the package from the project root instead of the installed version.
- Keep `__init__.py` files minimal. No logic. At most an `__all__` list and version metadata.
- Define `__all__` in every module that will be imported by others. This controls `from module import *` and documents the public API.
  ```python
  __all__ = ["InferenceRequest", "InferenceResponse", "ModelConfig"]
  ```
- Group related classes and functions in the same module. Split when a module exceeds ~500 lines.
- Keep `utils/` thin. If a utility module grows, it deserves its own properly named module.

## Code Conventions

### Style and Formatting

- Use `ruff` for linting and formatting. It replaces flake8, isort, and black.
- Configure ruff in `pyproject.toml`:
  ```toml
  [tool.ruff]
  target-version = "py311"
  line-length = 100

  [tool.ruff.lint]
  select = [
      "E", "F", "I", "N", "W", "UP", "B", "A", "SIM", "TCH",
      "S",    # flake8-bandit (security)
      "DTZ",  # flake8-datetimez (timezone-aware datetime)
      "PT",   # flake8-pytest-style
      "RUF",  # ruff-specific rules
  ]
  ignore = ["S101"]  # allow assert in tests

  [tool.ruff.lint.per-file-ignores]
  "tests/**/*.py" = ["S101", "S106"]
  ```
- Maximum line length is 100 characters.

### Type Hints

- Use type hints on all function signatures. This is not optional.
- Use modern syntax (Python 3.10+): `list[str]`, `str | None`, not `List[str]`, `Optional[str]`.
- Use `TypeAlias` for complex types. Use `Protocol` for callback signatures.
- Run `mypy` in strict mode:
  ```toml
  [tool.mypy]
  strict = true
  warn_return_any = true
  warn_unreachable = true

  [[tool.mypy.overrides]]
  module = "tests.*"
  disallow_untyped_defs = false
  ```
- For libraries missing stubs, add inline ignores with comments: `# type: ignore[import-untyped]  # no stubs available`

### Naming

- `snake_case` for functions, variables, modules. `PascalCase` for classes. `UPPER_SNAKE_CASE` for constants.
- Prefix private attributes with a single underscore. No double underscores unless avoiding collisions in subclassing hierarchies.
- Name booleans as questions: `is_valid`, `has_permission`, `can_retry`.

### Imports

- Sort with `ruff` (isort-compatible). Group: stdlib, third-party, local.
- Use absolute imports. No wildcard imports.
- Use `TYPE_CHECKING` guards for imports needed only in annotations:
  ```python
  from __future__ import annotations
  from typing import TYPE_CHECKING

  if TYPE_CHECKING:
      from mypackage.services import HeavyService
  ```

### Error Handling

- Never use bare `except:`. Catch the most specific exception possible.
- Define a custom exception hierarchy:
  ```python
  # mypackage/exceptions.py
  class AppError(Exception):
      """Base exception for all application errors."""
  class ConfigError(AppError): ...
  class ServiceError(AppError): ...
  class NotFoundError(ServiceError): ...
  class ValidationError(AppError): ...
  ```
- Use `raise ... from err` to chain exceptions and preserve tracebacks.
- Never silently swallow exceptions. If you catch and continue, log at WARNING or higher.
- Use context managers for cleanup instead of try/finally.

### Data Models

- Use Pydantic for validation, serialization, and anything crossing a trust boundary:
  ```python
  from pydantic import BaseModel, ConfigDict, Field, field_validator

  class InferenceRequest(BaseModel):
      model_config = ConfigDict(frozen=True)

      prompt: str = Field(..., min_length=1, max_length=4096)
      temperature: float = Field(default=0.7, ge=0.0, le=2.0)
      max_tokens: int = Field(default=256, ge=1, le=4096)

      @field_validator("prompt")
      @classmethod
      def prompt_must_not_be_blank(cls, v: str) -> str:
          if not v.strip():
              raise ValueError("prompt must contain non-whitespace characters")
          return v
  ```
- Use `dataclasses` for simple internal data that does not need validation.
- Do not pass structured data between functions as plain dicts. Define a model.
- Make models immutable by default (`frozen=True`). Mutability should be a deliberate choice.

### Async Code

- Use `async`/`await` for I/O-bound operations.
- Use `asyncio.gather()` with `return_exceptions=True` and check results for exceptions.
- Use `asyncio.to_thread()` to run blocking code in an async context.
- Use `httpx` for async HTTP. Avoid `requests` in async code.
- Always use async context managers for connections and sessions.

## Dependency Management

### Preferred tools (in order)

1. **uv** (fast, modern, recommended for new projects)
2. **pip** with `requirements.txt` (simple, widely supported)
3. **poetry** (if the project already uses it)

### Virtual environments

- Always use a virtual environment. Never install packages globally.
- Use `uv venv` or `python -m venv .venv`. Add `.venv/` to `.gitignore`.

### Pinning

- Pin all dependency versions for applications. For libraries, use version ranges in `pyproject.toml`.
- Separate dev dependencies from production:
  ```toml
  [project.optional-dependencies]
  dev = ["pytest>=8.0", "pytest-cov>=5.0", "mypy>=1.10", "ruff>=0.8", "pip-audit>=2.7"]
  ```

### Security scanning

- Run `pip-audit` in CI: `pip-audit --require-hashes --strict`
- Pin hashes in production requirements: `pip-compile --generate-hashes requirements.in -o requirements.txt`
- Review new dependencies before adding them. Check maintenance status, license, and adoption.

### License compliance

- Check that all dependencies are license-compatible with your project: `pip-licenses --format=table --with-urls`
- Watch for GPL-licensed transitive dependencies in permissive-licensed projects.

### Conflicting transitive dependencies

- Use `pip check` to detect broken relationships.
- Options: update both packages (preferred), pin an intermediate version, or vendor (last resort).
- Document any version overrides with a comment explaining the conflict.

### .gitignore essentials

```text
.venv/
venv/
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
.idea/
.vscode/
*.swp
.env
.env.local
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

### Pre-commit hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.13.0
    hooks:
      - id: mypy
        additional_dependencies: [pydantic]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-yaml
      - id: detect-private-key
      - id: end-of-file-fixer
      - id: trailing-whitespace
```

Install: `pip install pre-commit && pre-commit install`

## Security

### Secrets management

- Never hardcode credentials, API keys, tokens, or passwords. Not even in tests.
- Use `pydantic-settings` to load secrets from environment variables. Use `Field(repr=False)` on sensitive fields.
- For production, use a secrets manager (Vault, AWS Secrets Manager, OpenShift secrets).
- If you accidentally commit a secret, consider it compromised. Rotate immediately.

### Input validation

- Validate all external input at the boundary. Never trust data from users, APIs, files, or queues.
- Sanitize filenames before filesystem operations:
  ```python
  from pathlib import Path

  def safe_path(base_dir: Path, user_filename: str) -> Path:
      clean = Path(user_filename).name  # strips directory components
      resolved = (base_dir / clean).resolve()
      if not resolved.is_relative_to(base_dir.resolve()):
          raise ValueError("Path traversal detected")
      return resolved
  ```

### SQL injection prevention

- Always use parameterized queries. Never use f-strings to build SQL:
  ```python
  # DANGEROUS
  cursor.execute(f"SELECT * FROM users WHERE id = '{user_id}'")
  # Safe
  cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
  ```

### SSRF prevention

- When making HTTP requests to user-provided URLs, validate the scheme is `http` or `https` and resolve the hostname to check it is not a private/internal network address (10.x, 172.16.x, 192.168.x, 127.x, 169.254.x).

### Secure deserialization

- Never use `pickle` to load untrusted data. It executes arbitrary code.
- Never use `yaml.load()`. Use `yaml.safe_load()`.
- When deserializing JSON from external sources, validate with Pydantic before acting on it.

### Automated security checks

- Enable `S` (bandit) rules in ruff to catch common issues automatically.
- Run `pip-audit` in CI (see Dependency Management).

## Performance

### Profiling

Do not guess about performance. Measure first, then optimize the bottleneck.

- **CPU profiling**: `python -m cProfile -s cumulative -m mypackage`
- **Production-safe profiling** with `py-spy` (no code changes, low overhead): `py-spy record -o profile.svg --pid <PID>`
- **Memory profiling** with `memray`: `memray run -o output.bin my_script.py && memray flamegraph output.bin`
- For timing, use `time.perf_counter()`, not `time.time()`.

### Common performance patterns

- **Connection pooling**: Reuse database and HTTP connections. Never create a new connection per request.
  ```python
  client = httpx.AsyncClient(
      limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
      timeout=httpx.Timeout(30.0, connect=5.0),
  )
  ```
- **Caching**: `functools.lru_cache` for pure functions with hashable args. Redis or memcached for shared/async caches.
- **Lazy loading**: Defer expensive initialization until first use.
- **Batch operations**: Batch database and API calls instead of one per item.
- **Generators**: Use generators instead of materializing large lists in memory.

### Async performance pitfalls

- **Blocking the event loop**: CPU-bound or blocking I/O in async functions blocks all coroutines. Use `asyncio.to_thread()`.
- **Unbounded concurrency**: `asyncio.gather()` with thousands of tasks overwhelms downstream services. Use a semaphore:
  ```python
  sem = asyncio.Semaphore(50)
  async def limited_fetch(url: str) -> Response:
      async with sem:
          return await client.get(url)
  ```
- **Forgetting to await**: Missing `await` means the work never runs. Enable ruff rule `RUF006`.

### GIL considerations

- The GIL means CPU-bound Python runs on a single core regardless of thread count.
- `threading` helps I/O-bound work. For CPU-bound parallelism, use `multiprocessing` or `ProcessPoolExecutor`.
- Python 3.13+ has experimental free-threaded mode. Do not rely on it in production yet.

## Logging

### Structured logging with structlog

```python
import structlog

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
)
logger = structlog.get_logger()
```

### Correlation IDs

Attach a correlation ID to every request for cross-service tracing:
```python
import uuid
import structlog

def middleware(request: Request, call_next: Callable) -> Response:
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(correlation_id=correlation_id)
    response = call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

### Log levels

- **DEBUG**: Internal state, development only. Disabled in production.
- **INFO**: Normal operations (startup, shutdown, request served).
- **WARNING**: Unexpected but handled (retry, fallback).
- **ERROR**: Operation failed, needs attention.
- **CRITICAL**: System cannot continue.

### What NOT to log

- Never log passwords, tokens, API keys, or session IDs.
- Never log PII (emails, phone numbers) without compliance approval.
- Never log full request/response bodies in production. Log status code, content length, elapsed time.

### Standard library fallback

```python
import logging
logging.basicConfig(format="%(asctime)s %(levelname)s %(name)s %(message)s", level=logging.INFO)
logger = logging.getLogger(__name__)
```

## Testing

### Framework: pytest

Configure in `pyproject.toml`:
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --strict-markers --tb=short"
markers = ["slow: marks tests as slow", "integration: marks integration tests"]
filterwarnings = ["error"]
```

### Test conventions

- Name test files `test_<module>.py`, functions `test_<behavior_being_tested>`.
- Mirror the source tree: `src/mypackage/services/auth.py` gets `tests/unit/services/test_auth.py`.
- Use `pytest.mark.parametrize` for testing multiple inputs:
  ```python
  @pytest.mark.parametrize("input_val,expected", [
      ("hello", "HELLO"),
      ("", ""),
  ])
  def test_transform(input_val: str, expected: str) -> None:
      assert transform(input_val) == expected
  ```

### Fixture scoping pitfalls

- Default `scope="function"` is usually correct. It gives each test clean state.
- `scope="module"` or `scope="session"` shares state and causes order-dependent failures if the fixture is mutable.
- Only use wider scopes for read-only, expensive setup (trained models, compiled schemas).

### Testing async code

Use `pytest-asyncio`. Configure `asyncio_mode = "auto"` in `pyproject.toml`:
```python
@pytest.mark.asyncio
async def test_fetch_user() -> None:
    user = await fetch_user("123")
    assert user.name == "Alice"
```

### Property-based testing

Use `hypothesis` to generate test inputs and catch edge cases you would never write manually:
```python
from hypothesis import given, strategies as st

@given(st.text(min_size=1, max_size=100))
def test_roundtrip_serialization(name: str) -> None:
    user = User(name=name)
    restored = User.model_validate_json(user.model_dump_json())
    assert restored == user
```

### Snapshot testing

Use `syrupy` for complex outputs where manually writing expected values is brittle:
```python
def test_api_response_format(snapshot) -> None:
    response = generate_report(test_data)
    assert response == snapshot
```
Update snapshots: `pytest --snapshot-update`

### Test isolation

- Each test must be independent. Running in any order produces the same results.
- Use `tmp_path` for temporary files, `monkeypatch` for environment variables.
- Be suspicious of tests needing more than two or three mocks. That signals too many responsibilities.

### Mocking

- Mock at the boundary (HTTP client, database), not deep internals.
- Prefer dependency injection over monkey-patching.
- Use `responses` or `httpx_mock` for HTTP mocking.

### Coverage

```toml
[tool.coverage.run]
source = ["src/mypackage"]
branch = true

[tool.coverage.report]
fail_under = 85
show_missing = true
exclude_lines = ["pragma: no cover", "if TYPE_CHECKING:", "if __name__ == .__main__.:"]
```
Do not chase 100%. Focus on business logic and edge cases.

### Running tests

```bash
pytest                                              # all tests
pytest --cov=src/mypackage --cov-report=term-missing  # with coverage
pytest tests/unit/                                   # unit tests only
pytest -m integration                                # integration tests only
pytest -k "test_parse"                               # keyword match
pytest --tb=long -vv                                 # verbose failures
```

## Common Commands

```bash
# Set up development environment
uv venv && source .venv/bin/activate && uv pip install -e ".[dev]"

# Lint and format
ruff check src/ tests/ --fix && ruff format src/ tests/

# Type check
mypy src/

# Run the application
python -m mypackage

# Security audit
pip-audit

# Build container image
podman build -t myapp:latest .

# Pre-commit on all files
pre-commit run --all-files
```

## Debugging

### breakpoint()

```python
def process_request(data: dict) -> dict:
    result = transform(data)
    breakpoint()  # drops into pdb; remove before committing
    return result
```

Key `pdb` commands: `n` (next), `s` (step), `c` (continue), `p <expr>` (print), `l` (list), `bt` (backtrace), `pp` (pretty-print), `u`/`d` (up/down stack frames).

### Remote debugging

For containers, use `debugpy`:
```python
import debugpy
debugpy.listen(("0.0.0.0", 5678))
debugpy.wait_for_client()
```
Connect from VS Code with "Remote Attach" debug configuration.

### Logging-based debugging

When breakpoints are not practical (async code, production-adjacent environments):
```python
logger.debug("processing started", input_keys=list(data.keys()))
result = transform(data)
logger.debug("processing complete", output_keys=list(result.keys()))
```

## Container Image

Use Red Hat Universal Base Image:
```dockerfile
FROM registry.access.redhat.com/ubi9/python-311:latest
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ src/
USER 1001
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz')" || exit 1
CMD ["python", "-m", "mypackage"]
```

- Order layers from least to most frequently changing.
- Use multi-stage builds if you need build tools that should not be in the final image.
- Do not run as root. Do not store secrets in the image.
- Use `.containerignore` to exclude `.venv/`, `.git/`, `__pycache__/`, and tests.

## Environment Variables

```python
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="APP_", env_file=".env")

    database_url: str
    api_key: str = Field(repr=False)  # hidden from repr/logs
    debug: bool = False
    log_level: str = "INFO"
```

- Never hardcode credentials. Use environment variables or a secrets manager.
- Provide a `.env.example` with placeholder values (never real secrets).

## Common Python Pitfalls

These are real bugs that show up in production. Know them.

### Mutable default arguments

```python
# BUG: all callers share the same list
def append_to(item: str, target: list[str] = []) -> list[str]: ...
# Fix: use None sentinel
def append_to(item: str, target: list[str] | None = None) -> list[str]:
    if target is None:
        target = []
    target.append(item)
    return target
```

### Late binding closures

```python
# BUG: all functions return 4 (the final value of i)
functions = [lambda: i for i in range(5)]
# Fix: bind i as a default argument
functions = [lambda i=i: i for i in range(5)]
```

### Circular imports

- Symptom: `ImportError: cannot import name 'X' from partially initialized module`.
- Fixes: lazy import inside the function, `TYPE_CHECKING` guard for annotations, or restructure to break the cycle.

### Datetime timezone handling

```python
# BUG: naive datetime
now = datetime.now()       # no timezone
now = datetime.utcnow()    # still naive despite the name
# Fix: always timezone-aware
now = datetime.now(timezone.utc)
```
Enable ruff rule `DTZ` to catch this automatically.

### Float precision

```python
>>> 0.1 + 0.2 == 0.3   # False
# Use Decimal for financial math. Use math.isclose() for approximate comparisons.
```

### String encoding

```python
# BUG: platform-dependent encoding
with open("data.txt") as f: ...
# Fix: explicit encoding
with open("data.txt", encoding="utf-8") as f: ...
```

### `is` vs `==`

- `is` checks identity (same object). `==` checks equality (same value).
- Use `is` only for `None`, `True`, `False`, and sentinel objects. Never for integers or strings.

### Catching too broadly

```python
# BUG: swallows everything silently
try:
    do_work()
except Exception:
    pass
# Fix: catch specific exceptions, log or handle meaningfully
```

## Common Mistakes Claude Makes

These are patterns Claude tends to produce that will fail code review. Watch for them.

**Using `Optional[str]` instead of `str | None`.** Claude defaults to the old `typing.Optional` and `typing.List` syntax. Use modern Python 3.10+ union syntax: `str | None`, `list[str]`, `dict[str, int]`. The project targets Python 3.11+.

**Adding `from __future__ import annotations` unnecessarily.** Claude adds this import when the project already targets Python 3.11+ where modern type syntax works natively. Only use it when you need to avoid circular imports with `TYPE_CHECKING` guards.

**Writing overly broad exception handlers.** Claude catches `Exception` when it should catch a specific exception type. Every `except` block should name the most specific exception that can occur at that point.

**Creating a `utils.py` dumping ground.** Claude puts unrelated helper functions in a single `utils.py` file. Give utility functions a proper home: string manipulation goes in a `formatting` module, date helpers go in a `dates` module.

**Using `print()` instead of the project's logging setup.** Claude reaches for `print()` for debug output and status messages. Use `structlog` or the standard `logging` module configured in the project. Never use `print()` in production code.

**Ignoring the `src/` layout.** When creating new modules, Claude sometimes places them at the project root instead of under `src/mypackage/`. Follow the existing directory structure.

**Not using `pathlib.Path`.** Claude uses `os.path.join()` and string concatenation for file paths. Use `pathlib.Path` for all file path operations.

**Writing synchronous code in async contexts.** Claude uses `requests` or blocking I/O in async functions. Use `httpx` for HTTP calls in async code. Use `asyncio.to_thread()` to run blocking operations.

**Missing `return` type annotations.** Claude adds parameter type hints but forgets the return type. Every function signature needs both parameter types and a return type: `def process(data: dict[str, Any]) -> ProcessResult:`.

**Putting test fixtures in the wrong scope.** Claude creates `scope="session"` fixtures for mutable objects that should be `scope="function"`. Default to function scope. Only use wider scopes for expensive, read-only setup.

**Defaulting to class-based designs.** Claude creates classes with a single method when a plain function would be simpler. If a class has only `__init__` and one other method, it should probably be a function.

**Using `time.sleep()` in async code.** Claude uses `time.sleep()` instead of `await asyncio.sleep()` in async functions. `time.sleep()` blocks the entire event loop.

## Review Checklist

Before merging, verify every item. This is not a formality.

### Correctness
- [ ] All tests pass (unit, integration, property-based)
- [ ] Edge cases are tested (empty inputs, None, boundary values, Unicode)
- [ ] Error paths are tested, not just the happy path
- [ ] Async code is properly awaited
- [ ] Resource cleanup happens in all code paths (connections, file handles, temp files)

### Type safety and style
- [ ] `ruff check` and `ruff format --check` report no issues
- [ ] `mypy` passes in strict mode
- [ ] Type hints on all function signatures
- [ ] No unexplained `type: ignore` comments

### Security
- [ ] No hardcoded credentials, tokens, or API keys
- [ ] All external input is validated before use
- [ ] SQL queries are parameterized
- [ ] No `pickle.loads()`, `yaml.load()`, or `eval()` on untrusted data
- [ ] `pip-audit` reports no known vulnerabilities
- [ ] File paths from user input are sanitized against traversal

### Dependencies and configuration
- [ ] New dependencies are justified, maintained, and license-compatible
- [ ] Dependencies are pinned
- [ ] `.env.example` updated if new env vars were added

### Code quality
- [ ] Docstrings on public functions, classes, and modules
- [ ] No dead code or unresolved TODOs
- [ ] Functions are small and do one thing
- [ ] No mutable default arguments
- [ ] Logging uses appropriate levels, does not leak sensitive data
- [ ] No `print()` in production code

### Performance
- [ ] No N+1 query patterns
- [ ] Large collections use generators or pagination
- [ ] HTTP and database connections are pooled and reused
- [ ] No blocking calls in async code paths
