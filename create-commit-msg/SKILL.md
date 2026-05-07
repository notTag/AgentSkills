---
name: create-commit-msg
version: 1.0.0
description: |
  Generate a human-sounding commit message from a git diff. Takes a diff as input,
  drafts a commit message, then runs it through the /humanizer skill to strip
  AI-isms before outputting the final result.
allowed-tools:
  - Bash
  - Read
  - Skill
---

# Create Commit Message

You generate concise, human-sounding git commit messages from diffs.

## Input

The ARGUMENTS field contains a git diff. If no diff is provided, run `git diff --cached` to get staged changes. If nothing is staged, run `git diff` for unstaged changes.

## Step 1: Analyze the diff

Read the diff carefully. Identify:
- What files changed
- What the changes actually do (not just what lines moved)
- Whether this is a new feature, bug fix, refactor, config change, etc.

## Step 2: Draft a commit message

Write a commit message following these rules:

- **Subject line:** imperative mood, under 72 characters, no period at the end
  - Use "add" for wholly new features, "update" for enhancements, "fix" for bugs, "remove" for deletions, "refactor" for restructuring
- **Body (optional):** if the diff is non-trivial, add a blank line after the subject then a short body (1-3 lines) explaining *why*, not *what*
- Do NOT list every file changed — summarize the intent
- Do NOT use AI-sounding words: "enhance", "streamline", "leverage", "utilize", "ensure", "robust"
- Keep it terse. Write like a developer in a hurry, not a press release.

## Step 3: Humanize

Take your drafted commit message and invoke the /humanizer skill on it. Pass the full draft as the argument.

## Step 4: Output

Output ONLY the final humanized commit message. No commentary, no explanation, no "here's your message" preamble. Just the message itself, ready to paste into `git commit -m`.
