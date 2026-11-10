# feat

Capture a feature into the current project's `FEATURES/` directory as a numbered markdown file (`feat-NNN.md`). Parses a one-liner when given; falls back to interactive intake when fields are missing.

## Usage
- `/feat` — create a new feature via interactive TUI intake.
- `/feat <text>` — create a new feature, parsing the one-liner for what/why/done-when (skips the TUI if all three are clear).
- `/feat update feat-XXX` — edit an existing feature via the TUI.
- `/feat build feat-XXX` — work the feature toward delivery.

`feat-XXX` accepts `feat-003`, `003`, or `3` — normalized to the zero-padded `feat-NNN.md` in `<cwd>/FEATURES/`.

## Trigger
`/feat`, "log a feature", "capture this feature", "file a feature request".
