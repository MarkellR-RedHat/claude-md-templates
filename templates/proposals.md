# CLAUDE.md - Conference Proposals and CFPs

<!-- Quick customize: Fill in the TODOs below, then delete this section -->
<!-- TODO: Set your speaker name and email -->
<!-- TODO: Set your company name and role -->
<!-- TODO: List your previous speaking history (conferences, videos) -->
<!-- TODO: Add your team's internal review process for proposals -->

## Project Overview

This repo contains conference talk proposals, abstracts, and supporting materials. The goal is to maintain a library of proposals that can be adapted for different conferences and events.

## Target Conferences

### Cloud Native and Infrastructure

- **KubeCon + CloudNativeCon** (CNCF): Cloud native, Kubernetes, containers, service mesh, observability
- **Open Source Summit** (Linux Foundation): Linux, open source strategy, supply chain security
- **DevConf.cz / DevConf.us**: Open source, community-driven, broad technical topics
- **FOSDEM**: Open source, community, upstream projects
- **HashiConf**: Infrastructure as code, secrets management, service networking
- **Config Management Camp**: Configuration management, GitOps, infrastructure automation

### AI and Machine Learning

- **AI_dev** (Linux Foundation): AI/ML infrastructure, model serving, LLM operations
- **NeurIPS**: Machine learning research, applied ML, datasets and benchmarks
- **AAAI**: Artificial intelligence research and applications
- **MLOps World**: ML operations, model deployment, ML engineering
- **Ray Summit**: Distributed computing, AI infrastructure, scaling ML workloads
- **AI Engineer Summit**: Applied AI engineering, LLM applications, AI tooling

### Developer and Language-Specific

- **PyCon US / PyCon EU**: Python, data science, ML, developer tooling
- **GopherCon**: Go programming, cloud infrastructure, performance
- **SCALE**: Southern California Linux Expo, broad open source topics
- **All Things Open**: Open source technologies, community, enterprise open source
- **Strange Loop** (if active): Programming languages, distributed systems, emerging tech

### Automation and Operations

- **AnsibleFest / Ansible Automates**: Automation, IT operations, event-driven automation
- **SREcon**: Site reliability engineering, observability, incident management
- **Monitorama**: Monitoring, observability, alerting

### CFP deadline tracking

Track deadlines in a structured format. Add entries to a `deadlines.yaml` file:
```yaml
# deadlines.yaml
cfps:
  - conference: KubeCon NA
    year: 2026
    cfp_opens: "2026-04-01"
    cfp_closes: "2026-06-15"
    notification: "2026-07-15"
    event_dates: "2026-11-09 to 2026-11-12"
    location: "Los Angeles, CA"
    tracks:
      - "AI + ML"
      - "Platform Engineering"
      - "Application Development"
    submission_url: "https://events.linuxfoundation.org/"
    video_required: false
    notes: "250-word abstract limit"

  - conference: KubeCon + CloudNativeCon NA
    year: 2026
    cfp_opens: "2026-01-15"
    cfp_closes: "2026-03-01"
    notification: "2026-04-01"
    event_dates: "2026-06-15 to 2026-06-18"
    location: "Boston, MA"
    tracks:
      - "AI/ML"
      - "Operations"
    submission_url: "https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/"
    video_required: false
    notes: "Sessionize submission; co-speaker details required up front"
```

### Common session lengths

| Session type       | Duration    | Slides    | Structure                                    |
|--------------------|-------------|-----------|----------------------------------------------|
| Lightning talk     | 5 minutes   | 5 to 8    | One idea, one demo, one takeaway             |
| Standard talk      | 25 to 30 min| 15 to 25  | Problem, approach, demo, results, next steps |
| Deep dive          | 40 to 45 min| 25 to 40  | Add architecture details and extended demo   |
| Workshop (half-day)| 2 to 3 hours| 15 to 20  | Slides minimal; focus on hands-on exercises  |
| Workshop (full-day)| 6 to 7 hours| 20 to 30  | Mix of instruction and lab time with breaks  |
| Keynote            | 15 to 20 min| 15 to 25  | High-level story arc with a strong close     |
| Panel              | 30 to 60 min| 0 to 5    | Moderator-led; prepare talking points only   |

Timing tips:
- Plan for 1 to 2 minutes per slide, depending on content density.
- Reserve 5 minutes for Q&A in standard talks, 10 minutes in deep dives.
- Demo time expands unpredictably. Practice demos with a timer and add a 30% buffer.
- For workshops, plan 60% hands-on time and 40% instruction. Attendees came to do, not to watch.

## Audience Analysis Framework

Before writing a proposal, answer these questions about your target audience:

### What do they know?
- What is their experience level with the core technology? (beginner, intermediate, advanced)
- What related technologies are they likely familiar with?
- What terminology can you use without explanation?

### What do they need?
- What problem are they trying to solve today?
- What would save them time, reduce risk, or unblock their projects?
- What will they be able to do after your talk that they could not do before?

### What do they fear?
- What risks or trade-offs worry them about this technology?
- What has gone wrong for them (or people like them) in the past?
- What misconceptions might they have?

Address all three in your proposal. Reviewers can tell when a speaker understands their audience versus when a speaker is just presenting their own work.

## Talk Design Patterns

### Story-first pattern
Start with a real problem you or your team encountered. Walk through the investigation, the wrong turns, and the eventual solution. This pattern works well for post-mortems, case studies, and lessons-learned talks.

Structure: Setup (the problem) -> Tension (why it was hard) -> Resolution (what worked) -> Takeaway (what the audience should do)

### Tech-first pattern
Start with the technology and build up from fundamentals to advanced usage. This pattern works well for deep dives, new project introductions, and architecture talks.

Structure: What is it? -> How does it work? -> Demo -> When to use it (and when not to) -> Getting started

### Demo-driven pattern
Build the entire talk around a live demonstration. Use slides only for context that the demo cannot show (architecture diagrams, performance charts). This pattern works well for developer tooling, CLI tools, and platform features.

Structure: Context (2-3 slides) -> Demo part 1 -> Explain what just happened -> Demo part 2 -> Recap and resources

### Narrative arc
Every talk needs a narrative arc, regardless of pattern. The audience should feel tension (a problem worth solving) and resolution (a solution that works). Talks without tension are lectures. Talks without resolution are complaints.

## Proposal Structure

Every proposal file should include these sections:

### Title
- Keep it under 75 characters.
- Be specific. "Scaling ML Inference on Kubernetes with vLLM" is better than "ML at Scale."
- Avoid clickbait or question-format titles unless the conference culture favors them.
- Include the specific technology, not just the category. "Kubernetes" not "cloud native."

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
- If you have data or benchmarks, mention them here. Reviewers love evidence.

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

## Slide Design Principles

### One idea per slide
Each slide should communicate exactly one point. If you need a second sentence to explain the slide title, you have two ideas on one slide. Split them.

### Visual hierarchy
- Title: what the slide is about (short, scannable)
- Body: one key visual (diagram, code snippet, screenshot, or data chart)
- Avoid bullet-point slides. If you must use bullets, limit them to 3-4 items.
- Use large font sizes. If it cannot be read from the back of a 200-seat room, it is too small.

### Code on slides
- Maximum 10-15 lines of code per slide. Anything longer belongs in a demo.
- Highlight the 2-3 lines that matter. Gray out or fade the rest.
- Use a monospace font at 24pt minimum.
- Syntax highlighting helps, but do not rely on color alone. Use comments or arrows to point out key lines.
- Show the output on the next slide so the audience sees the result.

### Slide count guidelines
- Lightning talk (5 min): 5-8 slides. No room for filler.
- Standard talk (30 min): 15-25 slides. Budget 1-2 minutes per slide.
- Deep dive (45 min): 25-40 slides. Some slides will go fast (transition slides), others slow (architecture diagrams).

## Demo Design

### Planning
- Script every demo step. Write the exact commands you will run.
- Time your demo with a stopwatch. Add 30% buffer for live conditions (network latency, typos, audience questions).
- Decide what to skip if you run over time. Know your "fast path" through the demo.

### Failure modes and backup plans
- **Network failure**: Have a local version of anything that requires internet access. Pre-pull container images. Cache API responses.
- **Cluster failure**: Have a pre-recorded video of the demo as a backup. Record it during your final rehearsal.
- **Typo cascade**: Use a script or Makefile for complex commands. Type simple commands live for authenticity.
- **Unexpected output**: Practice the demo enough times that you know what normal output looks like. If something goes wrong live, narrate what is happening and pivot to the backup.

### Live coding best practices
- Increase your terminal font size to at least 24pt. Default 12pt is unreadable from row 5.
- Use a clean shell with minimal prompt. Your PS1 should show the working directory and nothing else.
- Close all notifications: Slack, email, calendar, OS notifications.
- Have all files pre-staged in your editor. Do not make the audience watch you navigate your file system.
- Practice the exact sequence at least 5 times. Muscle memory reduces live errors.

## Video Submission Tips

Many CFPs now require a 2-3 minute video pitch. This is your chance to show reviewers that you can present, not just write.

### Recording setup
- Use a webcam at eye level. Looking down at a laptop camera is unflattering and distracting.
- Choose a quiet room with decent lighting. Natural light from in front of you works best.
- Frame yourself from chest up. The video is about your face and energy, not your office.

### Content structure (for a 2-minute video)
1. **Hook** (15 seconds): State the problem you will address.
2. **Approach** (45 seconds): Describe your solution and why it is interesting.
3. **Why you** (30 seconds): What qualifies you to give this talk? Mention relevant experience.
4. **Why this audience** (15 seconds): Why should this specific conference accept this talk?
5. **Close** (15 seconds): Restate the key takeaway.

### Production tips
- Do not read from a script. Use bullet points as prompts.
- Look at the camera, not the screen. This creates a sense of direct connection.
- Record multiple takes and pick the best one. Three takes is usually enough.
- Keep it under the time limit. If the CFP says 3 minutes, aim for 2:30.

## Co-Speaker Coordination

### Before the proposal
- Decide who is the primary submitter and point of contact.
- Agree on the talk's core message and structure before writing the abstract.
- Divide the talk into clear sections with one owner per section. Avoid "we'll figure it out later."

### Rehearsal process
- Rehearse together at least 3 times: once for content, once for timing, once for transitions.
- Practice the handoffs between speakers. Awkward transitions break the audience's attention.
- Agree on a signal for "wrap up this section" in case someone runs long.
- Decide who handles Q&A for which topics.

### Day of the talk
- Arrive together. Test both laptops with the projector.
- Use one laptop for slides to avoid display switching mid-talk.
- Stand where the audience can see both speakers. Do not hide behind the podium.

## Post-Talk Engagement

### Within 24 hours
- Share your slides on Speaker Deck, SlideShare, or your own site. Post the link on social media.
- Tweet/post a thread with 3-5 key takeaways from your talk.
- Respond to anyone who mentions your talk online.

### Within 1 week
- Write a blog post based on the talk (see the content-writing template for blog structure).
- If the recording is available, share it on social media and add it to your speaker profile.

### Recording optimization
- When the recording is published, watch it once. Note the timestamps for key sections.
- Write a summary with timestamps and post it alongside the recording link.
- If the audio or video quality is poor, consider re-recording a screencast version of the talk.

### Building on success
- If the talk was well received, propose it (adapted) to 2-3 other conferences.
- Use audience questions to identify gaps in your content. Update the talk or write a follow-up post.
- Add the recording link and audience feedback to your speaker portfolio.

## Proposal Anti-Patterns

### What reviewers hate
- **Vague abstracts**: "We will discuss best practices for cloud native development." This tells the reviewer nothing specific.
- **Product pitches**: If the abstract reads like a press release, it will be rejected at community conferences.
- **No clear takeaways**: If the reader cannot answer "what will I learn?" after reading the abstract, rewrite it.
- **Overpromising**: "We will cover everything you need to know about Kubernetes." No, you will not. Be honest about scope.
- **Wall of text**: A 250-word abstract should have at least 2 paragraph breaks. Make it scannable.

### Common rejection reasons
- Topic already covered by 5 other submissions. Differentiate your angle.
- Speaker has no evidence of ability to present (no videos, no previous talks listed).
- Talk is too vendor-specific for a community conference.
- Abstract is too basic for the conference's audience level.
- Abstract does not match any of the conference's content tracks.

### How to stand out
- Include real data. "Reduced cold start time from 45 seconds to 3 seconds" beats "significantly improved startup performance."
- Reference the specific track you are submitting to. Show you read the track description.
- Mention what is new or different about your approach compared to existing content.
- If you have given this talk before, mention it and describe how this version is updated or improved.

## Writing Guidelines

- Write abstracts in present tense. "In this talk, we explore..." not "In this talk, we will explore..."
- Use "we" for co-presented talks. Use "I" for solo talks.
- Do not use em dashes anywhere. Use commas, periods, or "and" instead.
- Avoid acronyms in titles. Spell them out: "Kubernetes" not "K8s" in a title, though "K8s" is fine in the body.
- Do not oversell. Describe what you will actually deliver.
- Include real metrics or results when possible. "Reduced inference latency by 40%" is stronger than "significantly improved performance."
- Write for the reviewer, not just the attendee. Reviewers read hundreds of proposals. Make yours easy to evaluate.

## Adapting Proposals Across Conferences

When reusing a proposal for a different conference:
- Adjust the abstract length to match the CFP requirements.
- Tailor the "why this matters now" framing to the conference audience.
- Update the target audience section. A KubeCon audience has different baseline knowledge than a PyCon audience.
- Check the conference's content tracks and align your proposal with the right one.
- For community conferences, focus on the open source project. For vendor conferences, it is appropriate to reference product names.
- Update any metrics, benchmarks, or version numbers to reflect the latest data.

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

## Product References

When referencing commercial products in proposals:
- Use full product names on first reference (see content-writing.md for the full list).
- Position talks around the open source project when submitting to community conferences. Reference the upstream project (e.g., "Kubernetes" not a vendor distribution) as the primary technology.
- For vendor-sponsored events, it is appropriate to reference product names directly.
- If your talk includes a demo on a commercial product, mention both the upstream project and the product: "We will demo on a managed Kubernetes service, with steps that also work on vanilla Kubernetes."

## File Organization

```
proposals/
  2026/
    kubecon-na/
      scaling-ml-inference.md
      gpu-scheduling-deep-dive.md
    red-hat-summit/
      openshift-ai-workshop.md
    ai-dev/
      llm-serving-patterns.md
  bios/
    speaker-bio-short.md
    speaker-bio-long.md
    headshot-high-res.jpg
    headshot-square.jpg
  recordings/
    links-to-recordings.md
  templates/
    proposal-template.md
    pitch-email-template.md
  deadlines.yaml
```

## Common Mistakes Claude Makes

These are patterns Claude tends to produce in conference proposals that reviewers will reject.

**Writing abstracts that sound like marketing copy.** Claude uses phrases like "cutting-edge," "revolutionary," and "game-changing." Conference reviewers reject product pitches. Describe what the audience will learn in concrete, technical terms.

**Being vague about takeaways.** Claude writes "attendees will gain a deep understanding of..." without specifying what they will be able to DO afterward. Use action verbs: "deploy," "configure," "evaluate," "debug." Reviewers want to know the practical outcome.

**Overpromising scope.** Claude writes abstracts that promise to cover an entire technology stack in 30 minutes. Be honest about scope. A focused talk on one aspect of a topic is stronger than a surface-level tour of everything.

**Using the same abstract for every conference.** Claude produces generic abstracts that do not reference the specific conference, its audience, or its tracks. Tailor every abstract to the conference. Reference the track name. Acknowledge the audience's baseline knowledge.

**Writing speaker bios focused on job titles.** Claude creates bios like "Senior Software Engineer at Company with 10 years of experience." Reviewers care about relevant expertise: open source contributions, previous talks, published work on the topic.

**Skipping the "why now" framing.** Claude writes abstracts about topics without explaining why they are timely and relevant. Reviewers need to justify their selections. Help them by connecting your topic to current trends, recent releases, or pressing problems.

**Creating learning objectives that are too abstract.** Claude writes "Understand the fundamentals of X." This is not measurable. Write objectives that start with observable verbs: "Deploy a GPU-accelerated inference service using vLLM on OpenShift."

**Not differentiating from similar talks.** Claude produces abstracts that could describe any talk on the topic. Mention what makes YOUR approach or experience unique. Include specific data, benchmarks, or lessons from real deployments.

## Related Templates and Commands

If your work spans multiple domains, use these tools to extend this CLAUDE.md:

- **`/suggest-template`**: Run this command in your project directory to auto-detect the project type and get a tailored template recommendation. For proposal repos, it detects CFP-related directories and proposal markdown files.
- **`/compose-template proposals + [other]`**: Merge this template with another. Common combinations:
  - `proposals + content-writing` for teams that manage conference proposals and blog posts in the same repo (adds editorial standards, SEO, content lifecycle)
  - `proposals + general-devrel` for DevRel teams where proposal writing is part of a broader content and community strategy
- **`content-writing` template**: If you repurpose conference talks into blog posts (or vice versa), that template provides editorial standards, blog structure, SEO, and product naming conventions.
- **`general-devrel` template**: If your proposals are part of a broader DevRel effort that includes code samples, workshops, and community building, that template covers event planning checklists, demo guidelines, and developer journey mapping.

## Review Checklist

Before submitting a proposal:

### Content
- [ ] Title is under 75 characters and names a specific technology
- [ ] Abstract is within the CFP word limit
- [ ] Abstract follows the pattern: problem, approach, takeaways, timeliness
- [ ] Learning objectives start with action verbs and are specific
- [ ] Target audience and experience level are stated
- [ ] Talk matches one of the conference's content tracks

### Speaker Materials
- [ ] Speaker bio is current and under 100 words
- [ ] Headshot meets the CFP's size and format requirements
- [ ] Video pitch is recorded and under the time limit (if required)
- [ ] Previous talk recordings are linked (if available)

### Quality
- [ ] No spelling or grammar errors
- [ ] No em dashes anywhere in the text
- [ ] No product pitches disguised as talks (for community conferences)
- [ ] Real data or metrics are included where possible
- [ ] Proposal differentiates from similar talks on the topic

### Process
- [ ] Proposal has been reviewed by at least one colleague
- [ ] Submission deadline is tracked in the team calendar
- [ ] Co-speaker (if applicable) has reviewed and approved the final version
- [ ] Internal approval is obtained (if required by your organization)
