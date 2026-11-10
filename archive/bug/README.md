# bug

Capture a bug into the current project's `BUGS/` directory as a numbered markdown file (`bug-NNN.md`). Parses a one-liner when given; falls back to interactive intake when fields are missing.

## Usage
- `/bug` — create a new bug via interactive TUI intake.
- `/bug <text>` — create a new bug, parsing the one-liner for repro/expected/actual (skips the TUI if all three are clear).
- `/bug update bug-XXX` — edit an existing bug via the TUI.
- `/bug fix bug-XXX` — investigate and work the bug toward a fix, marking it `Resolved` only on user confirmation.

`bug-XXX` accepts `bug-003`, `003`, or `3` — normalized to the zero-padded `bug-NNN.md` in `<cwd>/BUGS/`.

## Trigger
`/bug`, "log a bug", "capture this bug", "file a bug".
