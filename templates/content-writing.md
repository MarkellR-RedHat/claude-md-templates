# CLAUDE.md - Content Writing Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your blog platform (Hugo, Jekyll, WordPress, Ghost) -->
<!-- TODO: Set your publication URL (e.g., https://developers.redhat.com/blog) -->
<!-- TODO: Set your team review process (PR-based, Google Docs, editorial board) -->
<!-- TODO: Update frontmatter format to match your static site generator -->
<!-- TODO: Set your target word counts per content type -->
<!-- TODO: Connect your analytics dashboard (Google Analytics, Matomo, etc.) -->
<!-- TODO: Set your editorial calendar tool (GitHub Projects, Trello, Notion) -->

## Project Overview

This is a content and blog writing project. All content follows Red Hat editorial standards and is written for a technical audience of developers, architects, and IT decision-makers. Content should be direct, technically accurate, and useful on first read.

## Writing Voice and Tone

- Write in an active, direct voice. Avoid passive constructions.
- Be conversational but professional. Write like you are explaining something to a smart colleague.
- Avoid buzzwords and marketing fluff. Lead with technical substance.
- Do not use jargon without explaining it, unless the target audience is explicitly expert-level.
- Keep sentences short. If a sentence has more than one comma, consider splitting it.
- Use contractions naturally (it's, you'll, we're). They make writing feel human.
- Address the reader as "you" and refer to Red Hat as "we" when writing on behalf of the company.
- Prefer concrete over abstract. Instead of "leverage cloud-native approaches," say "deploy on Kubernetes."
- Let the technology do the talking. Features and capabilities are more convincing than adjectives.
- When in doubt, cut the sentence. Shorter is almost always better.

## Red Hat Product Name Conventions

Always use the correct, full product names on first reference. After the first mention, you may use the short form.

| Correct (first reference)            | Acceptable short form | Never write            |
|--------------------------------------|-----------------------|------------------------|
| Red Hat OpenShift                    | OpenShift             | Openshift, openshift   |
| Red Hat Enterprise Linux             | RHEL                  | Redhat Linux           |
| Red Hat Ansible Automation Platform  | Ansible               | Ansible Tower (legacy) |
| Red Hat OpenShift AI                 | OpenShift AI          | RHOAI                  |
| Red Hat Advanced Cluster Management  | ACM                   | RHACM                  |
| Red Hat Developer Hub                | Developer Hub         | Backstage (alone)      |
| Red Hat build of Keycloak            | Keycloak              | RH-SSO (legacy)        |
| Red Hat Trusted Profile Analyzer     | TPA                   | Trusted Profile        |

- "Red Hat" is always two words, always capitalized.
- "OpenShift" is one word, capital O and capital S.
- Never abbreviate product names in titles or headings.
- Upstream project names (Kubernetes, Podman, Tekton) do not need the "Red Hat" prefix.
- When referencing a Red Hat product built from an upstream project, name both on first reference: "Red Hat OpenShift, the enterprise Kubernetes platform."

## Content Lifecycle

Every piece of content moves through these stages. Do not skip stages.

1. **Ideation**: Pull ideas from customer questions, support tickets, conference talks, product launches, upstream release notes, and community discussions. Validate: Is this timely? Does our audience care? Can we say something new? Log ideas in the editorial backlog with a one-line summary, target audience, and estimated effort.
2. **Outline**: Write a bullet-point outline before drafting. Include the working title, thesis statement, section headers, key points per section, and target word count. Identify code samples, diagrams, or screenshots needed. Get outline approval before drafting.
3. **Draft**: Write the first draft without self-editing. Follow the blog post structure and word count guidelines in this document. Mark uncertainty with `[TODO: verify]` or `[TODO: SME review needed]`.
4. **Review**: Self-review first using the checklist at the bottom of this document. Then submit for peer review, technical accuracy review (see the Technical Accuracy Review Process section), and editorial review.
5. **Publish**: Confirm all review feedback is addressed. Verify frontmatter, meta description, and social sharing images. Publish and check the live page: links, images, code formatting, responsive layout.
6. **Promote**: Share on social channels using the templates in the Social Media Promotion section. Notify internal stakeholders and quoted SMEs. Submit for relevant newsletters and roundups.
7. **Measure**: Check performance at 7, 30, and 90 days post-publish. See the Measurement section for which metrics to track. Note what worked and what did not for future reference.
8. **Update or Retire**: Revisit evergreen content every 6 months. Update versions, links, and screenshots. If a post references a deprecated product or API, update it or add a prominent notice. Retire content that cannot be updated and redirect old URLs.

## Editorial Calendar Management

Organize your calendar around these time horizons:

- **This week**: Content in review or publish stage. Final details only.
- **Next 2 weeks**: Content in draft stage. Committed topics with assigned authors.
- **Next 30 days**: Content in outline stage. Confirmed topics in the pipeline.
- **Next quarter**: Content in ideation stage. Tentative topics tied to product launches, events, or campaigns.

Coordination patterns:

- Align with product release schedules. Content should publish within one week of a GA release, not months later.
- Coordinate with events: publish related content before (to drive attendance) and after (to share key takeaways).
- Avoid publishing multiple posts on the same product in the same week unless they serve different audiences.
- Use labels in your tracking tool: `draft`, `in-review`, `ready-to-publish`, `published`, `needs-update`.
- Set a sustainable cadence and stick to it. One high-quality post per week beats three rushed posts.
- Plan buffer weeks for holidays and conference seasons when author bandwidth drops.

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

| Content type         | Target word count | Notes                                      |
|----------------------|-------------------|--------------------------------------------|
| Blog post (tutorial) | 1,500 to 2,500    | Include code samples and screenshots       |
| Blog post (opinion)  | 800 to 1,200      | Keep it focused on one clear argument      |
| Quick tip            | 300 to 500        | One concept, one code snippet              |
| Case study           | 1,200 to 1,800    | Problem, solution, results with metrics    |
| Newsletter item      | 100 to 200        | Hook and link only                         |
| Conference recap     | 800 to 1,500      | Key takeaways, not a transcript            |
| Product launch post  | 1,000 to 1,500    | Features, benefits, getting started steps  |
| How-to guide         | 2,000 to 3,500    | Complete workflow, start to finish         |
| Comparison post      | 1,500 to 2,000    | Objective criteria, tested examples        |

## SEO Deep Dive

### Keyword Research Workflow

1. Start with the problem your content solves, not the product name. Users search for problems.
2. Use tools like Google Search Console (for existing traffic), Ahrefs, or SEMrush to identify keyword volume and difficulty.
3. Target one primary keyword and 2-3 secondary keywords per post.
4. Check what currently ranks for your target keyword. If the top results are all official docs, write a tutorial. If they are all tutorials, write a comparison or opinion piece.
5. Include the primary keyword in: the title, the meta description, the first paragraph, and at least one H2 header.

### Internal Linking Strategy

- Every new post should link to at least 2 existing posts on your site.
- When you publish a new post, go back and add links to it from 2-3 relevant older posts.
- Use descriptive anchor text that includes the target post's primary keyword.
- Create "hub" posts for major topics (e.g., "Getting Started with OpenShift AI") and link related posts to them.
- Audit internal links quarterly. Remove links to retired content and add links to new content.

### Meta Description Patterns

Write meta descriptions that are under 160 characters, include the primary keyword, and tell the reader what they will get. Follow these patterns:

- Tutorial: "Learn how to [do X] with [technology]. Step-by-step guide with code examples."
- Opinion: "[Topic] is changing. Here's what [audience] needs to know and why it matters."
- Comparison: "Comparing [X] and [Y] for [use case]. Performance benchmarks, setup complexity, and production considerations."

### Structured Data and Schema.org

Add structured data to help search engines understand your content. At minimum, include:

- `Article` or `BlogPosting` schema with headline, author, datePublished, and dateModified.
- `HowTo` schema for tutorial posts with step-by-step instructions.
- `FAQPage` schema if your post includes a frequently asked questions section.

Example (JSON-LD for a blog post):
```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "Deploying LLMs on OpenShift with vLLM",
  "author": {
    "@type": "Person",
    "name": "Your Name"
  },
  "datePublished": "2025-03-15",
  "dateModified": "2025-03-20",
  "description": "A step-by-step guide to deploying large language models on Red Hat OpenShift using vLLM.",
  "publisher": {
    "@type": "Organization",
    "name": "Red Hat"
  }
}
```

## Code Samples in Content

- All code samples must be runnable. Do not include pseudocode without labeling it as such.
- Use fenced code blocks with language identifiers (```python, ```yaml, ```bash).
- Keep code samples short and focused. If a sample exceeds 30 lines, consider breaking it up or linking to a repo.
- Always include comments in code explaining non-obvious steps.
- Pin versions in code samples. Write `pip install vllm==0.4.2`, not `pip install vllm`.
- Test every code sample before publishing. Copy it from the rendered page, not your editor, to catch formatting issues.
- Include expected output when it helps the reader verify their setup.
- If a code sample requires prerequisites (packages, environment variables, cluster access), list them before the code block.

## Link Formatting

- Use descriptive link text. Never write "click here" or "this link."
- Bad: `For more info, click [here](https://example.com).`
- Good: `See the [OpenShift documentation on Routes](https://example.com) for details.`
- Link to official Red Hat docs when referencing product features.
- Link to upstream project docs (kubernetes.io, pytorch.org) for community technologies.
- Check all links before publishing. Broken links erode trust.
- When linking to versioned documentation, link to the specific version your content covers, not "latest."
- For GitHub links, link to a specific commit or tag rather than `main` when referencing code.

## Image and Diagram Guidelines

- Every image needs alt text that describes what the image shows.
- Use diagrams to explain architecture and workflows. Mermaid or draw.io are preferred.
- Screenshots should be current. Outdated UI screenshots confuse readers.
- Save images in an `images/` directory relative to the post.
- Optimize image file sizes. Use PNG for diagrams and screenshots, JPEG for photos, and SVG for vector graphics.
- Annotate screenshots to highlight the relevant UI elements. Do not assume the reader will find the right button.
- For diagrams, also include the source file (.drawio, .mmd) so future editors can update them.

## Technical Accuracy Review Process

Technical accuracy is non-negotiable. Follow this process for every piece of content.

### Code Testing

- Run all code samples in a clean environment that matches what the reader will use.
- Test on the specific product version mentioned in the post. If the post says OpenShift 4.15, test on 4.15.
- Document the test environment: OS, runtime versions, cluster version, and any relevant configuration.

### Version Pinning

- Pin all dependency versions in code samples and instructions.
- Include the product version in the post's introduction: "This guide uses Red Hat OpenShift 4.15 and vLLM 0.4.2."
- When a new version ships, either update the post or add a note at the top indicating which version was tested.

### SME Review

- Identify a subject matter expert (SME) for every post that covers a product or technology in depth.
- Send the SME a focused review request: "Please check the technical accuracy of sections 2 and 3. Are the CLI commands correct for version 4.15?"
- Give the SME at least 3 business days for review. Plan your timeline accordingly.
- Document SME feedback and your responses in the PR or review thread for future reference.

## Red Hat-Specific Publishing

### developers.redhat.com Submission

1. Write your post in Markdown following the structure and frontmatter guidelines in this document.
2. Submit via the editorial team's intake process (typically a form or email to the content lead).
3. Include: the final Markdown file, all images, a short author bio, and your preferred publish date.
4. Expect at least one round of editorial review. The editorial team will check for brand compliance, SEO, and style.
5. After publication, verify the live post and share it on social channels within 24 hours.

### Red Hat Enable (enable.com) Content

- Enable content targets Red Hat partners and solution architects.
- Use a more technical tone than external blog posts. Assume familiarity with Red Hat products.
- Include architecture diagrams, sizing guides, and deployment checklists.
- Follow the Enable content templates provided by the partner enablement team.

### Product Launch Content Coordination

- Content for product launches should be drafted 4 to 6 weeks before the GA date.
- Coordinate with product marketing to align messaging and key features.
- Plan a content bundle: announcement blog post, getting started tutorial, and at least one social thread.
- All launch content must go through legal review if it includes competitive claims or performance benchmarks.
- Embargo rules apply. Do not publish or share launch content externally before the official announcement date.

## Social Media Promotion

### General Principles

- Lead with the value to the reader, not the product name.
- Include a clear link to the full content.
- Tag relevant product or project accounts.
- Use 1-2 relevant hashtags, not more. Hashtag stuffing reduces engagement.

### Twitter/X

Single post: `New on the blog: [Title]. [One sentence on what the reader gets]. [Link]`

Thread: Open with the problem statement and "Thread below." Follow with one post per step (setup, core action, verification). Close with the full post link.

### LinkedIn

Open with a one-sentence hook about the problem or trend. Follow with 2-3 sentences on what you built, tested, or learned. State what the reader will get. Close with the link.

### Mastodon

`Published: "[Title]" - [One sentence on what it covers]. [Link] #[Tag] #[Tag]`

## Content Repurposing

Get more reach from each piece of content by adapting it across formats.

### Blog to Conference Talk

Identify the core narrative (problem, approach, results). Cut setup instructions and focus on the "why." Build slides around diagrams and key code snippets, not text. Add a live or recorded demo if the post was a tutorial. End with a slide linking to the blog post.

### Blog to Video

Write a script from the post (5-10 minutes for tutorials, 3-5 for concept explainers). Record a screencast with a readable font size (16pt minimum). Add reviewed captions (see Accessibility). Publish to YouTube and embed in the original post.

### Blog to Social Thread

Extract 4-6 key points. Write each as a standalone sentence. Open the thread with a hook. Close with the full post link.

### Talk to Blog

Start from speaker notes, not slides. Expand bullet points into paragraphs. Add code samples, configuration files, and links you skipped during the talk. Include screenshots of key slides as figures.

## Accessibility

All published content must meet WCAG 2.1 AA standards. This is a requirement, not a suggestion.

### Text Accessibility

- Use heading levels in order (H1, then H2, then H3). Do not skip levels.
- Keep paragraphs short (3 to 5 sentences). Long text blocks are hard to read on screens.
- Use sufficient color contrast in any custom-styled text. Minimum contrast ratio: 4.5:1 for normal text, 3:1 for large text.
- Avoid using color alone to convey meaning. Always pair color with text labels or patterns.
- Use plain language when possible. Avoid idioms and culturally specific references that may not translate.

### ARIA Landmarks and Semantic HTML

- Use semantic HTML elements: `<article>`, `<nav>`, `<aside>`, `<main>`, `<header>`, `<footer>`.
- Add ARIA labels to interactive elements that lack visible text labels.
- Use `role="region"` with `aria-label` for custom sections that do not map to standard HTML elements.
- Example: `<section role="region" aria-label="Prerequisites">` for a prerequisites section.

### Image Accessibility

- Every image requires descriptive alt text. Alt text should convey the same information as the image.
- For decorative images, use an empty alt attribute (`alt=""`).
- For complex diagrams, provide a text description below the image.
- Ensure text in images is also available as real text in the post.
- For charts and graphs, include a data table as an alternative.

### Table Accessibility

- Always include a `<caption>` element or a heading directly above the table describing its contents.
- Use `<th>` elements with `scope="col"` or `scope="row"` for header cells.
- Avoid merged cells. If you must merge, use `headers` attributes to associate data cells with their headers.
- Keep tables simple. If a table has more than 5 columns, consider splitting it or presenting the data differently.

### Video and Multimedia Accessibility

- All videos must have captions. Auto-generated captions must be reviewed and corrected.
- Provide a transcript for every video. Link it below the embedded video.
- Do not autoplay video or audio. Ensure video players are keyboard-navigable.

### Code Sample Accessibility

- Use semantic code blocks with language identifiers so screen readers announce the language.
- Provide text descriptions for what each code sample does, not just the code itself.
- For long code blocks, add a summary before the block: "The following YAML defines a deployment with 3 replicas and a GPU resource limit."

### Link Accessibility

- Use descriptive link text that makes sense out of context. Avoid "click here" or "read more."
- When linking to a file download, include the file type and size: "[Download the workshop guide (PDF, 2.4 MB)](url)".
- When linking to an external site that opens in a new tab, indicate it: "[Kubernetes documentation (opens in new tab)](url)".

## Measurement

### Metrics by Content Type

| Content type         | Primary metric         | Secondary metrics                     | Check at        |
|----------------------|------------------------|---------------------------------------|-----------------|
| Blog post (tutorial) | Unique page views      | Time on page, scroll depth            | 7, 30, 90 days  |
| Blog post (opinion)  | Social shares          | Comments, referral traffic            | 7, 30 days      |
| Getting started guide| Completion rate        | Bounce rate, next-page clicks         | 30, 90 days     |
| Product launch post  | Page views in week 1   | Referral to product page, CTA clicks  | 7, 14 days      |
| Case study           | PDF downloads or views | Referral to sales/contact page        | 30, 90 days     |
| Newsletter item      | Click-through rate     | Unsubscribe rate                      | 7 days          |

### Attribution

- Use UTM parameters on all shared links so you can trace traffic back to the promotion channel.
- Format: `?utm_source=[channel]&utm_medium=[format]&utm_campaign=[campaign-name]`
- Example: `?utm_source=twitter&utm_medium=social&utm_campaign=openshift-4-15-launch`
- Track which content drives downstream actions: product page visits, trial signups, documentation visits.
- Report content performance monthly. Include top-performing posts, underperforming posts, and recommendations for updates or promotion.

### Content Scoring

Use a simple scoring model to prioritize updates and future topics:

- **High performers**: Top 10% by page views AND above-average time on page. Repurpose and update these regularly.
- **Hidden gems**: Low page views but high time on page or high scroll depth. These need better promotion, not better content.
- **Underperformers**: Low page views AND low engagement. Evaluate whether to update, consolidate with other content, or retire.

## Common Mistakes to Avoid

- Do not mix up "its" (possessive) and "it's" (contraction).
- Do not use em dashes anywhere. Use commas, periods, semicolons, or "and" instead.
- Do not start sentences with "So" or "Basically."
- Do not assume the reader's gender. Use "they/them" as singular pronouns.
- Do not write "simple," "easy," or "just" when describing technical steps. What is simple for you may not be simple for the reader.
- Do not write "leverage" when you mean "use."
- Do not write walls of text. Break up long sections with headers, lists, or code blocks.
- Do not publish without testing every code sample.
- Do not use screenshots of code. Use actual code blocks that readers can copy.
- Do not reference a product version without checking that it is the current or specified version.
- Do not bury the useful information. Put the most important thing in the first two paragraphs.

## File Organization

```
content/
  posts/
    YYYY-MM-DD-post-title/
      index.md
      images/
        diagram-architecture.png
        diagram-architecture.drawio   # source file for editors
        screenshot-dashboard.png
  drafts/
    post-title/
      index.md
      images/
  templates/
    blog-post.md
    case-study.md
    quick-tip.md
  social/
    YYYY-MM-DD-post-title.md          # social copy per post
  calendar/
    editorial-calendar.md             # or link to your tracking tool
```

## Review Checklist

Before submitting content for review:

### Content Quality
- [ ] Title is clear, specific, and under 70 characters
- [ ] Introduction states the problem and what the reader will learn
- [ ] Each section covers one idea with a clear H2 header
- [ ] Conclusion includes a call to action or next step
- [ ] No passive voice in the introduction
- [ ] No buzzwords, marketing fluff, or unsupported claims
- [ ] Word count falls within the target range for this content type
- [ ] No em dashes anywhere in the text

### Technical Accuracy
- [ ] All code samples run without errors in a clean environment
- [ ] Product versions are specified and current
- [ ] Dependencies are version-pinned
- [ ] Technical claims are verified by an SME or by your own testing
- [ ] Prerequisites are listed before any hands-on steps

### SEO and Metadata
- [ ] Meta description is present and under 160 characters
- [ ] Primary keyword appears in title, meta description, first paragraph, and at least one H2
- [ ] Internal links to at least 2 related posts on the same site
- [ ] Structured data (JSON-LD) is present and valid

### Brand and Style
- [ ] Product names are correct on first and subsequent references
- [ ] "Red Hat" is two words and capitalized everywhere it appears
- [ ] Author bio and attribution are accurate
- [ ] No AI tool is listed as author or contributor

### Links and Media
- [ ] All links work and point to current resources
- [ ] Links to versioned docs use the correct version
- [ ] Images have descriptive alt text
- [ ] Diagrams include source files for future editing
- [ ] Screenshots are current and annotated where needed

### Accessibility
- [ ] Heading levels are sequential (H1, H2, H3) with no skipped levels
- [ ] Tables have captions and proper header markup
- [ ] Videos have reviewed captions and a linked transcript
- [ ] Color is not the sole means of conveying information
- [ ] Link text is descriptive and makes sense out of context

### Publishing
- [ ] Frontmatter is complete and correctly formatted
- [ ] Social media copy is drafted for at least 2 channels
- [ ] UTM parameters are set for all promotion links
- [ ] Publish date is confirmed on the editorial calendar
- [ ] Post renders correctly on the staging site (desktop and mobile)
