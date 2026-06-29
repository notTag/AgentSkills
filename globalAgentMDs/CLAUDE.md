# Global Claude Config

## Workspace Hygiene

- Tool-generated temp artifacts (sandboxed SwiftPM locks like `_Users_*.lock`, `TemporaryDirectory.*` dirs, /tmp scratch files, `*.bak` backups Claude created) get DELETED when the task that produced them completes — never gitignored to hide them
- Cleanup = part of task completion: check `git status` for artifacts before reporting done
- Git leftovers too: when a task's branch merges, delete the local branch (`git branch -d` — merged-only, never `-D` without confirming), remove its worktree (`git worktree remove`, or `git worktree prune` if dir already gone), and check `git worktree list` for prunable entries before reporting done
- Same applies to temp dirs/sibling worktree checkouts created for a task (e.g. `<repo>-<branch>` dirs next to the repo) — delete once merged
- Verify untracked junk before deleting — never touch load-bearing files (e.g. a `<project>.lock` may be a release pin, not a temp file)

---

## Feature Development Flow

- Default flow for focused work (feature/bug/chore), GSD-independent: named tmux session → git worktree off latest `main` → focused work → PR → review → cleanup → pull main. One worktree per task = no blocking, parallel work, resumable from any shell.
- Full process: `~/Code/Projects/ClaudeBrain/workflow-documentation/feature-development-flow.md`

---

## Whiteboard

- Scratch space at `whiteboard.md` — Claude only, not human-readable
- Entry format: `## [TYPE:key|YYYY-MM-DD] description` — types: TASK, FINDING, DECISION
- PINNED = staging for facts may go in CLAUDE.md permanently
- Prune inline as tasks complete — present = active, deleted = done
- Size target: ~5KB. Over 6KB = audit now
- Scope: each project's `whiteboard.md` is local to that project only — never read or write across project boundaries unless explicitly stated otherwise by the user

---

## Tools Reference

- Log commands to `~/.claude/tools-used.md`, grouped by tool
- Add as used — not end of session
- `grep`/`rg` via Bash are BLOCKED — do NOT attempt. Use fff MCP tools for ALL file search AND grep/content search — not default Grep tool, not `rtk grep`, not `grep`/`rg`/`egrep`/`fgrep` via Bash
- Use ctx7 MCP for documentation and reference lookups (library docs, framework APIs, specs) — prefer over WebFetch/WebSearch for known libraries

---

## Communication Mode

- Session start: activate caveman ultra mode immediately
- Drop articles + filler, abbreviate (DB/auth/config/req/res/fn/impl), arrows for causality (X → Y), fragments OK
- Exceptions stay normal: code/commits/PRs, security warnings, destructive op confirmations
- Off only if user says "stop caveman" or "normal mode"

---

## Runtime & Package Manager Preference

- Always prefer `bun` over `npm` — fallback to `npm` only if `bun` unavailable or pkg breaks under Bun (native bindings, postinstall quirks)
- Always prefer `bunx` over `npx` — fallback to `npx` only if `bunx` unavailable or pkg breaks under Bun
- Applies to: install, run scripts, one-shot CLI invocations, scaffolding, dev tooling
- Lockfiles: `bun.lock` / `bun.lockb` is source of truth when Bun used — do not mix with `package-lock.json`

---

## Agent Vars

- `+name` in a prompt = agent variable reference — resolve before acting
- Syntax: `+[a-zA-Z_][a-zA-Z0-9_-]*` — skip if inside code fence or backticks
- Distinct from `$VAR` (bash) — `+` is agent-only, no shell collision

**Storage** (lookup order, first hit wins):
1. `<project-root>/.claude-vars.json` — per-project override
2. `~/.claude/agent-vars.json` — global default

Both files: flat JSON `{ "name": "value", ... }`. Create on first write if missing. Add `.claude-vars.json` to project `.gitignore` unless the user says otherwise (may contain local paths).

**Authoring**:
- **Manual (primary)**: the user says "save +screenshots = ~/Desktop/shots" → ask global vs project scope, write to chosen file
- **Inference (fallback)**: if `+name` unset, Claude may propose a value (e.g. `+screenshots` → newest `~/Desktop/Screen Shot*.png` dir), confirm once, save to chosen scope
- Never silently guess — if unset and can't infer with high confidence: ask

**Examples**:
- "look at most recent +screenshots" → read `+screenshots` value, then read newest file in that dir
- "diff +branch against main" → resolve `+branch`, then `git diff <value>..main`

---

## Uncertainty Signaling

- Silence = high confidence (≥90%)
- Below 90% flag inline: `[~X% confidence — would need Y to be certain]`
- Applies to: recommendations, recalled facts, inferred intent, predicted behavior of external tools

---

## Claim Verification

- Verify claims instead of hand-waving — when asserting something is true (test passes, file exists, fn behaves X way, build clean), confirm it with a tool call first
- No "should work" / "this likely does Y" presented as fact — either verify, or flag as unverified per Uncertainty Signaling
- Applies to: test/build status, file + symbol existence, command behavior, API shape, recalled facts about the codebase
- Explanation responses too — when explaining how code/tool/system works, base it on the actual source (read it, check it), not memory or plausible-sounding inference; unverified explanation = flagged, not asserted
- Cost of verifying < cost of a confident wrong claim

---

## Code Readability — Decompose Dense Lines

- Dense one-liners are a smell, not a flex. When a single line nests multiple operations (a function call whose args are themselves call results, a slice expression indexed by another call, etc.), break it into named intermediate steps — one operation per line, each result given a meaningful variable name
- The reader should follow the logic top-to-bottom without mentally unwinding nested expressions. Naming the intermediates also documents what each step produces
- Exception: a compact one-liner is fine when it is the established idiom for the language (e.g. Go's `if v, ok := m[k]; ok {`, a ternary in C, a list comprehension in Python). Idiomatic ≠ merely "shorter"
- Being nitpicky about code is GOOD. Surface zero-behavior-change readability cleanups (redundant reslices, needless nesting, unclear names) even when the code already works — don't wave them through
- Why: correctness is the floor, not the goal. Code is read far more than written; a line that takes 30 seconds to parse costs every future reader that time. Named steps turn review into reading
- Reframe example (target style):
  ```go
  // Before — three operations crammed into one line:
  h.Write(lp[:binary.PutUvarint(lp[:], uint64(len(rel)))])
  // After — each step named and sequential:
  lenRelPath := uint64(len(relPath))
  n          := binary.PutUvarint(lp[:], lenRelPath)
  lpTrimmed  := lp[:n]
  h.Write(lpTrimmed)
  ```

---

## Naming — Descriptive Over Abbreviated

- Prefer full, descriptive identifiers: `relPath` or `relativePath`, NOT `rel`. Spell out what a value is
- Abbreviations allowed only when domain-standard and unambiguous (`fd`, `ctx`, `err`, `i`/`j` for trivial loop counters, `r`/`w` for an io.Reader/Writer in a short helper)
- A name's length should scale with its scope: a variable used many lines later or across a function deserves a real name; a one-line-lived temp can be short
- Why: a reader shouldn't have to infer what `rel` means from context. `relativePath` answers the question at the point of use
- How to apply: when introducing or renaming a variable, ask "would someone reading this cold know what it holds?" If not, expand it

---

## Code Self-Documents — Comments Optional, Not Load-Bearing

- The bar: code so clear — every name, every step, every function shaped so well — that you could delete ALL comments and a reader would STILL understand it. The code is the explanation; comments are a bonus, never the crutch
- Litmus test: mentally strip the comments. If the code becomes unclear, the CODE is wrong, not the comments. Fix the code (rename, decompose, extract a well-named function) until it stands on its own — don't patch comprehension with a comment
- Comments earn their place by explaining WHY, not WHAT: rationale, non-obvious constraints, security reasoning, links to findings, "this looks wrong but isn't because…". A comment that restates what the code already says is dead weight
- A comment is a code smell when it compensates for a bad name or a dense expression. `// the length of the path` next to `n` means the variable should be `lenRelPath`, not that the comment was needed
- Why: comments drift out of sync with code and lie; names and structure can't lie — they ARE the code. Self-documenting code stays correct by construction
- Builds on [[code-readability-decompose-dense-lines]] + [[naming-descriptive-over-abbreviated]]: decomposition + good names ARE the mechanism that makes code self-documenting

---

## GSD Workflow — Branch + PR per Phase

- Every GSD phase gets its own branch + PR
- Branch name: `phase-{N}/{1-2-word-qualifier}` — qualifier captures phase essence (e.g., `phase-1/toolchain`, `phase-2/template-engine`)
- All commits associated with a phase live in that branch's PR — research, plan, execution, verification, summaries — everything
- Create the branch BEFORE invoking `/gsd-plan-phase N` or `/gsd-execute-phase N` (or rebase retroactively if forgotten)
- Open the PR against the project's default branch at phase completion (after `/gsd-execute-phase N` returns success)
- Even when a remote doesn't exist yet, create one (`gh repo create`) — phase isolation is the rule, not the exception
- Why: phase = atomic unit of GSD scope (requirements → research → plan → code → verification). PR review aligns with that atomicity. Bisect, revert, and history-mining all become trivial.

---

## Learning Mode Scope

When `Learning` output style active, "Learn by Doing" contribution requests target:

- **In scope:** system design decisions, algorithms, component architecture, data structures, business logic, API shape, key code paths
- **Out of scope:** writing requirements, user stories, acceptance criteria, documentation prose, changelog entries, commit messages, traceability tables

Rationale: requirement authoring = product/PM exercise, not SWE learning opportunity. Scaffold those self; reserve human contribution slot for code + architecture where tradeoffs matter.

@RTK.md

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
