# skills

A collection of [Claude Code](https://claude.com/claude-code) skills — self-contained capability packs Claude loads on demand. Each top-level directory is one first-party skill; third-party skills live under [`vendor/`](#vendor).

## What's a skill?

A skill is a folder with a `SKILL.md` (instructions + YAML frontmatter holding the `name`, `description`, and trigger phrases) plus any supporting files. Claude reads the description to decide when a skill is relevant, then loads its `SKILL.md` to perform the task. Most are invokable by slash command (e.g. `/bug`) or natural-language trigger ("log a bug").

Each skill directory also carries a short `README.md` documenting its purpose, usage, and triggers.

## Layout

```
skills/
├── <skill-name>/          # first-party skill
│   ├── SKILL.md           #   instructions + frontmatter
│   └── README.md          #   human-facing summary
├── vendor/                # third-party skills, kept separate
├── globalAgentMDs/        # source-of-truth global Claude config (CLAUDE.md, RTK.md)
├── bootstrap.sh           # symlink the global config into ~/.claude on a machine
└── CLAUDE.md              # context-mode routing rules for this repo
```

## First-party skills

### Capture & tracking
| Skill | Purpose |
|-------|---------|
| `bug` | Capture a bug into `BUGS/` as a numbered `bug-NNN.md`; TUI intake, plus `update`/`fix` flows. |
| `feat` | Capture a feature into `FEATURES/` as a numbered `feat-NNN.md`. Same format as `bug`. |
| `todo` | Display/manage `TODO.md` — incomplete items sorted to top, completed grouped at bottom. |
| `agent-project-setup` | Scaffold (or audit + repair) `BACKLOG/`, `BUGS/`, and `WHITEBOARD.md` for a git project. Idempotent. |

### Session & context
| Skill | Purpose |
|-------|---------|
| `daily` | Summarize the current session into `~/.claude/daily-tracker.md`, then prompt `/clear`. |
| `whiteboard-get` | Display the current project's `whiteboard.md` scratch file. |
| `whiteboard-put` | Checkpoint session context into `whiteboard.md` before `/clear`. |

### Git & commits
| Skill | Purpose |
|-------|---------|
| `commit-audit` | Audit a project's pre-commit hooks against the gates expected for its stack. Read-only. |
| `create-commit-msg` | Generate a human-sounding commit message from a diff (runs it through `humanizer`). |

### Knowledge
| Skill | Purpose |
|-------|---------|
| `log-definition` | Log a definition Q&A as a standalone file in ClaudeBrain `knowledge/definitions/`. |
| `log-howto` | Log a how-to Q&A as a standalone file in ClaudeBrain `knowledge/howtos/`. |

### Domain-specific
| Skill | Purpose |
|-------|---------|
| `blood-results-analysis` | Structured analysis of blood-work panels (PDF/CSV) after a context-gathering intake. Not medical advice. |
| `jd-matcher` | Score a job description against the candidate profile; outputs fit verdict, gaps, positioning hooks. |
| `chrome-bookmarks` | Convert a tabbed outline of links into a Chrome-importable bookmarks HTML file. |
| `dummy` | Test skill (prints "Hello World") for the symlink/commit experiment. |

## vendor

Third-party skills, kept separate so first-party work stays isolated:

- `gsd` — Get Shit Done workflow suite (phases, plans, roadmaps, reviews).
- `humanizer` — strip AI-isms from text.
- `clean-code-typescript` — Clean Code practices for TS/React/Vue refactors.
- `vue`, `pinia`, `vite`, `vite-plugin-federation`, `tailwindcss` — framework reference skills.

## Global agent config

`globalAgentMDs/` holds the machine-independent global Claude config (`CLAUDE.md` and its `@RTK.md` include) as the single version-controlled source of truth. `bootstrap.sh` wires it onto a machine by **symlinking** — not copying — so edits to the files in `globalAgentMDs/` propagate to every linked location automatically:

```
~/.claude/CLAUDE.md  →  globalAgentMDs/CLAUDE.md
~/.claude/RTK.md     →  globalAgentMDs/RTK.md
```

New machine: clone this repo, then run `./bootstrap.sh` from the repo root. It backs up any pre-existing real file (`*.bak-<timestamp>`) before linking and is safe to re-run. Because the targets are symlinks into the repo, the clone is load-bearing — moving or deleting it leaves the global config dangling until you re-run `bootstrap.sh` from the new location.

## Adding a skill

1. Create `<skill-name>/SKILL.md` with frontmatter (`name`, `description` with trigger phrases, instructions).
2. Add a short `<skill-name>/README.md` (purpose, usage, triggers).
3. First-party skills go at the repo root; third-party ones under `vendor/`.
4. Symlink the skill into the Claude skills folder so Claude can load it:
   `ln -s "$(pwd)/<skill-name>" ~/.claude/skills/<skill-name>`.

## Notes

- `CLAUDE.md` defines context-mode routing rules for working in this repo.
- `jd-matcher/profile.local.md` is gitignored (personal data) — see `profile.local.example.md`.
