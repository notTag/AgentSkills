---
name: log-definition
description: Log a definition Q&A from the current conversation as a standalone file in ClaudeBrain knowledge/definitions/. Use when user says "/log-definition", "log that definition", or asks to save a definition.
---

# log-definition

Save a definition exchange as a standalone markdown file.

## Steps

1. **Identify exchange.** If user specified which (e.g. "log the definition about X"), use that. Otherwise use the most recent definition Q&A in the conversation.
2. **Build slug** from topic: kebab-case, lowercase, ≤6 words (e.g. `event-loop-javascript.md`).
3. **Check collision.** If `~/Code/Projects/ClaudeBrain/knowledge/definitions/<slug>.md` exists, append `-2`, `-3`, etc.
4. **Write file** with this exact structure:

```markdown
# <Title of term being defined>

**Q:** <user's question verbatim>

**A:** <your answer, cleaned up — remove pleasantries, keep technical content>

---

- Date: <YYYY-MM-DD>
- Time: <HH:MM TZ>
- Project: <absolute path of cwd where question was asked>
```

5. **Get timestamp + cwd** via a single short bash call: `date '+%Y-%m-%d %H:%M %Z' && pwd`
6. **Confirm** to user: file path + 1-line preview of title. Nothing else.

## Rules

- One file per definition. No index file.
- If the Q&A isn't actually a definition (user misfired), say so and ask before writing.
- Do NOT re-answer the question — only log what was already discussed.
