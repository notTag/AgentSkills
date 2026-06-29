---
name: pr
version: 1.0.0
description: |
  Branch + PR the current work in one shot. Creates a branch (if not already on
  one) containing the existing work relevant to what is currently being worked
  on, pushes it, opens a PR branch-name -> main, and posts the PR link.
  Trigger on "/pr", "open a pr", "make a pr for this", "branch and pr this".
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# pr: Branch current work and open a PR to main

One-shot flow: figure out what "the current work" is, get it onto its own
branch, push, open a PR against the default branch, and post the link.

## Preconditions

1. Must be inside a git repo. If not, stop and say so.
2. `gh` must be authenticated (`gh auth status`). If not, ask the user to run
   `! gh auth login`.
3. Determine the default branch (`gh repo view --json defaultBranchRef` or
   `git symbolic-ref refs/remotes/origin/HEAD`). Fall back to `main`. Referred
   to as `main` below.
4. If no remote exists, ask before creating one (`gh repo create --private
   --source . --push`) — never publish a repo without confirmation.

## Identify the current work

"Current work" = the changes relevant to what this session is working on:

- Uncommitted changes (staged + unstaged + untracked) related to the current
  task in conversation context.
- Plus any commits already on the current branch that aren't on `main`
  (when already on a feature branch).

Do NOT sweep in unrelated dirty files (stray `.DS_Store`, unrelated edits from
other tasks). When the working tree mixes relevant and unrelated changes,
stage only the relevant paths. If relevance is genuinely ambiguous, ask via
AskUserQuestion with the file list — don't guess.

## Branch

- **Already on a non-`main` branch** → use it. No new branch.
- **On `main`** → create one: `git checkout -b <branch-name>`. Name it
  `<type>/<2-4-word-kebab-slug>` from the current work (e.g.
  `feat/pr-skill`, `fix/auth-timeout`, `docs/system-design-update`).
  Uncommitted changes carry over to the new branch automatically.

## Commit

- If relevant uncommitted changes exist: stage only those paths and commit
  with a clear conventional message describing the work (normal prose, not
  caveman). End the message with the standard co-author trailer if the work
  was Claude-assisted.
- If everything relevant is already committed: skip.
- If there is nothing to PR at all (no diff vs `main`): stop and report that.

## Push + PR

1. `git push -u origin <branch>`
2. Reuse an existing open PR for this branch if one exists
   (`gh pr view --json url` succeeds) — don't create a duplicate.
3. Otherwise: `gh pr create --base main --head <branch>` with:
   - Title: concise summary of the work.
   - Body: short bullets of what changed + why, ending with:
     `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## Report

Post exactly: branch name, `branch -> main`, and the PR URL on its own line
so it's clickable. Nothing else needed.
