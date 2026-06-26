# CLAUDE.md - General Developer Relations Project

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your team name (e.g., AI Platform DevRel) -->
<!-- TODO: Set your GitHub org (e.g., github.com/redhat-developer) -->
<!-- TODO: List your primary technologies (e.g., OpenShift, vLLM, Kubernetes) -->
<!-- TODO: Set your SLA for community responses (currently 2 business days) -->
<!-- TODO: Update the CI workflow to match your GitHub org settings -->

## Project Overview

This is a Developer Relations project. It may include code samples, demos, tutorials, workshop materials, documentation, or community tooling. The primary audience is external developers, and everything produced here should be clear, runnable, and genuinely helpful.

## Dev Rel Principles

- **Developer-first**: Every piece of content exists to help developers succeed. If it does not help them build something, rethink it.
- **Honest and practical**: Do not oversell. Show real trade-offs. Developers respect honesty about limitations.
- **Runnable by default**: Every code sample, demo, and tutorial must work out of the box. If there are prerequisites, document them explicitly.
- **Community-oriented**: Engage with the community authentically. Respond to issues and PRs with empathy and context.

## Code Sample Standards

### Every code sample must include:
1. A `README.md` explaining what it does, who it is for, and how to run it.
2. Clear prerequisites (language version, tools, accounts needed).
3. Step-by-step setup instructions that a developer can follow without guessing.
4. Expected output or screenshots showing what success looks like.
5. A license file (Apache 2.0 is standard for Red Hat open source projects).

### Code quality:
- Code samples are production-quality examples, not throwaway scripts. Write them as if a developer will copy them directly into their project, because they will.
- Include error handling. Do not use bare `except` clauses in Python or ignore errors in Go.
- Add comments explaining "why," not "what." The code shows what. Comments explain decisions.
- Keep dependencies minimal. Every additional dependency is a potential point of failure.
- Pin dependency versions. `pip install flask` today and `pip install flask` six months from now may give different results.

### Repository structure for code samples:
```
sample-name/
  README.md
  LICENSE
  src/
    main.py (or main.go, index.js, etc.)
  tests/
  Containerfile (or Dockerfile)
  Makefile
  requirements.txt (or go.mod, package.json, etc.)
```

### CI for code samples

Add a GitHub Actions workflow to test code samples on every push and PR:
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
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run linting
        run: ruff check .
      - name: Run tests
        run: pytest tests/ -v

  test-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.21"
      - name: Run tests
        run: go test ./... -v -race
      - name: Run linting
        run: |
          go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          golangci-lint run ./...

  validate-yaml:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate YAML files
        run: |
          pip install yamllint
          yamllint -c .yamllint.yml .
```

Keep all code samples tested. Untested samples rot within weeks.

## Documentation Standards

- Write for scanning, not reading. Developers scan docs looking for the thing they need.
- Use headers, bullet points, and code blocks liberally. Walls of text lose people.
- Start every doc with the "what" and "why" before the "how."
- Include a table of contents for docs longer than three sections.
- Test all documented commands and procedures before publishing.
- Date your content. Technology moves fast, and readers need to know if instructions are current.

### Formatting rules:
- Use sentence case for all headers: "Getting started with OpenShift" not "Getting Started With OpenShift."
- Do not use em dashes. Use commas, periods, or "and" instead.
- Use backtick formatting for all CLI commands, file paths, environment variables, and code references.
- Use admonitions (Note, Warning, Important) sparingly. If everything is a warning, nothing is.

## Workshop and Tutorial Design

### Structure:
1. **Overview**: What will participants build? What will they learn? (2-3 sentences)
2. **Prerequisites**: Exact versions, tools, and accounts. Link to installation guides.
3. **Steps**: Numbered, with clear start and end points. Each step should take 5-15 minutes.
4. **Checkpoints**: After each major section, describe what the participant should see if everything worked.
5. **Troubleshooting**: Common issues and their solutions. These save workshop facilitators hours.
6. **Cleanup**: How to tear down resources created during the workshop. This is mandatory for cloud resources.

### Workshop best practices:
- Test the workshop end-to-end on a clean machine before delivering it.
- Assume the WiFi will fail. Have offline fallbacks for anything that requires downloads.
- Build in buffer time. Workshops always run longer than you expect.
- Provide a "fast path" for experienced participants who want to skip ahead.

## Community Interaction

### GitHub Issues and PRs:
- Respond to new issues within 2 business days, even if the response is "we've seen this and will investigate."
- Label issues consistently: `bug`, `enhancement`, `question`, `good-first-issue`, `help-wanted`.
- When closing issues, explain why and link to relevant resources.
- Review community PRs with the same rigor as internal PRs. Provide constructive feedback.
- Thank contributors. A simple "Thanks for the PR!" goes a long way.

### Writing for community:
- Use inclusive language. Avoid terms with exclusionary history.
- Write in English, but keep language simple for non-native speakers.
- Do not assume the reader's operating system, IDE, or experience level unless stated.
- When giving feedback on community contributions, be specific and constructive. "This doesn't work" is unhelpful. "This fails on Python 3.12 because of X" is actionable.

## Demo Guidelines

- Demos should tell a story: problem, solution, result.
- Keep demos under 10 minutes for conference talks, under 5 minutes for booth demos.
- Have a pre-recorded backup of every live demo. Live demos fail at the worst possible time.
- Script your demo steps. Practice them at least three times.
- Use a clean, distraction-free terminal and browser for demos. Close Slack, email, and notifications.

## Red Hat Brand Guidelines

- Use correct product names (see content-writing.md for the full reference).
- Follow Red Hat brand guidelines for presentations and visual materials.
- When creating content about upstream projects, focus on the community project name. Reference Red Hat products separately.
- Include appropriate disclaimers when showing pre-release or tech preview features.

## Analytics and Measurement

- Track key metrics for content: page views, time on page, GitHub stars, forks, and issue activity.
- Set goals for each piece of content. "Awareness" is not measurable. "500 unique visitors in the first month" is.
- Review analytics quarterly and retire or update content that is underperforming or outdated.

## Metrics Dashboard

Track these KPIs for developer relations work:

### Content metrics
| Metric                     | Target           | Measurement tool       |
|----------------------------|------------------|------------------------|
| Blog post unique visitors  | 500+ per post    | Google Analytics, Plausible |
| Time on page               | 3+ minutes       | Google Analytics       |
| Code sample GitHub stars   | 50+ per repo     | GitHub API             |
| Tutorial completion rate   | 60%+             | Custom tracking        |
| Documentation page views   | Track monthly    | Google Analytics       |

### Community metrics
| Metric                     | Target           | Measurement tool       |
|----------------------------|------------------|------------------------|
| Issue response time        | Under 2 business days | GitHub API          |
| PR review turnaround       | Under 3 business days | GitHub API          |
| Community PRs merged       | Track monthly    | GitHub API             |
| New contributors per quarter| Track quarterly | GitHub API             |
| Stack Overflow answers     | Track monthly    | Stack Exchange API     |

### Event metrics
| Metric                     | Target           | Measurement tool       |
|----------------------------|------------------|------------------------|
| Talks submitted per quarter| 3 to 5           | CFP tracking sheet     |
| Talks accepted             | 40%+ acceptance  | CFP tracking sheet     |
| Workshop attendees         | 30+ per workshop | Event registration     |
| Demo booth interactions    | 50+ per event    | Manual count           |

Review these metrics monthly in a team standup. Quarterly, publish a summary to stakeholders.

## Event Planning Checklist

### 4 weeks before the event
- [ ] Confirm talk or workshop is accepted and scheduled
- [ ] Book travel and accommodation
- [ ] Verify demo hardware and software requirements
- [ ] Start building or updating slides and demo environment
- [ ] Coordinate with co-presenters on content division

### 2 weeks before the event
- [ ] Complete slide deck and send for team review
- [ ] Test all demos end-to-end on the target hardware
- [ ] Record a backup video of every live demo
- [ ] Prepare printed handouts or QR codes linking to resources
- [ ] Confirm booth schedule and staffing if applicable

### 1 week before the event
- [ ] Do a full dry run of the presentation with timing
- [ ] Update all code repos linked in the talk (READMEs, dependencies)
- [ ] Prepare a "fast start" script that sets up the demo environment in one command
- [ ] Load all slides and demos on a backup USB drive
- [ ] Share your schedule with the team and set up a communication channel

### Day of the event
- [ ] Arrive 30 minutes early to test A/V and screen resolution
- [ ] Close all notifications (Slack, email, calendar popups)
- [ ] Open demo environment and verify connectivity
- [ ] Have backup demo video queued and ready
- [ ] Bring power adapters, dongles, and display cables

### After the event
- [ ] Share slides and demo repos on social media and team channels
- [ ] Write a short trip report (3 to 5 key takeaways, follow-up actions)
- [ ] Respond to new GitHub issues and questions within 48 hours
- [ ] Update the metrics dashboard with event data
- [ ] File expense reports within 5 business days

## Review Checklist

Before publishing:

- [ ] All code samples run without errors on a clean setup
- [ ] README includes prerequisites, setup steps, and expected output
- [ ] Links are valid and point to current resources
- [ ] Product names follow Red Hat conventions
- [ ] Content has been reviewed by at least one other person
- [ ] License file is included (Apache 2.0)
- [ ] No credentials, API keys, or internal URLs in the content
