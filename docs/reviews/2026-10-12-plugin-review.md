# heinzelwerk plugin review, 2026-10-12

Independent review with `prompts/review-plugin.md` (Opus, read-only) at v0.19.0.

Status:
- Applied in the review-blockers PR (v0.20.0): 1.1, 1.5, 2.1, 2.4 (policy and script from `origin/main`), 3.6. The same PR also adds worktree cleanup.
- Open for discussion: 1.2 (worktree location), 1.3 (AGENTS.md vs CLAUDE.md), 4.1 (ponytail and caveman auto-invocation).
- Planned: 2.x and 3.x rest in a gaps PR, 4.x and 5.x in a token and licensing PR.
- Live check: in the #179 run the team config's `members` later held only `team-lead`. Teammates were either removed or are not listed, which bears on 1.7 and on team-modes **Messaging**.

## 1. Will it run?
1. `coordinator:14-19`: spawns never name agent type `heinzelwerk:<role>` or teammate name `<role>`. Without the type, no role prompt, model, effort, or disallowedTools applies. Wrong per agent-teams#use-subagent-definitions-for-teammates.
2. `team-modes:45`: single-mode worktrees at `<repo>/../.worktrees/` sit outside the cwd, so every Read, Edit, and Write there prompts. Fix: `<repo>/.worktrees/` (gitignored) or `permissions.additionalDirectories`.
3. `setup:71`: AGENTS.md is ignored when any CLAUDE.md exists in the cwd or above it. Fix: always put the block in CLAUDE.md.
4. `README:30`: whether `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` works from settings `env` is undocumented. Fix: launch line with the env var. Unverifiable.
5. `phased-workflow:31`: teammates self-claim the next free task, while ownership lives only in the title. Fix: claim only own-role tasks.
6. `hooks.json:6`: `onFailure` needs v2.1.295. Fix: state the minimum version in README.
7. `team-modes:24`: only the lead's agent *type* `team-lead` is documented, not its member *name*. Unverifiable.
8. Confirmed: task states, delete via TaskUpdate, immutable titles, config path and `members`, revive-on-message, no teammates headless, `skills` frontmatter ignored, `model`/`effort`/`disallowedTools` applied, MCP from project and user config, `--strict-mcp-config`, subagent `model` precedence, command `model:` lasts one turn, `$ARGUMENTS`, `user-invocable: false`, `@` imports, marketplace `"."`. Plugin skills under `--plugin-dir` for teammates: unverifiable.

## 2. Contradictions and gaps
1. Fix-task cap: `validator:26` 2, `phased-workflow:33` 3, `tech-lead:18` 3.
2. `coordinator:17`: "validator when the first validate task appears" has no trigger. Fix: the implementer messages coordinator.
3. `validator:30,33`: slice acceptance assumes infra is applied, but nothing blocks it on the apply. Fix: an apply task that acceptance is blocked by.
4. `tf-gate:7`: the policy is read from the branch, so a PR can widen its own gate.
5. `bugfix:17` omits diagnose, while `coordinator:42` triggers it and tech-lead §4 needs acceptance criteria. Fix: bugfix diagnose = red on main, green on branch, expected behaviour.
6. `prototype/UI.md:28`: `heinzelwerk:prototype` in a path; a colon is invalid on Windows.
7. Agent bodies still use bare skill names (backend.md:7 etc.).

## 3. Failure paths
1. `coordinator:51`: resume gives a new session, a new team, and no tasks; no one is named to recreate tasks. Fix: tech-lead recreates them from the run-state comment.
2. `coordinator:36`: the dead-teammate replacement is unspecified (name, stuck task, worktree). Fix: `<role>-2`, abandon the old task and recreate it.
3. Usage or rate-limit caps look like API failures, and retry-then-respawn burns budget. Fix: post run state, end `stopped`.
4. `coordinator:25`: no threshold for "no answer". Fix: unanswered once every independent task is done.
5. `ui-shots:14`: parallel pushes to `heinzelwerk-screenshots` fail non-fast-forward. Fix: retry loop.
6. `guard.sh:20,29`: false positives on `git push … && gh pr create --base main` and on commit messages containing ` -n` or `--no-verify`.
7. `tf-gate:10`: `realpath --relative-to` fails on macOS.

## 4. Token cost
1. ponytail and caveman descriptions auto-load the full skills in every coding session and teammate. Fix: `disable-model-invocation: true`.
2. `team-modes:25`: reads config.json before every message. Fix: read once, reread on a send error.
3. Upstream skill descriptions duplicate an installed mattpocock-skills plugin. Fix: README note, trimmed descriptions.
4. `bugfix:8-16`: the phase list is copied into 3 spawn prompts. Fix: a separate file, passed by path.

## 5. Licensing
1. `THIRD_PARTY_NOTICES:9`: ponytail is marked "Modified? No" but its description was trimmed in b685c71; mattpocock descriptions were also trimmed without marks.
2. Caveman: pre-3.0 parts are MIT, and the `LICENSE-MIT` text is not reproduced. Confirm the source version.
3. `skills/model-selection` provenance is unresolved (deferred from the previous review).
4. Apache-2.0 obligations are met. Optional: `plugin.json` license `"MIT AND Apache-2.0"`.
