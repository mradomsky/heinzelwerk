---
name: team-modes
description: "heinzelwerk-cloud routing, reports, worktrees, contracts, GitHub through REST. Use at run start and for any branch, worktree, task, PR, or gh call."
user-invocable: false
---
# Team modes (cloud)

Cloud sessions have no agent team: every role is a **subagent** that coordinator spawns for one task and that ends with a
**report**. No messaging, no shared task list, no subagents of your own (the Agent tool is not available inside a
subagent). Everything a teammate would have said in a message goes into the report; coordinator routes it.

## 0. Mode
Single mode only: the session cwd is the repo. `ROOT` = repo dir. Workspace mode (a folder of repos) is not supported in
cloud: coordinator stops and tells the human.

## Routing
| About | To |
|---|---|
| scope, acceptance criteria, meaning of a term, priority | product |
| design, task split, seams, contract shape, failing checks, discovered work (as a proposed task) | tech-lead |
| process: stuck, blocked, idle, duplicate, budget cap | coordinator |
| anything only the user can decide | coordinator → user, with a recommended answer |
Only coordinator talks to the user, and only coordinator talks to roles: a role reaches another role through a
`question:` or `proposed:` line in its report. Coordinator spawns the target with the question and the context, then
respawns the asker with the answer (same branch and worktree). Keep working on everything that doesn't depend on the answer
before you report.

## Reports
- A report is the hand-back at the end of your run. It is the only channel: your plain text is not read.
- Start with `[<repo>@<branch>]` from an implementer, `[<role>]` from everyone else, then the done note (phased-workflow
  **Done note**): every line coordinator or the next role needs, payload exact, no transcript.
- Routing lines, each on its own line, as many as needed:
  `question: <product|tech-lead>: <one question>` · `proposed: <title>` + the proposal fields (phased-workflow `proposals.md`) ·
  `escalate: opus|haiku: <what, why>` (you cannot spawn; coordinator reruns that part on the tier you ask for) ·
  `spawn: <role>: <task title>` (tech-lead and validator: the next task to run) · `abandoned: <why>`.
- **Voice** in reports and done notes: answer first, no greeting or recap, short words, drop articles when the sentence
  still reads, keep every not/never/no/only, payload (paths, commands, numbers, errors) exact. Ticket comments, PRs, code,
  and docs: normal prose.
- Reports vanish with the run; what goes on GitHub is in phased-workflow **Ticket vs task**.

## GitHub through REST
`gh pr`, `gh issue`, `gh label`, and `gh search` subcommands are rejected in cloud (HTTP 403, GraphQL). Use the `gh api`
forms in [gh-rest.md](gh-rest.md); they replace the commands in `docs/agents/heinzelwerk/issue-tracker.md`.

## Contract changes
Contracts are the paths under **Contracts** in `docs/agents/heinzelwerk/team.md`. Compatible by default; a breaking change
is a proposal to tech-lead before coding: a `proposed:` block in your report, the breaking part held, the rest of your
task finished. The rules (who the provider is, what counts as compatible, how a breaking change or a mid-task consumer need
is handled) are in [contracts.md](contracts.md); where it says "message", read "report line", and coordinator does the
relay.

## 1. Worktrees, branches, commits
- **All edits happen in your own worktree.** The main checkout is read-only reference.
- **Worktree per task**, created explicitly (do not rely on automatic isolation):
  ```sh
  git -C <repo> fetch origin
  grep -qxF .claude/worktrees/ <repo>/.git/info/exclude || echo .claude/worktrees/ >> <repo>/.git/info/exclude
  git -C <repo> worktree add <repo>/.claude/worktrees/heinzelwerk/<branch> -b <branch> origin/main
  ```
  Then run the **Worktree setup** command from `team.md` inside it (e.g. `npm ci`): a fresh worktree has no dependencies.
  Work only inside that path. One task = one branch = one worktree = one PR. Use absolute paths: the harness may move the
  session cwd into a worktree after a `cd`.
- **Branch name**: `<type>/<ticket-number>-<topic>`, type from conventional commits (`feat`, `fix`, `docs`, `test`,
  `refactor`, `chore`). Example: `feat/19-anomaly-webhook`.
- **Commits**: conventional, reference ticket, keep Claude Code's `Co-Authored-By` trailer. `feat: add anomaly webhook (#19)`.
- **Stay current with main.** Before opening the PR, and whenever validator reports a conflict or a merged PR touched your
  files: `git fetch origin && git rebase origin/main` in your worktree. Task blocked-by a contract task whose PR isn't
  merged: rebase onto `origin/<contract-branch>` instead. Resolve conflicts **by intent**: read the other side's PR and
  ticket, keep both behaviours unless the specs say otherwise, never drop the other side's change silently. Can't tell what
  the other side intended → `question: tech-lead:` in your report. Run all checks after resolving. Push your own branch with
  `--force-with-lease` only; plain `--force` is blocked.
- Worktrees are disposable: the branch lives on the remote. Coordinator removes them at run end. A fix on an existing PR
  recreates one from the remote branch: `git -C <repo> fetch origin && git -C <repo> worktree add <path> -B <branch> origin/<branch>`.
  Remote branches cannot be deleted from cloud; the human prunes them.

## 2. Single-mode rules
[single.md](single.md): tickets, ownership by path, parallel work, contract branches, PR bodies, checks.

## 3. Tech-lead's plan comment
```
Decisions
- <decision>: <option A> vs <option B> (<trade-offs>) → <choice>, because <reason>
- <decision>: obvious: <choice>, because <reason>
Pre-mortem: <most likely failure after merge> → prevented by <task / seam / check>
Critique (risk-area slices): <point> → changed: <how> | kept: <why>
Tasks
<n>. <#N role kind: what> | repo | branch | worktree path | blocked-by | seams
```
