# Stacked work (building on an unmerged PR)

Read when your task's plan row names a `base` other than `main` or a `Depends on` PR, or your task is blocked by a task whose PR is not merged. The shared rules are in [SKILL.md](SKILL.md).

Work never waits for a merge. A task that needs another PR's change builds on that PR as it is now and records which commit that was: the **snapshot**. Whether that PR belongs to this run (a contract or prefactoring task) or to another ticket's run (`heinzelwerk:queue`) makes no difference.

| The PR you build on is in | Branch from | Your PR's base | Line in your PR body |
|---|---|---|---|
| your repo (your PR is **stacked**) | `origin/<its branch>` | its branch | `Depends on #<PR>, last snapshot <sha>` |
| another repo | `origin/main` | `main` | `Depends on <owner/repo>#<PR>, last snapshot <sha>` |

- **Snapshot**: the dependency PR's head, all 40 characters, at the moment you branched from it or last rebased onto it. Your repo: `git rev-parse origin/<its branch>` right after the fetch. Another repo: `gh pr view <PR> -R <owner/repo> --json headRefOid -q .headRefOid`.
- **The line**: one per dependency, exactly that form, on a line of its own above `## Done note`. `stack-check` and the merge gate read it. The gate never merges a stacked PR without it.
- **Create** (your repo): the worktree commands of SKILL.md §1 with `origin/<its branch>` in place of `origin/main`, then `gh pr create --draft --base <its branch>`.
- **One base per task.** Tech-lead names it in the plan. A task that needs two unmerged PRs of one repo stacks on one of them; tech-lead chains the two, or blocks the task until the other is merged.
- **Stay current with your base, not with main.** `git fetch origin`, then compare `git rev-parse origin/<its branch>` with your snapshot. A stacked branch is never rebased on `origin/main` while its base is unmerged.

## Check
`stack-check <PR>` (workspace mode: `stack-check -C <repo dir> <owner/repo>#<PR>`) prints one line per dependency:

| Line | Meaning | Do |
|---|---|---|
| `STACK OK` | open, and its head is your snapshot | nothing |
| `STACK MERGED` | merged at your snapshot | nothing; the gate retargets a stacked PR to main |
| `STACK STALE` | it moved after your snapshot, or the line changed without the rebase | the rebase round below |
| `STACK MISSING` | your PR is stacked and has no line | add the line |
| `STACK CLOSED`, `STACK ERROR` | closed unmerged; a lookup failed | message tech-lead with the line |

Who runs it:
- **the owner**, before the done note of an implement or fix task. No PR yet → compare by hand as in **Stay current**. Not `OK` → fix it first;
- **validator**, first, on every PR with a base other than main or a snapshot line: anything but `OK` or `MERGED` → fail, and the fix task is the rebase round;
- **coordinator**, when a PR others build on passed validation again after a fix round (`heinzelwerk:queue` §3);
- **the merge gate**, on every PR: `STALE`, `MISSING`, and `ERROR` are skip reasons.

## The dependency moved: rebase round
Tech-lead opens `#N <role> fix <k>: rebase on #<PR>` once the dependency's new head has passed validation; nobody chases a head that is still in a fix round. It is a fix round like any other (same branch, `gh pr ready --undo <PR>` first, done note, new validate task), except that it does not count against the fix-task cap: the cause is not in your PR.

- **Your repo:**
  ```sh
  git fetch origin
  git rebase --onto origin/<its branch> <old snapshot>
  ```
  `<old snapshot>` is the sha in your line, so the rebase moves only your own commits. Resolve conflicts by intent (SKILL.md §1), run every check, push with `--force-with-lease`, then replace the sha in the line with `git rev-parse origin/<its branch>`.
- **Another repo:** fetch in that repo's main checkout and read `git -C <that repo> diff <old snapshot> <new head>`. Adapt your code where the contract changed, run every check, then replace the sha in the line. No code change needed → the line changes anyway, and validator looks again.

## The dependency merged
- Nothing to do while the gate accepts your PR: it retargets a stacked PR to main, and your line keeps naming the dependency's last head.
- The gate skips your PR for `mergeable` → the usual rebase round, as `git rebase --onto origin/main <snapshot>`: a squash merge leaves the dependency's own commits in your branch, and `--onto` drops them.

## Validator
- **Fixed point** of the review: `origin/<base>` for a stacked PR, so the diff holds this task's commits only.
- **CI on a stacked PR.** A workflow that runs only for PRs into main shows no run here. For a check you cannot run locally either, write `inconclusive: stacked: <check>; CI runs after the retarget`. No acceptance is needed: the gate retargets the PR, reruns CI, and merges only when it is green.
- **Slice acceptance and integration.** A repo this run only depends on is checked out at the dependency PR's branch while that PR is unmerged, not at main.

## Merge order
Dependencies first: the bottom of a stack before what sits on it, a provider before its consumer. The gate refuses any other order (`base … is not main`, `depends on …`), and validator **Merge** holds back everything above a skipped PR.
