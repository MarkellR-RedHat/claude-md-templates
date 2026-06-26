# CLAUDE.md - General Developer Relations Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your team name (e.g., AI Platform DevRel) -->
<!-- TODO: Set your GitHub org (e.g., github.com/redhat-developer) -->
<!-- TODO: List your primary technologies (e.g., OpenShift, vLLM, Kubernetes) -->
<!-- TODO: Set your SLA for community responses (currently 2 business days) -->
<!-- TODO: Update the CI workflow to match your GitHub org settings -->
<!-- TODO: Identify your content pillars (see Content Strategy Framework) -->
<!-- TODO: Define your target developer personas (see Audience Personas) -->

## Project Overview

This is a Developer Relations project. It may include code samples, demos, tutorials, workshop materials, documentation, community tooling, or ecosystem integrations. The primary audience is external developers. Everything produced here must be clear, runnable, and genuinely helpful. The work is technical, but the goal is always the same: help developers succeed, then bring what you learn back to the product team.

## DevRel Principles

- **Developer-first**: Every piece of content exists to help developers succeed. If it does not help them build something, rethink it.
- **Honest and practical**: Do not oversell. Show real trade-offs. Developers respect honesty about limitations more than polish that hides them.
- **Runnable by default**: Every code sample, demo, and tutorial must work out of the box. If there are prerequisites, document them explicitly.
- **Community-oriented**: Engage with the community authentically. Respond to issues and PRs with empathy and context.
- **Feedback is the product**: The most valuable thing DevRel produces is not content. It is signal from developers about what works, what breaks, and what is missing. Capture it systematically.
- **Compound over time**: Invest in reusable assets (SDKs, templates, CLI tools) over one-off content. A well-maintained quickstart guide delivers value for years. A conference talk delivers value for 45 minutes.

## Developer Journey Mapping

DevRel work maps to the developer journey. Know which stage you are targeting with every piece of work.

### Awareness
The developer does not know the product exists, or knows the name but not what it does.

- **DevRel activities**: Conference talks, blog posts, social media, podcast appearances, open source contributions to adjacent projects.
- **Key content**: "What is X and why should I care?" articles. Comparison guides. Problem-statement posts that introduce the technology as a solution.
- **Success signal**: New visitors to docs and landing pages. Social mentions. Conference talk attendance.

### Evaluation
The developer is actively comparing options. They want to know if this technology fits their use case.

- **DevRel activities**: Quickstart guides, architecture diagrams, feature comparison pages, "X vs Y" content (be fair, not promotional).
- **Key content**: Getting started tutorials. Technical deep dives. Reference architectures. Pricing and limits documentation.
- **Success signal**: Quickstart completion rate. Time to first API call. Documentation engagement (pages per session, scroll depth).

### Adoption
The developer has decided to use the technology and is building with it.

- **DevRel activities**: SDK design and maintenance, sample applications, integration guides, Stack Overflow answers, office hours.
- **Key content**: How-to guides for common tasks. Troubleshooting docs. Migration guides. SDK reference documentation.
- **Success signal**: API usage growth. SDK downloads. Support ticket volume (lower is better). GitHub issue quality (specific questions, not "how do I start?").

### Retention
The developer is using the technology in production and needs it to keep working.

- **DevRel activities**: Changelog communication, upgrade guides, performance optimization content, breaking change announcements with migration paths.
- **Key content**: Release notes. Best practices guides. Production readiness checklists. Performance tuning documentation.
- **Success signal**: Retention rate. Version adoption curves. Churn rate. NPS scores from developer surveys.

### Advocacy
The developer actively recommends the technology to others.

- **DevRel activities**: Community champions programs, contributor recognition, case study development, speaking opportunity referrals, swag and rewards.
- **Key content**: Case studies. Guest blog posts from community members. Community spotlight features. Contributor guides.
- **Success signal**: Referral traffic. Community-authored content volume. Conference talks by community members. Net Promoter Score.

## Content Strategy Framework

### Content pillars

Define 3 to 5 pillars aligned with your product's value propositions. Every piece of content maps to at least one. Examples: (1) Getting started, (2) Building for production, (3) Integration and ecosystem, (4) Community and contribution, (5) Architecture and design.

### Audience personas

Define your target developer personas. Be specific about context, not just title. Example personas:

| Persona | Needs | Best content formats |
|---------|-------|---------------------|
| The Evaluator (senior dev researching tools) | Proof of concept, comparison data, architecture fit | Quickstarts, comparison guides |
| The Builder (mid-level dev implementing) | Working code, troubleshooting, integrations | How-to guides, sample apps, API reference |
| The Operator (platform eng in production) | Upgrade paths, monitoring, performance | Runbooks, changelogs, best practices |
| The Advocate (experienced user contributing) | Contributor guides, recognition, speaking opps | Community programs, case studies |

Customize for your project. Interview real developers to validate.

### Content calendar planning

- Plan content 1 quarter ahead. Align with product launches and conference schedules.
- Maintain a backlog of evergreen content to fill gaps when planned content slips.
- Review content performance monthly. Double down on what works. Retire what does not.
- Coordinate with product marketing on launch timelines. DevRel content should be ready at launch, not weeks after.
- Track content by journey stage and persona to identify coverage gaps.

## Developer Experience (DX) Principles

### Time to hello world

The most important DX metric is how long it takes a developer to go from "I want to try this" to "I have something working." Measure this. Optimize ruthlessly.

- Target: under 5 minutes for a quickstart, under 30 minutes for a meaningful sample application.
- Remove every unnecessary step between the developer and working code.
- Provide copy-paste commands. Do not make developers piece together CLI invocations from prose.

### Error message quality

- Every error message should say what went wrong, why, and what to do next.
- Include searchable error codes. "Error 4012: API key missing" is findable. "Something went wrong" is not.
- Never swallow errors silently.

### SDK and tooling design

- Follow target language conventions. A Python SDK should feel Pythonic. A Go SDK should feel like Go.
- Provide typed interfaces. Ship working examples for every major feature.
- Version the SDK alongside the API. Breaking changes without a major version bump will cost you trust.

### Onboarding friction audit

Quarterly, do a fresh-install test on a clean machine or container. Follow your own quickstart step by step. Record every point where you had to leave the guide. File issues for every friction point and fix the top 3 before the next quarter.

## Code Sample Standards

### Every code sample must include

1. A `README.md` with what it does, who it is for, prerequisites, setup steps, and expected output.
2. A license file (Apache 2.0 for Red Hat open source projects).
3. A `CONTRIBUTING.md` if accepting community contributions.

### Code quality

- Write production-quality code. Developers will copy it directly into their projects.
- Include error handling. No bare `except` in Python, no ignored errors in Go.
- Comment the "why," not the "what."
- Minimize dependencies and pin versions.
- Use environment variables for configuration. Include a `.env.example` with placeholder values.

### Repository structure

```
sample-name/
  README.md          # What it does, prerequisites, setup, expected output
  LICENSE            # Apache 2.0
  CONTRIBUTING.md    # If accepting community contributions
  src/               # Source code
  tests/             # Automated tests
  Containerfile      # Container build
  Makefile           # Build and run targets
  requirements.txt   # Pinned dependencies (or go.mod, package.json)
  .env.example       # Required environment variables with placeholders
  .github/workflows/ # CI configuration
```

### CI for code samples

Add a GitHub Actions workflow to test code samples on every push and PR. At minimum, include:

- Linting (e.g., `ruff check .` for Python, `golangci-lint run` for Go)
- Tests across supported language versions using a matrix strategy
- YAML validation for any configuration files

```yaml
# .github/workflows/test-samples.yml
name: Test code samples
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test-python:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.11", "3.12"]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - run: pip install -r requirements.txt
      - run: ruff check .
      - run: pytest tests/ -v
```

Adapt the workflow for your language and toolchain. Keep all code samples tested. Untested samples rot within weeks. Schedule a monthly dependency update review.

## Documentation Standards

- Write for scanning, not reading. Use headers, bullet points, and code blocks liberally.
- Start every doc with the "what" and "why" before the "how."
- Include a table of contents for docs longer than three sections.
- Test all documented commands before publishing. Date your content.
- Stale docs erode trust faster than missing docs. Update or archive outdated content with a clear notice.

### Formatting rules

- Sentence case for headers: "Getting started with OpenShift" not "Getting Started With OpenShift."
- No em dashes. Use commas, periods, semicolons, or "and" instead.
- Backtick formatting for CLI commands, file paths, environment variables, and code references.
- Admonitions (Note, Warning, Important) sparingly. If everything is a warning, nothing is.
- Active voice. Short sentences.

## Workshop and Tutorial Design

### Structure

1. **Overview**: What will participants build? What will they learn? (2 to 3 sentences)
2. **Prerequisites**: Exact versions, tools, and accounts. Link to installation guides.
3. **Steps**: Numbered, with clear start and end points. Each step should take 5 to 15 minutes.
4. **Checkpoints**: After each major section, describe what the participant should see if everything worked.
5. **Troubleshooting**: Common issues and their solutions. These save workshop facilitators hours.
6. **Cleanup**: How to tear down resources created during the workshop. This is mandatory for cloud resources.
7. **Next steps**: Where to go after completing the workshop. Link to related tutorials, documentation, and community channels.

### Workshop best practices

- Test end-to-end on a clean machine before delivering.
- Assume the WiFi will fail. Have offline fallbacks.
- Build in buffer time. Provide a "fast path" for experienced participants.
- Have a teaching assistant for every 15 participants.
- Collect feedback immediately after, not days later. A 3-question survey at the end beats a follow-up email.

## Community Building

### Discord and Slack management

- Pin channel purpose descriptions. Set response time expectations explicitly.
- Automate what you can: welcome messages, pinned FAQs, bot-powered answers to common questions.
- Moderate actively. A community that tolerates harassment or spam loses its best members first.
- Archive inactive channels rather than letting them accumulate unanswered questions.

### Community champions program

Recognize and reward your most active community members. Look for developers who answer questions, submit PRs, write blog posts, or give talks. Offer concrete benefits: early access to features, direct line to engineering, conference travel sponsorship, public recognition. Champions are volunteers, not employees; respect their time. Review the program annually as participants change.

### Contributor ladder

Define clear levels of community contribution:

| Level | Description | Recognition |
|-------|-------------|-------------|
| User | Uses the technology, asks questions | Community support |
| Contributor | Submits bug reports, small PRs, or documentation fixes | Listed in CONTRIBUTORS file |
| Regular Contributor | Consistent contributions over 3+ months | Maintainer nomination eligibility, champion program invitation |
| Maintainer | Trusted with merge access to specific areas | Organization membership, conference sponsorship |

### Community governance

- Publish a code of conduct and enforce it consistently.
- Document decision-making processes. Write them down even if the process is informal.
- Hold community meetings on a regular cadence (monthly or quarterly). Publish agendas and notes.
- Create a public roadmap. Developers contributing to a project deserve to know where it is headed.

## Community Interaction

### GitHub issues and PRs

- Respond to new issues within 2 business days, even if the response is "we've seen this and will investigate."
- Label issues consistently: `bug`, `enhancement`, `question`, `good-first-issue`, `help-wanted`.
- When closing issues, explain why and link to relevant resources.
- Review community PRs with the same rigor as internal PRs. Thank contributors.
- For stale issues (30+ days inactive), ask if still relevant before closing.

### Writing for community

- Use inclusive language. Write in simple English for non-native speakers.
- Do not assume operating system, IDE, or experience level unless stated.
- Be specific in feedback. "This doesn't work" is unhelpful. "This fails on Python 3.12 because of X" is actionable.

## Partnership and Ecosystem

### Integration guides

- Write a dedicated integration guide for each major partner. Do not bury integrations in a generic page.
- Include architecture diagrams showing how the technologies connect.
- Test integrations end-to-end with real accounts, not mocked services.
- Keep integration guides versioned. When either product updates, verify and update the guide.

### Marketplace listings and ecosystem programs

- Keep marketplace listing metadata current. Include a quickstart for each deployment method.
- For plugin ecosystems, publish a "build on top of X" guide and provide sandbox environments.
- Coordinate content calendars with key partners. Get written approval before using partner logos or product names.

## Internal Advocacy

DevRel is the voice of the developer inside the company. This work is as important as external-facing content.

### Translating developer feedback to product teams

- Aggregate feedback in a structured tracker, not ad hoc notes.
- Quantify feedback. "Developers want feature X" is weak. "23 developers asked for feature X last quarter, and 3 enterprise prospects listed it as a blocker" gets attention.
- Distinguish product feedback from documentation feedback. "The API is confusing" and "the API docs are confusing" are different problems with different owners.

### Feature request triage

- Maintain a feature request board. Tag requests by source: community issue, conference, support ticket, partner.
- Review monthly with product management. Identify patterns.
- Close the loop: when a requested feature ships, notify the developers who asked for it.

### Being the voice of the developer

- Attend product planning meetings. If DevRel is not in the room when decisions are made, developer needs will not be represented.
- Write internal "developer impact assessments" before shipping breaking changes or deprecations.
- Share developer sentiment trends with leadership quarterly, combining quantitative data (NPS, satisfaction scores) with qualitative stories.

## Crisis Communication

### Security vulnerability disclosure

- Follow your organization's security response process. Do not freelance on vulnerability disclosure.
- Prepare a communication template in advance covering: what is the vulnerability, who is affected, what developers should do now, and the timeline for a fix.
- Publish advisories through official channels: security mailing list, GitHub security advisories, and documentation site.
- Be direct. Downplaying a vulnerability destroys trust faster than the vulnerability itself.

### Breaking changes communication

- Announce breaking changes at least 1 major version in advance with a deprecation period.
- Every announcement must include a migration guide with before-and-after code examples.
- Give developers a timeline for when the old behavior stops working.

### Outage response and post-mortems

- Post status updates every 30 minutes during major outages, even with no new information.
- After resolution, publish a blameless post-mortem: timeline, root cause, impact, remediation, prevention.
- Post-mortems build trust. They show developers you take reliability seriously.

## Demo Guidelines

- Tell a story: problem, solution, result.
- Keep demos under 10 minutes for talks, under 5 minutes for booth demos.
- Have a pre-recorded backup of every live demo. Script steps. Practice at least three times.
- Clean, distraction-free terminal and browser. Close Slack, email, notifications.
- Design for the back row: 18pt minimum for terminal, 24pt minimum for slides, high contrast only.
- Have a mobile hotspot as backup. Conference WiFi is unreliable.

## Red Hat Brand Guidelines

- Use correct product names (see content-writing.md for the full reference).
- Follow Red Hat brand guidelines for presentations and visual materials.
- For upstream projects, focus on the community project name. Reference Red Hat products separately.
- Include disclaimers for pre-release or tech preview features.
- Get brand team approval for partner co-branded content.
- Never represent AI-generated content as human-authored.

## Analytics, Measurement, and ROI

### Developer funnel metrics

Track developers through the funnel stages. Pick the metrics that matter for your work.

| Funnel stage | Metric | How to measure |
|--------------|--------|----------------|
| Awareness | Unique visitors; social impressions | Google Analytics, platform analytics |
| Evaluation | Quickstart completion rate; time to first API call | Custom event tracking, API logs |
| Adoption | Active developers; SDK downloads | API key activity, package registry stats |
| Retention | Monthly active developers; churn rate | API usage logs |
| Advocacy | Community-authored content; Net Promoter Score | Social listening, developer surveys |

### Attribution models

DevRel attribution is hard. Use multiple models and triangulate:

- **First touch**: What brought the developer to the product initially? Track UTM parameters on all DevRel content.
- **Multi-touch**: Map the developer journey across blog posts, docs, events, and community interactions.
- **Self-reported**: Ask developers "How did you hear about us?" during signup. Simple but effective.
- **Cohort analysis**: Compare developer cohorts exposed to specific content against those who were not.

Focus on showing influence and correlation, not sole causation. DevRel is one of many inputs.

### Executive reporting

- Report metrics executives care about: developer adoption growth, retention trends, pipeline influence.
- Translate activity into outcomes. "We published 12 blog posts" is activity. "Blog-driven signups increased 30% QoQ" is impact.
- Include qualitative signal alongside numbers. A quote from a Fortune 500 developer carries weight that page view counts do not.

### Quarterly business reviews

Each quarter, prepare a review covering: key metrics vs. targets, top 3 wins, top 3 misses with lessons learned, developer feedback themes, and the plan for next quarter including priorities and resource needs.

## Metrics Dashboard

Track these KPIs for developer relations work:

### Content metrics

| Metric | Target | Measurement tool |
|--------|--------|------------------|
| Blog post unique visitors | 500+ per post | Google Analytics, Plausible |
| Time on page | 3+ minutes | Google Analytics |
| Code sample GitHub stars | 50+ per repo | GitHub API |
| Tutorial completion rate | 60%+ | Custom tracking |
| Documentation page views | Track monthly | Google Analytics |
| Content freshness (% updated in last 6 months) | 80%+ | Manual audit |

### Community metrics

| Metric | Target | Measurement tool |
|--------|--------|------------------|
| Issue response time | Under 2 business days | GitHub API |
| PR review turnaround | Under 3 business days | GitHub API |
| Community PRs merged | Track monthly | GitHub API |
| New contributors per quarter | Track quarterly | GitHub API |
| Stack Overflow answers | Track monthly | Stack Exchange API |
| Community champions active | 5+ per product area | Internal tracking |
| Discord/Slack active members | Track monthly | Platform analytics |

### Event metrics

| Metric | Target | Measurement tool |
|--------|--------|------------------|
| Talks submitted per quarter | 3 to 5 | CFP tracking sheet |
| Talks accepted | 40%+ acceptance | CFP tracking sheet |
| Workshop attendees | 30+ per workshop | Event registration |
| Demo booth interactions | 50+ per event | Manual count |
| Post-event follow-up conversion | 10%+ | CRM tracking |

### Developer adoption metrics

| Metric | Target | Measurement tool |
|--------|--------|------------------|
| New developer signups (monthly) | Track trend | Product analytics |
| Time to first API call | Under 15 minutes | API logs |
| Weekly active developers | Track trend | API logs |
| Developer NPS | 40+ | Quarterly survey |
| Support ticket volume per active developer | Decreasing trend | Support system |

Review content and community metrics monthly. Review adoption and funnel metrics quarterly with stakeholders.

## Event Planning Checklist

### 4 weeks before

- [ ] Confirm talk/workshop is accepted and scheduled
- [ ] Book travel and accommodation
- [ ] Verify demo hardware and software requirements
- [ ] Start building or updating slides and demo environment
- [ ] Coordinate with co-presenters on content division

### 2 weeks before

- [ ] Complete slide deck and send for team review
- [ ] Test all demos end-to-end on the target hardware
- [ ] Record a backup video of every live demo
- [ ] Prepare QR codes or handouts linking to resources
- [ ] Confirm booth schedule and staffing if applicable

### 1 week before

- [ ] Full dry run with timing
- [ ] Update all linked code repos (READMEs, dependencies)
- [ ] Prepare a one-command demo environment setup script
- [ ] Load slides and demos on a backup USB drive
- [ ] Verify all URLs in slides resolve correctly

### Day of

- [ ] Arrive 30 minutes early to test A/V and screen resolution
- [ ] Close all notifications. Open demo environment. Verify connectivity.
- [ ] Have backup demo video queued. Bring adapters and display cables.

### After

- [ ] Share slides and repos on social media and team channels
- [ ] Write trip report (3 to 5 key takeaways, follow-up actions)
- [ ] Respond to new GitHub issues within 48 hours
- [ ] Update metrics dashboard. File expenses within 5 business days.
- [ ] Log developer feedback in the feedback tracker

## Review Checklist

Before publishing any DevRel content, verify the following:

### Code and functionality
- [ ] All code samples run without errors on a clean setup
- [ ] Tests pass for all supported language versions and platforms
- [ ] README includes prerequisites, setup steps, and expected output
- [ ] Dependencies are pinned and up to date
- [ ] No credentials, API keys, secrets, or internal URLs in the content
- [ ] `.env.example` file is included if environment variables are required
- [ ] License file is included (Apache 2.0)

### Content quality
- [ ] Content has been reviewed by at least one other person
- [ ] Links are valid and point to current resources
- [ ] Product names follow Red Hat conventions
- [ ] No em dashes in the content
- [ ] Headers use sentence case
- [ ] Code blocks specify the language for syntax highlighting
- [ ] Screenshots and diagrams are current and legible at standard zoom

### Accessibility and inclusion
- [ ] Images have alt text
- [ ] Color is not the only way information is conveyed (in diagrams and screenshots)
- [ ] Language is inclusive and avoids exclusionary terms
- [ ] Content is readable for non-native English speakers

### Strategy alignment
- [ ] Content maps to a defined content pillar
- [ ] Target audience persona is identified
- [ ] Developer journey stage is identified
- [ ] Success metrics are defined before publishing
- [ ] Distribution plan is documented (where and when this will be promoted)

### Attribution
- [ ] Do not mark AI as a contributor or co-author in commits, repos, or published content
- [ ] Credit community contributors by name when their work is featured
- [ ] Link to upstream projects and dependencies used
