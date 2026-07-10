# agent-project-setup

Scaffold (or audit + repair) the agent working structure for a git project — tracked `BACKLOG/`, `BUGS/`, and `DOCS/` dirs plus a `WHITEBOARD.md`. Idempotent. Only `WHITEBOARD.md` is gitignored (via the **global** gitignore, never the project's); `BACKLOG/`, `BUGS/`, and `DOCS/` are committed.

Also writes a set of **agent workflow rules** into the project's committed `CLAUDE.md` (marker-guarded, so re-runs don't duplicate them):

- Every feature gets its own git branch.
- Every branch gets its own git worktree.
- Branch names derive from the feature name (`feat-NNN` → `feat-NNN`, `bug-NNN` → `bug-NNN`).
- Ambiguous branch/worktree target → prompt the user with a TUI offering options instead of guessing.

## Trigger
`/agent-project-setup`, "set up agent project", "scaffold backlog and bugs".
