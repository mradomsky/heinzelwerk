# One worktree per task, inside the repo at `.claude/worktrees/heinzelwerk/<branch>`, locked while held

Every teammate edits only in a worktree it created from `origin/main`, under the repo's own `.claude/worktrees/heinzelwerk/`, git-ignored through `.git/info/exclude`, and locked with `git worktree lock --reason "<role> #<ticket> <run start>"` until its done note. The main checkout is read-only reference.

## Considered Options

1. **Worktrees in a sibling folder (`../<repo>-wt/`)** — rejected. Outside the folder Claude Code was started in, so every edit asks the user for permission; an unattended run stalls.
2. **Platform-provided isolation (`isolation: worktree` on spawn)** — rejected as the only mechanism. Teammates spawned as agent-team members do not get it reliably, and the branch and path names would not follow the plan comment.
3. **Explicit worktree per task inside the repo, next to Claude Code's own** (chosen), with a lock since v0.40.0.

## Considered Options for the lock

1. **No lock, rely on `git worktree add` refusing an existing path** — rejected. A respawned `<role>-2` or a parallel session then either `rm -rf`s the path or works in a stale tree; nothing says who holds it.
2. **A lock file with a PID** — rejected. Every teammate shares one Claude process; a PID says nothing, and a file inside the worktree can be committed or deleted by the agent.
3. **`git worktree lock --reason`** (chosen). Native, visible in `git worktree list`, survives crashes, and `git worktree remove` refuses a locked tree without `--force`, which the guard blocks.

## Consequences

- Coordinator's cleanup table starts with the lock state; a lock whose run has no final report is left alone.
- Unfinished work waits as a WIP commit, never in the stash: the stash is one per repo, shared with the user.
