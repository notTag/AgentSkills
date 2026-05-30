---
name: agent-project-setup
description: Scaffold (or audit + repair) the agent working structure for a git project — BACKLOG/, BUGS/, and WHITEBOARD.md. Idempotent. Adds ignore patterns to the GLOBAL gitignore, never the project's. Trigger on "/agent-project-setup", "set up agent project", "scaffold backlog and bugs".
---

# agent-project-setup

Stand up the standard agent working structure in the current project, OR audit an
existing project and repair whatever is missing/misplaced. Safe to run repeatedly.

## Precondition

A `.git` directory MUST exist in the current working directory (the project root).

1. Check: is there a `.git` dir in cwd? `test -d .git`
2. If absent → STOP. Tell user this is not a git project root, offer `git init`, do
   nothing else. Do not create structure in a non-repo.

## Target structure

```
<project-root>/
├── BACKLOG/
│   ├── BACKLOG.md        # index / overview of backlog items
│   ├── backlog-001.md    # one file per item, zero-padded 3-digit, increments
│   ├── backlog-002.md
│   └── completed/        # done items moved here (keeps their filename)
├── BUGS/
│   └── bug-001.md        # one file per bug, zero-padded 3-digit, increments
└── WHITEBOARD.md         # agent scratch space
```

Do NOT pre-create `backlog-001.md` / `bug-001.md` on setup. Numbering starts at `001`
when the first real item is added later (see Item formats below). Setup only creates
dirs, `BACKLOG/BACKLOG.md`, `BACKLOG/completed/`, and `WHITEBOARD.md`.

## Procedure

Run as a single audit-and-repair pass — same logic whether the project is fresh or
partially set up. For each item, act only if the target is missing/misplaced; never
clobber existing content.

1. **`.git` check** (above). Abort if missing.

2. **BACKLOG dir.**
   - If `BACKLOG/` missing → create it.
   - **Migration:** if a loose `BACKLOG.md` exists at the project root (not inside
     `BACKLOG/`), move it: `mv BACKLOG.md BACKLOG/BACKLOG.md`. This is the audit case —
     "BACKLOG.md exists but isn't in a BACKLOG dir".
   - If `BACKLOG/BACKLOG.md` still missing → create it from the BACKLOG.md template.
   - If `BACKLOG/completed/` missing → create it.
   - **Migration:** any loose `backlog-*.md` at project root → move into `BACKLOG/`.

3. **BUGS dir.**
   - If `BUGS/` missing → create it.
   - **Migration:** any loose `bug-*.md` at project root → move into `BUGS/`.

4. **WHITEBOARD.md.**
   - If `WHITEBOARD.md` missing at project root → create it from the WHITEBOARD
     template. If a lowercase `whiteboard.md` already exists, leave it — flag to user
     that both casings now exist and ask whether to rename.

5. **Global gitignore** (NOT the project `.gitignore`). Resolve the global excludes
   file: `git config --global core.excludesfile` (here: `~/.gitignore_global`).
   Ensure these patterns are present, appended under an `# agent project structure`
   header if not already there:
   ```
   BACKLOG/
   BUGS/
   WHITEBOARD.md
   ```
   If a lowercase `whiteboard.md` line exists in that file, replace it with
   `WHITEBOARD.md` (don't add a duplicate). Add each pattern only if absent — re-runs
   must not duplicate lines.

6. **Report.** List exactly what was created, moved, and which gitignore lines were
   added/changed. If nothing was needed, say "already set up — no changes."

## Item formats (embedded — for adding items later, NOT created on setup)

When the user later adds a backlog item or bug, use these formats. Numbering: scan the
target dir for the highest existing `backlog-NNN.md` / `bug-NNN.md`, increment, zero-pad
to 3 digits. First item is `001`.

**backlog-NNN.md**
```markdown
# [NNN] <short title>

- Status: open
- Created: <YYYY-MM-DD>
- Priority: <low|med|high>

## What
<one-paragraph description of the work>

## Why
<value / motivation>

## Acceptance
- [ ] <criterion>
```
When done, move the file to `BACKLOG/completed/` (filename unchanged).

**bug-NNN.md** — this skill does NOT define the bug format. It only creates the
`BUGS/` dir. The `/bug` skill owns the per-bug file template and numbering. To add a
bug, use `/bug`.

## Templates created on setup

**BACKLOG/BACKLOG.md**
```markdown
# Backlog

Index of backlog items. One file per item in this dir (`backlog-NNN.md`).
Completed items live in `completed/`.

## Open
<!-- - [001](backlog-001.md) — short title -->

## Completed
<!-- - [001](completed/backlog-001.md) — short title -->
```

**WHITEBOARD.md**
```markdown
# Whiteboard

Agent scratch space — not human-facing. Entry format:
`## [TYPE:key|YYYY-MM-DD] description` — types: TASK, FINDING, DECISION.
```

## Rules

- Idempotent. Re-running on a fully set-up project changes nothing.
- Never write ignore patterns to the project `.gitignore` — global only.
- Use `git mv` if the loose file is tracked, plain `mv` otherwise.
- Preserve existing file contents — only create when missing.
