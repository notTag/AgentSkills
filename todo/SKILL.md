---
name: todo
version: 1.0.0
description: |
  Display the TODO.md file with incomplete items sorted by priority at the top
  and completed items grouped at the bottom. Supports adding, completing, and
  prioritizing items.
allowed-tools:
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Todo: Display and Manage TODO.md

Read and display `TODO.md` from the current working directory, sorted so that incomplete high-priority items appear first and completed items are grouped at the bottom.

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

1. Read `TODO.md`.
2. Within each section, separate items into **incomplete** and **complete** buckets.
3. Sort incomplete items: P1 → P2 → P3 → P4 → untagged (treated as P3).
4. Append complete items after all incomplete items within their section.
5. Print the full sorted list — sections and headings preserved. Always display items with literal `[x]` (complete) and `[ ]` (incomplete) markers. Do NOT use rendered markdown checkboxes.
6. After displaying, offer a one-line prompt: "Add item, mark complete, or set priority? (or press enter to skip)"

## Handling args

- `/todo` with no args → display sorted list
- `/todo add <text>` → append a new incomplete item; ask for priority if not specified
- `/todo done <partial text>` → mark the matching item complete. If the item line has a
  trailing ` (#<n>)` and `gh` is available, also `gh issue close <n>` (skip silently
  otherwise). Todo issues carry no `status:*` label, so closing is the only sync needed.
- `/todo priority <partial text> <P1|P2|P3|P4>` → update priority tag on an item

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
6. On success, append ` (#<n>)` to the item line in `TODO.md` so the entry links to its issue.

## File location

Always look for `TODO.md` in the current working directory. If not found, say so and offer to create it.
