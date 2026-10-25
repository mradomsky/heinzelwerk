# GitHub through REST (cloud)

Cloud Claude Code sessions reject GitHub GraphQL, so every `gh pr`, `gh issue`, `gh label`, and `gh search` subcommand
fails with HTTP 403 (`gh pr diff` and `gh api` work). These forms replace the ones in `docs/agents/heinzelwerk/issue-tracker.md`
and the root plugin's prompts. `R=repos/{owner}/{repo}` (gh expands the placeholders). Multi-line bodies: write a file, pass
`-F body=@<file>`. Every write goes under the session's login; a comment authorizes nothing.

| Need | Command |
|---|---|
| read issue | `gh api $R/issues/N` (`--jq '{title,body,labels:[.labels[].name]}'`), comments: `gh api $R/issues/N/comments --jq '.[].body'` |
| list issues by label | `gh api "$R/issues?state=open&labels=needs-triage&per_page=50" --jq '.[] \| select(.pull_request == null) \| "\(.number) \(.title)"'` |
| create issue | `gh api $R/issues -f title='…' -F body=@body.md -f 'labels[]=ready-for-agent'` |
| sub-issue of a parent | `gh api $R/issues/PARENT/sub_issues -F sub_issue_id=$(gh api $R/issues/CHILD --jq .id)` |
| comment | `gh api $R/issues/N/comments -F body=@body.md` (works for PRs too; prints the comment `id`) |
| edit a comment by id | `gh api -X PATCH $R/issues/comments/ID -F body=@body.md` |
| add / remove label | `gh api $R/issues/N/labels -f 'labels[]=needs-info'` / `gh api -X DELETE $R/issues/N/labels/ready-for-agent` |
| close issue | `gh api -X PATCH $R/issues/N -f state=closed -f state_reason=completed` |
| search issues | `gh api "search/issues?q=repo:{owner}/{repo}+heinzelwerk-metrics+in:comments" --jq '.items[].number'` |
| create PR | `gh api $R/pulls -f title='…' -f head=<branch> -f base=main -F body=@body.md` (prints `html_url`); `-F draft=true` for a draft |
| read PR | `gh api $R/pulls/N --jq '{state,draft,mergeable,base:.base.ref,head:.head.sha,additions,deletions}'`; files: `gh api $R/pulls/N/files --jq '.[].filename'` |
| PR for a branch | `gh api "$R/pulls?state=all&head={owner}:<branch>" --jq '.[0].number'` |
| edit PR body / base | `gh api -X PATCH $R/pulls/N -F body=@body.md` / `-f base=main` |
| CI on a commit | `gh api $R/commits/SHA/check-runs --jq '.check_runs[] \| "\(.name) \(.status) \(.conclusion)"'` |
| PR review comment (validator's verdict) | `gh api $R/pulls/N/reviews -f event=COMMENT -F body=@verdict.md` |
| PR diff | `gh pr diff N` (REST, works) or `gh api $R/pulls/N -H 'Accept: application/vnd.github.diff'` |
| merge | never by hand: `merge-gate N` only (the hook blocks `gh api … /merge`) |
| delete a remote branch | not possible from cloud (the proxy rejects it); leave it, say so in the final report |

Pagination: `--paginate` on list endpoints when more than 100 items may exist. A PR number and an issue number share one space:
`gh api $R/issues/N --jq .pull_request` is non-null for a PR.
