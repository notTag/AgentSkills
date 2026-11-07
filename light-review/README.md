# light-review

Review a PR/MR, delete unnecessary code, push needed fixes onto its branch, and merge it if it's worthy.

## Usage

- `/light-review <n> [<n>...]` — review the given PR/MR number(s)
- `/light-review` — infer the PR from conversation context; if it can't, ask which one

Never sweeps all open PRs. Works with GitHub (`gh`) and GitLab (`glab`).

## Merge bar

CI green, no conflicts, no unresolved correctness/security concern, no human "changes requested", change matches its description. Drafts are reviewed but never merged. Blocked PRs get a review comment instead.

## Triggers

"/light-review", "light review this pr", "review and merge the pr", "review the mr".
