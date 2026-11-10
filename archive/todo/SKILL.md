---
name: todo
version: 1.0.0
description: |
  Display the .project/TODO.md file with incomplete items sorted by priority at the top
  and completed items grouped at the bottom. Supports adding, completing, and
  prioritizing items, and keeps the .project/issue.html dashboard in sync.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# Todo: Display and Manage .project/TODO.md

Read and display `.project/TODO.md` from the current working directory, sorted so that incomplete high-priority items appear first and completed items are grouped at the bottom.

## Priority convention

Items may have an optional priority tag at the start of their label:

- `[P1]` — critical / do first
- `[P2]` — high priority
- `[P3]` — normal (default if no tag)
- `[P4]` — low / someday

Example:
```
- [ ] [P1] Set up GSD plugin for Claude Code
- [ ] [P3] Dockerize Claude Code
- [x] Set up Humanizer
```

## Display behavior

1. Read `.project/TODO.md`.
2. Within each section, separate items into **incomplete** and **complete** buckets.
3. Sort incomplete items: P1 → P2 → P3 → P4 → untagged (treated as P3).
4. Append complete items after all incomplete items within their section.
5. Print the full sorted list — sections and headings preserved. Always display items with literal `[x]` (complete) and `[ ]` (incomplete) markers. Do NOT use rendered markdown checkboxes.
6. After displaying, offer a one-line prompt: "Add item, mark complete, or set priority? (or press enter to skip)"

## Handling args

- `/todo` with no args → display sorted list
- `/todo add <text>` → append a new incomplete item; ask for priority if not specified.
  Then sync the row into `.project/issue.html` (see **issue.html dashboard sync**).
- `/todo done <partial text>` → mark the matching item complete. If the item line has a
  trailing ` (#<n>)` and `gh` is available, also `gh issue close <n>` (skip silently
  otherwise). Todo issues carry no `status:*` label, so closing is the only sync needed.
  Then flip the matching row's `data-status="done"` in `.project/issue.html`.
- `/todo priority <partial text> <P1|P2|P3|P4>` → update priority tag on an item, then
  update that row's Priority cell in `.project/issue.html`.

## GitHub issue (when in a git repo)

On **`/todo add`** only (not on display, `done`, or `priority`), if the current dir is a
git repo with a GitHub `origin` remote AND `gh` is available, also open a GitHub issue
mirroring the new item:

1. Detect: `git remote get-url origin` matches `github.com` and `command -v gh` succeeds.
   If either fails, skip this step silently — `TODO.md` is still the source of truth.
2. Title: the item text (without the `[Pn]` tag). Body: the item line verbatim.
3. Labels (skill taxonomy, see `~/Code/Projects/ClaudeBrain/workflow-documentation/github-labels.sh`):
   - always `type:todo`
   - the priority tag as its own label: `P1` / `P2` / `P3` / `P4` (untagged → `P3`)
4. Create it: `gh issue create --title "<text>" --body "<item line>" --label type:todo,P3`
5. If creation fails because a label is missing, run `github-labels.sh` once to create the
   taxonomy, then retry.
6. On success, append ` (#<n>)` to the item line in `.project/TODO.md` so the entry links
   to its issue.

## issue.html dashboard sync

`.project/issue.html` is a static, dependency-free dashboard listing all bugs, features,
and todos in one table. Keep it in sync on `/todo add`, `/todo done`, and `/todo priority`.

1. **Requires the dashboard.** `.project/issue.html` is created by `/project-setup` and is
   the single source of its structure. If it's missing, skip this sync and tell the user to
   run `/project-setup` — never create it here.
2. **Row key.** Todos have no `NNN`. Use `data-id="todo-<n>"` when a GitHub issue `#<n>`
   was created; otherwise `data-id="todo-<slug>"` where `<slug>` is a short kebab-case
   slug of the item text (stable so `done`/`priority` can find the row again).
3. **Build the row** (on `/todo add`, after the GitHub issue step so the link is known):
   ```html
   <tr data-id="todo-<key>" data-type="todo" data-status="open">
     <td class="t-todo">todo</td>
     <td><ID-CELL></td>
     <td><item text, without the [Pn] tag></td>
     <td>open</td>
     <td><Pn></td>
     <td><YYYY-MM-DD></td></tr>
   ```
   - `<ID-CELL>` is `<a href="<issue-url>">#<n></a>` when a GitHub issue was created, else `—`.
   - Priority cell: the `Pn` tag (untagged → `P3`).
4. **Insert or replace.** If the `tr[data-id]` already exists, replace it; otherwise insert
   before the `<!-- /issues -->` marker. On `/todo done`, set that row's
   `data-status="done"`. On `/todo priority`, update its Priority cell. Never duplicate a
   row for the same id.

## File location

Always look for `.project/TODO.md` in the current working directory. If not found, say so
and offer to create it (`mkdir -p .project` first).
