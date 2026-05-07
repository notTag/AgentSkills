---
name: whiteboard-get
description: Retrieve and display the contents of the current project's whiteboard.md scratch file. Use when user says "/whiteboard-get", "show whiteboard", "read whiteboard", or asks what's on the whiteboard.
---

# whiteboard-get

Print the current project's `whiteboard.md` so Claude (and the user) can see active scratch state.

## Steps

1. **Locate file.** Resolve `<cwd>/whiteboard.md` (current working directory).
2. **Check existence.** If missing, tell user: `No whiteboard.md at <cwd>` — offer to create one. Stop.
3. **Check size.** If file >6KB, prepend a one-line warning: `⚠️ whiteboard >6KB — audit recommended (see CLAUDE.md)`.
4. **Read file** with the Read tool.
5. **Print contents verbatim** in a fenced markdown block. Do not summarize, reorder, or omit entries — Claude needs full structure to decide what's active vs. promotable.
6. **End with a one-line index** of entry keys: `Entries: brain-db, write-append-tools, eval-suite, mermaid-render` (parsed from `[TYPE:key|date]` headers).

## Rules

- Project-scoped only. Never read whiteboards from other projects unless user explicitly names a path.
- Do not edit, prune, or rewrite — read-only operation.
- If the file is empty or only has the header, say so plainly.
- No commentary on entry quality — just surface the data.
