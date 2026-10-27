---
name: worktree
version: 1.0.0
description: |
  Isolate the following work in its own git worktree + branch off latest main,
  because another agent is working in the same repo checkout. Creates the
  worktree as a sibling dir, then does ALL subsequent work there — never in the
  main checkout. Trigger on "/worktree", "/wt", "use a worktree", "another agent
  is in this repo", "isolate this work".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# worktree: isolated worktree + branch for the following work

Another agent shares this repo's main checkout. Treat that checkout as
read-only for the rest of the task: no `checkout`, `switch`, `stash`, `reset`,
`commit`, or file edits there.

## Steps

1. Resolve the main checkout (works from inside a worktree too):
   `repo_root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")`
2. Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD` → strip
   `origin/`; fall back to `main`. No remote → base off local `main`.
3. `git fetch origin <default>` so the base is latest.
4. Branch name from the work described in the args / next message:
   `<feat|fix|chore|docs>/<2-4-word-kebab-slug>`. No description yet → ask for
   one, don't invent.
5. Worktree dir: `<repo_root>/../<repo>-<slug>` (sibling of the repo).
   `git worktree add <dir> -b <branch> origin/<default>`
   - Branch already exists → reuse it: `git worktree add <dir> <branch>`.
   - Dir already exists → it's likely a prior run; confirm before reusing.
6. `cd <dir>` and stay there. Use absolute paths under `<dir>` for every
   Read/Edit/Write — paths into the main checkout are a bug.
7. Project needs deps (lockfile present, no `node_modules` etc.) → install in
   the worktree (`bun install` preferred).

## Report

One line each: worktree path, branch `<branch>` ← `origin/<default>`. Then
start on the work.

## Done

Commits + PR happen from the worktree.

## Cleanup (once the MR is merged)

Confirm merged first (`gh pr view <branch> --json state` → `MERGED`). Then
delete the worktree + branch — not optional, part of finishing the task:

1. `cd <repo_root>` — can't remove the worktree you're standing in.
2. `git worktree remove <dir>` (dir already gone → `git worktree prune`).
3. `git branch -d <branch>`. Squash/rebase merges make `-d` refuse → confirm
   with the user before `-D`, never force silently.
4. Remote branch still exists (GitHub didn't auto-delete) →
   `git push origin --delete <branch>`.
5. `git worktree list` → no entry for `<dir>`, nothing prunable.
6. Pull the merged work into local `<default>`:
   - Main checkout on `<default>` → `git -C <repo_root> pull --ff-only`.
   - On another branch → `git fetch origin <default>:<default>` (updates the
     ref without touching that checkout's working tree).
