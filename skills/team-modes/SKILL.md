---
name: team-modes
description: Exact cooperation rules for the dev team in single-repo mode vs multi-repo workspace mode — where tickets live, worktrees, branches, ownership, contracts, PR order, validation. Use at the start of every team run and whenever creating a branch, worktree, task, or PR.
---
# Team modes

## 0. Detect mode (coordinator does this first and tells the team; lead confirms it in the plan comment)
- Session cwd is a git repo → **single mode**. `ROOT` = repo dir.
- Session cwd is not a git repo, contains child repos, and `CLAUDE.workspace.md` is loaded → **workspace mode**. `ROOT` = cwd.
- Anything else → stop, tell the human. Do not guess.

## Routing
Scope → product. Technical → lead. Discovered work → lead (as a proposed task). Process (stuck, blocked, idle, duplicate) → coordinator. Only coordinator talks to the user.

## Messaging
- Message a peer **only if it is running**. Coordinator, product, and lead always run. Coordinator sends you the roster at spawn; lead and running implementers also get an update whenever it changes. Trust the latest roster; unsure → ask coordinator. Replying to a message you received is always allowed.
- Target not running → message **lead** instead, saying who you meant and why. Lead decides whether that role is needed (coordinator spawns it) or the matter becomes a task or proposal.
- Messages vanish with the run. Anything a later run or a human needs goes on GitHub: ticket comment, PR body, or contract file.

## Contract changes
Contracts: the paths under **Contracts** in `docs/agents/team.md` (older files: **API contract**), plus cross-repo interfaces in workspace mode. **Provider** = the role named there (shared types: the task's named owner; workspace: the provider repo's role); **consumers** = the roles whose code reads it.
- **Backward compatible by default**: compatible = new optional inputs or new outputs only; never rename, remove, retype, or make something required. A new enum value in an output is breaking (exhaustive consumers fail). A compatible change needs no consumer work: update the contract file in the provider's own PR and put this line in the PR body: `contract: compatible — <what changed>`.
- **Breaking change your task doesn't already name** → propose it to lead **before coding** it (a proposed task naming the consumers it breaks). Hold the breaking part until lead answers; keep working on the rest of your task. Contract proposals don't count against the proposal budget. Accepted → that proposed task becomes the contract task; the breaking part goes there, not in your current PR. Lead decides:
  - consumer update in scope → lead accepts the contract task and adds the consumer task, blocked by it; consumer role not running → lead tells coordinator to spawn it;
  - scope unclear → product rules **in** (previous bullet) or **out** (next bullet);
  - out of scope → product picks: drop the breaking part (stay compatible), or keep a compatible shim and file a `needs-triage` issue for the consumer update. Lead tells the proposer and rejects the proposed task; the compatible version goes in the proposer's current PR.
- Never break a consumer that has no task in this run.

## 1. Same in both modes
- **Never edit the main checkout.** All edits happen in your own worktree. Main checkout is read-only reference.
- **Worktree per task**, created explicitly (do not rely on automatic isolation):
  ```sh
  git -C <repo> fetch origin
  git -C <repo> worktree add <repo>/../.worktrees/<repo-name>/<branch> -b <branch> origin/main
  ```
  Work only inside that path. One task = one branch = one worktree = one PR.
- **Branch name**: `<type>/<ticket-number>-<topic>`, type from conventional commits (`feat`, `fix`, `docs`, `test`, `refactor`, `chore`). Example: `feat/19-anomaly-webhook`.
- **Commits**: conventional, reference ticket, keep Claude Code's `Co-Authored-By` trailer (retro uses it to tell agent commits from human fixes). `feat: add anomaly webhook (#19)` / `(owner/repo#19)` in workspace mode.
- **Every message to a teammate starts with** `[<repo>@<branch>]`. Coordinator and lead ignore messages without it.
- **Stay current with main.** Before moving a task to under review, and whenever validator reports a conflict or a merged PR touched your files: `git fetch origin && git rebase origin/main` in your worktree.
  Resolve conflicts **by intent**: read the other side's PR and ticket, keep both behaviours unless the specs say otherwise, never drop the other side's change silently. Can't tell what the other side intended → ask lead. Run all checks after resolving. Push your own branch with `--force-with-lease` only; plain `--force` is blocked.
- Worktrees are left in place after PR. Lead lists them in the final report; human prunes after merge.

## 2. Single mode
| Topic | Rule |
|---|---|
| Tickets | issues of this repo, refs `#N` |
| Ownership | by path, from `docs/agents/team.md` (backend, frontend, infra, shared paths). Never edit outside your paths. Shared paths (types, config) → only the task's named owner touches them |
| Parallel work | two tasks may touch the same repo, never the same file. Lead checks file overlap when seeding; overlap → make one task block the other |
| Contract | paths from **Contracts** in `docs/agents/team.md`. Contract change a consumer task depends on (compatible or breaking): own task for the provider role, lands in a PR first; consumer tasks blocked-by it and branch from the contract branch: `worktree add ... -b <branch> origin/<contract-branch>`. Compatible change no consumer task needs: in the provider's own PR (see **Contract changes**) |
| PR body | `Closes #N` on the PR that completes the ticket, `Refs #N` on the others |
| Checks | from `docs/agents/team.md` |
| Validator | checks out PR branch in its own worktree, runs checks, walks criteria |

## 3. Workspace mode
| Topic | Rule |
|---|---|
| Tickets | only in the tickets repo named in its `docs/agents/workspace.md`. Refs always `owner/repo#N`, also in commits |
| Ownership | by repo, from the repo table in `docs/agents/workspace.md` (role column). Inside a repo, that repo's own `docs/agents/team.md` applies as in single mode |
| Same feature, several repos | **same branch name in every touched repo**. That name is the feature's key; lead writes it in the plan |
| Task granularity | one task per repo. A task never edits two repos |
| Cross-repo contract | change a consumer task depends on: provider repo's task first (it owns the contract); consumer tasks blocked-by it; consumer PR body: `Depends on owner/provider-repo#<PR>`. Compatible change no consumer task needs: provider PR with the `contract: compatible` line (see **Contract changes**) |
| PR body | `Refs owner/tickets-repo#N` on all PRs; `Closes owner/tickets-repo#N` only on the last PR lead names |
| Checks | each repo's own `checks:`, run inside that repo's worktree |
| Integration | if `docs/agents/workspace.md` defines one, validator creates worktrees of the shared branch name in every touched repo (main for untouched ones) and runs it from there |
| Learnings, `GLOSSARY-MAP.md`, workspace-wide ADRs | only in tickets repo. Per-repo `GLOSSARY.md` and ADRs stay in their repo |
| Repo not in workspace map | do not touch. Tell lead |

## 4. Lead's plan comment (both modes)
For every task:
```
#<task> phase | owner | repo | branch | worktree path | blocked-by
```
In workspace mode also: shared branch name, PR order, which PR closes the ticket.

## 5. Validator checklist per mode
- Single: own worktree on PR branch → checks → task done-when → criteria → diff review.
- Workspace: per repo as single, then integration (if defined) across all touched repos on the shared branch name. Fail → needs work to the owner of the repo where the failure originates; unclear → lead.
