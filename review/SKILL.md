---
name: review
version: 1.0.0
description: |
  Review a GitHub PR / GitLab MR at a chosen rigor level 1-10. 1 = light skim
  for obvious bugs; 10 = exhaustive review with rigorous security testing
  (threat model, dependency + secrets scans, SAST, adversarial tests run in a
  throwaway worktree). Read-only on the PR: reports findings, never pushes or
  merges. Args: `<pr-number> <level>` plus optional `--post` to post findings
  as a PR review comment. Trigger on "/review <n> <level>", "review pr <n> at
  level <x>", "rigor <x> review of pr <n>".
allowed-tools:
  - Bash
  - Read
  - Write
  - Agent
  - AskUserQuestion
---

# review: PR review on a 1-10 rigor dial

## Args

`/review <pr-number> <level> [--post]`

- `pr-number` required. Missing → infer from current branch's PR
  (`gh pr view --json number`); still nothing → AskUserQuestion with a few
  `gh pr list --state open` options. Never guess.
- `level` integer 1-10. Missing → default 5 and say so. Out of range / not an
  integer → clamp into 1-10 and say so.
- `--post` → after the report, post it as one PR review comment
  (`gh pr review <n> --comment --body-file <file>`), TOF-GH format. Without it,
  nothing leaves the terminal.

## Invariants (every level)

- Never push, merge, approve, request changes, or close. Fixing = `/fix-review`.
- Host: `origin` URL contains `gitlab` → `glab`, else `gh`. Check auth;
  not authed → ask user to run `! gh auth login`.
- Anything that executes PR code (tests, builds, PoCs) runs in a throwaway
  worktree `../<repo>-review-<n>`, removed at the end. Fork PRs from unknown
  authors: read before running — PR code can be hostile (postinstall scripts,
  test hooks). Unsure → don't execute, say so in the report.
- Every finding cites `file:line` and a concrete failure scenario. No
  "might be an issue" without one — verify or flag confidence per global rules.
- Rank most severe first: `critical` > `high` > `medium` > `low` > `nit`.

## Levels

Levels are cumulative: each tier includes everything below it.

### 1-2 — Light

- Read PR title/body + `gh pr diff <n>` only.
- Flag: obvious bugs, typos in logic, debug leftovers, hardcoded secrets
  visible in the diff, diff doesn't match description.
- Level 1: ≤3 findings, high-confidence only. Level 2: ≤5, add nits.

### 3-4 — Standard

- Read full files the diff touches, not just hunks. Check `gh pr checks <n>`.
- Correctness: edge cases (empty/null/zero/max), error handling, off-by-one,
  wrong conditions, resource leaks.
- Readability per global rules: dense lines, abbreviated names, comments
  compensating for unclear code, unnecessary code (dead, speculative, duplicated
  helpers that already exist in repo).
- Level 4: trace every caller of changed functions/signatures (fff grep).

### 5-6 — Thorough

- Check out in worktree; run the project's build, lint, tests (detect from
  package.json / Makefile / go.mod / Cargo.toml / CI config; prefer bun).
  Report failures with output.
- Test coverage: new non-trivial logic without a test → finding.
- Security pass on the diff: injection (SQL/shell/template/path), authz checks
  on new endpoints, input validation at trust boundaries, unsafe
  deserialization, secrets/PII in logs, new deps (name, maintainer, necessity).
- Concurrency: shared mutable state, races, missing locks/context cancellation.
- Level 6: API/contract changes — backward compat, migrations reversible,
  config/env changes documented.

### 7-8 — Deep

- Data flow: trace every untrusted input the PR touches from entry to sink.
- Failure modes: what happens on timeout, partial failure, retry, restart;
  idempotency of writes; data-loss paths.
- Performance: N+1 queries, unbounded loops/allocations, hot-path regressions.
- Dependency audit on changed manifests: `bun audit` / `npm audit` /
  `govulncheck ./...` / `pip-audit` / `cargo audit` — whichever exists.
- Secrets scan of the PR's commits (not just the final diff):
  `git log -p origin/<base>..origin/<head>` — invoke `/secrets-audit` logic
  scoped to that range.
- Level 8: second independent pass — spawn one `general-purpose` Agent with the
  diff + "find what the first reviewer missed", then verify each new claim
  yourself before including it.

### 9-10 — Rigorous + security testing

- Threat model the change (STRIDE-lite): assets touched, trust boundaries
  crossed, attacker-controlled inputs, privilege changes. Write it into the
  report.
- SAST if available: `semgrep --config auto <changed paths>`, `gosec`,
  `bandit`, `eslint-plugin-security` — use what's installed, don't install
  new global tools without asking.
- Adversarial tests: for each trust-boundary input, write and RUN tests in the
  worktree that attempt abuse — injection payloads, path traversal (`../`,
  absolute paths, symlinks), oversized/malformed input, auth bypass (missing,
  expired, other-tenant tokens), race/TOCTOU, integer overflow, unicode/
  encoding tricks. Tests stay in the worktree; never committed or pushed.
  Report each as pass/fail with output.
- Supply chain: new/changed deps — lockfile diff matches manifest, no
  typosquats, install scripts reviewed, pinned versions.
- Crypto/auth code touched → check algorithm choice, constant-time compares,
  randomness source, key/token lifetime and storage.
- Level 10: fan out parallel `general-purpose` Agents, one per dimension
  (correctness, security, concurrency/failure-modes, performance, tests),
  each with the diff + touched-file list. Then a verify pass: every finding
  either reproduced (test/PoC/trace) → `CONFIRMED`, or reasoned but unproven →
  `PLAUSIBLE`. Drop anything you can't defend. Level 10 has no finding cap.

## Report

Write to scratchpad `review-<n>-L<level>.md`, print it, give the full path.
Plain text in terminal; TOF-GH only if `--post`.

```
PR #<n> <title> — review level <L>/10
Verdict: ship | ship with fixes | blocked
CI: <green | red | none> · Tests run: <yes: pass/fail | no: why>

<severity> <file:line> — <one-line defect>
	scenario: <input/state → wrong result>
	fix: <smallest fix>
	[verdict: CONFIRMED | PLAUSIBLE]   (level 10)

Threat model: (level 9-10)
	<boundary> — <attacker input> — <mitigated? where>

Security tests: (level 9-10)
	<test name> — pass | FAIL — <one line>

Not checked: <what this level skipped that a higher one would cover>
```

## Cleanup

- `git worktree remove ../<repo>-review-<n>` and `git worktree prune`.
- Delete any scratch test files outside the worktree. `git status` in the main
  checkout must be unchanged from before the review.
- Keep the report file (user may pipe it into `/fix-review`).
