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
- Do not use em dashes. Use commas, periods, or "and" instead.

### Terminology
- Use consistent terminology throughout the docs. Pick one term and stick with it.
- Maintain a glossary or terminology reference if the project has domain-specific terms.
- Follow Red Hat product name conventions (see the content-writing template for the full reference).

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

## Navigation and Information Architecture

- Organize content by user task, not by product feature. Users visit docs to accomplish something, not to read about features.
- Use progressive disclosure: start with the most common tasks, then link to advanced topics.
- Every page should be reachable from the navigation. Orphaned pages are invisible pages.
- Keep navigation depth to 3 levels maximum. Deeper nesting makes content hard to find.
- Include breadcrumbs for context so users know where they are in the content hierarchy.
- Add "next steps" or "related topics" links at the bottom of each page.

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

- [ ] Content builds without errors or warnings
- [ ] All links are valid (internal and external)
- [ ] Images have descriptive alt text
- [ ] Headers use sentence case
- [ ] No broken code samples (test them if possible)
- [ ] Frontmatter is complete (title, description, date)
- [ ] Navigation reflects the new or changed pages
- [ ] Content has been reviewed by at least one other person
- [ ] Vale linter reports no errors
- [ ] Content reads well for non-native English speakers
- [ ] Product names follow Red Hat conventions
- [ ] No em dashes used anywhere in the content
