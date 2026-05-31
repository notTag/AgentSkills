# create-commit-msg

Generate a human-sounding commit message from a git diff. Takes a diff as input, drafts a commit message, then runs it through the `/humanizer` skill to strip AI-isms before outputting the final result.

## Trigger
`/create-commit-msg`, "write a commit message from this diff".
