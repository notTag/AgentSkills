---
name: feat
version: 1.0.0
description: |
  Capture a feature into the current project's FEATURES/ directory as a numbered
  markdown file (feat-NNN.md). Parses a one-liner when given; falls back to
  interactive intake when fields are missing. Trigger on "/feat", "log a feature",
  "capture this feature", "file a feature request".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# feat: Capture a feature to FEATURES/feat-NNN.md

Log a feature as a numbered markdown file in the **current project's** `FEATURES/` directory.
This skill owns the feature file format. (`agent-project-setup` only scaffolds working
dirs; it does not define the per-feature template.)

## Location

- Always `<cwd>/FEATURES/` — per-project, relative to the current working directory.
- If `FEATURES/` does not exist, create it (`mkdir -p FEATURES`). Do not require
  `agent-project-setup` to have run first.

## Numbering

1. Scan `FEATURES/` for the highest existing `feat-NNN.md`.
2. Increment, zero-pad to 3 digits. First feature is `001`.
3. Filename: `feat-NNN.md` (lowercase `feat-`, uppercase `.md`, e.g. `feat-007.md`).

## Feature file format

```markdown
# [NNN] <short title>

- Status: open
- Created: <YYYY-MM-DD>
- Priority: <low|med|high>
- Bump: <patch|minor|major>

## What
<the feature — what is being added/changed>

## Why
<motivation — the problem it solves or value it adds>

## Done When
- [ ] <acceptance criterion>

## Notes
<design notes, dependencies, references>
```

Field rules:
- `Status` — `open` on creation. Stays `open` through `update` and while a `build` is in
  progress. Only set to `Done` once the user confirms the feature is delivered/accepted.
- `Created` — today's date, `YYYY-MM-DD`.
- `Priority` — **optional**. Omit the line entirely if unknown/unset. Measures urgency.
- `Bump` — **optional** (Semantic Versioning bump level). Omit the line entirely if
  unset. Measures release impact. Priority and Bump are independent — include either,
  both, or neither.
- `## Notes` — **optional**. Omit the whole section if there's nothing to add.
- `What` / `Why` / `Done When` — core fields, always present.

## Subcommands

- **`/feat`** or **`/feat <text>`** — create a new feature (see Intake / Create below).
- **`/feat update feat-XXX`** — edit an existing feature via the TUI (see Update below).
- **`/feat build feat-XXX`** — work the feature toward delivery (see Build below).

`feat-XXX` may be given as `feat-003`, `003`, or `3` — normalize to the zero-padded
`feat-NNN.md` file in `<cwd>/FEATURES/`. If the file doesn't exist, say so and list the
features that do.

## Update (`/feat update feat-XXX`)

1. Read the existing `feat-NNN.md` and parse its current field values.
2. Run the **same two-batch TUI** as Create, but prepend each question with the current
   value as a selectable option so the user can keep it:
   - Core fields (What/Why/Done When): options become `Keep current: "<value>"`,
     `Deduce from context`, `Deduce from chat` (+ auto Other to retype).
   - Priority / Semantic: the fixed options — preselect/point out the current value;
     re-picking it keeps it. To clear an optional field, the user types `none` in Other.
   - Notes: `Keep current`, `Omit`, `Add from context`, `Add from chat` (+ auto Other).
3. For any question where the user picks the current value, leave that field unchanged.
   For any other selection, replace the field with the new value.
4. Preserve `Created`. Leave `Status` as-is (don't auto-complete on update).
5. **Write immediately** on TUI submit — no extra confirmation. Report the path + what
   changed.

## Build (`/feat build feat-XXX`)

This subcommand works the feature toward an actual delivery — it is not just a status flip.

1. Read `feat-NNN.md`; understand What / Why / Done When.
2. Investigate the relevant code/context. Ask any clarifying questions needed (TUI or
   inline) before attempting changes.
3. Implement the feature in the codebase, working toward each `Done When` criterion.
4. `Status` stays `open` throughout. Do **not** mark it done yourself.
5. When the user confirms the feature is delivered/accepted, set `Status: Done` and add a
   `Done: <YYYY-MM-DD>` line under the header.
6. **Sync the GitHub issue** (only if `feat-NNN.md` has an `- Issue: <url>` line and `gh`
   is available): take the issue number `<n>` from that URL and run
   `gh issue edit <n> --add-label status:done --remove-label status:open` then
   `gh issue close <n>`. If it has no `- Issue:` line, skip silently.
7. Report the path, issue state, and a one-line summary.

## Intake

- **`/feat <text>`** — parse `<text>` for what, why, and done-when. If all three core
  fields are clearly captured, skip the TUI and go straight to writing (see Procedure).
- **`/feat` with no args, or gaps** — collect fields via the `AskUserQuestion` TUI below.

### TUI flow (AskUserQuestion)

`AskUserQuestion` allows **max 4 questions per call** and **2–4 options per question**;
a free-text **Other** field is auto-appended to every question — do NOT add an explicit
"Other" option. Collect in **two batches**:

**Batch 1 — core fields** (What, Why, Done When). Options for each:
- `Deduce from context` — infer the field from project/codebase state.
- `Deduce from chat` — infer the field from this conversation.
- (auto Other) — user types the value as free text.

**Batch 2 — Priority, Semantic, Notes**:
- **Priority** — `low` / `med` / `high`. Auto-Other allowed; if left unanswered, omit
  the line.
- **Semantic** (SemVer bump) — `patch` / `minor` / `major`. Optional; omit the line if
  unanswered.
- **Notes** — `Omit` / `Add from context` / `Add from chat` (auto Other to type). `Omit`
  drops the whole `## Notes` section.

Derive a concise `<short title>` from the feature (one line, no trailing period).

## GitHub issue (when in a git repo)

After the file is written, if the current dir is a git repo with a GitHub `origin`
remote AND `gh` is available, also open a GitHub issue mirroring the feature:

1. Detect: `git remote get-url origin` matches `github.com` and `command -v gh` succeeds.
   If either fails, skip this whole step silently — the file is still the source of truth.
2. Title: the feature's `<short title>`. Body: the full `feat-NNN.md` contents.
3. Labels (skill taxonomy, see `~/Code/Projects/ClaudeBrain/workflow-documentation/github-labels.sh`):
   - always `type:feat`, `status:open`
   - `priority:<low|med|high>` — only if the `Priority` field was set
   - `bump:<patch|minor|major>` — only if the `Bump` field was set
4. Create it: `gh issue create --title "<title>" --body-file FEATURES/feat-NNN.md --label type:feat,status:open[,priority:X][,bump:X]`
5. If creation fails because a label is missing, run `github-labels.sh` once to create the
   taxonomy, then retry the `gh issue create`.
6. On success, add an `- Issue: <url>` line under the header in `feat-NNN.md`.

## Procedure

1. Resolve fields via Intake above.
2. Ensure `FEATURES/` exists (`mkdir -p FEATURES`).
3. Compute next `NNN` (scan `FEATURES/`, increment, zero-pad).
4. **Write immediately** — do NOT ask for confirmation after the TUI is submitted. TUI
   submission IS the confirmation. (Only the `/feat <text>` one-liner path may show a
   draft first, since it had no TUI step.)
5. Open the GitHub issue if applicable (see **GitHub issue** above).
6. Report the created path, the issue URL (if any), and a one-line summary.
