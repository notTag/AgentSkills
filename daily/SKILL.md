---
name: daily
description: Summarize current session into ~/.claude/daily-tracker.md then prompt /clear. Records session start/end timestamps from the transcript (falls back to current time). Trigger on "/daily", "log and clear", "summarize session".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

<objective>
Summarize current session into global daily tracker at ~/.claude/daily-tracker.md, stamped
with the transcript's actual time range, then prompt user to /clear.
</objective>

<steps>

## Step 1 — Locate current session transcript

Resolve across Claude profile dirs (supports ~/.claude, ~/.claude-wakelax, ~/.claude-daivergent, etc):

```bash
python3 - <<'PY'
import os, glob
cwd_slug = os.getcwd().replace('/', '-')
candidates = []
for base in glob.glob(os.path.expanduser("~/.claude*")):
    patt = os.path.join(base, "projects", f"*{cwd_slug}", "*.jsonl")
    candidates.extend(glob.glob(patt))
if not candidates:
    print("NO_TRANSCRIPT")
else:
    print(max(candidates, key=os.path.getmtime))
PY
```

## Step 2 — Extract messages + timestamps

Read the transcript JSONL. For each line, parse JSON and collect:
- `timestamp` field (ISO 8601, if present)
- assistant text blocks (type=="assistant", content blocks where type=="text")

Record:
- **session_start** = earliest timestamp found
- **session_end**   = latest timestamp found
- If no timestamps available → use current local date/time for both and note `(approx)`.

Convert timestamps to local time, format: `YYYY-MM-DD HH:MM`.

## Step 3 — Summarize

5-10 concise bullets of what was accomplished. Decisions, files created/modified, config
changes, features/workflows built, problems solved. No tool-call details, no file contents,
no low-level steps.

## Step 4 — Append to tracker

Append to `~/.claude/daily-tracker.md`:

```
[project-name] [session_start → session_end]
	- bullet
	- bullet
```

If transcript timestamps missing:

```
[project-name] [YYYY-MM-DD HH:MM (approx, current time)]
	- bullet
```

Create file with `# Daily Tracker` header if absent.

## Step 5 — Prompt user

Show bullets + time range to user. Ask them to run /clear.

</steps>
