# Suggest Template

Analyze the current project and recommend which CLAUDE.md template to use.

## Instructions

You are a project analyzer. Examine the current project directory to determine its type, languages, frameworks, and tooling. Then recommend the best CLAUDE.md template from the available options.

Use $ARGUMENTS if the user provides additional context about their project (for example, "this is a FastAPI app" or "we use Helm charts").

## Analysis Steps

1. **Detect the primary language and framework** by examining these files and directories:
   - `go.mod` or `go.sum` -> Go project
   - `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile`, `uv.lock` -> Python project
   - `Cargo.toml`, `Cargo.lock` -> Rust project
   - `Chart.yaml`, `values.yaml`, `templates/` -> Helm chart
   - `Dockerfile`, `Containerfile`, `deploy/`, `config/crd/` -> Kubernetes project
   - `api/v1alpha1/`, `controllers/`, `PROJECT` (kubebuilder) -> Operator SDK project
   - `mkdocs.yml`, `antora.yml`, `antora-playbook.yml`, `hugo.toml`, `config.toml` (Hugo) -> Documentation project
   - FastAPI imports in Python files, `alembic.ini`, `alembic/` -> FastAPI project
   - `dags/`, `pipelines/`, Spark or Beam imports, `great_expectations/` -> Data pipeline project
   - `cmd/` with Cobra imports, Click/Typer in Python, Clap in Rust with CLI patterns -> CLI tool project
   - Content directories with markdown posts, `content/posts/`, blog frontmatter -> Content writing
   - `proposals/`, CFP-related content -> Conference proposals
   - Mixed content with demos, workshops, code samples, community docs -> General DevRel

2. **Check for AI/ML indicators**:
   - PyTorch, TensorFlow, JAX imports
   - Model files (`.pt`, `.safetensors`, `.onnx`, `.gguf`)
   - vLLM, TGI, KServe, Triton references
   - MLflow, Weights & Biases configuration
   - Training scripts, inference servers, model configs
   - If found, recommend `ai-ml-project.md`

3. **Detect secondary concerns** that might suggest combining templates:
   - A Python project with `Chart.yaml` might need both `python-project.md` and `helm-chart.md`
   - An operator project benefits from both `operator-sdk.md` and `kubernetes-project.md`
   - A FastAPI project with ML serving might need `fastapi-project.md` and `ai-ml-project.md`

4. **Present recommendations** in this format:

```
## Template Recommendation

### Primary match: [template-name]
**Confidence: High/Medium/Low**

Why this template fits:
- [specific evidence from the project]
- [specific evidence from the project]

### Also consider: [secondary-template-name] (if applicable)
Why you might combine:
- [reason]

### Quick install:
cp templates/[template-name].md /path/to/project/CLAUDE.md

### Or combine templates:
Use the /compose-template command:
/compose-template [template1] + [template2]
```

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

When multiple templates could fit, show a comparison table:

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

## Example Interaction

User runs: `/suggest-template`

The command scans the project and outputs:

```
Scanned project at /home/dev/my-fastapi-app

Detected:
  Language: Python 3.11 (from pyproject.toml)
  Framework: FastAPI (from imports in src/main.py)
  Database: SQLAlchemy + Alembic (alembic/ directory found)
  Testing: pytest (from pyproject.toml)
  Container: Containerfile present

Primary match: fastapi-project.md
Confidence: High

Also consider combining with:
  - ai-ml-project.md (if this serves ML models)
  - kubernetes-project.md (Containerfile suggests k8s deployment)
```
