# CLAUDE.md - Documentation Project

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Set your docs framework (Antora, Hugo, or mkdocs) -->
<!-- TODO: Set your repository URL for source links and edit-on-GitHub links -->
<!-- TODO: Set your preview command (e.g., "npm run serve", "hugo serve", "mkdocs serve") -->
<!-- TODO: Set your deploy target (GitHub Pages, Netlify, OpenShift, internal CMS) -->
<!-- TODO: Set your product name and version for frontmatter defaults -->
<!-- TODO: Set your link checker tool (lychee, htmltest, or linkchecker) -->

## Project Overview

This is a documentation-as-code project. Content is written in Markdown or AsciiDoc, stored in version control, built with a static site generator, and deployed through CI/CD. The primary audience is developers, platform engineers, and technical decision-makers.

## Content Types (Diataxis Framework)

Structure documentation using the four Diataxis content types. Each type serves a different user need, and mixing them creates confusing docs.

### Tutorials
- **Purpose**: Learning-oriented. Walk a newcomer through a complete experience.
- **Structure**: Numbered steps with a clear start and end. The user builds something real.
- **Voice**: Encouraging and specific. "Run this command. You should see this output."
- **Example**: "Deploy your first application on OpenShift"
- **Do not**: Skip steps, assume prior knowledge, or add optional side quests.

### How-To Guides
- **Purpose**: Task-oriented. Help an experienced user accomplish a specific goal.
- **Structure**: Numbered steps focused on the task. Assume the reader knows the basics.
- **Voice**: Direct and efficient. Get to the point fast.
- **Example**: "Configure GPU scheduling for inference workloads"
- **Do not**: Teach fundamentals or explain concepts that belong in a separate page.

### Reference
- **Purpose**: Information-oriented. Describe the machinery: APIs, CLI flags, configuration options.
- **Structure**: Consistent format for every entry. Tables, parameter lists, type definitions.
- **Voice**: Precise and neutral. Describe what things are, not how to use them.
- **Example**: API endpoint reference, CLI command reference, configuration file reference
- **Do not**: Include tutorials or opinions. Reference docs are lookup tables.

### Explanation (Conceptual Docs)
- **Purpose**: Understanding-oriented. Explain why things work the way they do.
- **Structure**: Prose with diagrams. Discuss design decisions, trade-offs, and architecture.
- **Voice**: Conversational and analytical. "Here is why we chose this approach."
- **Example**: "How the scheduler allocates GPU resources" or "Architecture overview"
- **Do not**: Include step-by-step instructions. Link to how-to guides for that.

## Docs Framework

This project uses one of the following frameworks. Refer to the section that applies.

### Antora (AsciiDoc)
```
docs/
  antora.yml                  # Component descriptor
  modules/
    ROOT/
      nav.adoc                # Navigation file
      pages/
        index.adoc
        getting-started.adoc
      images/
      examples/               # Includable code samples
      partials/               # Reusable content fragments
    module-name/
      nav.adoc
      pages/
      images/
antora-playbook.yml           # Site playbook
```

### Hugo (Markdown)
```
docs/
  config.toml                 # Site configuration (or hugo.toml)
  content/
    _index.md                 # Landing page
    getting-started/
      _index.md
      installation.md
      quickstart.md
    guides/
    reference/
  layouts/                    # Custom templates
  static/                     # Static assets (images, CSS)
  themes/
```

### MkDocs (Markdown)
```
docs/
  index.md
  getting-started/
    installation.md
    quickstart.md
  guides/
  reference/
  images/
mkdocs.yml                    # Site configuration
overrides/                    # Theme customizations
```

## Docs-as-Code Workflow

### PR review for docs

Treat documentation changes like code changes. Every change goes through a pull request.

- Assign at least one reviewer for every docs PR.
- For technical content, assign a subject matter expert (SME) as a reviewer.
- For style and structure, assign a technical writer or docs maintainer.
- Use CI checks to catch issues before human review (see CI Validation Pipeline below).

### CI validation pipeline

Run these checks automatically on every PR:

1. **Build check**: Does the site build without errors or warnings?
2. **Link check**: Are all internal and external links valid?
3. **Lint check**: Does the content pass Vale and any custom lint rules?
4. **Spell check**: Flag unknown words (add technical terms to a custom dictionary).
5. **Image check**: Do all referenced images exist? Are alt attributes present?

Example GitHub Actions workflow:
```yaml
name: Docs validation
on:
  pull_request:
    paths: ['docs/**']

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build docs
        run: mkdocs build --strict
      - name: Check links
        uses: lycheeverse/lychee-action@v1
        with:
          args: --config .lychee.toml "docs/**/*.md"
          fail: true
      - name: Run Vale
        uses: errata-ai/vale-action@v2
        with:
          files: docs/
```

### Staging preview environments

- Deploy a preview build for every PR so reviewers can see the rendered output.
- Use Netlify Deploy Previews, GitHub Pages preview branches, or an OpenShift staging deployment.
- Include the preview URL in the PR description or as an automated comment.
- Preview builds should match production configuration (same theme, same plugins, same base URL behavior).

## Content Style Guide

### Voice and Tone
- Write in second person: "you" and "your." Address the reader directly.
- Use active voice. "Run the command" not "The command should be run."
- Be direct and practical. Lead with what the reader needs to do.
- Use present tense: "The API returns a JSON response" not "The API will return a JSON response."
- Keep paragraphs short: 3-5 sentences maximum.
- Write for scanning. Developers do not read documentation top to bottom. They scan for the specific thing they need.

### Headers
- Use sentence case for all headers: "Getting started with OpenShift" not "Getting Started With OpenShift."
- Headers should describe what the section contains: "Configure the database connection" not "Database."
- Do not skip heading levels. H2 follows H1, H3 follows H2.
- Do not use more than 4 heading levels (H1 through H4). Deeper nesting signals content that should be split into separate pages.

### Formatting
- Use backtick formatting for all code references: commands, file paths, environment variables, function names, config keys.
- Use fenced code blocks with language identifiers for multi-line code:
  ````markdown
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  ```
  ````
- Use bold for UI elements and field names: **Save**, **Project Name**.
- Use ordered lists for sequential steps. Use unordered lists for non-sequential items.
- Do not use em dashes anywhere. Use commas, periods, semicolons, or "and" instead.

### Terminology
- Use consistent terminology throughout the docs. Pick one term and stick with it.
- Maintain a glossary or terminology reference if the project has domain-specific terms.
- Follow Red Hat product name conventions (see the content-writing template for the full reference).

## Versioned Documentation

### Version strategy
- Maintain docs for the current release and at least one previous release.
- Use branches or directory structures to separate versions: `docs/v2.1/`, `docs/v2.0/`.
- Display a version selector in the site navigation so readers can switch between versions.

### Deprecation notices
- When a feature is deprecated, add a notice at the top of its docs page:
  ```markdown
  !!! warning "Deprecated"
      This feature is deprecated in version 2.1 and will be removed in version 3.0.
      Use [new feature](link) instead.
  ```
- Keep deprecated docs available for at least one release cycle after removal.

### Migration guides
- For every major version, publish a migration guide covering: what changed, what broke, and how to update.
- Structure migration guides as checklists so users can track their progress.
- Include before/after code examples for API or configuration changes.

## API Documentation

### OpenAPI/Swagger integration
- Generate API reference docs from OpenAPI specs. Do not maintain them by hand.
- Use tools like Redoc, Swagger UI, or Stoplight for rendering.
- Store the OpenAPI spec file in the same repo as the API code so it stays in sync.

### Code sample generation
- Include working code samples for every API endpoint in at least one language (curl, Python, or Go).
- Auto-generate code samples from the OpenAPI spec when possible.
- Test generated samples in CI to catch drift between the spec and the actual API.

### API docs structure
```
reference/
  api/
    index.md              # Overview, authentication, rate limits, error codes
    endpoints/
      users.md            # GET/POST/PUT/DELETE for users
      projects.md         # GET/POST/PUT/DELETE for projects
    schemas/
      user.md             # User object schema
    changelog.md          # API version history
```

## Frontmatter Conventions

### Hugo
```yaml
---
title: "Installing the CLI"
description: "Step-by-step guide to installing and configuring the project CLI."
date: 2025-01-15
lastmod: 2025-03-20
weight: 10
draft: false
tags: ["installation", "cli", "getting-started"]
categories: ["guides"]
---
```

### MkDocs (with meta plugin)
```yaml
---
title: Installing the CLI
description: Step-by-step guide to installing and configuring the project CLI.
tags:
  - installation
  - cli
---
```

### Antora (AsciiDoc page attributes)
```asciidoc
= Installing the CLI
:description: Step-by-step guide to installing and configuring the project CLI.
:keywords: installation, cli, getting-started
:page-aliases: install.adoc
```

## Admonitions and Callouts

Use admonitions to highlight important information. Do not overuse them. If everything is a warning, nothing is a warning.

| Type | When to use |
|------|-------------|
| NOTE | Additional context that is helpful but not essential. |
| TIP | Shortcuts, best practices, or time-saving suggestions. |
| IMPORTANT | Information the reader must know to avoid problems. |
| WARNING | Actions that could cause data loss, security issues, or breaking changes. |
| CAUTION | Actions that are irreversible or have significant consequences. |

Markdown (MkDocs Material):
```markdown
!!! note
    This feature requires version 2.0 or later.

!!! warning
    This action deletes all existing data. Back up your database first.
```

AsciiDoc (Antora):
```asciidoc
NOTE: This feature requires version 2.0 or later.

WARNING: This action deletes all existing data. Back up your database first.
```

## Search Optimization

### Searchability patterns
- Write descriptive page titles. "Install the CLI" is searchable. "Step 2" is not.
- Include the key action and technology in each page's title and description.
- Use headings that match the words users type when searching. Check your site's search query logs to learn what users actually search for.

### Metadata and taxonomy
- Add tags and categories to every page via frontmatter.
- Use a controlled vocabulary for tags. Do not let tags proliferate without a naming convention.
- Include a `description` field in frontmatter. Many search engines and site search tools use it for the snippet.

### Content structure for search
- Put the most important information in the first paragraph. Search snippets pull from early content.
- Use one H1 per page. Use H2 and H3 to create scannable sections that search indexes can parse.
- Avoid putting critical information only in images, diagrams, or code blocks. Search engines index text.

## Link Checking

Run link checks in CI to catch broken links before they reach production.

### Lychee (recommended for Markdown)
```yaml
# .lychee.toml
exclude_path = ["node_modules", ".git", "public"]
max_concurrency = 16
timeout = 30
accept = [200, 204]
exclude = [
    "localhost",
    "127.0.0.1",
    "example\\.com",
]
```

```bash
# Check all Markdown files
lychee --config .lychee.toml "docs/**/*.md"

# Check built HTML output
lychee --config .lychee.toml "public/**/*.html"
```

### htmltest (for built HTML)
```yaml
# .htmltest.yml
DirectoryPath: "public"
CheckExternal: true
CheckInternal: true
IgnoreURLs:
  - "example.com"
```

```bash
htmltest
```

### CI integration (GitHub Actions)
```yaml
- name: Check links
  uses: lycheeverse/lychee-action@v1
  with:
    args: --config .lychee.toml "docs/**/*.md"
    fail: true
```

## Image Handling

- Every image must have descriptive alt text. The alt text should convey the same information as the image.
- Store images next to the content that references them, or in a per-section `images/` directory.
- Use descriptive file names: `architecture-overview.png` not `image1.png` or `screenshot.png`.
- Optimize images before committing. Use tools like `pngquant`, `optipng`, or `svgo` for SVGs.
- Prefer SVG for diagrams and architecture visuals. They scale cleanly and are smaller.
- For screenshots, crop to show only the relevant part. Full-screen screenshots with irrelevant UI elements add noise.
- Maximum image width: 800px for inline images, 1200px for full-width diagrams.
- Store source files (.drawio, .mmd) alongside exported images so future contributors can edit them.

## Navigation and Information Architecture

- Organize content by user task, not by product feature. Users visit docs to accomplish something, not to read about features.
- Use progressive disclosure: start with the most common tasks, then link to advanced topics.
- Every page should be reachable from the navigation. Orphaned pages are invisible pages.
- Keep navigation depth to 3 levels maximum. Deeper nesting makes content hard to find.
- Include breadcrumbs for context so users know where they are in the content hierarchy.
- Add "next steps" or "related topics" links at the bottom of each page.

## Contributor Experience

### CONTRIBUTING.md for docs

Include a CONTRIBUTING.md file that covers:
- How to set up the docs build locally (prerequisites, install, serve commands).
- What style guide to follow (link to your Vale config or style guide page).
- How to submit a change (fork, branch, PR, review process).
- What to expect during review (turnaround time, types of feedback).
- Where to ask questions (Slack channel, mailing list, GitHub Discussions).

### Style guide enforcement
- Use Vale for automated style checking. Run it locally and in CI.
- Provide a pre-commit hook so contributors catch style issues before pushing.
- Document your style exceptions. If your project uses specific terms that differ from the style guide, list them.

### Review process
- Every docs PR needs at least one approving review.
- Technical accuracy: reviewed by an SME or the feature developer.
- Style and structure: reviewed by a technical writer or docs maintainer.
- Target a 3-business-day turnaround for docs reviews. Slow reviews discourage contributors.

### Onboarding new contributors
- Tag issues with `good-first-issue` for newcomers.
- Maintain a list of "quick fixes" (typos, broken links, missing alt text) that new contributors can pick up.
- Pair new contributors with an experienced reviewer for their first 2-3 PRs.

## Localization Workflow

### Translation management
- Use a translation management system (TMS) like Crowdin, Transifex, or Weblate.
- Extract translatable strings from docs and sync them to the TMS automatically.
- Set up a CI workflow that exports new source strings to the TMS on every merge to main.

### Translation process
- Prioritize pages for translation based on traffic. Translate the top 20% of pages first.
- Provide context notes for translators: screenshots, glossary terms, and examples of correct usage.
- Use translation memory to maintain consistency across pages and reduce repeated work.

### Locale testing
- Build and preview the site in each translated locale before publishing.
- Check for layout issues: text expansion (German and French text is typically 30% longer than English), right-to-left languages, and character encoding.
- Validate that code samples are not translated. Code stays in English.

## Writing for Internationalization

- Use simple, clear sentences. Avoid idioms, slang, and culturally specific references.
- Write "for example" instead of "e.g." and "that is" instead of "i.e." These abbreviations do not translate well.
- Avoid humor and wordplay. They rarely survive translation.
- Use complete sentences. Telegraphic style ("Config file. Must exist.") is harder to translate.
- Do not embed text in images. Extract text into alt text or captions so it can be translated.

## Vale Linter

Use Vale for automated style enforcement:

```ini
# .vale.ini
StylesPath = .vale/styles
MinAlertLevel = suggestion

Packages = RedHat, write-good

[*.md]
BasedOnStyles = Vale, RedHat, write-good

[*.adoc]
BasedOnStyles = Vale, RedHat, write-good
```

```bash
# Install Vale
brew install vale   # macOS
sudo snap install vale  # Linux

# Sync style packages
vale sync

# Check documentation
vale docs/

# Check a single file
vale docs/getting-started/installation.md
```

## Accessibility

- Use proper heading hierarchy. Screen readers use headings to navigate.
- Write descriptive link text. "See the configuration guide" not "click here."
- Provide alt text for all images. For decorative images, use empty alt text (`alt=""`).
- Ensure sufficient color contrast in diagrams and screenshots. Do not rely on color alone to convey meaning.
- Use tables for tabular data only, not for layout.
- Test the built docs with an accessibility checker (axe, Lighthouse).

## Analytics

### Which pages matter
- Track page views, but focus on unique page views per session. A page with high views but low time-on-page may have a misleading title.
- Identify your "golden paths": the pages users visit most when getting started. Prioritize quality and freshness for these pages.
- Track 404 pages to find broken links and missing content.

### Search query analysis
- Review your site search logs monthly. The queries with no results tell you what content is missing.
- Group search queries into themes. If 50 users searched for "GPU scheduling" and your docs call it "accelerator management," rename it.
- Use search data to update page titles, headings, and descriptions.

### Feedback collection
- Add a "Was this page helpful?" widget to every docs page. Track the ratio over time.
- Provide a way for users to report issues directly from the docs page (link to a GitHub issue template).
- Review feedback monthly and prioritize fixes for pages with consistently low ratings.

### Using data to prioritize
- Update high-traffic pages first when a new version ships.
- Invest in search optimization for pages with high search volume but low click-through.
- Retire or consolidate pages with near-zero traffic. Check that they are not linked from external sources first.

## Common Commands

```bash
# MkDocs: serve locally
mkdocs serve --dev-addr localhost:8000

# MkDocs: build
mkdocs build --strict

# Hugo: serve locally
hugo server --buildDrafts

# Hugo: build
hugo --minify

# Antora: generate site
antora antora-playbook.yml

# Antora: generate with local sources
antora antora-playbook.yml --to-dir build/site

# Check links
lychee "docs/**/*.md"

# Run Vale linter
vale docs/

# Optimize images
find docs -name "*.png" -exec pngquant --force --quality=65-80 --skip-if-larger {} \;
```

## .gitignore

```
# Build output
public/
site/
build/
_site/

# Node modules (if using npm-based tooling)
node_modules/

# Editor files
*.swp
*.swo
.idea/
.vscode/

# OS files
.DS_Store
Thumbs.db
```

## Review Checklist

Before merging documentation changes:

### Content quality
- [ ] Content builds without errors or warnings
- [ ] Content follows the correct Diataxis type (tutorial, how-to, reference, or explanation)
- [ ] Headers use sentence case
- [ ] No em dashes used anywhere in the content
- [ ] Content reads well for non-native English speakers
- [ ] Product names follow Red Hat conventions

### Technical accuracy
- [ ] All code samples are tested and produce the expected output
- [ ] Version numbers and CLI flags are current
- [ ] API references match the actual API behavior
- [ ] Prerequisites are listed before any procedural steps

### Links and media
- [ ] All links are valid (internal and external)
- [ ] Images have descriptive alt text
- [ ] Diagram source files are included alongside exported images
- [ ] No broken code samples

### Structure and navigation
- [ ] Frontmatter is complete (title, description, date)
- [ ] Navigation reflects the new or changed pages
- [ ] Breadcrumbs and "next steps" links are accurate
- [ ] Page is reachable from the main navigation

### CI and process
- [ ] Vale linter reports no errors
- [ ] Link checker passes
- [ ] Content has been reviewed by at least one other person
- [ ] Preview build has been checked for rendering issues
