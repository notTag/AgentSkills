---
name: jd-matcher
description: >
  Analyze a job description against Nick's senior-engineering-leadership background and
  produce a structured fit analysis: numeric score, fit verdict, honest gap list, and
  positioning hooks. Trigger when Nick (1) types the bare word "JDMatcher", (2) sends a
  message starting with "ANALYZE_JD_FIT" followed by JD text, or (3) pastes a JD with
  natural-language phrasing like "analyze this JD", "score this role", "is this a fit",
  "compare me to this job", "how do I stack up". Outputs a consistent format optimized
  for fast triage, tailored applications, and pattern-tracking across many roles. Trigger
  on /JDMatcher and /jd-matcher.
---

# JDMatcher Skill

## Purpose

Nick is in an active senior-engineering-leadership search. He evaluates many JDs. This
skill makes that evaluation fast, consistent, honest. Goals:

1. **Triage in under a minute** — apply / pass / stretch decisions
2. **Spot patterns** — which gaps recur across desirable roles
3. **Tailor applications** — what to lead with, what to address, which resume variant to send

---

## Authoritative profile sources

When analyzing, treat these as the truth about Nick's background. **Do not** invent
experience or infer beyond what's documented.

1. **`/Users/nicktag/Code/Projects/JobSearch/GoodFitDoc.md`** — primary canonical profile.
   Defines what counts as a "good fit". Always read first.
2. **`/Users/nicktag/Code/Resume/CompletedResumes/`** — three resume variants:
   - `DoE/NickTagliasacchi-Resume-DoE.tex` — Director of Engineering scope
   - `SrEM/NickTagliasacchi-Resume-SrEM.tex` — Senior Engineering Manager scope
   - `EM/NickTagliasacchi-Resume-EM.tex` — Engineering Manager scope

   PDFs alongside .tex (same basename). Read the `.tex` for citing concrete bullets.

3. **`/Users/nicktag/Code/AI/skills/jd-matcher/anchors.md`** — calibration anchors.
   Read before scoring. **Never write to this file** — Nick curates it manually.

If a JD requirement isn't backed by evidence in those three sources, treat it as a gap.

---

## Resume variant selection

In every analysis, recommend which resume variant to send. Map JD scope:

| JD scope signal | Recommend |
|---|---|
| "Director of Engineering", "Sr. Director", manager-of-managers, multi-team org | **DoE** |
| "Senior Engineering Manager", "Lead EM", single large team or two teams | **SrEM** |
| "Engineering Manager", first-line manager, team of 5–10 | **EM** |
| Ambiguous title but scope reads larger than title → score by scope, recommend variant matching scope | (note mismatch) |

State the recommendation explicitly in the output (see "Tailoring suggestions" section).

---

## Triggers

### Trigger 1 — bare word `JDMatcher`

If the user message is just `JDMatcher` (or `/JDMatcher` / `/jd-matcher`) with no JD
attached, respond with **exactly one line**:

```
Paste the JD below.
```

Then stop. Wait for the next message and treat its full content as the JD.

### Trigger 2 — `ANALYZE_JD_FIT` prefix

Message starts with `ANALYZE_JD_FIT` (any whitespace after). Treat everything after as
the JD. Run analysis directly. Do not echo. Do not ask clarifying questions unless the
JD is genuinely unparseable.

### Trigger 3 — natural-language

User pastes a JD with phrasing like "analyze this JD", "score this for me", "is this a
fit", "compare me to this job", "how do I stack up" — run the same analysis. No prompt
needed; the JD is already in hand.

---

## Workflow

### Stage 0 — Prefilter (run before scoring)

Auto-skip without scoring if the JD title or top requirements contain any of:

- "Staff Engineer" / "Staff Software Engineer" (IC track)
- "Principal Engineer" / "Principal Software Engineer" (IC track)
- "VP of Engineering" at orgs >100 engineers
- "CTO" or co-founder roles
- Pure SRE / Infrastructure / Platform leadership where K8s/cloud-native is the entire domain
- Pure ML research / model-training leadership
- Frontend-only specialist roles (e.g. "Staff Frontend Architect")

When auto-skipping, output:

```
## [Company] — [Role Title]

**AUTO-SKIPPED** — [one-line reason]
```

Skip the rest of the analysis. Do not score.

### Stage 1 — Extract company + role

Pull company name and role title from the JD. If either is missing or ambiguous, use
`[Unknown Company]` or `[Unknown Role]` and note it.

### Stage 2 — Read profile + anchors

Before scoring, read:
1. `GoodFitDoc.md` (always)
2. The matching resume `.tex` based on inferred scope (DoE / SrEM / EM)
3. `anchors.md` (for score calibration)

### Stage 3 — Score and write analysis

Use the format below. Then persist to disk (Stage 4).

### Stage 4 — Persist analysis

Write the full analysis to:
```
/Users/nicktag/Code/Projects/JobSearch/JobFit/analyses/<company>_<role>_MM-DD-YYYY.md
```

Rules for the filename:
- Lowercase company and role
- Replace spaces with `-`
- Strip punctuation other than `-`
- `MM-DD-YYYY` from today's date
- If file exists, append ` -2`, ` -3`, etc. (don't overwrite — Nick may want to compare re-analyses)

Create `JobFit/analyses/` if missing.

After writing, include the file path at the bottom of the chat output:
```
Saved: JobFit/analyses/<filename>.md
```

---

## Output format

Always use this structure. Consistency matters — Nick compares roles to each other.

```
## [Company] — [Role Title]

**Fit Score: XX/100** — [Strong Fit | Good Fit | Partial Fit | Weak Fit | Not a Fit]
**Resume variant: [DoE | SrEM | EM]**

### Why this scores where it does
[2–4 sentences. Honest top-line read. Lead with the dominant factor — positive or negative.]

### Strong alignment
- [Specific resume/profile evidence → specific JD requirement. Be concrete on both sides.]
- [3–6 bullets.]

### Gaps & risks
- [What the JD asks for that Nick can't cleanly demonstrate.]
- [Distinguish "missing experience" from "have it but resume doesn't show it well".]
- [Flag deal-breakers vs. stretches explicitly.]

### How to position if applying
- [1–2 strongest hooks for cover letter / recruiter call.]
- [Which resume bullets to surface or rewrite to address biggest gaps.]
- [Reframing of existing experience that maps better to JD's language.]

### Tailoring suggestions
- **Send:** [DoE | SrEM | EM] resume — [one-line why]
- **Bullets to add or strengthen:** [specific bullets, if any]
- **Cover letter angle:** [one sentence]

### Verdict
[1–2 sentences. Apply / strong apply / pass / apply only if X. No hedging.]

Saved: JobFit/analyses/<filename>.md
```

---

## Scoring rubric

Score is a calibrated judgment, not a checklist. Anchor to these bands:

| Score | Band | Meaning |
|-------|------|---------|
| 85–100 | Strong Fit | Resume already tells this story. Apply with minimal tailoring. |
| 70–84 | Good Fit | Core match, 1–2 framing or evidence gaps. Tailor and apply. |
| 55–69 | Partial Fit | Real overlap, meaningful gaps. Apply only if compelling. |
| 40–54 | Weak Fit | Significant mismatch in domain, scope, or skills. Stretch at best. |
| <40  | Not a Fit | Don't apply unless something exceptional offsets it. |

Weighting:

- **Required / "must have"** — heavy. Missing one caps the score.
- **Responsibilities** — medium. Match against demonstrated experience, not aspirations.
- **Nice-to-haves** — light. Don't let these shift the score much.
- **Domain / industry fit** — material. Security SaaS depth helps for some roles, irrelevant for others.
- **Scope of leadership** — material. "Manage managers" vs. "lead a team of 5" map very differently.
- **Tech stack** — light unless JD requires deep specialization (e.g. "deep React/TS" for a frontend EM).

### Anchor sanity-check

After computing a score, read `anchors.md` and verify relative ordering. If new score is
within 3 points of an anchor, ask: is this role really stronger/weaker than that anchor?
Adjust until ordering is honest. Do not write to anchors.md.

---

## Edge cases

- **JD incomplete or vague** → score with available signal; flag thin JD in "Why this
  scores" with a wider error bar.
- **Comp / location / visa deal-breakers** → note in Verdict, but don't let logistics
  drive the fit score. Fit is about the work.
- **Title says "Senior Engineer" but scope is leadership** → score the actual scope, flag
  the title mismatch in "How to position".
- **Title says "Director" but scope is small-team IC-leaning** → same — score scope, flag.
- **Multiple roles pasted at once** → run the analysis per role. Do not merge. Save each
  to its own file.
- **Company only, no JD** → ask Nick to paste the JD. Don't guess.

---

## Tone

- Direct. Senior leader, doing his own search. No cheerleading, no hedging.
- No "everyone has gaps" softening. Plain language about gaps.
- "How to position" + "Tailoring suggestions" sections are where the value lives — make
  them actionable.
- Whole output scannable. He's reading many of these.
