# project-setup

Scaffold (or audit + repair) the agent working structure for a git project — a tracked `.project/` dir holding `BACKLOG/`, `BUGS/`, `FEATURES/`, `DOCS/`, `TODO.md`, and an `issue.html` at-a-glance dashboard, plus a `WHITEBOARD.md`. Idempotent. Only `WHITEBOARD.md` is gitignored (via the **global** gitignore, never the project's) and stays at the project root; everything under `.project/` is committed.

The `/bug`, `/feat`, and `/todo` skills write into `.project/` and keep `issue.html` in sync — each creates `issue.html` on demand if it does not exist yet.

Also writes a set of **agent workflow rules** into the project's committed `CLAUDE.md` (marker-guarded, so re-runs don't duplicate them):

- Every feature gets its own git branch.
- Every branch gets its own git worktree.
- Branch names derive from the feature name (`feat-NNN` → `feat-NNN`, `bug-NNN` → `bug-NNN`).
- Ambiguous branch/worktree target → prompt the user with a TUI offering options instead of guessing.

## Trigger
`/project-setup`, "set up agent project", "scaffold backlog and bugs".
