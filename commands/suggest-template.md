# Suggest Template

Analyze the current project in depth and recommend which CLAUDE.md template to use.

## Instructions

You are a project analyzer. Examine the current project directory to determine its type, languages, frameworks, build system, CI pipeline, testing approach, and tooling. Then recommend the best CLAUDE.md template from the available options.

Use $ARGUMENTS to control behavior:
- If the user passes `deep` or `--deep`, run in **deep scan** mode (read file contents, parse imports, check git history).
- If the user passes other text, treat it as additional context about the project (for example, "this is a FastAPI app" or "we use Helm charts").
- If no arguments are given, run in **quick scan** mode (check file and directory existence, read only key config files).

## Quick Scan Mode (default)

Check for the existence of these files and directories. Do NOT read file contents except for the items marked "(read contents)".

### Step 1: Identify project language and type

Check for these marker files in order. Stop at the first strong match, but continue scanning for secondary signals.

**Go project:**
- `go.mod` (read contents: check module path and Go version)
- `go.sum`
- `cmd/` directory
- `internal/` or `pkg/` directory

**Python project:**
- `pyproject.toml` (read contents: check `[project]` for dependencies, `[tool.ruff]`, `[tool.pytest]`, `[tool.mypy]` sections)
- `setup.py`, `setup.cfg`
- `requirements.txt`, `requirements-dev.txt`
- `Pipfile`, `uv.lock`, `poetry.lock`
- `src/` with `.py` files, or top-level `.py` files

**Rust project:**
- `Cargo.toml` (read contents: check `[dependencies]` and `[[bin]]` vs `[lib]`)
- `Cargo.lock`
- `src/main.rs` vs `src/lib.rs`

**Helm chart:**
- `Chart.yaml` (read contents: check chart name, type, dependencies)
- `values.yaml`
- `templates/` directory with `.yaml` files

**Kubernetes/OpenShift project:**
- `Dockerfile` or `Containerfile`
- `deploy/`, `manifests/`, `k8s/`, `kustomize/`
- `config/crd/`, `config/rbac/`, `config/manager/`

**Operator SDK project:**
- `PROJECT` file (kubebuilder marker)
- `api/` with versioned subdirectories (e.g., `api/v1alpha1/`)
- `controllers/` or `internal/controller/`
- `config/crd/bases/`

**Documentation project:**
- `mkdocs.yml` (read contents: check theme and plugins)
- `antora.yml`, `antora-playbook.yml`
- `hugo.toml`, `config.toml` with Hugo markers
- `docs/` directory with `.md` or `.adoc` files as primary content

**Data pipeline project:**
- `dags/` directory
- `pipelines/` directory
- `great_expectations/` directory
- `dbt_project.yml`

**CLI tool project:**
- `cmd/` with a `main.go` containing Cobra imports (Go)
- Top-level Python files with Click, Typer, or argparse patterns
- `src/main.rs` with Clap in `Cargo.toml`

**Content/DevRel projects:**
- `content/posts/`, `_posts/`, markdown files with blog frontmatter
- `proposals/`, CFP-related directories
- Mixed content with demos, workshops, code samples

### Step 2: Check for AI/ML indicators

Look for any of these:
- Python dependencies referencing `torch`, `tensorflow`, `jax`, `transformers`, `vllm`, `triton`, `kserve`
- Model files: `.pt`, `.safetensors`, `.onnx`, `.gguf`
- Directories: `models/`, `checkpoints/`, `weights/`
- Config files: `mlflow/`, `wandb/`, `.mlflow`, `model_config.yaml`
- Training or inference scripts in filenames

### Step 3: Check for containerization and deployment

- `Dockerfile` or `Containerfile` existence
- `docker-compose.yml` or `compose.yml`
- `.github/workflows/` directory
- `.tekton/` directory
- `Jenkinsfile`
- `.gitlab-ci.yml`
- `Makefile` or `Justfile`
- `Tiltfile` or `skaffold.yaml`

### Step 4: Check for existing CLAUDE.md

- If `CLAUDE.md` already exists, read its contents so you can compare it against the recommended template and suggest specific improvements.

## Deep Scan Mode (when user passes `deep` or `--deep`)

Run everything from Quick Scan, plus the following additional analysis. Read file contents where indicated.

### Step 5: Parse dependency files for framework detection

**For `go.mod`:** Read the file. Look for these import paths in the `require` block:
- `github.com/gin-gonic/gin` -> Gin web framework
- `github.com/labstack/echo` -> Echo web framework
- `github.com/gorilla/mux` -> Gorilla router
- `github.com/spf13/cobra` -> CLI tool (Cobra)
- `github.com/urfave/cli` -> CLI tool (urfave)
- `sigs.k8s.io/controller-runtime` -> Operator SDK / controller
- `k8s.io/client-go` -> Kubernetes client usage
- `google.golang.org/grpc` -> gRPC service
- `google.golang.org/protobuf` -> Protocol Buffers

**For `pyproject.toml` or `requirements.txt`:** Read the file. Look for these dependencies:
- `fastapi` -> FastAPI framework
- `flask` -> Flask framework
- `django` -> Django framework
- `click`, `typer` -> CLI tool
- `pydantic` -> Data validation (common with FastAPI)
- `sqlalchemy`, `alembic` -> Database ORM and migrations
- `celery`, `rq` -> Task queues
- `pytest`, `unittest` -> Testing framework
- `ruff`, `black`, `isort`, `flake8` -> Linting/formatting tools
- `mypy`, `pyright` -> Type checking
- `torch`, `tensorflow`, `jax`, `transformers`, `vllm` -> AI/ML

**For `Cargo.toml`:** Read the file. Look for these in `[dependencies]`:
- `axum`, `actix-web`, `rocket`, `warp` -> Web framework
- `clap` -> CLI tool
- `tokio`, `async-std` -> Async runtime
- `sqlx`, `diesel` -> Database
- `tonic` -> gRPC
- `serde` -> Serialization

**For `package.json`:** Read the file. Look for these in `dependencies` or `devDependencies`:
- `next`, `react`, `vue`, `angular` -> Frontend framework
- `express`, `fastify`, `koa` -> Node.js backend
- `jest`, `vitest`, `mocha` -> Testing framework
- `eslint`, `prettier` -> Linting/formatting

### Step 6: Scan source files for import patterns

Read up to 5 source files (prioritize `main.*`, `app.*`, `server.*`, or files in `cmd/`, `src/`, or the project root). Look for:
- Framework initialization (e.g., `app = FastAPI()`, `gin.Default()`, `axum::Router::new()`)
- Database connections
- API route definitions
- gRPC service definitions
- ML model loading or inference code

### Step 7: Analyze build and CI configuration

**Makefile or Justfile:** Read the file. List all targets (e.g., `build`, `test`, `lint`, `fmt`, `docker-build`, `deploy`, `generate`). These reveal what commands the CLAUDE.md should reference.

**CI config files:** Read `.github/workflows/*.yml`, `.tekton/*.yaml`, `Jenkinsfile`, or `.gitlab-ci.yml`. Look for:
- Build commands being run
- Test commands and test matrix
- Linting steps
- Container build steps
- Deployment targets (staging, production)
- Required checks or gates

**Dockerfile or Containerfile:** Read the file. Look for:
- Base image (e.g., `golang:1.22`, `python:3.12`, `rust:1.78`, `node:20`)
- Build steps that reveal the build system
- Multi-stage builds
- Runtime dependencies

### Step 8: Analyze test structure

Look at the testing setup:
- `*_test.go` files and their location relative to source
- `tests/` or `test/` directory structure
- `conftest.py` for pytest fixtures
- Test naming conventions
- Integration test directories (`tests/integration/`, `tests/e2e/`)
- Test configuration in `pyproject.toml`, `Cargo.toml`, or CI files

### Step 9: Check linter and formatter configuration

- `.golangci.yml` or `.golangci.yaml` (read contents: check enabled linters)
- `ruff` section in `pyproject.toml` or `ruff.toml`
- `clippy.toml` or clippy configuration in `Cargo.toml`
- `.eslintrc.*`, `.prettierrc.*`
- `.editorconfig`
- `rustfmt.toml`

### Step 10: Check git history for context

Run `git log --oneline -20` to see recent commit messages. Look for patterns like:
- "fix:", "feat:", "chore:" -> Conventional commits
- Issue/PR references
- Release tags or version bumps
- Types of work being done (features, fixes, refactoring, docs)

Also run `git remote -v` to understand where the project lives (GitHub, GitLab, Bitbucket).

### Step 11: Read README.md

If a `README.md` exists, read it. Extract:
- Project description and purpose
- Build/install instructions
- Architecture notes
- Contributing guidelines

## Output Format

Present your findings in this format:

```
## Project Analysis

**Scan mode:** Quick / Deep
**Project root:** [path]

### What I Found

| Signal | Source | Detail |
|--------|--------|--------|
| Language | [file] | [e.g., Go 1.22] |
| Framework | [file] | [e.g., Gin web framework] |
| Build system | [file] | [e.g., Makefile with targets: build, test, lint] |
| Testing | [file] | [e.g., pytest with conftest.py fixtures] |
| CI | [file] | [e.g., GitHub Actions with 3 workflows] |
| Container | [file] | [e.g., Multi-stage Dockerfile, golang:1.22 base] |
| Linting | [file] | [e.g., golangci-lint with 12 linters enabled] |
| AI/ML | [file] | [e.g., PyTorch + vLLM for model serving] |

### Template Recommendation

**Primary match: [template-name]**
**Confidence: High / Medium / Low**

Evidence:
- [specific file or pattern that confirms this match]
- [specific file or pattern that confirms this match]
- [specific file or pattern that confirms this match]

**What this template adds to your workflow:**
- [concrete thing the template provides that the project does not currently document]
- [concrete thing the template provides that the project does not currently document]
- [concrete thing the template provides that the project does not currently document]

### Secondary match: [template-name] (if applicable)

Why you might combine this with the primary template:
- [specific reason based on what you found in the project]

### Confidence Explanation

- **High** = Multiple strong signals confirm this project type. Found framework code, matching dependency files, appropriate directory structure, and CI that builds/tests accordingly.
- **Medium** = Some signals match but others are ambiguous. For example, found Go source files but no go.mod, or found Python files but could not determine the framework.
- **Low** = Few signals match. Relying mostly on file extensions or user-provided context. You may want to provide more information or try `/suggest-template deep` for a deeper analysis.
```

If the user already has a `CLAUDE.md`, add this section:

```
### Comparison with Existing CLAUDE.md

Your current CLAUDE.md covers:
- [list what it already documents well]

Gaps the template would fill:
- [specific section or instruction missing from their CLAUDE.md]
- [specific section or instruction missing from their CLAUDE.md]

Suggestion: Rather than replacing your CLAUDE.md, consider adding these sections from the template:
- [section name]: [why it would help]
```

After the recommendation, always include:

```
### Quick Install

cp templates/[template-name].md /path/to/project/CLAUDE.md

### Or Combine Templates

Use the /compose-template command to merge multiple templates:
/compose-template [template1] + [template2]

### Want More Detail?

Run `/suggest-template deep` to scan file contents, parse imports, and analyze your build and CI configuration.
```

(Omit the "Want More Detail?" section if already running in deep scan mode.)

## Available Templates

| Template File | Best For |
|---|---|
| `python-project.md` | Python applications and libraries |
| `go-project.md` | Go services and CLI tools |
| `rust-project.md` | Rust crates and binaries |
| `fastapi-project.md` | FastAPI web services with Pydantic, SQLAlchemy, Alembic |
| `ai-ml-project.md` | AI/ML pipelines, model serving, training workloads |
| `kubernetes-project.md` | Kubernetes and OpenShift deployment projects |
| `operator-sdk.md` | Kubernetes operators built with Operator SDK |
| `helm-chart.md` | Standalone Helm charts |
| `data-pipeline.md` | Data engineering with Spark, Beam, or similar |
| `cli-tool.md` | Command-line tools in any language |
| `content-writing.md` | Blog posts, technical articles, content projects |
| `proposals.md` | Conference talk proposals and CFP submissions |
| `documentation.md` | Documentation sites and knowledge bases |
| `general-devrel.md` | Developer relations work (demos, workshops, samples) |

## Side-by-Side Comparison

When multiple templates could fit, show a comparison table relevant to the detected project type. Here is an example for a Python project where the type is ambiguous:

```
| Feature | python-project | fastapi-project | ai-ml-project |
|---|---|---|---|
| Type hints | Yes | Yes | Yes |
| Pydantic models | Basic | Deep (v2 patterns) | Basic |
| Database patterns | No | SQLAlchemy + Alembic | No |
| API design | No | Comprehensive | Inference APIs |
| GPU support | No | No | Yes |
| Testing | pytest | httpx + pytest | pytest + GPU |
```

Adapt the comparison columns to match the actual templates being considered.

## Important Rules

1. Never guess. If you cannot find clear signals, say so and set confidence to Low.
2. In quick scan mode, do NOT read source files or run git commands. Only check file/directory existence and read the specific config files marked "(read contents)" in the steps above.
3. In deep scan mode, read files but do NOT execute the project's build, test, or run commands. Only use read-only operations and git log/remote.
4. If the project is clearly a monorepo (multiple independent services or packages), note this and suggest running the command from within each subproject directory.
5. Always ground your recommendation in specific files and patterns you observed, not assumptions.
