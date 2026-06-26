# Compose Template

Combine multiple CLAUDE.md templates into a single, unified CLAUDE.md file.

## Instructions

You are a template composer. The user provides template names in $ARGUMENTS (separated by `+` signs), and you merge them into a single, cohesive CLAUDE.md.

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

## Composition Rules

When merging templates, follow these rules:

### 1. Section Merging Strategy

Merge sections intelligently. Do not just concatenate files.

- **Project Overview**: Combine into a single overview that mentions all relevant technologies
- **Project Structure**: Merge directory trees, avoiding duplicates. Show one unified tree.
- **Code Conventions**: Keep all language-specific conventions. Group by language if multiple languages are involved.
- **Testing**: Merge testing sections. Keep framework-specific patterns (pytest, go test, cargo test) but avoid repeating generic advice.
- **Common Commands**: Combine into one section, grouped by activity (build, test, lint, deploy).
- **Review Checklist**: Merge all checklist items, remove duplicates, group logically.
- **Security Considerations**: Merge and deduplicate. Keep the most specific advice from each template.
- **Performance Considerations**: Merge and deduplicate.
- **Common Pitfalls**: Merge all pitfall lists. Remove duplicates.
- **.gitignore**: Combine all ignore patterns, organized by category with comments.

### 2. Deduplication Rules

- If two templates both say "use type hints on all function signatures," keep it once.
- If two templates have different advice on the same topic, keep both and label which applies to which context.
- If two templates reference the same tool (e.g., both mention `ruff`), consolidate the configuration.
- Keep the TODO markers from all templates, but combine them into a single block at the top.

### 3. Conflict Resolution

- If templates disagree (unlikely but possible), prefer the more specific template's advice.
- For container images, always use Red Hat Universal Base Image.
- For CI/CD, combine all relevant checks into a single pipeline section.

### 4. Output Structure

The composed CLAUDE.md should follow this structure:

```markdown
# CLAUDE.md - [Combined Project Description]

<!-- Quick customize: TODO markers from all source templates -->

## Project Overview
[Combined overview]

## Tech Stack
[Merged tech stacks]

## Project Structure
[Unified directory tree]

## Code Conventions
[Merged conventions, grouped by language/domain if needed]

## [Domain-Specific Sections]
[Sections unique to specific templates, kept as-is]

## Testing
[Merged testing guidance]

## Security Considerations
[Merged security guidance]

## Performance Considerations
[Merged performance guidance]

## Common Commands
[All commands, grouped by activity]

## Common Pitfalls
[Merged pitfall lists]

## Review Checklist
[Merged and deduplicated checklist]
```

## Example

User runs: `/compose-template python + kubernetes + ai-ml`

Output should be a single CLAUDE.md that:
1. Covers Python coding conventions (ruff, mypy, type hints)
2. Covers Kubernetes deployment patterns (Helm, CRDs, RBAC)
3. Covers AI/ML patterns (GPU-aware code, model serving, inference optimization)
4. Has a unified project structure showing Python source, Kubernetes manifests, and model configs
5. Has a combined testing section covering pytest, envtest, and GPU test markers
6. Has a combined .gitignore with Python, Kubernetes, and ML artifact patterns
7. Has a single review checklist covering all three domains

## Error Handling

If the user provides a template name that does not match any known template:
- List the available templates
- Suggest the closest match
- Ask the user to clarify

If only one template is provided (no `+` separator):
- Just use that single template as-is
- Suggest that they can combine with other templates using the `+` syntax
