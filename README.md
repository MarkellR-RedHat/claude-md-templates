# CLAUDE.md Templates

Production-grade project configuration templates for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Drop one into your project and Claude Code immediately understands your conventions, tooling, testing patterns, and review standards.

Each template was written by engineers who work in that domain daily. These are not generic "write clean code" checklists. They encode the specific patterns, pitfalls, and practices that matter in each project type.

## Why Use a CLAUDE.md?

When Claude Code opens a project, it reads `CLAUDE.md` from the root directory. This file tells Claude:

- What language and framework conventions to follow
- How to run tests, linters, and builds
- What security and performance patterns to use
- What common mistakes to avoid
- What to check before committing code

Without a CLAUDE.md, Claude guesses. With one, it knows.

## Available Templates

### Code Projects

| Template | File | What It Covers |
|---|---|---|
| Python | [`python-project.md`](templates/python-project.md) | ruff, mypy, pytest, Pydantic, structured logging, dependency scanning, performance profiling, security patterns |
| Go | [`go-project.md`](templates/go-project.md) | golangci-lint, table-driven tests, pprof, concurrency patterns, graceful shutdown, error wrapping, module management |
| Rust | [`rust-project.md`](templates/rust-project.md) | clippy, cargo-deny, thiserror/anyhow, tokio async, unsafe policy, Miri, fuzzing, criterion benchmarks |
| FastAPI | [`fastapi-project.md`](templates/fastapi-project.md) | Pydantic v2, SQLAlchemy 2.0, Alembic migrations, dependency injection, httpx testing, OpenAPI customization |
| AI/ML | [`ai-ml-project.md`](templates/ai-ml-project.md) | PyTorch, vLLM, model lifecycle, distributed training, quantization, RAG patterns, GPU profiling, model monitoring |
| Data Pipeline | [`data-pipeline.md`](templates/data-pipeline.md) | Apache Spark, Beam, schema evolution, idempotency, backfill strategies, data quality, orchestration patterns |
| CLI Tool | [`cli-tool.md`](templates/cli-tool.md) | Cobra/Click/Clap, config file handling, shell completion, output formatting, release automation, man pages |

### Infrastructure Projects

| Template | File | What It Covers |
|---|---|---|
| Kubernetes | [`kubernetes-project.md`](templates/kubernetes-project.md) | Pod Security Standards, network policies, RBAC, HPA tuning, observability, GitOps, troubleshooting patterns |
| Operator SDK | [`operator-sdk.md`](templates/operator-sdk.md) | controller-runtime, reconciliation loops, finalizers, status conditions, webhooks, OLM packaging, envtest |
| Helm Chart | [`helm-chart.md`](templates/helm-chart.md) | Template patterns, values schema, hooks, library charts, OCI registries, chart-testing, OpenShift compatibility |

### Content Projects

| Template | File | What It Covers |
|---|---|---|
| Content Writing | [`content-writing.md`](templates/content-writing.md) | Red Hat editorial standards, SEO, content lifecycle, accessibility, editorial calendar, measurement |
| Proposals | [`proposals.md`](templates/proposals.md) | CFP structure, talk design, demo planning, audience analysis, slide design, post-talk engagement |
| Documentation | [`documentation.md`](templates/documentation.md) | Diataxis framework, docs-as-code CI, versioning, API docs, link checking, Vale linting, accessibility |
| DevRel | [`general-devrel.md`](templates/general-devrel.md) | Developer journey, code sample standards, workshop design, community building, metrics, crisis communication |

## Template Comparison Matrix

Use this matrix to find the right template when you are not sure which one fits.

| If your project... | Primary Template | Consider Combining With |
|---|---|---|
| Is a Python app or library | `python-project` | `kubernetes-project` for deployment |
| Uses FastAPI | `fastapi-project` | `ai-ml-project` if serving models |
| Serves ML models (vLLM, TGI) | `ai-ml-project` | `kubernetes-project` for k8s deployment |
| Is a Go service or API | `go-project` | `kubernetes-project` or `helm-chart` |
| Is a Kubernetes operator | `operator-sdk` | `go-project` for Go conventions |
| Packages apps as Helm charts | `helm-chart` | `kubernetes-project` for cluster patterns |
| Processes data at scale | `data-pipeline` | `python-project` or `kubernetes-project` |
| Is a CLI tool (any language) | `cli-tool` | Language template (`go`, `python`, `rust`) |
| Is a Rust binary or library | `rust-project` | `cli-tool` if it is a CLI |
| Is a blog or article repo | `content-writing` | `general-devrel` for broader DevRel |
| Contains conference proposals | `proposals` | `content-writing` for writing standards |
| Is a documentation site | `documentation` | - |
| Is a DevRel project with demos | `general-devrel` | Language template for code quality |

## Quick Start

### Option 1: Interactive installer

The interactive mode asks questions about your project and recommends a template.

```bash
git clone https://github.com/MarkellR-RedHat/ai-bu-claude-md-templates.git
cd ai-bu-claude-md-templates
chmod +x install.sh
./install.sh --interactive
```

### Option 2: Direct install

If you already know which template you want:

```bash
./install.sh --template python-project --dir ~/my-project
```

### Option 3: Standard selection

Browse all templates and pick one:

```bash
./install.sh
```

### Option 4: Preview before choosing

See the first 20 lines of each template before selecting:

```bash
./install.sh --preview
```

### Option 5: Copy manually

```bash
cp templates/python-project.md /path/to/your/project/CLAUDE.md
```

### Option 6: Download with curl (no clone needed)

```bash
curl -o CLAUDE.md https://raw.githubusercontent.com/MarkellR-RedHat/ai-bu-claude-md-templates/main/templates/python-project.md
```

## Slash Commands

This repo includes Claude Code slash commands for template management.

### `/suggest-template`

Analyzes your current project (language, frameworks, file structure) and recommends which template to use. Shows a side-by-side comparison when multiple templates might fit.

```
/suggest-template
```

Or provide context:

```
/suggest-template this is a FastAPI app that serves ML models
```

### `/compose-template`

Combines multiple templates into a single CLAUDE.md. Merges sections intelligently, deduplicates shared advice, and produces a unified file.

```
/compose-template python + kubernetes
/compose-template fastapi + ai-ml
/compose-template go + helm-chart + kubernetes
```

To use these commands, add this repo as a command source in your Claude Code settings or copy the `commands/` directory into your project's `.claude/commands/` directory.

## Customizing a Template

After installing a template:

1. **Search for TODO markers.** Every template has `<!-- TODO: ... -->` comments at the top. Work through each one to customize for your project.
2. **Update Project Overview** with your specific project description.
3. **Adjust the tech stack** to match what you actually use.
4. **Modify the project structure** to reflect your real directory layout.
5. **Update common commands** with your actual Makefile targets or scripts.
6. **Remove sections that do not apply** and add anything that is missing.

The templates are starting points. Remove what does not apply. Add what is missing.

## What Makes These Templates Effective

Each template includes:

- **Domain-specific conventions**: not "write clean code" but "use `thiserror` for library error types and `anyhow` for binaries"
- **Common pitfalls**: the mistakes that cost teams hours, specific to each domain
- **Testing patterns**: framework-specific testing strategies, not just "write tests"
- **Security considerations**: threat models and mitigations for each project type
- **Performance guidance**: profiling tools, optimization patterns, and what to measure
- **Tool configurations**: ready-to-use configs for linters, formatters, and test runners
- **Review checklists**: what to verify before every commit, tailored to the domain

## Install Script Reference

```
Usage: ./install.sh [OPTIONS]

Options:
  -h, --help                  Show help message and exit
  -l, --list                  List available templates and exit
  -p, --preview               Preview template contents before selecting
  -i, --interactive           Guided template selection based on your project
  -t, --template NAME         Install a specific template by name
  -d, --dir PATH              Set the target directory
```

Examples:

```bash
./install.sh                              # Standard selection mode
./install.sh --interactive                 # Answer questions, get a recommendation
./install.sh --template go-project         # Install Go template directly
./install.sh -t fastapi-project -d ~/app   # Install FastAPI template to ~/app
./install.sh --preview                     # Preview templates before choosing
./install.sh --list                        # List all available templates
```

## Contributing

Contributions are welcome. If you have a template for a project type not covered here, open a PR.

### Template requirements

Every template must include:

1. **TODO markers** in an HTML comment block at the top for quick customization
2. **Project Overview** with tech stack and directory structure
3. **Code/Content Conventions** with specific, actionable guidance
4. **Testing/Validation** patterns for that project type
5. **Security Considerations** relevant to the domain
6. **Performance Considerations** with profiling and optimization patterns
7. **Common Pitfalls** that are specific, not generic
8. **Common Commands** for daily development workflow
9. **Review Checklist** tailored to the domain

### Style rules

- Write in Red Hat engineering voice: direct, practical, no fluff
- Use imperative mood for instructions
- Be specific. "Functions must not exceed 50 lines" beats "write clean code"
- No em dashes. Use commas, periods, semicolons, or "and" instead
- Include concrete code examples where they help

### Testing your template

Before submitting:

1. Copy the template into an actual project as `CLAUDE.md`
2. Open the project with Claude Code
3. Ask Claude to perform typical tasks (write a function, fix a bug, add a test)
4. Verify Claude follows the conventions in your template
5. Check that TODO markers are clear and easy to find

## License

Apache License 2.0
