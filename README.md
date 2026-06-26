# CLAUDE.md Templates

The difference between a good Claude Code session and a frustrating one is usually the CLAUDE.md file. A good one means Claude writes code that passes review on the first try.

## See the Difference

Here is the same prompt, with and without a proper CLAUDE.md.

**Prompt:** "Write a function to fetch user data from our API"

### Without CLAUDE.md

Claude guesses at your conventions and produces something generic:

```python
import requests

def get_user(user_id):
    response = requests.get(f"https://api.example.com/users/{user_id}")
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None
```

No type hints. Synchronous `requests` instead of `httpx`. `print` instead of structured logging. Raw dict instead of a model. No error handling beyond a print statement. This code would not survive review.

### With CLAUDE.md (Python template installed)

Claude reads your conventions and produces code that matches your stack:

```python
import httpx
import structlog
from pydantic import BaseModel

from app.exceptions import APIError, NotFoundError

logger = structlog.get_logger(__name__)


class User(BaseModel):
    id: int
    email: str
    display_name: str


async def get_user(client: httpx.AsyncClient, user_id: int) -> User:
    """Fetch a user by ID from the upstream API."""
    try:
        response = await client.get(f"/users/{user_id}")
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code == 404:
            raise NotFoundError(f"User {user_id} not found") from exc
        logger.error("api_request_failed", user_id=user_id, status=exc.response.status_code)
        raise APIError(f"Failed to fetch user {user_id}") from exc

    return User.model_validate(response.json())
```

Type hints throughout. Async with `httpx`. Pydantic model for the response. Custom exceptions. Structured logging. Dependency injection via the client parameter. This is the code you would have written yourself.

The only difference is a CLAUDE.md file in the project root.

## Available Templates

### Code Projects

| Template | File | Description |
|---|---|---|
| Python | [`python-project.md`](templates/python-project.md) | ruff, mypy, pytest, Pydantic, structlog, security patterns |
| Go | [`go-project.md`](templates/go-project.md) | golangci-lint, table-driven tests, concurrency, error wrapping |
| Rust | [`rust-project.md`](templates/rust-project.md) | clippy, cargo-deny, tokio async, unsafe policy, fuzzing |
| FastAPI | [`fastapi-project.md`](templates/fastapi-project.md) | Pydantic v2, SQLAlchemy 2.0, Alembic, dependency injection |
| AI/ML | [`ai-ml-project.md`](templates/ai-ml-project.md) | PyTorch, vLLM, distributed training, RAG, GPU profiling |
| Data Pipeline | [`data-pipeline.md`](templates/data-pipeline.md) | Spark, Beam, schema evolution, idempotency, data quality |
| CLI Tool | [`cli-tool.md`](templates/cli-tool.md) | Cobra/Click/Clap, config handling, shell completion, releases |

### Infrastructure Projects

| Template | File | Description |
|---|---|---|
| Kubernetes | [`kubernetes-project.md`](templates/kubernetes-project.md) | Pod security, network policies, RBAC, HPA, GitOps |
| Operator SDK | [`operator-sdk.md`](templates/operator-sdk.md) | controller-runtime, reconciliation, finalizers, webhooks, envtest |
| Helm Chart | [`helm-chart.md`](templates/helm-chart.md) | Template patterns, values schema, hooks, OCI registries |

### Content Projects

| Template | File | Description |
|---|---|---|
| Content Writing | [`content-writing.md`](templates/content-writing.md) | Editorial standards, SEO, content lifecycle, accessibility |
| Proposals | [`proposals.md`](templates/proposals.md) | CFP structure, talk design, demo planning, audience analysis |
| Documentation | [`documentation.md`](templates/documentation.md) | Diataxis framework, docs-as-code, versioning, Vale linting |
| DevRel | [`general-devrel.md`](templates/general-devrel.md) | Developer journey, code samples, workshops, community metrics |

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

The template works out of the box. Drop it in as `CLAUDE.md` and Claude Code will follow the conventions immediately. Customization makes it better but is not required.

When you are ready to tailor it to your project:

1. **Search for TODO markers.** Every template has `<!-- TODO: ... -->` comments at the top. These mark the spots where project-specific details (repo name, tech stack, directory layout) improve accuracy. Work through them when you have five minutes.
2. **Update the tech stack** to match what you actually use. If the template says `httpx` but you use `aiohttp`, change it. Claude will follow whatever the file says.
3. **Remove sections that do not apply.** Using Django instead of FastAPI? Delete the FastAPI-specific advice. Shorter files are faster for Claude to process and less likely to go stale.
4. **Add your team's patterns.** If your team has conventions that are not in the template (naming schemes, specific banned patterns, required review steps), add them. The template gives you the structure; fill it with your reality.

The goal is a file that stays accurate for months, not one you have to update every sprint.

## What Makes These Templates Effective

Most CLAUDE.md files fail because they are either too vague to change behavior or too specific to stay current. These templates hit the middle ground.

Here is the contrast:

| Generic CLAUDE.md | These Templates |
|---|---|
| "Write clean code" | "Use `thiserror` for library error types and `anyhow` for application binaries" |
| "Write tests" | "Use table-driven tests with `t.Run` subtests. Cover error paths, not just happy paths" |
| "Handle errors properly" | "Wrap errors with `%w` to preserve the chain. Never discard errors with `_ =`" |
| "Use logging" | "Use `structlog` with bound loggers. Never use `print()` or `logging.warning(f'...')`" |
| "Follow security best practices" | "Validate all path inputs against traversal. Use `secrets.compare_digest` for token comparison" |
| "Keep dependencies updated" | "Run `cargo-deny check` in CI. Ban `openssl-sys` in favor of `rustls`" |

The generic version sounds reasonable but changes nothing. Claude already "writes clean code" by default. The specific version changes actual output. Claude will reach for `thiserror` instead of hand-rolling error enums. It will write table-driven tests instead of one-assertion test functions. It will use `structlog` instead of `print`.

Every template in this repo follows that principle: specific enough to change Claude's behavior, general enough to stay accurate across your codebase.

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

- Write in a direct, practical voice. No fluff.
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
