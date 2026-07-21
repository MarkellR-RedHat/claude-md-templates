# CLAUDE.md Templates

Part of the [AI BU](https://github.com/MarkellR-RedHat/ai-bu-hub) tool suite.

## Claude generates Python that looks like Go when it has no CLAUDE.md.

Without project conventions, Claude guesses. It picks `requests` instead of `httpx`, skips type hints, uses `print()` instead of structured logging, and returns raw dicts instead of Pydantic models. The code compiles, but it would never pass review.

A CLAUDE.md file fixes this. Drop a template into your project root, and Claude writes code that matches your stack on the first try.

## Before and After

**Prompt:** "Write a function to fetch user data from our API"

<table>
<tr>
<th>Without CLAUDE.md</th>
<th>With CLAUDE.md (Python template)</th>
</tr>
<tr>
<td>

```python
import requests

def get_user(user_id):
    response = requests.get(
        f"https://api.example.com/users/{user_id}"
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code}")
        return None
```

No type hints. Synchronous `requests`. `print` instead of logging. Raw dict return. No real error handling.

</td>
<td>

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


async def get_user(
    client: httpx.AsyncClient, user_id: int
) -> User:
    """Fetch a user by ID."""
    try:
        response = await client.get(f"/users/{user_id}")
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code == 404:
            raise NotFoundError(
                f"User {user_id} not found"
            ) from exc
        logger.error(
            "api_request_failed",
            user_id=user_id,
            status=exc.response.status_code,
        )
        raise APIError(
            f"Failed to fetch user {user_id}"
        ) from exc
    return User.model_validate(response.json())
```

Type hints. Async `httpx`. Pydantic model. Custom exceptions. Structured logging. Dependency injection.

</td>
</tr>
</table>

The only difference is a CLAUDE.md file in the project root.

## Quick Start

### 30-second install

```bash
git clone https://github.com/MarkellR-RedHat/ai-bu-claude-md-templates.git
cd ai-bu-claude-md-templates
./install.sh --template python-project --dir ~/my-project
```

That copies the Python template into `~/my-project/CLAUDE.md`. Open Claude Code in that directory and you are done.

### Not sure which template? Use interactive mode

```bash
./install.sh --interactive
```

Answer three questions about your project and get a recommendation.

### Browse all templates first

```bash
./install.sh --list       # See what's available
./install.sh --preview    # Read the first 20 lines of each template
./install.sh              # Pick from the full list
```

## Available Templates

### Code Projects

| Template | What it covers |
|---|---|
| [`python-project`](templates/python-project.md) | ruff, mypy, pytest, Pydantic, structlog, security patterns |
| [`go-project`](templates/go-project.md) | golangci-lint, table-driven tests, concurrency, error wrapping |
| [`rust-project`](templates/rust-project.md) | clippy, cargo-deny, tokio async, unsafe policy, fuzzing |
| [`fastapi-project`](templates/fastapi-project.md) | Pydantic v2, SQLAlchemy 2.0, Alembic, dependency injection |
| [`ai-ml-project`](templates/ai-ml-project.md) | PyTorch, vLLM, distributed training, RAG, GPU profiling |
| [`data-pipeline`](templates/data-pipeline.md) | Spark, Beam, schema evolution, idempotency, data quality |
| [`cli-tool`](templates/cli-tool.md) | Cobra/Click/Clap, config handling, shell completion, releases |

### Infrastructure Projects

| Template | What it covers |
|---|---|
| [`kubernetes-project`](templates/kubernetes-project.md) | Pod security, network policies, RBAC, HPA, GitOps |
| [`operator-sdk`](templates/operator-sdk.md) | controller-runtime, reconciliation, finalizers, webhooks, envtest |
| [`helm-chart`](templates/helm-chart.md) | Template patterns, values schema, hooks, OCI registries |

### Content Projects

| Template | What it covers |
|---|---|
| [`content-writing`](templates/content-writing.md) | Editorial standards, SEO, content lifecycle, accessibility |
| [`proposals`](templates/proposals.md) | CFP structure, talk design, demo planning, audience analysis |
| [`documentation`](templates/documentation.md) | Diataxis framework, docs-as-code, versioning, Vale linting |
| [`general-devrel`](templates/general-devrel.md) | Developer journey, code samples, workshops, community metrics |

### Which template do I need?

| If your project... | Start with | Consider adding |
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

## Why These Templates Work

Most CLAUDE.md files are too vague to change behavior. "Write clean code" tells Claude nothing it does not already know. These templates are specific enough to shift actual output.

| Vague CLAUDE.md | These templates |
|---|---|
| "Write clean code" | "Use `thiserror` for library error types and `anyhow` for application binaries" |
| "Write tests" | "Use table-driven tests with `t.Run` subtests. Cover error paths, not just happy paths" |
| "Handle errors properly" | "Wrap errors with `%w` to preserve the chain. Never discard errors with `_ =`" |
| "Use logging" | "Use `structlog` with bound loggers. Never use `print()` or `logging.warning(f'...')`" |
| "Follow security best practices" | "Validate all path inputs against traversal. Use `secrets.compare_digest` for token comparison" |

The specific version changes what Claude actually generates. Every template in this repo follows that principle.

## Slash Commands

Two slash commands ship with this repo for template management inside Claude Code.

**`/suggest-template`** analyzes your current project (language, frameworks, file structure) and recommends the right template. Optionally pass context:

```
/suggest-template this is a FastAPI app that serves ML models
```

**`/compose-template`** combines multiple templates into a single CLAUDE.md with intelligent section merging:

```
/compose-template python + kubernetes
/compose-template fastapi + ai-ml
```

To use these commands, copy the files in `commands/` into `~/.claude/commands/` (available in every project) or into your project's `.claude/commands/` directory (available in that project only).

### Typical workflow

1. **Run `/suggest-template`** in your project directory to detect your stack and get a recommendation.
2. **Install the template** with `./install.sh -t <name> -d ~/your-project` or pick interactively.
3. **Search for TODO markers** in the installed CLAUDE.md and fill in your project-specific details.
4. **Run `/compose-template`** if your project spans multiple domains (e.g., `python + kubernetes`).
5. **Start prompting.** Open Claude Code in that directory and the conventions take effect immediately.

**The detail that saves the most rework:** Fill in the `<!-- TODO -->` markers before your first real prompt. On a team of four, one engineer spent 45 minutes retrofitting type hints and structured logging after Claude generated 12 files without them. Filling in the template's stack section took 3 minutes and would have prevented every one of those fixes.

### Pairs with other AI BU tools

| When you need to... | Use |
|----------------------|-----|
| Generate proposals for a conference CFP | [`/cfp`](https://github.com/MarkellR-RedHat/ai-bu-cfp-generator) drafts submission-ready abstracts |
| Review content from a specific audience's perspective | [`/review-as-persona`](https://github.com/MarkellR-RedHat/ai-bu-review-as-persona) plays a skeptical reviewer or a target user |
| Check writing style before publishing | [`/style-check`](https://github.com/MarkellR-RedHat/ai-bu-style-checker) catches jargon, passive voice, and filler |
| Build a slide deck from your documented project | [`/slides`](https://github.com/MarkellR-RedHat/ai-bu-slide-outliner) generates a focused talk outline |
| Set up new team members on Claude Code | [`/onboarding-kit`](https://github.com/MarkellR-RedHat/ai-bu-onboarding-kit) walks new hires through setup and conventions |

## Customizing a Template

Templates work out of the box. Drop one in as `CLAUDE.md` and Claude follows the conventions immediately. Customization makes them better, but it is not required.

When you are ready to tailor a template:

1. **Search for TODO markers.** Every template has `<!-- TODO: ... -->` comments at the top marking spots where project-specific details improve accuracy.
2. **Update the tech stack** to match what you actually use. If the template says `httpx` but you use `aiohttp`, change it.
3. **Remove sections that do not apply.** Shorter files are faster for Claude to process and less likely to go stale.
4. **Add your team's patterns.** Naming schemes, banned patterns, required review steps. The template gives you the structure; fill it with your reality.

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
  -c, --combine NAMES         Combine templates separated by +
      --check                 Check existing CLAUDE.md status and remaining TODOs
```

Examples:

```bash
./install.sh                                       # Standard selection mode
./install.sh --interactive                          # Answer questions, get a recommendation
./install.sh --template go-project                  # Install Go template directly
./install.sh -t fastapi-project -d ~/app            # Install FastAPI template to ~/app
./install.sh --preview                              # Preview templates before choosing
./install.sh --list                                 # List all available templates
./install.sh --combine "python-project + kubernetes-project"  # Combine templates
./install.sh --check -d ~/myapp                     # Check existing CLAUDE.md status
```

## Contributing

Open an issue or PR. If a template gave you bad output, tell us what Claude generated and what you expected. If you have a template for a project type not covered here, send it.

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
- Use imperative mood for instructions.
- Be specific. "Functions must not exceed 50 lines" beats "write clean code."
- No em dashes. Use commas, periods, semicolons, or "and" instead.
- Include concrete code examples where they help.

### Testing your template

Before submitting:

1. Copy the template into an actual project as `CLAUDE.md`
2. Open the project with Claude Code
3. Ask Claude to perform typical tasks (write a function, fix a bug, add a test)
4. Verify Claude follows the conventions in your template
5. Check that TODO markers are clear and easy to find

## License

Apache License 2.0
