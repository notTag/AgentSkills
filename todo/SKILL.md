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
- `/todo done <partial text>` → mark the matching item complete
- `/todo priority <partial text> <P1|P2|P3|P4>` → update priority tag on an item

## File location

Always look for `TODO.md` in the current working directory. If not found, say so and offer to create it.
