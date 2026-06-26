# CLAUDE.md - Conference Proposals and CFPs

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your speaker name and email -->
<!-- TODO: Set your company name and role -->
<!-- TODO: List your previous speaking history (conferences, videos) -->
<!-- TODO: Set the target year for proposals (currently shows 2025 in examples) -->
<!-- TODO: Add your team's internal review process for proposals -->

## Project Overview

This repo contains conference talk proposals, abstracts, and supporting materials. The goal is to maintain a library of proposals that can be adapted for different conferences and events.

## Target Conferences

Common conferences this content targets:

- **KubeCon + CloudNativeCon** (CNCF): Cloud native, Kubernetes, containers, service mesh, observability
- **Red Hat Summit**: Red Hat products, hybrid cloud, automation, AI/ML on OpenShift
- **DevConf.cz / DevConf.us**: Open source, community-driven, broad technical topics
- **AnsibleFest**: Automation, IT operations, event-driven automation
- **FOSDEM**: Open source, community, upstream projects
- **PyCon**: Python, data science, ML, developer tooling
- **Open Source Summit**: Linux, open source strategy, supply chain security
- **AI_dev**: AI/ML infrastructure, model serving, LLM operations

### CFP deadline tracking

Track deadlines in a structured format. Add entries to a `deadlines.yaml` file:
```yaml
# deadlines.yaml
cfps:
  - conference: KubeCon NA
    year: 2025
    cfp_opens: "2025-04-01"
    cfp_closes: "2025-06-15"
    notification: "2025-07-15"
    event_dates: "2025-11-10 to 2025-11-13"
    location: "Salt Lake City, UT"
    tracks:
      - "AI + ML"
      - "Platform Engineering"
      - "Application Development"
    submission_url: "https://events.linuxfoundation.org/"
    notes: "250-word abstract limit"

  - conference: Red Hat Summit
    year: 2025
    cfp_opens: "2025-01-15"
    cfp_closes: "2025-03-01"
    notification: "2025-04-01"
    event_dates: "2025-06-22 to 2025-06-25"
    location: "Boston, MA"
    tracks:
      - "AI/ML"
      - "Hybrid Cloud"
    submission_url: "https://www.redhat.com/summit"
    notes: "Internal reviewers required before submission"
```

### Common session lengths

Structure your content to fit these standard session formats:

| Session type       | Duration    | Slides    | Structure                                    |
|--------------------|-------------|-----------|----------------------------------------------|
| Lightning talk     | 5 minutes   | 5 to 8    | One idea, one demo, one takeaway             |
| Standard talk      | 25 to 30 min| 15 to 25  | Problem, approach, demo, results, next steps |
| Deep dive          | 40 to 45 min| 25 to 40  | Add architecture details and extended demo   |
| Workshop (half-day)| 2 to 3 hours| 15 to 20  | Slides minimal; focus on hands-on exercises  |
| Workshop (full-day)| 6 to 7 hours| 20 to 30  | Mix of instruction and lab time with breaks  |
| Keynote            | 15 to 20 min| 15 to 25  | High-level story arc with a strong close     |

Timing tips:
- Plan for 1 to 2 minutes per slide, depending on content density.
- Reserve 5 minutes for Q&A in standard talks, 10 minutes in deep dives.
- Demo time expands unpredictably. Practice demos with a timer and add a 30% buffer.

## Proposal Structure

Every proposal file should include these sections:

### Title
- Keep it under 75 characters.
- Be specific. "Scaling ML Inference on Kubernetes with vLLM" is better than "ML at Scale."
- Avoid clickbait or question-format titles unless the conference culture favors them.

### Abstract (250 words max, unless the CFP specifies otherwise)
Follow this pattern:
1. **Problem statement** (1-2 sentences): What challenge does the audience face?
2. **Approach** (2-3 sentences): What solution or technique will you present?
3. **What attendees will learn** (1-2 sentences): Concrete takeaways.
4. **Why this matters now** (1 sentence): Timeliness and relevance.

### Description / Extended Abstract
- Provide more technical depth than the abstract.
- Include an outline of the talk structure with approximate timing.
- Mention any demos, live coding, or audience interaction.

### Learning Objectives
List 3-5 specific things attendees will be able to do after the talk:
- Start each objective with an action verb (deploy, configure, evaluate, implement).
- Be concrete. "Understand Kubernetes" is too vague. "Deploy a GPU-accelerated inference service on OpenShift" is specific.

### Target Audience
- Specify the experience level: beginner, intermediate, advanced.
- Name the roles this talk serves: developers, platform engineers, data scientists, SREs.
- Note any prerequisite knowledge.

### Speaker Bio
- Keep it under 100 words.
- Focus on relevant experience, not job titles.
- Mention open source contributions, previous talks, or published work.
- Write in third person.

## File Organization

```
proposals/
  2025/
    kubecon-na/
      scaling-ml-inference.md
      gpu-scheduling-deep-dive.md
    red-hat-summit/
      openshift-ai-workshop.md
  bios/
    speaker-bio-short.md
    speaker-bio-long.md
  templates/
    proposal-template.md
```

## Writing Guidelines

- Write abstracts in present tense. "In this talk, we explore..." not "In this talk, we will explore..."
- Use "we" for co-presented talks. Use "I" for solo talks.
- Do not use em dashes. Use commas, periods, or "and" instead.
- Avoid acronyms in titles. Spell them out: "Kubernetes" not "K8s" in a title, though "K8s" is fine in the body.
- Do not oversell. Describe what you will actually deliver.
- Include real metrics or results when possible. "Reduced inference latency by 40%" is stronger than "significantly improved performance."

## Adapting Proposals Across Conferences

When reusing a proposal for a different conference:
- Adjust the abstract length to match the CFP requirements.
- Tailor the "why this matters now" framing to the conference audience.
- Update the target audience section. A KubeCon audience has different baseline knowledge than a PyCon audience.
- Check the conference's content tracks and align your proposal with the right one.

## Pitch Emails

When submitting outside normal CFP channels (invited talks, meetups, podcast appearances), use this template:

```text
Subject: Talk proposal: [Title] for [Event/Meetup Name]

Hi [Organizer Name],

I'd like to propose a talk for [Event Name] on [Topic in plain language].

The talk covers [1-2 sentence summary of what attendees will learn].
I presented a version of this at [Previous Conference] and it was
well received ([link to recording or slides if available]).

Here is the quick pitch:

Title: [Your Title]
Format: [Talk / Workshop / Panel] ([Duration])
Level: [Beginner / Intermediate / Advanced]

Abstract:
[2-3 sentence version of your abstract]

About me:
[2-3 sentences about your relevant background]

I am happy to adjust the scope or format to fit your event. Let me
know if you'd like a full proposal or have any questions.

Best,
[Your Name]
[Your Title, Company]
[Link to speaker profile or website]
```

Tips for pitch emails:
- Keep the email under 250 words. Organizers read dozens of these.
- Link to a previous recording if you have one. It saves them the guesswork about your speaking ability.
- Offer flexibility on format and length. It shows you are collaborative.
- Follow up once after 7 to 10 days if you do not hear back. After that, move on.

## Red Hat Product References

When referencing Red Hat products in proposals:
- Use full product names on first reference (see content-writing.md for the full list).
- Position talks around the open source project when submitting to community conferences. Reference the upstream project (e.g., "Kubernetes" not "OpenShift") as the primary technology.
- For Red Hat-sponsored events, it is appropriate to reference product names directly.

## Review Checklist

Before submitting a proposal:

- [ ] Title is under 75 characters and specific
- [ ] Abstract is within the CFP word limit
- [ ] Learning objectives start with action verbs
- [ ] Target audience and experience level are specified
- [ ] Speaker bio is current and under 100 words
- [ ] No spelling or grammar errors
- [ ] Proposal has been reviewed by at least one colleague
- [ ] Submission deadline is tracked in the team calendar
