---
name: team-modes
description: "heinzelwerk routing, messaging, worktrees, contracts per mode. Use at run start and for any branch, worktree, task, or PR."
user-invocable: false
---
# Team modes

## 0. Detect mode
Coordinator does this first and tells the team; tech-lead confirms it in the plan comment.
- Session cwd is a git repo → **single mode**. `ROOT` = repo dir.
- Session cwd is not a git repo, contains child repos, and the loaded CLAUDE.md imports `CLAUDE.workspace.md` → **workspace mode**. `ROOT` = cwd. (That file's `## Agent skills (heinzelwerk)` block names `workspace.md`.)
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
- Every message starts with a tag: `[<repo>@<branch>]` from an implementer, `[<role>]` from everyone else.
- Member names: coordinator is `team-lead` (the platform's name for the main session); every other role is its own name (`tech-lead`, `product`, …; a respawn after a release or crash: `<role>-N`). Never confuse `team-lead` with `tech-lead`.
- Coordinator, product, and tech-lead always run: message them without checking.
- Any other role → message it **only if it is running**. To check, first read the `members` array in the team config; its path is in your spawn prompt (`~/.claude/teams/<team>/config.json`). Replying to a message you received is always allowed. A message to a stopped teammate revives it with stale context; only coordinator spawns.
- Target not running → message **tech-lead** instead, saying who you meant and why. Tech-lead decides whether that role is needed (then coordinator spawns it) or whether the matter becomes a task or proposal.
- Messages vanish when the run ends; which things go on GitHub instead is in phased-workflow **Ticket vs task**.
- **Footer**: every comment, review, and PR body an agent posts on GitHub ends with a line `— heinzelwerk`. One exception: a pass verdict keeps `heinzelwerk: validated <sha>` as its last line and puts the footer right above it. Humans and retro tell agent text from the user's that way; every role posts under the user's login. Commits carry the `Co-Authored-By` trailer instead.
- **Voice** in teammate messages and done notes: answer first; no greeting or recap; short words; drop articles when the sentence still reads without them; keep every not/never/no/only; payload (paths, commands, numbers, errors) exact. Ticket comments, PRs, code, and docs use normal prose.

## Contract changes
Contracts are the paths under **Contracts** in `docs/agents/heinzelwerk/team.md`, plus cross-repo interfaces in workspace mode. Changes are compatible by default; a breaking change goes to tech-lead as a proposal before you code it. The rules are in [contracts.md](contracts.md): who the provider is, what counts as compatible, how a breaking change or a mid-task consumer need is handled. Read it when your task, or team.md, names a contract your change touches.

## 1. Same in both modes
- **All edits happen in your own worktree.** The main checkout is read-only reference.
- **Worktree per task**, which you create yourself with these commands (do not rely on automatic isolation):
  ```sh
  git -C <repo> fetch origin
  grep -qxF .claude/worktrees/ <repo>/.git/info/exclude || echo .claude/worktrees/ >> <repo>/.git/info/exclude
  git -C <repo> worktree add <repo>/.claude/worktrees/heinzelwerk/<branch> -b <branch> origin/main
  git -C <repo> worktree lock <repo>/.claude/worktrees/heinzelwerk/<branch> --reason "<role> #<ticket> <run start>"
  ```
  `<role>` is your member name (`backend`, `backend-2`); `<ticket>` and `<run start>` (UTC) come from your spawn prompt's `## Context` header. The lock says who holds the worktree. `worktree add` refuses a path that exists → never remove it; read `git worktree list --porcelain` for its lock reason and message coordinator with it. Coordinator unlocks only worktrees whose owner is gone (coordinator §3, §4.2). Unlock your own worktree (`git worktree unlock <path>`) as the last step of phased-workflow **Done**; a fix round locks it again.
  Then run the **Worktree setup** command from `team.md` inside the new worktree (e.g. `npm ci`): a fresh worktree has no dependencies. Work only inside that path. One task = one branch = one worktree = one PR.
  Temp files go in your own scratchpad directory; `/tmp` is shared with every agent on the machine. Unfinished work waits as a WIP commit on your branch, not in the stash: the stash is one per repo, shared by every worktree and by the user.
- **Branch name**: `<type>/<ticket-number>-<slug>[-<role>]`, deterministic, so a second run on the same ticket lands on the same branch:
  - type from conventional commits (`feat`, `fix`, `docs`, `test`, `refactor`, `chore`);
  - slug = the ticket title, lower-case, every run of non-alphanumerics replaced by one `-`, the first three words, leading and trailing `-` dropped;
  - `-be`, `-fe`, `-infra` only when the plan gives one ticket more than one implement task.

  Example: ticket #19 "Anomaly webhook: notify on spike" → `feat/19-anomaly-webhook-notify`. Tech-lead writes the names in the plan comment. Before inventing one, read the ticket's run-state comment and earlier plan comments: a branch named there is reused, whatever its slug. The slug is the one place ticket text reaches a command (phased-workflow **Untrusted content**): the rule leaves only `[a-z0-9-]`. Validator's detached worktrees (`val-`, `red-`, `accept-`) and the docs PR branch (`docs/agent-docs-<ticket>`) keep their own fixed shapes.
- **Commits**: conventional commits that reference the ticket; keep Claude Code's `Co-Authored-By` trailer (retro uses it as one signal to tell agent commits from human ones). Example: `feat: add anomaly webhook (#19)`; in workspace mode the ref is `(owner/repo#19)`.
- **Stay current with main.** Run `git fetch origin && git rebase origin/main` in your worktree:
  - before moving a task to under review;
  - whenever validator reports a conflict;
  - whenever a merged PR touched your files.

  If your task is blocked-by a **same-repo** contract task whose PR isn't merged, rebase onto `origin/<contract-branch>` instead. If that contract task is in another repo, stay on `origin/main`.
  Resolve conflicts **by intent**: read the other side's PR and ticket; keep both behaviours unless the specs say otherwise; never drop the other side's change silently. Can't tell what the other side intended → ask tech-lead. Run all checks after resolving. Push your own branch with `--force-with-lease` only; plain `--force` is blocked.
- Worktrees are disposable: the branch lives on the remote. Coordinator removes them at run end (coordinator §4). A later fix on an existing PR recreates the worktree from the remote branch: `git -C <repo> fetch origin && git -C <repo> worktree add <path> -B <branch> origin/<branch>`, then locks it as above. The path still exists → the rule above: read the lock, message coordinator, never `-B` over a worktree someone holds.

## 2. Mode rules
Read the file for your mode once, at run start, and keep to it:
- [single.md](single.md): tickets, ownership by path, parallel work, contract branches, PR bodies, checks, validator.
- [workspace.md](workspace.md): tickets repo, ownership by repo, shared branch name, one task per repo, cross-repo contracts, PR bodies, per-repo checks, integration, docs placement.

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
In workspace mode the comment also lists: shared branch name, PR order, which PR closes the ticket.
