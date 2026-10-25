# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use `gh api` (REST) for all operations: in cloud Claude Code
sessions GitHub GraphQL is rejected, so `gh issue`, `gh pr`, `gh label`, and `gh search` subcommands fail with HTTP 403.
`R=repos/{owner}/{repo}`; `gh` expands the placeholders from `git remote -v`. Multi-line bodies: write a file, pass
`-F body=@<file>`.

## Conventions

- **Create an issue**: `gh api $R/issues -f title='...' -F body=@body.md -f 'labels[]=needs-triage'`.
- **Read an issue**: `gh api $R/issues/<number> --jq '{number,title,body,labels:[.labels[].name]}'`; comments: `gh api $R/issues/<number>/comments --jq '.[].body'`.
- **List issues**: `gh api "$R/issues?state=open&labels=<label>&per_page=100" --jq '.[] | select(.pull_request == null) | {number,title}'` (the endpoint lists PRs too; the `select` drops them).
- **Make an issue a sub-issue of a parent**: `gh api $R/issues/<parent>/sub_issues -F sub_issue_id=$(gh api $R/issues/<child> --jq .id)` (database id, as in **Blocking** below). Without sub-issues, put `Part of #<parent>` at the top of the child body.
- **Comment on an issue**: `gh api $R/issues/<number>/comments -F body=@body.md` (prints the comment `id`; edit later with `gh api -X PATCH $R/issues/comments/<id> -F body=@body.md`).
- **Apply / remove labels**: `gh api $R/issues/<number>/labels -f 'labels[]=<label>'` / `gh api -X DELETE $R/issues/<number>/labels/<label>`.
- **Close**: comment, then `gh api -X PATCH $R/issues/<number> -f state=closed -f state_reason=completed`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either: `gh api $R/issues/42 --jq .pull_request` is non-null for a PR.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above.

## Blocking edges

Use GitHub's **native issue dependencies**: `gh api $R/issues/<child>/dependencies/blocked_by -F issue_id=$(gh api $R/issues/<blocker> --jq .id)`. Where dependencies aren't available, put a `Blocked by: #<n>, #<n>` line at the top of the body. A ticket is unblocked when every blocker is closed.
