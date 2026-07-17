---
name: session-handoff
description: Bridge context across a /clear. `/session-handoff` (or `put`/`save`) captures the current session state into <cwd>/.session-handoff.md so the next conversation resumes fast; `/session-handoff get` (or `restore`) reads it back after clearing. Latest-only — each capture overwrites the last. Use when the user is about to /clear, says "save context", "checkpoint", "handoff", "resume", or "restore session".
---

# session-handoff

A context bridge across `/clear`. NOT a live scratchpad, NOT a log — one snapshot,
overwritten each capture, read once on the far side.

File: `<cwd>/.session-handoff.md` (dot-prefixed, ephemeral, gitignored). Project-scoped only.

## Mode routing

Parse the argument (default `put` when none):

- `put` / `save` / `checkpoint` / no arg → **capture** (Capture steps)
- `get` / `restore` / `resume` → **restore** (Restore steps)

## Capture steps

1. **Audit the conversation** for what future-Claude needs to resume — no more:
   - Active task + goal (what we're doing and why)
   - Decisions reached, with one-line rationale each
   - Files created/modified — **absolute paths** + what changed
   - Non-obvious findings (things not re-derivable from the code or `git log`)
   - Open questions / parked threads
   - The immediate next step
2. **Skip noise:** trivial answers, command lookups, ephemeral debugging, anything
   already in `git log`, `git status`, `MEMORY.md`, or a committed file. If the code
   already says it, don't restate it.
3. **Write the snapshot** to `<cwd>/.session-handoff.md`, OVERWRITING any prior handoff.
   This is intentional — do NOT append, do NOT confirm the overwrite (overwriting the
   stale handoff every clear is the whole point). Use this shape:

```markdown
# Session Handoff — <YYYY-MM-DD HH:MM ZZZ>

**Goal:** <what we're trying to accomplish>

**State:** <where things stand right now, 1-3 lines>

**Decisions:**
- <decision> — <why>

**Files touched:**
- `<absolute path>` — <what changed / current state>

**Open questions:**
- <question>

**Next step:** <the concrete next action to take on resume>

**Refs:** <URLs, MCP/library IDs, branch name, PR link — only if relevant>
```

4. **Timestamp** via one bash call: `date '+%Y-%m-%d %H:%M %Z'`.
5. **Confirm** to the user: file path + bytes + a reminder they can `/clear` safely,
   then `/session-handoff get` to resume. Nothing else.

## Restore steps

1. Resolve `<cwd>/.session-handoff.md`. If missing → tell the user plainly there's no
   handoff here and stop.
2. **Read it and internalize** — this is your ramp-up context, treat it as active state.
3. **Print it verbatim** in a fenced block so the user sees what you loaded.
4. **State the next step** from the handoff in one line, then continue the work.
5. Do NOT delete the file — leave it until the next capture overwrites it.

## Rules

- Latest-only: capture always overwrites. Never accumulate entries — that bloat is
  exactly what made the old whiteboards go stale and unused.
- Absolute paths only — relative paths break after `/clear`.
- Never write secrets, API keys, tokens, or full file contents — path + summary only.
- Project-scoped: never read/write another project's handoff unless the user names a path.
- If the session has nothing resume-worthy, say so and ask before writing a stub.
- This replaces the put/clear/get whiteboard flow. The whiteboard (if used at all) is
  for a live typed-entry scratchpad; the handoff is a single ephemeral bridge.
