---
name: log-howto
description: Log a how-to Q&A from the current conversation as a standalone file in ClaudeBrain knowledge/howtos/. Use when user says "/log-howto", "log that how-to", or asks to save a how-to.
---

# log-howto

Save a how-to exchange as a standalone markdown file.

## Steps

1. **Identify exchange.** If user specified which (e.g. "log the how-to about tailscale"), use that. Otherwise use the most recent how-to Q&A in the conversation.
2. **Build slug** from task: kebab-case, lowercase, ≤6 words (e.g. `tailscale-localhost-phone.md`).
3. **Check collision.** If `~/Code/Projects/ClaudeBrain/knowledge/howtos/<slug>.md` exists, append `-2`, `-3`, etc.
4. **Write file** with this exact structure:

```markdown
# How to <task>

**Q:** <user's question verbatim>

**A:** <your answer, cleaned up — keep steps, commands, code blocks intact>

---

- Date: <YYYY-MM-DD>
- Time: <HH:MM TZ>
- Project: <absolute path of cwd where question was asked>
```

5. **Get timestamp + cwd** via a single short bash call: `date '+%Y-%m-%d %H:%M %Z' && pwd`
6. **Confirm** to user: file path + 1-line preview of title. Nothing else.

## Rules

- One file per how-to. No index file.
- Preserve code blocks, commands, and shell snippets exactly as given.
- If the Q&A isn't actually a how-to (user misfired), say so and ask before writing.
- Do NOT re-answer the question — only log what was already discussed.
