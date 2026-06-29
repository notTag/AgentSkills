---
name: fix-review
version: 1.0.0
description: |
  Apply code-review findings as safe, atomic per-finding commits in ANY git
  repo (no GSD / framework dependency). Reads findings from the conversation,
  a review file, or a GitHub PR; intelligently fixes each (read source → adapt →
  verify → commit), rolls back failures, skips-and-logs what it can't fix, and
  writes a fix report. Branch rule: related work → current branch; unrelated
  work → a new branch. Trigger on "/fix-review", "fix the review findings",
  "apply the code review", "fix the PR review".
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# fix-review: Apply code-review findings as atomic commits

Turn a set of code-review findings into one verified, atomic commit per finding,
in any git repository. This skill is **framework-agnostic** — it does not require
GSD, a phase directory, `gsd-tools`, or any project scaffolding. It works in a
plain repo with nothing but `git`.

It is the reusable distillation of the GSD `code-review-fix` workflow: same
fix-safety discipline (intelligent application, per-finding rollback, 3-tier
verification, skip-and-log, atomic commits), minus the phase/config/agent
coupling, plus an explicit branch-placement rule.

---

## Inputs (the skill resolves whichever is present)

Findings can come from any of these; pick the first that applies:

1. **The conversation** — a review just produced findings (e.g. a `/code-review`
   run, or a JSON/markdown list of findings already on screen). Use those
   directly. This is the common case.
2. **A file path** — `$ARGUMENTS` is a path to a review markdown/JSON file
   (e.g. `REVIEW.md`, `findings.json`). Read and parse it.
3. **A GitHub PR** — `$ARGUMENTS` is a PR number or URL (e.g. `15`,
   `https://github.com/owner/repo/pull/15`). Fetch review comments with
   `gh pr view <n> --comments` and `gh api` as needed.

If none is obvious and nothing is on screen, ask the user where the findings are
(`AskUserQuestion`).

A **finding** needs, at minimum: a target file (path, optionally `:line`), a
description of the problem, and ideally a suggested fix. Treat the suggested fix
as **guidance**, never a patch to blind-apply.

---

## Step 1: Gather findings

- Collect every finding into a normalized list: `{ id, severity, file, line,
  issue, fix_guidance, extra_files[] }`.
  - `id`: stable label (use the source's, e.g. `CR-01`, or synthesize `F1, F2…`).
  - `severity`: critical / warning / info if the source provides it; else `n/a`.
  - `extra_files`: any additional files named in the fix guidance (multi-file fix).
- **Scope default:** apply critical + warning. Include info findings only if the
  user passed `--all` or said so. Skip purely stylistic notes unless asked.
- If a finding has no actionable file or is pure opinion, mark it `skipped:
  not actionable` up front and move on.

---

## Step 2: Decide the branch (THE branch rule)

Determine **related vs unrelated**, then place commits accordingly.

```
related   → commit on the CURRENT branch
unrelated → create and switch to a NEW branch first
```

Decide like this:

1. Compute the current branch: `git branch --show-current`.
   - **Detached HEAD** → stop and tell the user; commits would be lost.
2. Identify the **default branch** (usually `main` or `master`):
   `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` (strip `origin/`),
   falling back to `main` then `master`.
3. **Hard rule — never commit fixes directly onto the default branch.** If the
   current branch IS the default branch, the work is treated as **unrelated** →
   always create a new branch.
4. Otherwise, judge relatedness by overlap between the findings' target files and
   the current branch's own changes:
   - `git diff <default>...HEAD --name-only` = files this branch already touches.
   - If the finding files overlap that set (or the findings came from reviewing
     **this** branch / its PR) → **related** → current branch.
   - If there's no overlap (the findings are about code this branch doesn't own)
     → **unrelated** → new branch.
5. **PR-sourced findings:** if findings came from PR #N and the current branch is
   that PR's head branch → related → current branch. If the current branch is
   *not* the PR branch, prefer checking out the PR branch
   (`gh pr checkout <n>`) so fixes update that PR; if that's not possible, branch
   off the PR head.
6. **When genuinely ambiguous**, ask with `AskUserQuestion` (related→current vs
   new branch), recommending the safer option. Don't silently guess on the
   default branch — there the rule already forces a new branch.

New-branch naming: `fix/<short-topic>-review` (e.g. `fix/launchatlogin-review`).
Create with `git switch -c <name>` from the current tip. Announce the chosen
branch before committing.

---

## Step 3: Apply each fix (intelligent, verified, atomic)

Process findings **most-severe first**. For each finding:

**a. Read the real source.** Open the cited file at the line, plus ±10 lines of
context. Read every `extra_files` entry in full. Confirm the code still matches
what the review described.

**b. Record the rollback set.** Note every file you're about to modify. Rollback
is `git checkout -- <file>` (atomic; safe because nothing is committed yet) —
**never** use Write to "restore" a file.

**c. Adapt, don't blind-apply.** If the code drifted from the review context but
the intent still holds, adapt the fix. If it changed so much the fix no longer
makes sense → `skipped: code context differs from review`, continue.

**d. Edit.** Prefer the `Edit` tool for targeted changes; `Write` only for full
rewrites. Apply to all referenced files. Respect the repo's `CLAUDE.md` /
conventions and match surrounding style.

**e. Verify (3 tiers):**
- **Tier 1 (always):** re-read the changed region; confirm the fix is present
  and surrounding code is intact (no corruption).
- **Tier 2 (when a checker exists):** quick syntax/parse check for the file type:
  - JS: `node -c file` · TS: `npx tsc --noEmit` (if tsconfig)
  - Python: `python -c "import ast; ast.parse(open('file').read())"`
  - JSON: parse it · Swift: `swiftc -parse file` or `swift build` if cheap
  - Shell: `bash -n file` · else skip to Tier 1.
  - **Only fail on NEW errors in the file you edited.** Pre-existing errors and
    errors in other files are not yours — proceed. If the checker can't handle
    the file type (e.g. `node -c` on JSX), fall back to Tier 1.
- **Tier 3 (fallback):** no checker for this type (`.md`, obscure langs) → accept
  Tier 1. Don't skip a fix merely because syntax-checking is unavailable.
- **On a genuine new failure** → run rollback (`git checkout --` each touched
  file), mark `skipped: fix caused errors, rolled back`, continue.

**f. Commit atomically.** One commit per finding, listing every modified file:
```bash
git add <files…> && git commit -m "fix: <id> <short description>"
```
- Use a conventional message; include the finding id. Examples:
  `fix: CR-01 call launchctl disable when launch-at-login turned off`,
  `fix: F3 restore sketchybar pkill fallback in BarControl.restart()`.
- Append the repo's commit trailer convention if it has one.
- If the commit fails after a good edit → rollback, mark `skipped: commit
  failed`, continue. Never leave uncommitted changes behind.

**g. Logic-bug caveat.** Syntax checks don't prove semantic correctness. If the
finding is a logic bug (wrong condition, off-by-one, bad state handling), commit
it but flag the report entry as `fixed (needs human verification)`.

**Counters:** use `N=$((N+1))` (not `((N++))`, which trips `set -e`).

---

## Step 4: Write the fix report

Write `REVIEW-FIX.md` in the repo root (or beside the source review file if one
was passed). Do **not** commit it by default — it's a working artifact; mention
its path and let the user decide. (Commit it only if they ask.)

```markdown
---
fixed_at: <ISO timestamp>
source: <conversation | path | PR #n>
branch: <branch commits landed on>
findings_in_scope: <count>
fixed: <count>
skipped: <count>
status: all_fixed | partial | none_fixed
---

# Code Review Fix Report

**Summary:** <in_scope> in scope · <fixed> fixed · <skipped> skipped
**Branch:** <branch>  (<related → current | unrelated → new>)

## Fixed
### <id>: <title>
- **Files:** `a`, `b`   **Commit:** <short hash>
- **Applied:** <what changed>   <"needs human verification" if logic bug>

## Skipped
### <id>: <title>
- **File:** `path:line`   **Reason:** <skip reason>
- **Original issue:** <from the review>
```

---

## Step 5: Present results

Inline summary: in-scope / fixed / skipped counts, the branch commits landed on,
and the report path. Then next steps that fit the situation:

- On a new branch → offer to open/refresh a PR (`gh pr create` / push).
- Skipped findings remain → list them briefly so the user can handle manually.
- Suggest re-running the review to confirm the fixes resolved the findings.

---

## Critical rules (carried over from the GSD fixer, de-coupled)

- **Read the real source before every fix** — review suggestions are guidance.
- **One atomic commit per finding**, all modified files listed.
- **Rollback is `git checkout -- <file>`** — atomic, never Write.
- **Skip-and-log** anything that won't apply cleanly; never force a broken fix.
- **Never leave uncommitted changes** — commit or roll back each finding.
- **Never commit fixes onto the default branch** — that's the unrelated path.
- **Respect repo conventions** (`CLAUDE.md`, style, commit trailers).
- **Don't touch code unrelated to the finding** — keep each fix narrowly scoped.
- **Don't run the full test suite between fixes** (too slow) — per-fix verify only.

## Optional: parallel/background fixing

For a large batch you may spawn a subagent (`Agent`) to apply a disjoint subset
of findings. If you do, give it its own git worktree (`isolation: "worktree"`)
so it never races the main working tree's index/HEAD, and have it follow the same
per-finding rollback + atomic-commit discipline. For small batches, just do it
inline — the worktree dance isn't worth it.
