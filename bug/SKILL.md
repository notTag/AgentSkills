---
name: bug
version: 1.0.0
description: |
  Capture a bug into the current project's BUGS/ directory as a numbered
  markdown file (bug-NNN.md). Parses a one-liner when given; falls back to
  interactive intake when fields are missing. Trigger on "/bug", "log a bug",
  "capture this bug", "file a bug".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# bug: Capture a bug to BUGS/bug-NNN.md

Log a bug as a numbered markdown file in the **current project's** `BUGS/` directory.
This skill owns the bug file format. (`agent-project-setup` only creates the `BUGS/`
dir; it does not define the per-bug template.)

## Location

- Always `<cwd>/BUGS/` — per-project, relative to the current working directory.
- If `BUGS/` does not exist, create it (`mkdir -p BUGS`). Do not require
  `agent-project-setup` to have run first.

## Numbering

1. Scan `BUGS/` for the highest existing `bug-NNN.md`.
2. Increment, zero-pad to 3 digits. First bug is `001`.
3. Filename: `bug-NNN.md` (lowercase `bug-`, uppercase `.md`, e.g. `bug-007.md`).

## Bug file format

```markdown
# [NNN] <short title>

- Status: open
- Created: <YYYY-MM-DD>
- Severity: <low|med|high|critical>
- Bump: <patch|minor|major>

## Repro
<steps to reproduce — STR>

## Expected
<expected result — ER>

## Actual
<actual result — AR>

## Notes
<environment, logs, suspected cause>
```

Field rules:
- `Status` — `open` on creation. Stays `open` through `update` and while a `fix` is in
  progress. Only set to `Resolved` once the user confirms the bug is fixed/acceptable.
- `Created` — today's date, `YYYY-MM-DD`.
- `Severity` — **optional**. Omit the line entirely if unknown/unset. Measures how bad.
- `Bump` — **optional** (Semantic Versioning bump level). Omit the line entirely if
  unset. Measures release impact. Severity and Bump are independent — include either,
  both, or neither.
- `## Notes` — **optional**. Omit the whole section if there's nothing to add.
- `Repro` / `Expected` / `Actual` — core fields, always present.

## Subcommands

- **`/bug`** or **`/bug <text>`** — create a new bug (see Intake / Create below).
- **`/bug update bug-XXX`** — edit an existing bug via the TUI (see Update below).
- **`/bug fix bug-XXX`** — work the bug toward a fix (see Fix below).

`bug-XXX` may be given as `bug-003`, `003`, or `3` — normalize to the zero-padded
`bug-NNN.md` file in `<cwd>/BUGS/`. If the file doesn't exist, say so and list the bugs
that do.

## Update (`/bug update bug-XXX`)

1. Read the existing `bug-NNN.md` and parse its current field values.
2. Run the **same two-batch TUI** as Create, but prepend each question with the current
   value as a selectable option so the user can keep it:
   - Core fields (Repro/Expected/Actual): options become `Keep current: "<value>"`,
     `Deduce from context`, `Deduce from chat` (+ auto Other to retype).
   - Severity / Semantic: the four/three fixed options — preselect/point out the current
     value; re-picking it keeps it. To clear an optional field, the user types `none` in
     Other.
   - Notes: `Keep current`, `Omit`, `Add from context`, `Add from chat` (+ auto Other).
3. For any question where the user picks the current value, leave that field unchanged.
   For any other selection, replace the field with the new value.
4. Preserve `Created`. Leave `Status` as-is (don't auto-resolve on update).
5. **Write immediately** on TUI submit — no extra confirmation. Report the path + what
   changed.

## Fix (`/bug fix bug-XXX`)

This subcommand works the bug toward an actual resolution — it is not just a status flip.

1. Read `bug-NNN.md`; understand Repro / Expected / Actual.
2. Investigate the relevant code/context. Ask any clarifying questions needed (TUI or
   inline) before attempting changes.
3. Attempt the fix in the codebase.
4. `Status` stays `open` throughout. Do **not** mark it resolved yourself.
5. When the user confirms the bug is fixed/acceptable, set `Status: Resolved` and add a
   `Resolved: <YYYY-MM-DD>` line under the header, then report.

## Intake

Glossary the user may use: **STR** = steps to reproduce (`## Repro`),
**ER** = expected result (`## Expected`), **AR** = actual result (`## Actual`).

- **`/bug <text>`** — parse `<text>` for repro, expected, and actual. If all three core
  fields are clearly captured, skip the TUI and go straight to writing (see Procedure).
- **`/bug` with no args, or gaps** — collect fields via the `AskUserQuestion` TUI below.

### TUI flow (AskUserQuestion)

`AskUserQuestion` allows **max 4 questions per call** and **2–4 options per question**;
a free-text **Other** field is auto-appended to every question — do NOT add an explicit
"Other" option. Collect in **two batches**:

**Batch 1 — core fields** (Repro, Expected, Actual). Options for each:
- `Deduce from context` — infer the field from project/codebase state.
- `Deduce from chat` — infer the field from this conversation.
- (auto Other) — user types the value as free text.

**Batch 2 — Severity, Semantic, Notes**:
- **Severity** — `low` / `med` / `high` / `critical`. Auto-Other allowed; if left
  unanswered, omit the line.
- **Semantic** (SemVer bump) — `patch` / `minor` / `major`. Optional; omit the line if
  unanswered.
- **Notes** — `Omit` / `Add from context` / `Add from chat` (auto Other to type). `Omit`
  drops the whole `## Notes` section.

Derive a concise `<short title>` from the bug (one line, no trailing period).

## Procedure

1. Resolve fields via Intake above.
2. Ensure `BUGS/` exists (`mkdir -p BUGS`).
3. Compute next `NNN` (scan `BUGS/`, increment, zero-pad).
4. **Write immediately** — do NOT ask for confirmation after the TUI is submitted. TUI
   submission IS the confirmation. (Only the `/bug <text>` one-liner path may show a
   draft first, since it had no TUI step.)
5. Report the created path and a one-line summary.
