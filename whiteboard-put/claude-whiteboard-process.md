# Claude Whiteboard Process

A lightweight system for giving Claude persistent scratch space during complex tasks,
without polluting CLAUDE.md with temporary state.

---

## The Problem

Claude loses intermediate working state between sessions. Rediscovering context
(file paths, decisions made, things tried) wastes time and context window. At the
same time, CLAUDE.md should stay clean — it's for instructions, not notes.

---

## The Solution: whiteboard.md

A project-level scratch file with two sections:

### PINNED
Persistent facts that survive task completion. Things like discovered library IDs,
key architectural decisions, or non-obvious project quirks. This is a **staging area**
— if something stays pinned long enough to matter, it should be promoted to CLAUDE.md.

### ENTRIES
Keyed sections for active working state. Each entry has a typed key for fast retrieval:

```
## [TASK:key] Short description
## [SESSION:date] Short description
## [FINDING:key] Short description
## [DECISION:key] Short description
```

Claude can `grep` for a key and pull just that section rather than loading the whole file.

---

## Size Management

- **Target size:** ~5KB
- **Audit threshold:** 6KB (20% over target)
- **When:** Claude checks file size at the start of every session

### Audit rules
- Completed tasks → summarize to one line or remove
- Redundant entries → merge
- Stale PINNED items → promote to CLAUDE.md or drop
- PINNED section is never auto-purged — only manually reviewed

---

## Relationship to CLAUDE.md

| | CLAUDE.md | whiteboard.md |
|---|---|---|
| **Purpose** | Instructions & conventions | Working state & findings |
| **Lifespan** | Permanent | Ephemeral (with PINNED exception) |
| **Loaded** | Always | On demand (grep by key) |
| **Written by** | Human or Claude (deliberately) | Claude during tasks |

**Rule of thumb:**
- Still relevant after the task is done → CLAUDE.md
- Might become permanent → whiteboard PINNED
- Task-specific scratch → whiteboard body

---

## Session Start Checklist

1. Check `whiteboard.md` file size
2. If over 6KB → audit before proceeding
3. Scan PINNED for items ready to promote to CLAUDE.md
4. Write new entries as work progresses using typed keys
