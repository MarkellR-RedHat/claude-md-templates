# CLAUDE.md - Content Writing Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your blog platform (Hugo, Jekyll, WordPress, Ghost) -->
<!-- TODO: Set your publication URL (e.g., https://developers.redhat.com/blog) -->
<!-- TODO: Set your team review process (PR-based, Google Docs, editorial board) -->
<!-- TODO: Update frontmatter format to match your static site generator -->
<!-- TODO: Set your target word counts per content type -->

## Project Overview

This is a content and blog writing project. All content follows Red Hat editorial standards and is written for a technical audience of developers, architects, and IT decision-makers.

## Writing Voice and Tone

- Write in an active, direct voice. Avoid passive constructions.
- Be conversational but professional. Write like you are explaining something to a smart colleague.
- Avoid buzzwords and marketing fluff. Lead with technical substance.
- Do not use jargon without explaining it, unless the target audience is explicitly expert-level.
- Keep sentences short. If a sentence has more than one comma, consider splitting it.
- Use contractions naturally (it's, you'll, we're). They make writing feel human.

## Red Hat Product Name Conventions

Always use the correct, full product names on first reference. After the first mention, you may use the short form.

| Correct (first reference)            | Acceptable short form | Never write            |
|--------------------------------------|-----------------------|------------------------|
| Red Hat OpenShift                    | OpenShift             | Openshift, openshift   |
| Red Hat Enterprise Linux             | RHEL                  | Redhat Linux           |
| Red Hat Ansible Automation Platform  | Ansible               | Ansible Tower (legacy) |
| Red Hat OpenShift AI                 | OpenShift AI          | RHOAI                  |
| Red Hat Advanced Cluster Management  | ACM                   | RHACM                  |

- "Red Hat" is always two words, always capitalized.
- "OpenShift" is one word, capital O and capital S.
- Never abbreviate product names in titles or headings.

## Blog Post Structure

Follow this standard structure for blog posts:

1. **Title**: Clear, specific, under 70 characters. Include the key technology or concept.
2. **Introduction** (2-3 paragraphs): State the problem, why it matters, and what the reader will learn.
3. **Body sections**: Use H2 headers. Each section should cover one idea. Include code samples or diagrams where relevant.
4. **Conclusion** (1-2 paragraphs): Summarize key takeaways. Include a clear call to action or next step.
5. **Resources**: Link to docs, GitHub repos, or related posts.

### Blog post frontmatter

Use the appropriate frontmatter format for your static site generator.

Hugo:
```yaml
---
title: "Deploying LLMs on OpenShift with vLLM"
date: 2025-03-15
author: "Your Name"
categories: ["AI/ML", "OpenShift"]
tags: ["vllm", "inference", "kubernetes"]
description: "A step-by-step guide to deploying large language models on Red Hat OpenShift using vLLM."
draft: false
---
```

Jekyll:
```yaml
---
layout: post
title: "Deploying LLMs on OpenShift with vLLM"
date: 2025-03-15
author: yourname
categories: ai-ml openshift
tags: [vllm, inference, kubernetes]
excerpt: "A step-by-step guide to deploying large language models on Red Hat OpenShift using vLLM."
---
```

### Word count guidelines by content type

| Content type        | Target word count | Notes                                      |
|---------------------|-------------------|--------------------------------------------|
| Blog post (tutorial)| 1,500 to 2,500    | Include code samples and screenshots       |
| Blog post (opinion) | 800 to 1,200      | Keep it focused on one clear argument      |
| Quick tip           | 300 to 500        | One concept, one code snippet              |
| Case study          | 1,200 to 1,800    | Problem, solution, results with metrics    |
| Newsletter item     | 100 to 200        | Hook and link only                         |
| Conference recap    | 800 to 1,500      | Key takeaways, not a transcript            |

## Code Samples in Content

- All code samples must be runnable. Do not include pseudocode without labeling it as such.
- Use fenced code blocks with language identifiers (```python, ```yaml, ```bash).
- Keep code samples short and focused. If a sample exceeds 30 lines, consider breaking it up or linking to a repo.
- Always include comments in code explaining non-obvious steps.

## Link Formatting

- Use descriptive link text. Never write "click here" or "this link."
- Bad: `For more info, click [here](https://example.com).`
- Good: `See the [OpenShift documentation on Routes](https://example.com) for details.`
- Link to official Red Hat docs when referencing product features.
- Link to upstream project docs (kubernetes.io, pytorch.org) for community technologies.
- Check all links before publishing. Broken links erode trust.

## Image and Diagram Guidelines

- Every image needs alt text that describes what the image shows.
- Use diagrams to explain architecture and workflows. Mermaid or draw.io are preferred.
- Screenshots should be current. Outdated UI screenshots confuse readers.
- Save images in an `images/` directory relative to the post.

## SEO and Metadata

- Include a meta description (under 160 characters) for every post.
- Use keywords naturally in the title and first paragraph.
- Use H2 and H3 headers to structure content for both readers and search engines.

## Accessibility

All published content must meet basic accessibility standards.

### Text accessibility
- Use heading levels in order (H1, then H2, then H3). Do not skip levels.
- Keep paragraphs short (3 to 5 sentences). Long text blocks are hard to read on screens.
- Use sufficient color contrast in any custom-styled text. Follow WCAG 2.1 AA guidelines.
- Avoid using color alone to convey meaning. Always pair color with text labels or patterns.

### Image accessibility
- Every image requires descriptive alt text. Alt text should convey the same information as the image.
- For decorative images, use an empty alt attribute (`alt=""`).
- For complex diagrams, provide a text description below the image.
- Ensure text in images is also available as real text in the post.

### Code sample accessibility
- Use semantic code blocks with language identifiers so screen readers announce the language.
- Provide text descriptions for what each code sample does, not just the code itself.
- Avoid relying on syntax highlighting colors alone to explain code. Describe key parts in surrounding text.

### Link accessibility
- Use descriptive link text that makes sense out of context. Screen readers often navigate by link text alone.
- Avoid "click here" or "read more" as link text.
- When linking to a file download, include the file type and size in the link text: "[Download the workshop guide (PDF, 2.4 MB)](url)".

## Common Mistakes to Avoid

- Do not mix up "its" (possessive) and "it's" (contraction).
- Do not use em dashes. Use commas, periods, or "and" instead.
- Do not start sentences with "So" or "Basically."
- Do not assume the reader's gender. Use "they/them" as singular pronouns.
- Do not write "simple," "easy," or "just" when describing technical steps. What is simple for you may not be simple for the reader.

## File Organization

```
content/
  posts/
    YYYY-MM-DD-post-title/
      index.md
      images/
  drafts/
  templates/
```

## Review Checklist

Before submitting content for review:

- [ ] Product names are correct on first and subsequent references
- [ ] All code samples run without errors
- [ ] All links work and point to current resources
- [ ] Images have alt text
- [ ] Post follows the standard structure
- [ ] No passive voice in the introduction
- [ ] Meta description is present and under 160 characters
