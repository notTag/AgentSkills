---
name: commit-audit
version: 1.0.0
description: |
  Audit the current project's git pre-commit hooks against the gates expected
  for its stack. Sniffs project type, inspects existing hook config, and
  returns a checklist of covered vs missing gates plus recommended additions.
  Read-only — does NOT run builds, linters, or tests.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Commit Audit

Audit whether the current repo's pre-commit gates match the stack. Read-only inspection. Output: checklist + recommendations.

## Step 1: Sniff project type

Check for these markers (in priority order, multiple may apply for polyglot repos):

- `package.json` → Node/JS/TS
  - Inspect `dependencies` + `devDependencies` to classify:
    - React/Next/Vue/Svelte/Angular/Solid/Remix/Astro → **web app**
    - `tsup`/`rollup`/`vite build --lib` → **library**
    - `express`/`fastify`/`hono`/`nestjs` → **node service**
    - Else → **generic node**
- `pyproject.toml` / `setup.py` / `requirements*.txt` → **python**
- `Cargo.toml` → **rust**
- `go.mod` → **go**
- `Gemfile` → **ruby**
- `composer.json` → **php**
- `pom.xml` / `build.gradle` → **java/jvm**

Also detect package manager: `bun.lockb` → bun, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm.

## Step 2: Inspect existing hook config

Check (in this order, skip if file absent):

- `.husky/` — list files, read each `pre-commit` / `commit-msg` / `pre-push`
- `package.json` → `lint-staged`, `husky`, `simple-git-hooks` keys
- `.pre-commit-config.yaml` — pre-commit framework
- `lefthook.yml` / `lefthook.yaml`
- `.githooks/` — custom hook dir (check `core.hooksPath` via `git config --get core.hooksPath`)
- `.git/hooks/` — raw hooks not starting with `.sample`
- CI config as fallback awareness: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/config.yml` (note but don't count as commit gate)

For each hook file found, parse what it actually runs (build, lint, format, type-check, tests, secret scan, etc.).

## Step 3: Build the expected-gates matrix

Baseline gates for every project:

- **Format** (prettier / ruff format / gofmt / rustfmt / etc.)
- **Lint** (eslint / ruff / clippy / golangci-lint / rubocop / etc.)
- **Lint auto-fix on staged files** (lint-staged or equivalent)
- **Unit tests** (fast subset, not full suite unless suite is quick)
- **Secret scan** (gitleaks / trufflehog) — always recommended

Stack-specific additions:

- **web app / node service / library:**
  - Build (`tsc --noEmit` at minimum, real build for libraries)
  - Type-check
- **python:**
  - Type-check (mypy/pyright) if project uses types
- **rust:**
  - `cargo check` (build) + `cargo clippy -- -D warnings`
- **go:**
  - `go vet` + `go build ./...`
- **java/jvm:**
  - Compile check

Monorepo signal: if `pnpm-workspace.yaml` / `turbo.json` / `nx.json` / `lerna.json` present, note that gates should run only on affected packages (lint-staged patterns or turbo filters).

## Step 4: Produce the checklist

Output format — one block per audit:

```
# Commit Audit: <repo name>

## Detected
- Stack: <type> (<pkg manager>)
- Hook runner: <husky|pre-commit|lefthook|none|raw>
- Currently runs on commit: <comma-sep list of gates>

## Gate Checklist
- [x] Format      — <tool> via <where>
- [x] Lint        — <tool> via <where>
- [ ] Lint-fix staged — MISSING
- [x] Type-check  — <tool> via <where>
- [ ] Build       — MISSING
- [ ] Unit tests  — MISSING
- [ ] Secret scan — MISSING

## Recommendations
1. <actionable change> — e.g. "Add `bun run build` to `.husky/pre-commit` after lint-staged"
2. <...>

## Notes
- <monorepo caveat, CI-covered-but-not-locally gate, anything worth flagging>
```

Rules:
- `[x]` only if gate actually runs on `git commit` (not just in CI).
- If a gate runs in CI but not locally, list under Notes, not as covered.
- Recommendations must be concrete: name the file, the line to add, the command.
- Do not recommend installing a new hook framework unless none exists.
- If `.husky` exists, recommend additions there — don't suggest switching to lefthook.

## Step 5: Output

Print only the audit block. No preamble, no "here's the audit" intro. One block, markdown, terminal-readable.
