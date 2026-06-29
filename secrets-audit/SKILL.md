---
name: secrets-audit
version: 1.0.0
description: |
  Scan a git repo's FULL history (every blob in every commit, not just the working
  tree) for leaked secrets: API keys, tokens, private keys, and credentialed
  connection strings. Separates real exposures from benign placeholders (localhost
  DSNs, test fixtures, *.example templates) and renders a PASS / EXPOSED verdict.
  Read-only — never rewrites history or modifies files. Designed to run BEFORE
  flipping a repo public, or as a post-publish check.
trigger: |
  Invoke when user types /secrets-audit, "audit secrets", "scan for leaked keys",
  "check git history for secrets", or before/after making a repo public.
  Accepts an optional path argument (defaults to cwd / repo root):
    /secrets-audit                 → scan current repo's full history
    /secrets-audit ~/Code/foo      → scan a specific repo
    /secrets-audit --worktree      → scan only the working tree (fast, shallow)
allowed-tools:
  - Bash
  - mcp__plugin_context-mode_context-mode__ctx_execute
---

# secrets-audit

Find credentials leaked into a git repository. The key idea: **a repo going public
exposes its entire history, not just `HEAD`.** A secret deleted in a later commit is
still trivially recoverable from the blob it was committed in. So the scan walks
every reachable object (`git rev-list --all`), not just the current tree.

## Why two passes

1. **Broad net** — match anything *shaped* like a secret (high recall, many false
   positives). This is the same everywhere; never weaken it.
2. **Benign allowlist** — subtract matches that are safe *by design* for this repo:
   localhost dev DSNs, `test:test` fixtures, `*.example` templates, doc prose. This
   is the judgment layer and is the only part you tune per project.

A finding is **real** only if it survives both passes.

## Running the scan

Run the scan in the context-mode sandbox so the raw match dump (which itself
contains secret material) stays out of the agent's context window. Only the
redacted summary is surfaced.

```bash
# Resolve target repo (arg or cwd), confirm it's a git repo.
REPO="${1:-$PWD}"
cd "$REPO" || { echo "not a directory: $REPO"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo: $REPO"; exit 1; }

# ── Pass 1: broad net ────────────────────────────────────────────────
# One bare pattern per secret class. Extend, never narrow.
PATTERNS='sk-[A-Za-z0-9]{20}'                 # OpenAI legacy
PATTERNS="$PATTERNS|sk-proj-[A-Za-z0-9_-]{20}" # OpenAI project keys
PATTERNS="$PATTERNS|sk-ant-[A-Za-z0-9_-]{20}"  # Anthropic
PATTERNS="$PATTERNS|AKIA[0-9A-Z]{16}"          # AWS access key id
PATTERNS="$PATTERNS|ghp_[A-Za-z0-9]{36}"       # GitHub PAT (classic)
PATTERNS="$PATTERNS|gho_[A-Za-z0-9]{36}"       # GitHub OAuth
PATTERNS="$PATTERNS|github_pat_[A-Za-z0-9_]{30,}" # GitHub fine-grained PAT
PATTERNS="$PATTERNS|xox[bpsar]-[A-Za-z0-9-]{10,}" # Slack tokens
PATTERNS="$PATTERNS|AIza[0-9A-Za-z_-]{35}"     # Google API key
PATTERNS="$PATTERNS|pa-[A-Za-z0-9]{20,}"       # Voyage AI (real keys)
PATTERNS="$PATTERNS|-----BEGIN [A-Z ]*PRIVATE KEY-----" # PEM private keys
PATTERNS="$PATTERNS|postgres(ql)?://[^ ]*:[^ @\"'\''<]+@" # credentialed DSN
PATTERNS="$PATTERNS|mysql://[^ ]*:[^ @\"'\''<]+@"
PATTERNS="$PATTERNS|mongodb(\+srv)?://[^ ]*:[^ @\"'\''<]+@"
PATTERNS="$PATTERNS|redis://[^ ]*:[^ @\"'\''<]+@"
PATTERNS="$PATTERNS|(password|passwd|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*[\"'\''][^\"'\'' ]{6,}"

# Walk every reachable blob across all refs.
git grep -nIE "$PATTERNS" $(git rev-list --all) 2>/dev/null > /tmp/secrets_raw.txt
RAW=$(wc -l < /tmp/secrets_raw.txt | tr -d ' ')

# ── Pass 2: benign allowlist (the judgment layer — see is_benign) ────
# Implemented in the shell helper below.
```

### The allowlist filter

```bash
# is_benign <match-line> → exit 0 if the line is a safe-by-design false positive.
# This is the ONE place that encodes per-repo judgment about what's NOT a leak.
is_benign() {
  local line="$1"
  # TODO(human): decide which matches are safe-by-design and return 0 for them.
  # Consider: localhost/127.0.0.1 dev DSNs, well-known dev passwords, test
  # fixtures (test:test, foo:bar), *.example / *.sample / *.template files,
  # documentation prose, and obvious placeholders (<your-key>, CHANGEME, xxxx).
  # Return 1 (not benign) for everything else so it surfaces as a real finding.
  return 1
}
```

```bash
# ── Apply the filter + render verdict ───────────────────────────────
REAL=0
: > /tmp/secrets_real.txt
while IFS= read -r line; do
  is_benign "$line" && continue
  REAL=$((REAL + 1))
  # Redact: keep file:line + first 8 chars of the secret region, mask the tail.
  echo "$line" | sed -E 's/([:=] *["'\'']?.{0,8})[^ ]*/\1••••REDACTED/' >> /tmp/secrets_real.txt
done < /tmp/secrets_raw.txt

echo "scanned $(git rev-list --all | wc -l | tr -d ' ') commits"
echo "broad-net matches: $RAW   |   real (post-allowlist): $REAL"
if [ "$REAL" -eq 0 ]; then
  echo "VERDICT: PASS ✅ — no real secrets in history (all matches were benign placeholders)"
else
  echo "VERDICT: EXPOSED ❌ — $REAL finding(s) need remediation:"
  cat /tmp/secrets_real.txt
fi
rm -f /tmp/secrets_raw.txt /tmp/secrets_real.txt
```

## Reporting

Surface to the user, concisely:
- Commits scanned + broad-net match count + real count
- The **PASS/EXPOSED verdict**
- For each real finding: redacted `commit:file:line`
- Hygiene state: is `.env` gitignored? Are only `*.example` templates tracked?

## Remediation (only if EXPOSED)

History rewrite is required — deleting in a new commit does NOT remove the secret.
1. **Rotate the credential first.** Assume it's compromised the moment it was public.
2. Purge from history with `git filter-repo --replace-text` (preferred) or BFG.
3. Force-push, then have all collaborators re-clone.
Never auto-run these — they rewrite history. Present the plan and let the user run it.
