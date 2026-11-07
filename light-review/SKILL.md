---
name: light-review
version: 1.0.0
description: |
  Review open PRs/MRs in the current repo, delete unnecessary code, push any
  needed fixes onto the PR branch, and merge each one judged worthy. Works with
  GitHub (gh) and GitLab (glab). Optional arg: PR/MR number(s); no arg = PR
  inferred from conversation context, else ask the user. Never sweeps all open
  PRs. Trigger on "/light-review", "light review this pr", "review and merge
  the pr", "review the mr".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - AskUserQuestion
---

# light-review: review → trim → fix → merge

Invoking this skill = authorization to push fixes to and merge the resolved
target PR(s) only, when they pass the bar below.

## Preconditions

1. Inside a git repo, else stop.
2. Host: `origin` URL contains `gitlab` → `glab`; else `gh`. Check auth
   (`gh auth status` / `glab auth status`). Not authed → ask user to run
   `! gh auth login` (or `! glab auth login`).
3. Default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
   (GitLab: `glab repo view -F json`). Fallback `main`.

## Targets

Never sweep all open PRs. Resolve exactly which PR(s), in this order:

1. Arg given → those numbers only.
2. No arg → infer from conversation context: a PR URL/number mentioned, a PR
   opened earlier this session, or the current branch's PR
   (`gh pr view --json number` on the checked-out branch) when this session
   has been working on that branch.
3. Still ambiguous or nothing found → ask via AskUserQuestion which PR to
   review (list a few open ones with
   `gh pr list --state open --json number,title,headRefName` / `glab mr list --opened`
   as options). Never guess.

- Draft PR → review and fix, but don't merge.
- Several PRs that stack (one's base = another's head) → merge the base first,
  then retarget/rebase the dependent.

## Per PR

### 1. Read it fully

- Description, diff (`gh pr diff <n>`), existing review comments, CI status
  (`gh pr checks <n>`).
- Read the files the diff touches, not just the hunks — understand the change
  end to end before judging it.

### 2. Work in a worktree

- `git fetch origin <head>` then
  `git worktree add ../<repo>-review-<n> origin/<head>`, check out the head
  branch there. Never edit in the main checkout.
- Fork PR (`isCrossRepository` true) or branch not pushable → no edits; review
  comment only, then judge merge on the code as-is.

### 3. Review

Look for, in order:
- Correctness bugs, security issues, data-loss paths → must fix.
- Unnecessary code → delete: dead code, unused imports/vars/params, debug
  prints, commented-out blocks, speculative abstractions (one-impl interfaces,
  unused config/flags), duplicated helpers that already exist in the repo,
  comments restating the code, stray temp/artifact files.
- Readability per global rules: decompose dense lines, descriptive names.
- Missing check: non-trivial logic with no test → add the smallest one.

Stay in the PR's scope. Unrelated issues → note in the report, don't fix.

### 4. Fix

- Make the edits in the worktree. Run the project's build/lint/tests (whatever
  the repo uses — check package.json / Makefile / go.mod / CI config).
- Commit in normal prose, one commit per logical fix, no assistant
  attribution trailer. Push to the PR head branch (no force-push unless a
  rebase was required, then `--force-with-lease`).
- Wait for CI to finish on the new head (`gh pr checks <n> --watch`).

### 5. Decide

Merge only if ALL hold:
- CI green (or no CI and local build/tests pass).
- No unresolved correctness/security concern.
- Mergeable (no conflicts; rebase onto default branch if trivially possible).
- The change does what its title/description says.
- No blocking review ("changes requested") from a human.

Otherwise don't merge: leave a review comment (`gh pr review <n> --comment`)
listing what blocks it, terse, TOF-GH style. If the PR is fundamentally
wrong (not fixable by trimming/small fixes) — comment, never close.

### 6. Merge

- Use a method the repo allows; prefer squash:
  `gh pr merge <n> --squash --delete-branch`
  (GitLab: `glab mr merge <n> --squash --remove-source-branch`).
- Squash commit body: no assistant attribution.

### 7. Cleanup (every PR, merged or not)

- `git worktree remove ../<repo>-review-<n>`.
- Merged → `git branch -d <head>` locally if it exists, `git worktree prune`.
- Ticket sync: if the PR title/body references `Ticket #N`, move it per the
  Project Tracker rules in global CLAUDE.md (merged → `in-dev`).

## Finish

- Main checkout: `git checkout <default> && git pull`.
- `git status` + `git worktree list` clean of review leftovers.

## Report

One line per PR:

```
#<n> <title> — merged | blocked: <reason> | skipped: <reason>
	trimmed: <what was deleted>
	fixed: <what was changed>
```

Then any out-of-scope issues noticed. Nothing else.
