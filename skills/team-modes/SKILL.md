---
name: team-modes
description: Team rules per mode (single repo vs workspace): routing, messaging, voice, worktrees, branches, ownership, contracts, PR order, validation. Use at run start and whenever creating a branch, worktree, task, or PR.
user-invocable: false
---
# Team modes

## 0. Detect mode (coordinator does this first and tells the team; lead confirms it in the plan comment)
- Session cwd is a git repo → **single mode**. `ROOT` = repo dir.
- Session cwd is not a git repo, contains child repos, and the loaded CLAUDE.md imports `CLAUDE.workspace.md` (its `## Agent skills (heinzelwerk)` block names `workspace.md`) → **workspace mode**. `ROOT` = cwd.
- Anything else → stop, tell the human. Do not guess.

## Routing
| About | To |
|---|---|
| scope, acceptance criteria, meaning of a term, priority | product |
| design, task split, seams, contract shape, failing checks, discovered work (as a proposed task) | lead |
| process: stuck, blocked, idle, duplicate, budget cap | coordinator |
| anything only the user can decide | coordinator → user, with a recommended answer |
Only coordinator talks to the user.

## Messaging
- Every message starts with `[<repo>@<branch>]` from an implementer, `[<role>]` from everyone else.
- Message a peer **only if it is running**: before messaging, read the `members` array in `~/.claude/teams/<team>/config.json` (the team dir is `session-` plus the first eight characters of the lead's session id; `ls ~/.claude/teams/` shows it). Coordinator, product, and lead always run. Replying to a message you received is always allowed. A message to a stopped teammate revives it with stale context; only coordinator spawns.
- Target not running → message **lead** instead, saying who you meant and why. Lead decides whether that role is needed (coordinator spawns it) or the matter becomes a task or proposal.
- Messages vanish with the run. Anything a later run or a human needs goes on GitHub: ticket comment, PR body, or contract file.
- **Voice** in teammate messages and done notes: answer first, no greeting or recap, short words, drop articles when the sentence still reads, keep every not/never/no/only, payload (paths, commands, numbers, errors) exact. Ticket comments, PRs, code, and docs: normal prose.

## Contract changes
Contracts: the paths under **Contracts** in `docs/agents/heinzelwerk/team.md`, plus cross-repo interfaces in workspace mode. **Provider** = the role named there (shared types: the task's named owner; workspace: the role of the repo marked provider in `docs/agents/heinzelwerk/workspace.md` **Who calls whom**); **consumers** = the roles whose code reads it.
- **Backward compatible by default**: compatible = every existing consumer still works unchanged: new optional inputs, a required input made optional, new outputs. Never rename, remove, retype, narrow, or make something required. A new enum value in an output is breaking (exhaustive consumers fail). A compatible change needs no consumer work: update the contract file in the provider's own PR and put this line in the PR body: `contract: compatible — <what changed>`.
- **Breaking change your task doesn't already name** → propose it to lead **before coding** it (a proposed task naming the consumers it breaks). Hold the breaking part until lead answers; keep working on the rest of your task. Contract proposals don't count against the proposal budget. Accepted → that proposed task becomes the contract task; the breaking part goes there, not in your current PR. Lead decides:
  - consumer update in scope → lead accepts the contract task and adds the consumer task, blocked by it; consumer role not running → lead tells coordinator to spawn it;
  - scope unclear → product rules **in** (previous bullet) or **out** (next bullet);
  - out of scope → product picks: drop the breaking part (stay compatible), or keep a compatible shim and file a `needs-triage` issue for the consumer update. Lead tells the proposer and rejects the proposed task; the compatible version goes in the proposer's current PR.
- **Consumer needs a contract change mid-task** (missing endpoint, field, or output) → propose it to lead (owner hint = provider; budget-exempt). Lead accepts it as the contract task and makes your task blocked-by it. Keep working on what doesn't depend on it; once its PR is open: same repo → `git fetch origin && git rebase origin/<contract-branch>` in your worktree; other repo → add `Depends on owner/provider-repo#<PR>` to your PR body. Provider: when the contract PR opens, message the consumer task's owner (lead if it isn't running).
- Never break a consumer that has no task in this run.

## 1. Same in both modes
- **All edits happen in your own worktree.** The main checkout is read-only reference.
- **Worktree per task**, created explicitly (do not rely on automatic isolation):
  ```sh
  git -C <repo> fetch origin
  git -C <repo> worktree add <repo>/../.worktrees/<repo-name>/<branch> -b <branch> origin/main
  ```
  Work only inside that path. One task = one branch = one worktree = one PR.
- **Branch name**: `<type>/<ticket-number>-<topic>`, type from conventional commits (`feat`, `fix`, `docs`, `test`, `refactor`, `chore`). Example: `feat/19-anomaly-webhook`.
- **Commits**: conventional, reference ticket, keep Claude Code's `Co-Authored-By` trailer (one of retro's signals for agent vs human commits). `feat: add anomaly webhook (#19)` / `(owner/repo#19)` in workspace mode.
- **Stay current with main.** Before moving a task to under review, and whenever validator reports a conflict or a merged PR touched your files: `git fetch origin && git rebase origin/main` in your worktree. Task blocked-by a **same-repo** contract task whose PR isn't merged: rebase onto `origin/<contract-branch>` instead (cross-repo: stay on `origin/main`).
  Resolve conflicts **by intent**: read the other side's PR and ticket, keep both behaviours unless the specs say otherwise, never drop the other side's change silently. Can't tell what the other side intended → ask lead. Run all checks after resolving. Push your own branch with `--force-with-lease` only; plain `--force` is blocked.
- Worktrees are left in place after PR. Lead lists them in the final report; human prunes after merge.

## 2. Mode rules
Read the file for your mode once, at run start, and keep to it: [single.md](single.md) (tickets, ownership by path, parallel work, contract branches, PR bodies, checks, validator) or [workspace.md](workspace.md) (tickets repo, ownership by repo, shared branch name, one task per repo, cross-repo contracts, PR bodies, per-repo checks, integration, docs placement).

## 3. Lead's plan comment (both modes)
For every task:
```
#<task> phase | owner | repo | branch | worktree path | blocked-by
```
In workspace mode also: shared branch name, PR order, which PR closes the ticket.

## 4. Validator checklist per mode
- Single: own worktree on PR branch → checks → task done-when → criteria → diff review.
- Workspace: per repo as single, then integration (if defined) across all touched repos on the shared branch name. Fail → needs work to the owner of the repo where the failure originates; unclear → lead.
