---
name: agent-project-setup
description: Scaffold (or audit + repair) the agent working structure for a git project — tracked BACKLOG/ and BUGS/ dirs, a tracked DOCS/ knowledge dir, WHITEBOARD.md, and agent workflow rules in the project's CLAUDE.md. Idempotent. Only WHITEBOARD.md is gitignored (via the GLOBAL gitignore, never the project's). Trigger on "/agent-project-setup", "set up agent project", "scaffold backlog and bugs".
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
├── BACKLOG/              # tracked (committed, NOT gitignored)
│   ├── BACKLOG.md        # index / overview of backlog items
│   ├── backlog-001.md    # one file per item, zero-padded 3-digit, increments
│   ├── backlog-002.md
│   └── completed/        # done items moved here (keeps their filename)
├── BUGS/                 # tracked (committed, NOT gitignored)
│   └── bug-001.md        # one file per bug, zero-padded 3-digit, increments
├── WHITEBOARD.md         # agent scratch space (gitignored)
└── DOCS/                 # tracked repo knowledge (committed, NOT gitignored)
    ├── SETUP-RUN.md      # how to set up, build, and run the repo
    ├── definitions.md    # 1-3 sentence definitions of tech + repo terms
    ├── ARCHITECTURE.md   # component map + data flow — how the pieces fit
    ├── CONVENTIONS.md    # code style, naming, and patterns to follow here
    ├── GOTCHAS.md        # non-obvious pitfalls and fragile spots
    └── TESTING.md        # how to run and write tests
```

Do NOT pre-create `backlog-001.md` / `bug-001.md` on setup. Numbering starts at `001`
when the first real item is added later (see Item formats below). Setup only creates
dirs, `BACKLOG/BACKLOG.md`, `BACKLOG/completed/`, `WHITEBOARD.md`, and the `DOCS/` seed
files.

`WHITEBOARD.md` is the only gitignored artifact — it's ephemeral agent scratch space.
Everything else is **committed**: `BACKLOG/` and `BUGS/` are durable project tracking,
and `DOCS/` is durable repo knowledge for humans and agents alike. None of these are
added to the gitignore. Each `DOCS/` seed file holds a one-line stub describing what
belongs in it; later sessions fill in the real content.

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

5. **DOCS dir.** Create `DOCS/` if missing. For each seed file below, create it only if
   absent (never clobber existing docs — re-runs leave filled-in content alone). Each is
   created with its one-line stub from the DOCS seed templates section. `DOCS/` and its
   files are committed, so do NOT add them to the gitignore.

6. **Global gitignore** (NOT the project `.gitignore`). Resolve the global excludes
   file: `git config --global core.excludesfile` (here: `~/.gitignore_global`).
   Ensure `WHITEBOARD.md` is present, appended under an `# agent project structure`
   header if not already there:
   ```
   WHITEBOARD.md
   ```
   If a lowercase `whiteboard.md` line exists in that file, replace it with
   `WHITEBOARD.md` (don't add a duplicate). Only `WHITEBOARD.md` is gitignored —
   `BACKLOG/` and `BUGS/` are committed, so do NOT add them to the gitignore. If a
   prior run added `BACKLOG/` or `BUGS/` lines to the global gitignore, remove them.
   Add the pattern only if absent — re-runs must not duplicate lines.

7. **Project `CLAUDE.md` workflow rules** (the project's committed `CLAUDE.md`, NOT the
   global one). Unlike the directories/whiteboard above, these rules are project policy
   and belong in the repo's tracked `CLAUDE.md` — they are NOT gitignored.
   - If `CLAUDE.md` is missing at the project root → create it.
   - Append the rules block below, guarded by the marker comments so re-runs never
     duplicate it. If the marker `<!-- agent-project-setup:workflow-rules -->` is already
     present → leave it untouched (idempotent).
   ```markdown
   <!-- agent-project-setup:workflow-rules -->
   ## Agent Workflow Rules

   - Every feature gets its own git branch.
   - Every branch gets its own git worktree.
   - Branch names derive from the feature name:
     - A `feat-NNN` item → branch `feat-NNN`.
     - A `bug-NNN` item → branch `bug-NNN`.
     - Otherwise, derive a short kebab-case branch name from the feature's title.
   - If the branch name or worktree target is ambiguous, prompt the user with a TUI
     offering the candidate options instead of guessing.
   <!-- /agent-project-setup:workflow-rules -->
   ```

8. **Report.** List exactly what was created, moved, which `DOCS/` seed files were added,
   which gitignore lines were added/changed, and whether the `CLAUDE.md` workflow rules
   were added. If nothing was needed, say "already set up — no changes."

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

### DOCS seed files

Each `DOCS/` file is created with a heading and a one-sentence stub describing what it
should hold. Later sessions replace the stub with real, repo-specific content.

**DOCS/SETUP-RUN.md**
```markdown
# Setup & Run

How to set up the environment, build, and run this repo — prerequisites, install
commands, env vars, and the commands to start it locally.
```

**DOCS/definitions.md**
```markdown
# Definitions

One-to-three-sentence definitions of the tech, domain terms, and project-specific
concepts used in this repo.
```

**DOCS/ARCHITECTURE.md**
```markdown
# Architecture

The high-level component map and data flow — what the major pieces are and how they
fit together.
```

**DOCS/CONVENTIONS.md**
```markdown
# Conventions

The code style, naming rules, and patterns to follow when working in this repo.
```

**DOCS/GOTCHAS.md**
```markdown
# Gotchas

Non-obvious pitfalls, footguns, and fragile spots — the "looks wrong but isn't" notes
that save wasted cycles.
```

**DOCS/TESTING.md**
```markdown
# Testing

How to run the test suite, how to write new tests, and which tests guard core behavior.
```

## Rules

- Idempotent. Re-running on a fully set-up project changes nothing — the `CLAUDE.md`
  rules block is marker-guarded against duplication.
- Never write ignore patterns to the project `.gitignore` — global only, and only
  `WHITEBOARD.md` is ignored. The `CLAUDE.md` workflow rules, the `DOCS/` tree, and the
  `BACKLOG/` and `BUGS/` trees are written into the project's tracked files on purpose;
  only `WHITEBOARD.md` is gitignored.
- Use `git mv` if the loose file is tracked, plain `mv` otherwise.
- Preserve existing file contents — only create when missing.
