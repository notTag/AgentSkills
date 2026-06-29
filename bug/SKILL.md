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
   `Resolved: <YYYY-MM-DD>` line under the header.
6. **Sync the GitHub issue** (only if `bug-NNN.md` has an `- Issue: <url>` line and `gh`
   is available): take the issue number `<n>` from that URL and run
   `gh issue edit <n> --add-label status:resolved --remove-label status:open` then
   `gh issue close <n>`. If it has no `- Issue:` line, skip silently.
7. Report the path, issue state, and a one-line summary.

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

## GitHub issue (when in a git repo)

After the file is written, if the current dir is a git repo with a GitHub `origin`
remote AND `gh` is available, also open a GitHub issue mirroring the bug:

1. Detect: `git remote get-url origin` matches `github.com` and `command -v gh` succeeds.
   If either fails, skip this whole step silently — the file is still the source of truth.
2. Title: the bug's `<short title>`. Body: the full `bug-NNN.md` contents.
3. Labels (skill taxonomy, see `~/Code/Projects/ClaudeBrain/workflow-documentation/github-labels.sh`):
   - always `type:bug`, `status:open`
   - `severity:<low|med|high|critical>` — only if the `Severity` field was set
   - `bump:<patch|minor|major>` — only if the `Bump` field was set
4. Create it: `gh issue create --title "<title>" --body-file BUGS/bug-NNN.md --label type:bug,status:open[,severity:X][,bump:X]`
5. If creation fails because a label is missing, run `github-labels.sh` once to create the
   taxonomy, then retry the `gh issue create`.
6. On success, add an `- Issue: <url>` line under the header in `bug-NNN.md`.

## Procedure

1. Resolve fields via Intake above.
2. Ensure `BUGS/` exists (`mkdir -p BUGS`).
3. Compute next `NNN` (scan `BUGS/`, increment, zero-pad).
4. **Write immediately** — do NOT ask for confirmation after the TUI is submitted. TUI
   submission IS the confirmation. (Only the `/bug <text>` one-liner path may show a
   draft first, since it had no TUI step.)
5. Open the GitHub issue if applicable (see **GitHub issue** above).
6. Report the created path, the issue URL (if any), and a one-line summary.
