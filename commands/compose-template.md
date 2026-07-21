# Compose Template

Combine multiple CLAUDE.md templates into a single, unified CLAUDE.md file with intelligent section merging.

## Instructions

You are a template composer. The user provides template names in $ARGUMENTS (separated by `+` signs), and you merge them into a single, cohesive CLAUDE.md. You do NOT simply concatenate files. You merge sections by domain, resolve conflicts with explicit rules, and produce a result where the origin of each piece of guidance is clearly labeled.

**Input format**: `$ARGUMENTS` contains template names separated by `+`, for example:
- `python + kubernetes`
- `fastapi + ai-ml`
- `go + helm-chart + kubernetes`
- `rust + cli-tool`

## Template Name Resolution

Match user input to template files using these aliases:

| User might type | Template file |
|---|---|
| `python`, `py` | `python-project.md` |
| `go`, `golang` | `go-project.md` |
| `rust`, `rs` | `rust-project.md` |
| `fastapi`, `fast-api` | `fastapi-project.md` |
| `ai`, `ml`, `ai-ml`, `aiml` | `ai-ml-project.md` |
| `k8s`, `kubernetes`, `kube`, `openshift` | `kubernetes-project.md` |
| `operator`, `operator-sdk`, `operators` | `operator-sdk.md` |
| `helm`, `helm-chart`, `chart` | `helm-chart.md` |
| `data`, `pipeline`, `data-pipeline`, `spark`, `beam` | `data-pipeline.md` |
| `cli`, `cli-tool`, `command-line` | `cli-tool.md` |
| `content`, `blog`, `writing`, `content-writing` | `content-writing.md` |
| `proposals`, `cfp`, `talks` | `proposals.md` |
| `docs`, `documentation` | `documentation.md` |
| `devrel`, `dev-rel`, `general-devrel` | `general-devrel.md` |

---

## Composition Rules

When merging templates, follow these section-by-section merge strategies. Every strategy is explicit about what to keep, what to deduplicate, and how to label origins.

### 1. Project Overview

Combine into a single overview paragraph that names all technologies in the stack. Example opener: "This project is a Python-based Kubernetes operator that uses ..." Do not repeat boilerplate from individual templates.

### 2. Tech Stack

Create one unified table or list. If two templates list the same tool (e.g., both mention `ruff`), list it once. Add a parenthetical note if a tool is used differently in different contexts (e.g., "`ruff` (Python linting and import sorting)").

### 3. Project Structure

Merge directory trees into one unified tree. Follow these rules:

- Use the **most specific template's structure as the base**. For example, when combining `python + kubernetes`, start with the Python `src/` layout and graft the Kubernetes directories (`deploy/`, `config/`, `api/`) alongside it.
- When both templates define a `tests/` directory, merge the subdirectories:
  ```
  tests/
    unit/           # Python unit tests (pytest)
    integration/    # Python integration tests (pytest)
    e2e/            # Kubernetes end-to-end tests (kind/envtest)
  ```
- Never show two separate directory trees. Always show one merged tree.
- Add inline comments to clarify which domain a directory serves: `deploy/helm/  # [Kubernetes]` or `src/models/  # [AI/ML]`.

### 4. Code Conventions

Keep all language-specific conventions. When multiple languages are present (e.g., Go + Helm templates + Kubernetes YAML), organize under sub-headers by language:

```markdown
### Go Conventions
...
### Kubernetes YAML Conventions
...
### Helm Template Conventions
...
```

If only one language is present but two templates contribute conventions (e.g., `python + ai-ml` both have Python style guidance), merge into a single section. Keep the more specific rule when two rules overlap. For example, if the Python template says "use type hints" and the AI/ML template also says "use type hints with tensor shape annotations," keep the AI/ML version since it is more specific, but note that general type hint guidance applies project-wide.

### 5. Testing

**Do NOT merge testing sections into a single flat list.** Organize by test type with sub-headers, and label the source domain:

```markdown
## Testing

### Unit Tests
#### Python Unit Tests [Python]
- Framework: pytest
- Fixture scoping, mocking patterns, async testing with pytest-asyncio
- Coverage: pytest-cov with fail_under=85

#### Kubernetes Controller Unit Tests [Kubernetes]
- Framework: controller-runtime fake client
- Test reconciliation loops with mock objects

### Integration Tests
#### Python Integration Tests [Python]
- testcontainers or pytest fixtures with real databases

#### Kubernetes Integration Tests [Kubernetes]
- Framework: envtest (spins up a real API server and etcd)
- Test CRD validation and webhook behavior

### End-to-End Tests [Kubernetes]
- Framework: kind (Kubernetes in Docker)
- Full cluster deployment testing

### Model Evaluation Tests [AI/ML]
- Benchmark suites for model quality regression
- GPU-aware test markers: @pytest.mark.gpu

### Load Tests [AI/ML]
- Tools: locust, vegeta for inference endpoint benchmarking

### Helm Chart Tests [Helm]
- helm-unittest for snapshot testing
- chart-testing (ct) for lint-and-install
```

When two templates mention the same testing tool (e.g., both Python and AI/ML use pytest), consolidate into the most relevant sub-header and cross-reference:
> "pytest is the standard framework for both application logic tests and model evaluation tests. See Unit Tests above for core patterns."

### 6. Security Considerations

**Merge by domain, not by template.** Create sub-headers by security domain:

```markdown
## Security Considerations

### Application Security [from Python/Go/Rust/FastAPI template]
- Input validation patterns
- SQL injection prevention
- SSRF prevention
- Secure deserialization
- Secrets management in application code (pydantic-settings, Vault)
- Dependency scanning (pip-audit, cargo-audit, govulncheck)
- CORS, rate limiting, security headers (if applicable)

### AI/ML Security [from AI/ML template]
- Prompt injection prevention
- Output filtering (PII leakage detection)
- Model access control (API keys, OAuth, RBAC)
- Data privacy in training data
- Adversarial input handling

### Infrastructure Security [from Kubernetes/Helm template]
- Pod Security Standards (restricted profile)
- RBAC least privilege
- Network Policies (default-deny ingress)
- Image security and supply chain (Trivy scanning, cosign signing, Sigstore)
- Secrets management in cluster (External Secrets Operator, Sealed Secrets, Vault CSI)
- Image pull secrets
- SecurityContext and securityContextConstraints (OpenShift)

### Supply Chain Security [from Rust/Go template, if applicable]
- cargo-vet, cargo-deny, cargo-audit
- gosec, govulncheck
- SBOM generation
```

If a security topic appears in two templates (e.g., both Python and Kubernetes mention secrets management), keep both and distinguish scope:
- "Application-level secrets: use pydantic-settings or environment variables [Python]"
- "Cluster-level secrets: use External Secrets Operator or Sealed Secrets [Kubernetes]"

### 7. Container Images

When two templates both mention container images, apply these rules:

- **Base image**: Pick one base image family and use it consistently across the composed output. The final stage should be minimal: `gcr.io/distroless/static` for Go, `debian:stable-slim` for Rust, `python:3.11-slim` for Python apps.
- **Builder stage**: Use the language-appropriate builder. For Go: `golang:1.2x`. For Rust: `rust:1-slim`. For Python: the slim Python image directly.
- **Multi-arch builds**: If the Go template is included, keep its multi-arch build pattern (`--platform linux/amd64,linux/arm64`) and apply it to the composed Dockerfile.
- **Common rules across all templates**: Non-root USER 1001, multi-stage builds, minimal final image.
- When one template has a more detailed Dockerfile pattern than another, use the more detailed one as the base and add any unique steps from the other template (e.g., adding `COPY --from=builder` steps for model artifacts from the AI/ML template into a Go operator's Dockerfile).

### 8. Common Pitfalls

**Merge with sub-headers by domain.** Never produce a single flat list of pitfalls from different domains mixed together:

```markdown
## Common Pitfalls

### Python Pitfalls [Python]
- Mutable default arguments
- Late binding closures
- Circular imports
- Datetime timezone handling
...

### Kubernetes Pitfalls [Kubernetes]
- Missing resource limits
- Misconfigured probes (readiness vs liveness)
- PVC access mode mismatches
- ConfigMap/Secret reload not triggering pod restart
...

### Go Pitfalls [Go]
- Goroutine leaks
- Nil interface vs nil pointer
- Deferred calls in loops
...

### Helm Pitfalls [Helm]
- Whitespace control in templates
- Nil pointer errors in nested values
- Release name length limits
...
```

If a template does not have a dedicated Common Pitfalls section (e.g., ai-ml-project.md), scan its other sections for cautionary guidance and include relevant items under an appropriate sub-header.

### 9. Performance Considerations

Merge under sub-headers by domain:

```markdown
## Performance Considerations

### Application Performance [Language template]
...
### Inference Performance [AI/ML]
...
### Cluster Resource Management [Kubernetes]
...
```

### 10. Common Commands

Combine into one section grouped by activity, with the source noted:

```markdown
## Common Commands

### Build
- `python -m build` [Python]
- `go build -o bin/myapp ./cmd/myapp` [Go]
- `helm package .` [Helm]

### Test
- `pytest tests/ -v` [Python]
- `go test ./... -race` [Go]
- `make test-e2e` [Kubernetes]
- `helm unittest .` [Helm]

### Lint
- `ruff check . && mypy .` [Python]
- `golangci-lint run` [Go]
- `helm lint .` [Helm]
- `ct lint` [Helm]

### Deploy
- `helm upgrade --install ...` [Kubernetes/Helm]
- `kubectl apply -k ...` [Kubernetes]
```

### 11. Review Checklist

Merge all checklist items. Remove exact duplicates. Group by domain with sub-headers:

```markdown
## Review Checklist

### Code Quality [Language template]
- [ ] Type hints on all public functions
- [ ] Error handling follows project patterns
...

### Kubernetes Resources [Kubernetes]
- [ ] Resource requests and limits set
- [ ] RBAC follows least privilege
...

### Helm Chart [Helm]
- [ ] values.schema.json updated
- [ ] NOTES.txt reflects changes
...
```

### 12. Domain-Specific Sections

Sections that are unique to one template (e.g., "Operator Development" from the Kubernetes template, "RAG Patterns" from the AI/ML template, "Shell Completion" from the CLI template) should be kept as-is in the composed output. Place them after the merged common sections and before the Review Checklist. Add a domain label to the header:

```markdown
## Operator Development [Kubernetes]
...

## RAG Patterns [AI/ML]
...

## Shell Completion [CLI]
...
```

### 13. Deduplication Rules

- If two templates give identical advice (e.g., both say "use type hints"), keep it once in the most relevant section.
- If two templates give different advice on the same topic, keep both and label which context each applies to.
- If two templates reference the same tool with different config (e.g., both mention `ruff` but with different rule sets), consolidate the configuration into one block with comments explaining domain-specific rules.
- Combine all TODO markers from all templates into a single block at the top of the composed output.

---

## Merge Conflict Resolution

When templates give contradictory guidance, apply these explicit resolution rules:

### Container Base Image
Use one consistent base image family in the composed output. If templates disagree, prefer the more minimal option (distroless or slim over full OS images). The builder stage uses the language-specific image (e.g., `golang:1.2x` for Go, `python:3.11-slim` for Python).

### Testing Frameworks
Keep all testing frameworks. Never discard one in favor of another. Organize by test type (unit, integration, e2e, load, evaluation) with clear sub-headers indicating which framework applies where. When two templates both use pytest, consolidate their pytest configuration into one `pyproject.toml` snippet covering all test paths and markers.

### Linting
Keep all linter configurations. Merge into one section with sub-headers by language or tool:
- If Python + Kubernetes: keep `ruff`, `mypy`, and `helm lint` / `ct lint`
- If Go + Kubernetes: keep `golangci-lint`, `helm lint`, and `kubeconform`
- Show one merged `pyproject.toml` or `.golangci.yml` config that includes all rules

### Project Structure
Merge directory trees. Use the most specific template's structure as the base:
- Language template provides `src/` or `cmd/` + `internal/` layout
- Kubernetes template grafts `deploy/`, `config/`, `api/` alongside
- Helm template grafts `charts/` or replaces `deploy/helm/` if already present
- AI/ML template grafts `model_cards/`, `configs/`, `data/` alongside
- CLI template uses the language template's layout but adds `completions/`, `docs/man/`

### Dependency Management
If two templates describe dependency management for the same language (e.g., both Python and FastAPI use pip/poetry), merge into one section. Keep the more detailed guidance.

### Error Handling
If two templates describe error handling differently for the same language, keep the more detailed pattern. For cross-language projects (Go + Helm), keep both under language-specific sub-headers.

### Secrets Management
Always include both application-level and infrastructure-level secrets guidance when both are present:
- Application: environment variables, pydantic-settings, Vault client libraries
- Infrastructure: External Secrets Operator, Sealed Secrets, Vault CSI driver

---

## Common Combination Guidance

For the most frequently used template combinations, follow this additional specific guidance.

### python + kubernetes

**Project Structure**: Start with the Python `src/` layout. Add `deploy/` (with `helm/` and `kustomize/` subdirectories), `config/` (for Kubernetes manifests), and update `tests/` to include `tests/e2e/` for Kubernetes end-to-end tests alongside the existing `tests/unit/` and `tests/integration/`.

**Testing**: The Python template provides pytest patterns (fixtures, mocking, async testing, property-based testing). The Kubernetes template provides envtest (integration) and kind (e2e). Keep both complete. Under "Unit Tests," include pytest conventions. Under "Integration Tests," include BOTH Python integration tests (with testcontainers or real database fixtures) AND Kubernetes envtest patterns. Under "End-to-End Tests," include kind-based cluster tests. Unify the test runner: all Python tests still run via `pytest`; Kubernetes envtest and e2e may use `go test` or `make` targets if the operator is in Go, or pytest with kubernetes-client if the operator is in Python.

**Container Images**: Use `ubi9/python-311` as the base. Keep the Python template's multi-stage build pattern. Add Kubernetes-specific labels (`app.kubernetes.io/*`) to the image.

**Security**: Create "Application Security" (from Python: input validation, SQL injection, SSRF, secure deserialization, dependency scanning) and "Infrastructure Security" (from Kubernetes: Pod Security Standards, RBAC, Network Policies, image supply chain). For secrets, include both `pydantic-settings` for app config and External Secrets Operator for cluster secrets.

### fastapi + ai-ml

**Project Structure**: Start with the FastAPI `src/myapp/` layout. Add directories from AI/ML: `src/myapp/models/` (ML model definitions, not to be confused with FastAPI Pydantic models), `src/myapp/serving/` (inference endpoints), `configs/` (model configs, training configs), `model_cards/`, and `data/`. Rename Pydantic model files to `schemas/` to avoid confusion with ML models, or use an explicit naming convention like `src/myapp/schemas/` for Pydantic and `src/myapp/ml_models/` for ML.

**Testing**: Both use pytest. Merge into one pytest configuration. Key distinction: the FastAPI template's tests use `httpx.AsyncClient` with `ASGITransport` for API endpoint testing; the AI/ML template's tests include GPU-aware markers (`@pytest.mark.gpu`) and model evaluation benchmarks. Keep both. Organize as:
- Unit Tests: FastAPI route logic + ML model unit tests (CPU-only)
- Integration Tests: API endpoint tests with `httpx.AsyncClient` + model inference tests
- Evaluation Tests: model quality benchmarks (accuracy, latency)
- Load Tests: inference endpoint load testing with locust

**Serving**: The FastAPI template provides generic API patterns (routers, middleware, dependency injection). The AI/ML template provides vLLM serving patterns (continuous batching, KV cache management, tensor parallelism). Merge by making FastAPI the HTTP layer and referencing the AI/ML serving config for the model backend. Include a "Model Serving Architecture" section that shows how FastAPI routes call into vLLM or a similar inference backend.

**Security**: Merge FastAPI's API security (CORS, rate limiting, auth middleware, input validation) with AI/ML's model security (prompt injection prevention, output filtering, adversarial inputs). Both are application-level security but in distinct sub-domains.

### go + kubernetes + helm-chart

**Project Structure**: Start with the Go `cmd/` + `internal/` layout (common for operators). Graft `api/v1alpha1/` for CRD types, `config/` for Kubernetes manifests, and `deploy/helm/` for the Helm chart. The Helm chart structure (`Chart.yaml`, `values.yaml`, `templates/`) goes under `deploy/helm/myapp/`.

**Testing**: Three distinct testing stacks:
- Go unit tests: table-driven tests with `go test`, controller-runtime fake client for reconciler tests
- Kubernetes integration tests: envtest for CRD validation and webhook testing
- Kubernetes E2E tests: kind for full cluster deployment
- Helm chart tests: `helm-unittest` for template snapshot testing, `ct lint` for chart validation, `helm test` for deployed chart verification

Keep all four. They test different layers. The test commands section should list `go test ./...`, `make test-e2e`, `helm unittest charts/myapp`, and `ct lint`.

**Container Images**: Use the Go template's multi-arch build pattern as the base. Builder stage: `golang:1.2x`. Final stage: `ubi9/ubi-minimal:latest`. The Helm chart's `values.yaml` should reference the same image. Include the Go template's CGO_ENABLED=0 static binary pattern.

**Code Conventions**: Three sub-sections: "Go Conventions" (naming, error handling, concurrency), "Kubernetes YAML Conventions" (naming, labels, annotations from the Kubernetes template), and "Helm Template Conventions" (whitespace control, named templates, _helpers.tpl patterns).

**Common Pitfalls**: Three sub-sections: "Go Pitfalls" (goroutine leaks, nil interface, deferred calls in loops), "Kubernetes Pitfalls" (resource limits, probe misconfiguration, DNS resolution), "Helm Pitfalls" (whitespace, nil pointer in nested values, release name length).

### rust + cli-tool

**Project Structure**: Use the Rust template's layout (`src/main.rs`, `src/lib.rs`, `src/bin/`, etc.) and add CLI-specific directories: `completions/` (generated shell completions), `docs/man/` (man pages), `examples/`. The CLI template has three language-specific layouts; use only the Rust (Clap) variant and discard the Go and Python variants.

**Argument Parsing**: The CLI template provides Clap-specific patterns (derive API, subcommands, help text, value parsers). The Rust template provides general Rust conventions. Keep the CLI template's Clap guidance as the primary reference for argument parsing and add Rust-specific patterns (custom error types, `thiserror` for user-facing errors).

**Testing**: Merge the Rust template's testing tools (cargo test, insta for snapshots, proptest for property-based, cargo-fuzz, Miri) with the CLI template's testing patterns (assert_cmd for end-to-end CLI testing, golden file comparison). Organize as:
- Unit Tests: `#[test]` and `#[tokio::test]` for library logic
- CLI Integration Tests: `assert_cmd` for subcommand invocation and exit code verification
- Snapshot Tests: `insta` for output comparison
- Fuzz Tests: `cargo-fuzz` for untrusted input
- Property-Based Tests: `proptest` for invariant verification

**Container Images**: Override the CLI template's distroless suggestion. Use `ubi9/ubi:latest` as builder (with rustup) and `ubi9/ubi-minimal:latest` as the final stage. Keep the Rust template's Dockerfile pattern.

**Error Handling**: The Rust template covers `thiserror` and `anyhow` patterns. The CLI template covers user-facing error messages, exit codes, and TTY detection. Merge: use `thiserror` for typed errors, map them to appropriate exit codes per the CLI template's exit code table, and format error output based on TTY detection.

---

## Output Structure

The composed CLAUDE.md should follow this structure. Every section header that merges content from multiple templates should use domain labels `[TemplateName]` to indicate origin. Sections unique to a single template should have the domain label in the H2 header.

```markdown
# CLAUDE.md - [Combined Project Description]

<!-- Quick customize: all TODO markers from all source templates, consolidated -->
<!-- Source templates: [list of template files used] -->

## Project Overview
[Combined overview naming all technologies]

## Tech Stack
[Merged, deduplicated tech stacks]

## Project Structure
[One unified directory tree with inline domain comments]

## Code Conventions
### [Language 1] Conventions
...
### [Language 2 / Domain] Conventions
...

## Dependency Management
[Merged, one section per language/tool]

## Testing
### Unit Tests
#### [Domain A] Unit Tests
...
#### [Domain B] Unit Tests
...
### Integration Tests
...
### End-to-End Tests
...
### [Other test types as applicable]
...

## Security Considerations
### Application Security [from language/framework template]
...
### Infrastructure Security [from Kubernetes/Helm template]
...
### AI/ML Security [from AI/ML template, if applicable]
...
### Supply Chain Security [from applicable templates]
...

## Performance Considerations
### Application Performance [language template]
...
### Infrastructure Performance [Kubernetes template, if applicable]
...

## Container Image
[Merged Dockerfile pattern, UBI base, domain comments on each stage]

## [Domain-Specific Sections, kept intact]
[e.g., Operator Development, RAG Patterns, Shell Completion, etc.]

## Common Commands
### Build
...
### Test
...
### Lint
...
### Deploy
...

## Common Pitfalls
### [Domain A] Pitfalls
...
### [Domain B] Pitfalls
...

## Review Checklist
### Code Quality [language template]
...
### Infrastructure [Kubernetes/Helm, if applicable]
...
### [Other domains]
...
```

---

## Output Calibration

The composed CLAUDE.md must read like it was written by a senior engineer who knows all the tools in the stack, not like two documents stapled together. Be direct. Every rule should be an imperative.

### Bad output (do not do this)

```markdown
## Testing

This project uses a comprehensive testing strategy that encompasses both Python and Kubernetes testing paradigms. The testing approach facilitates quality assurance across multiple layers of the application stack.

### Python Testing
Tests should be written using pytest, which provides robust test infrastructure...

### Kubernetes Testing
Kubernetes testing leverages envtest to provide a scalable integration testing solution...
```

This is filler. "Comprehensive testing strategy" says nothing. "Facilitates quality assurance" is corporate noise. Nobody needs to be told that pytest "provides robust test infrastructure."

### Good output (do this)

```markdown
## Testing

### Unit Tests

#### Python [Python]
Run with `pytest tests/unit/ -v`. Use fixtures for database sessions and HTTP clients. Mock external services with `respx` or `pytest-httpx`. Async tests use `pytest-asyncio` with `mode=auto`.

Coverage threshold: 85%. Run `pytest --cov=src --cov-fail-under=85`.

#### Controller [Kubernetes]
Use controller-runtime's fake client. Test each reconciliation path: create, update, delete, error. Assert status conditions after each reconcile call.

### Integration Tests

#### API [Python]
Use `httpx.AsyncClient` with `ASGITransport`. Test against a real database (testcontainers or a pytest fixture that spins up PostgreSQL). Do not mock the database in integration tests.

#### CRD Validation [Kubernetes]
Use envtest. It runs a real API server and etcd. Test CRD validation, defaulting webhooks, and RBAC rules.

### End-to-End Tests [Kubernetes]
Use kind. Deploy the full stack (operator, CRDs, sample CR). Verify the operator creates the expected child resources. Tear down after each test.
```

### What makes the good output work

- Each section starts with a command you can run or a tool you should use
- No preamble explaining what testing is or why it matters
- Rules are imperatives: "Use fixtures," "Mock external services," "Do not mock the database"
- Domain labels (`[Python]`, `[Kubernetes]`) tell you where each rule comes from
- Specific thresholds and tool names, not "robust" or "comprehensive"

## Edge Cases

Handle these situations explicitly. Do not paper over them with generic advice.

### Multi-Language Projects (3+ Templates)

When composing three or more templates (e.g., `go + kubernetes + helm-chart + cli-tool`):

1. **Identify the primary language template.** This template drives the project structure, dependency management, and build commands. All other templates graft onto it.
2. **Group templates by layer.** Language templates (go, python, rust) form the base. Infrastructure templates (kubernetes, helm-chart, operator-sdk) add deployment. Domain templates (ai-ml, data-pipeline, cli-tool) add specialized patterns.
3. **Avoid section bloat.** With 3+ templates, merged sections like "Common Pitfalls" or "Security Considerations" can become overwhelming. Keep sub-headers but limit each domain's entries to the 5 most impactful items. Add a note: "See the full [template-name] template for additional guidance."
4. **Consolidate the Review Checklist.** Do not produce a 50-item checklist. Group by activity (pre-commit, pre-merge, pre-release) rather than by template source.
5. **Warn the user.** If composing 4+ templates, add a note at the top of the output: "This CLAUDE.md combines guidance from [N] templates. Consider whether your project genuinely spans all of these domains, or whether some belong in subproject-level CLAUDE.md files instead."

### Existing Conflicting CLAUDE.md

When the user's project already has a `CLAUDE.md` and they run `/compose-template`:

1. Read the existing `CLAUDE.md` first.
2. Treat it as an additional "template" in the merge. Existing project-specific rules (custom lint configs, team conventions, repo-specific commands) take priority over template defaults.
3. Never discard project-specific content from the existing file. If it conflicts with a template rule, keep the project-specific version and add a comment: `<!-- Template suggests [X], but this project uses [Y] per team convention -->`.
4. In the output, clearly mark which sections came from the existing file vs. the templates: `[Existing]` label alongside the `[Python]` and `[Kubernetes]` labels.
5. If the existing `CLAUDE.md` already covers a section well, do not duplicate it from the template. Reference it: "Your existing CLAUDE.md already covers this section. Keeping your version."

### Projects with No Tests, CI, or Linter

When composing templates for a project that lacks testing, CI, or linter setup:

1. Include the testing and CI sections from the templates as-is. These are the most valuable sections for an under-tooled project.
2. Add a callout at the top of the Testing section: "This project does not currently have a test suite. The patterns below are a starting point. Adapt the directory structure and test commands to match your project's needs."
3. For linting, include the combined linter configuration from all relevant templates. Mark it as a starting point, not a requirement: "Add this to your `pyproject.toml` (or equivalent) to enable the recommended linters."
4. Do not skip or minimize these sections just because the project does not have them yet. The whole point of the template is to fill these gaps.

### Unknown Frameworks in Composition

When the user requests a composition that includes a framework not covered by any template (e.g., `django + kubernetes` when there is no Django template):

1. Use the closest language template for the framework's language (e.g., `python-project` for Django).
2. Note the gap in the composed output's Project Overview: "This CLAUDE.md uses the Python template as a base. Django-specific patterns (views, URL routing, ORM, management commands, middleware) are not covered by the available templates and should be added based on your project's conventions."
3. Still compose the other templates normally. The Kubernetes sections are just as relevant regardless of the web framework.
4. Never generate framework-specific guidance you do not have a template for. Acknowledge the gap and move on.

### Contradictory Template Combinations

Some template combinations include guidance that fundamentally conflicts:

- `cli-tool + fastapi`: CLI tools and web services have different entry points, lifecycle models, and output patterns. Note this: "These templates serve different application types. If your project is a CLI that also runs a local API server, use the CLI template as the base and add the FastAPI dependency injection and Pydantic patterns."
- `operator-sdk + helm-chart`: Many operators deploy Helm charts, but the operator template and helm-chart template have different scopes. Note: "The operator-sdk template covers the Go controller code. The helm-chart template covers the chart your operator may deploy. Keep them in separate sections, not merged."
- `content-writing + python-project`: These are different domains. If combined, keep them completely separate: content guidance in one block, Python code guidance in another. Do not try to merge their conventions.

## Error Handling

If the user provides a template name that does not match any known template:
- List the available templates
- Suggest the closest match
- Ask the user to clarify

If only one template is provided (no `+` separator):
- Just use that single template as-is
- Suggest that they can combine with other templates using the `+` syntax
