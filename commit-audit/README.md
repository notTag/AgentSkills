# commit-audit

Audit the current project's git pre-commit hooks against the gates expected for its stack. Sniffs project type, inspects existing hook config, and returns a checklist of covered vs missing gates plus recommended additions.

**Read-only** — does NOT run builds, linters, or tests.

## Trigger
`/commit-audit`, "audit my commit hooks", "check pre-commit gates".
