---
name: project-setup
description: Scaffold (or audit + repair) the agent working structure for a git project — a tracked `.project/` dir holding BACKLOG/, BUGS/, FEATURES/, DOCS/, TODO.md, and an issue.html dashboard, plus a WHITEBOARD.md and agent workflow rules in the project's CLAUDE.md. Idempotent. Only WHITEBOARD.md is gitignored (via the GLOBAL gitignore, never the project's). Trigger on "/project-setup", "set up agent project", "scaffold backlog and bugs".
---

# project-setup

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
├── .project/                # tracked (committed, NOT gitignored) — all agent working files
│   ├── BACKLOG/
│   │   ├── BACKLOG.md        # index / overview of backlog items
│   │   ├── backlog-001.md    # one file per item, zero-padded 3-digit, increments
│   │   └── completed/        # done items moved here (keeps their filename)
│   ├── BUGS/                 # bug-001.md — one file per bug (format owned by /bug)
│   ├── FEATURES/             # feat-001.md — one file per feature (format owned by /feat)
│   ├── TODO.md               # single-file todo list (format owned by /todo)
│   ├── issue.html            # at-a-glance dashboard: bugs + features + todos in one table
│   └── DOCS/                 # tracked repo knowledge
│       ├── SETUP-RUN.md      # how to set up, build, and run the repo
│       ├── definitions.md    # 1-3 sentence definitions of tech + repo terms
│       ├── ARCHITECTURE.md   # component map + data flow — how the pieces fit
│       ├── CONVENTIONS.md    # code style, naming, and patterns to follow here
│       ├── GOTCHAS.md        # non-obvious pitfalls and fragile spots
│       └── TESTING.md        # how to run and write tests
└── WHITEBOARD.md             # agent scratch space (gitignored) — stays at project root
```

Everything agent-facing now lives under `.project/` to keep the project root lean. The
only exception is `WHITEBOARD.md`, which stays at the root and is the sole gitignored
artifact.

Do NOT pre-create `backlog-001.md` / `bug-001.md` / `feat-001.md` on setup. Numbering
starts at `001` when the first real item is added later. Setup only creates the `.project/`
tree, `.project/BACKLOG/BACKLOG.md`, `.project/BACKLOG/completed/`, an empty
`.project/TODO.md`, the `.project/issue.html` dashboard, `WHITEBOARD.md`, and the `DOCS/`
seed files.

`WHITEBOARD.md` is the only gitignored artifact — it's ephemeral agent scratch space.
Everything under `.project/` is **committed**: `BACKLOG/`, `BUGS/`, `FEATURES/`, `TODO.md`,
`issue.html`, and `DOCS/` are durable project tracking and repo knowledge. None of these
are added to the gitignore. Each `DOCS/` seed file holds a one-line stub describing what
belongs in it; later sessions fill in the real content.

## Procedure

Run as a single audit-and-repair pass — same logic whether the project is fresh or
partially set up. For each item, act only if the target is missing/misplaced; never
clobber existing content.

1. **`.git` check** (above). Abort if missing.

2. **`.project/` dir.** If `.project/` missing → create it. This is the parent for
   everything below.

3. **Migration (audit case).** Move any pre-nesting layout into `.project/`. For each of
   `BACKLOG/`, `BUGS/`, `FEATURES/`, `DOCS/`, `TODO.md`, `issue.html` that exists at the
   **project root** (not already inside `.project/`), move it in:
   `git mv <path> .project/<path>` if tracked, plain `mv` otherwise. Also move any loose
   `backlog-*.md` / `bug-*.md` / `feat-*.md` at the project root into the matching
   `.project/<DIR>/`. Never overwrite a file that already exists at the destination —
   flag the collision to the user instead.

4. **BACKLOG.** Ensure `.project/BACKLOG/` exists. If a loose `BACKLOG.md` sits directly
   under `.project/` (not inside `BACKLOG/`), move it to `.project/BACKLOG/BACKLOG.md`.
   If `.project/BACKLOG/BACKLOG.md` is still missing → create it from the BACKLOG.md
   template. If `.project/BACKLOG/completed/` missing → create it.

5. **BUGS / FEATURES.** Ensure `.project/BUGS/` and `.project/FEATURES/` exist (empty is
   fine — the `/bug` and `/feat` skills own their file formats and numbering).

6. **TODO.md.** If `.project/TODO.md` missing → create it from the TODO.md template.

7. **issue.html.** If `.project/issue.html` missing → create it from the issue.html
   template below. Do NOT regenerate it if it already exists (it accumulates rows as
   items are added).

8. **DOCS.** Create `.project/DOCS/` if missing. For each seed file below, create it only
   if absent (never clobber filled-in docs). Each is created with its one-line stub. All
   are committed — do NOT gitignore them.

9. **WHITEBOARD.md.** If `WHITEBOARD.md` missing at the project **root** → create it from
   the WHITEBOARD template. If a lowercase `whiteboard.md` already exists, leave it — flag
   that both casings now exist and ask whether to rename.

10. **Global gitignore** (NOT the project `.gitignore`). Resolve it with
    `git config --global core.excludesfile` (here: `~/.gitignore_global`). Ensure
    `WHITEBOARD.md` is present, appended under an `# agent project structure` header if
    absent:
    ```
    WHITEBOARD.md
    ```
    If a lowercase `whiteboard.md` line exists, replace it with `WHITEBOARD.md` (don't
    duplicate). Only `WHITEBOARD.md` is gitignored — `.project/` is committed, so do NOT
    add it to any gitignore. If a prior run added `BACKLOG/`, `BUGS/`, or `.project/`
    lines to the global gitignore, remove them. Add the pattern only if absent — re-runs
    must not duplicate lines.

11. **Project `CLAUDE.md` workflow rules** (the project's committed `CLAUDE.md`, NOT the
    global one). These rules are project policy and belong in the repo's tracked
    `CLAUDE.md` — they are NOT gitignored.
    - If `CLAUDE.md` is missing at the project root → create it.
    - Append the rules block below, guarded by the marker comments so re-runs never
      duplicate it. If the marker `<!-- agent-project-setup:workflow-rules -->` is already
      present → leave it untouched (idempotent). The marker string is kept as
      `agent-project-setup:` for back-compat so projects set up under the old skill name
      are not re-appended to.
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

12. **Report.** List exactly what was created, moved, which `DOCS/` seed files were added,
    which gitignore lines were added/changed, and whether the `CLAUDE.md` workflow rules
    were added. If nothing was needed, say "already set up — no changes."

## Item formats (embedded — for adding items later, NOT created on setup)

When the user later adds a backlog item, use the format below. Numbering: scan the target
dir for the highest existing `backlog-NNN.md`, increment, zero-pad to 3 digits. First item
is `001`. Bugs are owned by `/bug` (`.project/BUGS/bug-NNN.md`), features by `/feat`
(`.project/FEATURES/feat-NNN.md`), todos by `/todo` (`.project/TODO.md`).

**.project/BACKLOG/backlog-NNN.md**
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
When done, move the file to `.project/BACKLOG/completed/` (filename unchanged).

## Templates created on setup

**.project/BACKLOG/BACKLOG.md**
```markdown
# Backlog

Index of backlog items. One file per item in this dir (`backlog-NNN.md`).
Completed items live in `completed/`.

## Open
<!-- - [001](backlog-001.md) — short title -->

## Completed
<!-- - [001](completed/backlog-001.md) — short title -->
```

**.project/TODO.md**
```markdown
# Todo

- [ ] [P3] <first item>
```

**.project/issue.html** — a static, dependency-free dashboard. The `/bug`, `/feat`, and
`/todo` skills inject a `<tr>` here whenever they add an item (and update the row on status
change). Setup creates it with an empty table body; do not populate rows on setup.
```html
<!doctype html>
<title>.project — issues</title>
<style>
  :root{color-scheme:light dark}
  body{font:14px/1.5 system-ui,sans-serif;margin:2rem;max-width:60rem}
  table{border-collapse:collapse;width:100%}
  th,td{text-align:left;padding:.4rem .6rem;border-bottom:1px solid #8884}
  th{font-weight:600;text-transform:uppercase;font-size:.72rem;letter-spacing:.04em;opacity:.7}
  a{color:inherit}
  .t-bug{color:#e5484d}.t-feat{color:#3b82f6}.t-todo{color:#f5a524}
  tr[data-status="done"] td,tr[data-status="resolved"] td,tr[data-status="closed"] td{opacity:.45;text-decoration:line-through}
</style>
<h1>.project issues</h1>
<table><thead><tr>
  <th>Type</th><th>ID</th><th>Title</th><th>Status</th><th>Priority</th><th>Created</th>
</tr></thead>
<tbody id="issues">
<!-- /issues --></tbody></table>
```

### issue.html row contract (shared by /bug, /feat, /todo)

Each capture skill keeps `.project/issue.html` in sync. The canonical rule:

1. **Requires the dashboard.** Only `/project-setup` creates `.project/issue.html`. If it's
   missing, the capture skill skips the sync and tells the user to run `/project-setup`.
2. **Build the row:**
   ```html
   <tr data-id="<type>-NNN" data-type="<type>" data-status="<status>">
     <td class="t-<type>"><type></td>
     <td><ID-CELL></td>
     <td><short title></td>
     <td><status></td>
     <td><priority-or-dash></td>
     <td><YYYY-MM-DD></td></tr>
   ```
   - `<type>` is `bug` | `feat` | `todo`.
   - `<ID-CELL>` is `<a href="<issue-url>">NNN</a>` when a GitHub issue was created for the
     item, else plain `NNN`. (Todos use their text as the ID cell if they have no NNN.)
   - Priority cell: `/feat` → Priority, `/bug` → Severity, `/todo` → the `Pn` tag; `—` if unset.
3. **Insert or replace.** If a `tr[data-id="<type>-NNN"]` already exists, replace that whole
   `<tr>` (handles status/priority updates). Otherwise insert the new row immediately before
   the `<!-- /issues -->` marker. Never duplicate a row for the same id.

### DOCS seed files

Each `.project/DOCS/` file is created with a heading and a one-sentence stub. Later sessions
replace the stub with real, repo-specific content.

**.project/DOCS/SETUP-RUN.md**
```markdown
# Setup & Run

How to set up the environment, build, and run this repo — prerequisites, install
commands, env vars, and the commands to start it locally.
```

**.project/DOCS/definitions.md**
```markdown
# Definitions

One-to-three-sentence definitions of the tech, domain terms, and project-specific
concepts used in this repo.
```

**.project/DOCS/ARCHITECTURE.md**
```markdown
# Architecture

The high-level component map and data flow — what the major pieces are and how they
fit together.
```

**.project/DOCS/CONVENTIONS.md**
```markdown
# Conventions

The code style, naming rules, and patterns to follow when working in this repo.
```

**.project/DOCS/GOTCHAS.md**
```markdown
# Gotchas

Non-obvious pitfalls, footguns, and fragile spots — the "looks wrong but isn't" notes
that save wasted cycles.
```

**.project/DOCS/TESTING.md**
```markdown
# Testing

How to run the test suite, how to write new tests, and which tests guard core behavior.
```

**WHITEBOARD.md** (project root)
```markdown
# Whiteboard

Agent scratch space — not human-facing. Entry format:
`## [TYPE:key|YYYY-MM-DD] description` — types: TASK, FINDING, DECISION.
```

## Rules

- Idempotent. Re-running on a fully set-up project changes nothing — the `CLAUDE.md`
  rules block is marker-guarded against duplication, and `issue.html` is left alone once
  it exists.
- Never write ignore patterns to the project `.gitignore` — global only, and only
  `WHITEBOARD.md` is ignored. The `CLAUDE.md` workflow rules and the entire `.project/`
  tree are committed on purpose; only `WHITEBOARD.md` is gitignored.
- Use `git mv` if the loose file is tracked, plain `mv` otherwise.
- Preserve existing file contents — only create when missing.
