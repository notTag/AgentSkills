---
name: whiteboard-put
description: Capture relevant context from the current session into the project's whiteboard.md before /clear, so the next session can ramp up fast. Use when user says "/whiteboard-put", "save context", "checkpoint before clear", or signals they're about to /clear.
---

# whiteboard-put

Write a session ramp-up snapshot into `<cwd>/whiteboard.md` so the next conversation can recover context after `/clear`.

## Purpose

User is about to wipe context. Capture what matters: active task, decisions made, files touched, open questions, next step. Future-Claude reads this and resumes without re-asking.

## Steps

1. **Resolve path.** `<cwd>/whiteboard.md`. If missing, create with header from `workflow-documentation/claude-whiteboard-process.md` template if available, otherwise minimal header.
2. **Read current whiteboard** to avoid duplicating existing entries and to respect prune state.
3. **Audit conversation** for ramp-up-worthy signal:
   - Active task / current goal
   - Decisions reached (with rationale)
   - Findings / non-obvious discoveries
   - Files created or modified (absolute paths)
   - External resources referenced (URLs, MCP IDs, library IDs)
   - Open questions / parked threads
   - Immediate next step
4. **Skip noise:** trivial answers, command lookups already saved as how-tos, ephemeral debugging, anything already in `git log` or `MEMORY.md`.
5. **Build entry** using the project format from CLAUDE.md:

```markdown
## [TASK:<short-key>|YYYY-MM-DD] <one-line summary>

**Status:** active — context cleared <YYYY-MM-DD HH:MM>

**Goal:** <what we're trying to accomplish>

**Decisions:**
- <decision> — <why>

**Files touched:**
- `<absolute path>` — <what changed>

**Open questions:**
- <question>

**Next step:** <concrete next action>

**Ref:** <related entry keys, MEMORY refs, external URLs if any>
```

6. **Append** to whiteboard before the trailing `---`. Use Edit (anchor on last `---`) or Read+Write.
7. **Get timestamp** via single bash call: `date '+%Y-%m-%d %H:%M %Z'`.
8. **Confirm** to user: entry key + 1-line preview + remind them they can now `/clear` safely. Nothing else.

## Rules

- One entry per `/whiteboard-put` call — do not bulk-dump multiple sessions.
- Use TASK type for active work, DECISION for finalized choices, FINDING for discoveries.
- Key = kebab-case, ≤4 words, unique within whiteboard.
- Absolute paths only — relative paths break post-/clear.
- If conversation has no ramp-up-worthy signal, say so and ask before writing a stub.
- Never write secrets, API keys, or full file contents — use file path + summary.
- Do NOT modify other entries. Append only.
- After writing, check total whiteboard size; if >6KB, warn user to audit.
