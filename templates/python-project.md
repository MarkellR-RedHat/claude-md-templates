# CLAUDE.md - Python Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Replace "mypackage" with your actual package name -->
<!-- TODO: Set your Python version (currently 3.11) -->
<!-- TODO: Update the ruff config to match your pyproject.toml -->
<!-- TODO: Update test commands to match your Makefile targets -->
<!-- TODO: Set your CI tool (GitHub Actions, Tekton, Jenkins) -->

## Project Overview

This is a Python project. It follows modern Python conventions with an emphasis on type safety, testability, and clear dependency management.

## Python Version

- Target Python 3.11+ unless the project specifies otherwise.
- Use the version specified in `pyproject.toml` or `.python-version`.
- Do not use features deprecated in the target Python version.

## Project Structure

```
project-root/
  src/
    mypackage/
      __init__.py
      main.py            # Application entrypoint
      config.py          # Configuration and settings
      models.py          # Data models (Pydantic, dataclasses)
      services/          # Business logic
      api/               # API routes and handlers
      utils/             # Utility functions
  tests/
    unit/
      test_models.py
      test_services.py
    integration/
      test_api.py
    conftest.py          # Shared fixtures
  pyproject.toml
  requirements.txt       # Or use uv.lock / poetry.lock
  Containerfile
  Makefile
  .python-version
```

### Layout rules:
- Use the `src/` layout. This prevents accidentally importing the package from the project root instead of the installed version.
- Keep `__init__.py` files minimal. Do not put logic in them.
- One class per file is not required. Group related classes and functions in the same module.

## Code Conventions

### Style and Formatting
- Use `ruff` for linting and formatting. It replaces flake8, isort, and black.
- Configure ruff in `pyproject.toml`:
  ```toml
  [tool.ruff]
  target-version = "py311"
  line-length = 100

  [tool.ruff.lint]
  select = ["E", "F", "I", "N", "W", "UP", "B", "A", "SIM", "TCH"]
  ```
- Maximum line length is 100 characters.

### Type Hints
- Use type hints on all function signatures. This is not optional.
- Use modern type hint syntax (Python 3.10+):
  ```python
  # Good
  def process(items: list[str]) -> dict[str, int]:
  def fetch(url: str) -> str | None:

  # Avoid (old style)
  from typing import List, Dict, Optional
  def process(items: List[str]) -> Dict[str, int]:
  def fetch(url: str) -> Optional[str]:
  ```
- Use `TypeAlias` for complex types:
  ```python
  from typing import TypeAlias
  UserMap: TypeAlias = dict[str, list[int]]
  ```
- Run `mypy` in strict mode for type checking:
  ```toml
  [tool.mypy]
  strict = true
  ```

### Naming
- Use `snake_case` for functions, variables, and module names.
- Use `PascalCase` for classes.
- Use `UPPER_SNAKE_CASE` for constants.
- Prefix private methods and attributes with a single underscore: `_internal_method`.
- Do not use double underscores for name mangling unless you have a specific reason.

### Imports
- Sort imports with `ruff` (isort-compatible).
- Group imports: standard library, third-party, local.
- Use absolute imports. Avoid relative imports except within the same package.
- Do not use wildcard imports (`from module import *`).

### Error Handling
- Never use bare `except:` clauses. Always specify the exception type.
- Catch the most specific exception possible.
- Use custom exceptions for domain-specific errors:
  ```python
  class ModelNotFoundError(Exception):
      """Raised when a requested model is not available."""
  ```
- Let unexpected exceptions propagate. Do not catch exceptions just to log and re-raise them unless you are adding context.
- Use `raise ... from err` to chain exceptions and preserve the traceback:
  ```python
  try:
      result = parse(data)
  except ValueError as err:
      raise ConfigError(f"Invalid config data: {data!r}") from err
  ```

### Data Models
- Use Pydantic for data validation and serialization:
  ```python
  from pydantic import BaseModel, Field

  class InferenceRequest(BaseModel):
      prompt: str = Field(..., min_length=1, max_length=4096)
      temperature: float = Field(default=0.7, ge=0.0, le=2.0)
      max_tokens: int = Field(default=256, ge=1, le=4096)
  ```
- Use `dataclasses` for simple internal data structures that do not need validation.
- Do not use plain dictionaries for structured data that gets passed between functions. Define a model.

### Async Code
- Use `async`/`await` for I/O-bound operations (HTTP calls, database queries, file I/O).
- Use `asyncio.gather()` for concurrent async operations.
- Do not mix sync and async code without careful thought. Use `asyncio.to_thread()` to run blocking code in an async context.
- Use `httpx` for async HTTP clients. Avoid `requests` in async code.

## Dependency Management

### Preferred tools (in order):
1. **uv** (fast, modern, recommended for new projects)
2. **pip** with `requirements.txt` (simple, widely supported)
3. **poetry** (if the project already uses it)

### Virtual environments:
- Always use a virtual environment. Never install packages globally.
- Use `uv venv` or `python -m venv .venv` to create the environment.
- Add `.venv/` to `.gitignore`.
- Document how to set up the environment in the README.

### Pinning:
- Pin all dependency versions for applications. Use `uv lock` or `pip freeze > requirements.txt`.
- For libraries, specify version ranges in `pyproject.toml` and pin in the lock file.

### .gitignore essentials

Include these entries in `.gitignore` for Python projects:
```text
# Virtual environments
.venv/
venv/
env/

# Python artifacts
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/

# IDE
.idea/
.vscode/
*.swp

# Environment and secrets
.env
.env.local

# Test and coverage
.coverage
htmlcov/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

### Pre-commit hooks

Use `pre-commit` to enforce quality checks before every commit:
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
```

Install and activate:
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Testing

### Framework: pytest
- Use `pytest` for all tests. Do not use `unittest` unless maintaining legacy code.
- Configure pytest in `pyproject.toml`:
  ```toml
  [tool.pytest.ini_options]
  testpaths = ["tests"]
  addopts = "-v --strict-markers"
  markers = [
      "slow: marks tests as slow",
      "integration: marks integration tests",
      "gpu: marks tests requiring GPU",
  ]
  ```

### Test conventions:
- Name test files `test_<module>.py`.
- Name test functions `test_<behavior_being_tested>`.
- Use descriptive test names: `test_parse_config_raises_on_missing_field` not `test_parse_1`.
- Use fixtures for setup and teardown. Define shared fixtures in `conftest.py`.
- Use `pytest.mark.parametrize` for testing multiple inputs:
  ```python
  @pytest.mark.parametrize("input_val,expected", [
      ("hello", "HELLO"),
      ("", ""),
      ("123", "123"),
  ])
  def test_transform(input_val: str, expected: str) -> None:
      assert transform(input_val) == expected
  ```

### Mocking:
- Use `pytest-mock` or `unittest.mock`.
- Mock at the boundary, not deep inside the code. Mock the HTTP client, not the internal function that calls it.
- Prefer dependency injection over monkey-patching.
- Use `responses` or `httpx_mock` for mocking HTTP requests.

### Running tests:
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src/mypackage --cov-report=term-missing

# Run only unit tests
pytest tests/unit/

# Run only integration tests
pytest tests/integration/ -m integration

# Run a specific test
pytest tests/unit/test_models.py::test_parse_config_raises_on_missing_field
```

## Common Commands

```bash
# Set up development environment
uv venv && source .venv/bin/activate && uv pip install -e ".[dev]"

# Or with pip
python -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"

# Lint and format
ruff check src/ tests/ --fix
ruff format src/ tests/

# Type check
mypy src/

# Run the application
python -m mypackage

# Build container image
podman build -t myapp:latest .
```

## Debugging

### Common debugging patterns

Use the built-in `breakpoint()` function (Python 3.7+) to drop into a debugger:
```python
def process_request(data: dict) -> dict:
    result = transform(data)
    breakpoint()  # Drops into pdb; remove before committing
    return result
```

Useful `pdb` commands once inside the debugger:
- `n` (next): Execute the next line.
- `s` (step): Step into a function call.
- `c` (continue): Continue until the next breakpoint.
- `p <expr>` (print): Evaluate and print an expression.
- `l` (list): Show the current source code context.
- `bt` (backtrace): Show the full call stack.

### Remote debugging

For containers or remote environments, use `debugpy`:
```python
import debugpy
debugpy.listen(("0.0.0.0", 5678))
debugpy.wait_for_client()  # Blocks until a debugger attaches
```

Then connect from VS Code using the "Remote Attach" debug configuration.

### Logging-based debugging

When breakpoints are not practical (async code, production-adjacent environments), use structured logging:
```python
import structlog

logger = structlog.get_logger()

def process(data: dict) -> dict:
    logger.debug("processing started", input_keys=list(data.keys()))
    result = transform(data)
    logger.debug("processing complete", output_keys=list(result.keys()))
    return result
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
CMD ["python", "-m", "mypackage"]
```

## Environment Variables

- Use `pydantic-settings` for environment variable management:
  ```python
  from pydantic_settings import BaseSettings

  class Settings(BaseSettings):
      database_url: str
      api_key: str
      debug: bool = False
      log_level: str = "INFO"

      model_config = SettingsConfigDict(env_prefix="APP_")
  ```
- Never hardcode credentials. Always use environment variables or a secrets manager.
- Document all required environment variables in the README.
- Provide a `.env.example` file with placeholder values.

## Common Mistakes to Avoid

- Do not use mutable default arguments: `def func(items: list = [])`. Use `None` and create a new list inside the function.
- Do not use `type()` for type checking. Use `isinstance()`.
- Do not use em dashes in comments, docstrings, or documentation. Use commas, periods, or "and" instead.
- Do not catch `Exception` or `BaseException` at the top level unless you are in a framework entry point.
- Do not use `print()` for logging in production code. Use the `logging` module or `structlog`.
- Do not commit `.env` files. Add them to `.gitignore`.

## Review Checklist

Before merging:

- [ ] All tests pass
- [ ] `ruff check` and `ruff format --check` report no issues
- [ ] `mypy` passes in strict mode
- [ ] Type hints are present on all function signatures
- [ ] No hardcoded credentials or configuration
- [ ] New dependencies are justified and pinned
- [ ] Docstrings are present on public functions and classes
- [ ] `.env.example` is updated if new env vars were added
