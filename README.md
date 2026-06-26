# CLAUDE.md Templates

A collection of ready-to-use CLAUDE.md template files for different project types.

## What is CLAUDE.md?

CLAUDE.md is a file you place in your project's root directory to give [Claude Code](https://docs.anthropic.com/en/docs/claude-code) context about your project. It tells Claude about your coding conventions, project structure, testing approaches, and how to work effectively in your codebase. Think of it as onboarding documentation for your AI coding assistant.

When Claude Code opens a project, it reads the CLAUDE.md file and uses that context to generate better, more project-appropriate code and suggestions.

## Available Templates

| Template | File | Best For |
|----------|------|----------|
| Content Writing | `templates/content-writing.md` | Blog posts, technical articles, and content projects. Includes Red Hat tone guidelines, product name conventions, blog structure patterns, and link formatting rules. |
| Conference Proposals | `templates/proposals.md` | CFP submissions and talk proposals. Includes abstract structure, learning objectives, audience targeting, and speaker bio formatting. Covers KubeCon, Red Hat Summit, DevConf, and more. |
| AI/ML Project | `templates/ai-ml-project.md` | Machine learning and AI codebases. Covers model serving with vLLM and KServe, GPU-aware testing, inference pipelines, PyTorch conventions, and container image best practices. |
| Kubernetes Project | `templates/kubernetes-project.md` | Kubernetes and OpenShift projects. Includes Helm chart conventions, operator patterns, CRD naming rules, RBAC best practices, and testing with kind and envtest. |
| General Dev Rel | `templates/general-devrel.md` | Developer Relations work. Covers code sample standards, documentation guidelines, workshop design, demo best practices, and community interaction patterns. |
| Go Project | `templates/go-project.md` | Go codebases. Includes Go naming conventions, error handling patterns, concurrency guidelines, testing with table-driven tests, and container image builds. |
| Python Project | `templates/python-project.md` | Python codebases. Covers type hints, pytest conventions, dependency management with uv and pip, Pydantic models, ruff linting, and virtual environment handling. |
| Rust Project | `templates/rust-project.md` | Rust codebases. Covers cargo conventions, clippy lints, error handling with thiserror and anyhow, async patterns with tokio, and unsafe code guidelines. |
| Documentation | `templates/documentation.md` | Documentation-focused projects. Covers style guides, information architecture, content structure, review checklists, and publishing workflows. |
| Helm Chart | `templates/helm-chart.md` | Helm chart development. Covers chart structure, values schema design, template helpers, hook patterns, dependency management, and chart testing with helm-unittest. |

## Template Comparison

Use this table to quickly find the right template for your project.

| If your project is... | Use this template | Key features |
|---|---|---|
| A Python application or library | `python-project.md` | ruff, pytest, type hints, Pydantic, uv/pip, virtual environments |
| A Go service or CLI tool | `go-project.md` | golangci-lint, table-driven tests, error wrapping, concurrency patterns |
| A Rust crate or binary | `rust-project.md` | cargo, clippy, thiserror/anyhow, tokio, unsafe code guidelines |
| An AI/ML pipeline or model serving system | `ai-ml-project.md` | vLLM, KServe, PyTorch, GPU-aware testing, inference pipelines |
| A Kubernetes operator or controller | `kubernetes-project.md` | Helm charts, CRD patterns, RBAC, envtest, OpenShift compatibility |
| A standalone Helm chart | `helm-chart.md` | values schema, template helpers, hooks, helm-unittest, dependency management |
| A blog post, article, or content piece | `content-writing.md` | Red Hat tone, product naming, blog structure, link formatting |
| A conference talk or CFP submission | `proposals.md` | Abstract structure, learning objectives, audience targeting, speaker bios |
| A documentation site or knowledge base | `documentation.md` | Style guides, information architecture, content structure, review checklists |
| A developer relations project (demos, workshops, samples) | `general-devrel.md` | Code samples, workshop design, demo best practices, community patterns |

## Quick Start

### Option 1: Use the install script

```bash
git clone https://github.com/MarkellR-RedHat/ai-bu-claude-md-templates.git
cd ai-bu-claude-md-templates
chmod +x install.sh
./install.sh
```

The script will show you the available templates, let you pick one, and copy it to a directory of your choice.

Additional flags:

```bash
./install.sh --help       # Show usage information
./install.sh --list       # List templates and exit (useful for scripting)
./install.sh --preview    # Preview template contents before selecting
```

### Option 2: Copy manually

```bash
# Copy a template directly into your project
cp templates/python-project.md /path/to/your/project/CLAUDE.md
```

### Option 3: Use curl (no clone needed)

```bash
# Download a single template directly
curl -o CLAUDE.md https://raw.githubusercontent.com/MarkellR-RedHat/ai-bu-claude-md-templates/main/templates/python-project.md
```

## Customizing a Template

After copying a template into your project, customize it:

1. **Search for TODO markers.** Every template includes `TODO` comments that flag sections you need to fill in or adjust for your project. Start by searching for `TODO` and working through each one.
2. Update the **Project Overview** section with a description of your specific project.
3. Adjust the **Tech Stack** to match what your project actually uses.
4. Modify **Project Structure** to reflect your real directory layout.
5. Add or remove conventions based on your team's practices.
6. Update **Common Commands** with the actual commands for your project.

The templates are starting points, not rigid specifications. Remove what does not apply and add what is missing.

## Contributing a Template

Contributions are welcome. If you have a template for a project type not covered here, open a PR. Below are the guidelines for new templates.

### File naming

- Use lowercase, hyphenated names with a `.md` extension. Examples: `python-project.md`, `helm-chart.md`, `content-writing.md`.
- Pick a name that clearly identifies the project type or domain.

### Required sections

Every template must include these sections (order may vary):

1. **Quick customize** (or TODO markers). Provide inline `TODO` comments so users can quickly find and fill in project-specific details.
2. **Project Overview.** A placeholder for the project description, tech stack, and directory structure.
3. **Code/Content Conventions.** The core guidance for Claude: naming rules, patterns, style, linting, and formatting.
4. **Testing/Validation.** How to run tests, what frameworks to use, coverage expectations, and any project-specific testing patterns.
5. **Common Commands.** The shell commands a developer runs daily (build, test, lint, deploy).
6. **Review Checklist.** A final checklist Claude can use before submitting code or content.

### Voice and tone

- Write in a direct, practical voice. No filler, no fluff.
- Use imperative mood for instructions ("Run tests with pytest" not "You should run tests with pytest").
- Be specific. Generic advice like "write clean code" does not help. Instead, say exactly what you mean ("Functions must not exceed 50 lines").
- Avoid em dashes. Use commas, periods, semicolons, or "and" instead.

### Testing your template

Before submitting a PR, test your template in a real project:

1. Copy the template into an actual project directory as `CLAUDE.md`.
2. Open that project with Claude Code.
3. Ask Claude to perform typical tasks (write a function, fix a bug, add a test).
4. Verify that Claude follows the conventions in your template.
5. Check that the TODO markers are clear and easy to find.

### PR process

1. Fork the repository and create a branch for your template.
2. Add your template file to the `templates/` directory.
3. Update the "Available Templates" table and the "Template Comparison" table in this README.
4. Open a PR with a brief description of what project type the template covers and why it is useful.
5. Be ready to iterate on feedback.

## License

Apache License 2.0
