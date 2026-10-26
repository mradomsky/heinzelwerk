---
name: team-modes
description: "heinzelwerk routing, messaging, worktrees, contracts per mode. Use at run start and for any branch, worktree, task, or PR."
user-invocable: false
---
# Team modes

## 0. Detect mode (coordinator does this first and tells the team; tech-lead confirms it in the plan comment)
- Session cwd is a git repo → **single mode**. `ROOT` = repo dir.
- Session cwd is not a git repo, contains child repos, and the loaded CLAUDE.md imports `CLAUDE.workspace.md` (its `## Agent skills (heinzelwerk)` block names `workspace.md`) → **workspace mode**. `ROOT` = cwd.
- Anything else → stop, tell the human. Do not guess.

## Routing
| About | To |
|---|---|
| scope, acceptance criteria, meaning of a term, priority | product |
| design, task split, seams, contract shape, failing checks, discovered work (as a proposed task) | tech-lead |
| process: stuck, blocked, idle, duplicate, budget cap | coordinator |
| anything only the user can decide | coordinator → user, with a recommended answer |
Only coordinator talks to the user.

## Messaging
- Every message starts with `[<repo>@<branch>]` from an implementer, `[<role>]` from everyone else.
- Member names: coordinator is `team-lead` (the platform's name for the main session); every other role is its own name (`tech-lead`, `product`, …; a respawn after a release or crash: `<role>-N`). Never confuse `team-lead` with `tech-lead`.
- Coordinator, product, and tech-lead always run: message them without checking. Any other role → message it **only if it is running**: first read the `members` array in the team config (path in your spawn prompt: `~/.claude/teams/<team>/config.json`). Replying to a message you received is always allowed. A message to a stopped teammate revives it with stale context; only coordinator spawns.
- Target not running → message **tech-lead** instead, saying who you meant and why. Tech-lead decides whether that role is needed (coordinator spawns it) or the matter becomes a task or proposal.
- Messages vanish with the run; what goes on GitHub is in phased-workflow **Ticket vs task**.
- **Voice** in teammate messages and done notes: answer first, no greeting or recap, short words, drop articles when the sentence still reads, keep every not/never/no/only, payload (paths, commands, numbers, errors) exact. Ticket comments, PRs, code, and docs: normal prose.

## Contract changes
Contracts are the paths under **Contracts** in `docs/agents/heinzelwerk/team.md`, plus cross-repo interfaces in workspace mode. Compatible by default; a breaking change is a proposal to tech-lead before coding. The rules (who the provider is, what counts as compatible, how a breaking change or a mid-task consumer need is handled) are in [contracts.md](contracts.md): read it when your task, or team.md, names a contract your change touches.

## 1. Same in both modes
- **All edits happen in your own worktree.** The main checkout is read-only reference.
- **Worktree per task**, created explicitly (do not rely on automatic isolation):
  ```sh
  git -C <repo> fetch origin
  grep -qxF .claude/worktrees/ <repo>/.git/info/exclude || echo .claude/worktrees/ >> <repo>/.git/info/exclude
  git -C <repo> worktree add <repo>/.claude/worktrees/heinzelwerk/<branch> -b <branch> origin/main
  ```
  Then run the **Worktree setup** command from `team.md` inside it (e.g. `npm ci`): a fresh worktree has no dependencies. Work only inside that path. One task = one branch = one worktree = one PR.
  Temp files go in your own scratchpad directory (`/tmp` is shared with every agent on the machine). Unfinished work waits as a WIP commit on your branch (the stash is one per repo, shared by every worktree and by the user).
- **Branch name**: `<type>/<ticket-number>-<topic>`, type from conventional commits (`feat`, `fix`, `docs`, `test`, `refactor`, `chore`). Example: `feat/19-anomaly-webhook`.
- **Commits**: conventional, reference ticket, keep Claude Code's `Co-Authored-By` trailer (one of retro's signals for agent vs human commits). `feat: add anomaly webhook (#19)` / `(owner/repo#19)` in workspace mode.
- **Stay current with main.** Before moving a task to under review, and whenever validator reports a conflict or a merged PR touched your files: `git fetch origin && git rebase origin/main` in your worktree. Task blocked-by a **same-repo** contract task whose PR isn't merged: rebase onto `origin/<contract-branch>` instead (cross-repo: stay on `origin/main`).
  Resolve conflicts **by intent**: read the other side's PR and ticket, keep both behaviours unless the specs say otherwise, never drop the other side's change silently. Can't tell what the other side intended → ask tech-lead. Run all checks after resolving. Push your own branch with `--force-with-lease` only; plain `--force` is blocked.
- Worktrees are disposable: the branch lives on the remote. Coordinator removes them at run end (coordinator §4). A later fix on an existing PR recreates one from the remote branch: `git -C <repo> fetch origin && git -C <repo> worktree add <path> -B <branch> origin/<branch>`.

## 2. Mode rules
Read the file for your mode once, at run start, and keep to it: [single.md](single.md) (tickets, ownership by path, parallel work, contract branches, PR bodies, checks, validator) or [workspace.md](workspace.md) (tickets repo, ownership by repo, shared branch name, one task per repo, cross-repo contracts, PR bodies, per-repo checks, integration, docs placement).

## 3. Tech-lead's plan comment (both modes)
```
Decisions
- <decision>: <option A> vs <option B> (<trade-offs>) → <choice>, because <reason>
- <decision>: obvious: <choice>, because <reason>
Pre-mortem: <most likely failure after merge> → prevented by <task / seam / check>
Critique (risk-area slices): <point> → changed: <how> | kept: <why>
Tasks
#<task> phase | owner | repo | branch | worktree path | blocked-by
```
In workspace mode also: shared branch name, PR order, which PR closes the ticket.
