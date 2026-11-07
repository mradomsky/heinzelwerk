# One team per session holds several runs; members are named by role and ticket

A session has one agent team for its whole life. A second `/heinzelwerk:feature` or `/heinzelwerk:bugfix` while a run is active starts a second run inside that team, on an independent ticket (no shared file in single mode, no shared repo in workspace mode). Every member is named `<role>-<ticket>` (`tech-lead-168`; a respawn `<role>-<ticket>-N`), in a one-run session as much as in a two-run one, so the docs can keep saying "message tech-lead" and mean the member for your ticket.

## Considered Options

1. **One ticket per session, parallel work in parallel sessions** — rejected. It is what the docs implied from v0.40 to v0.43 and what the coordinator of 2026-11-07 enforced, but the October stagehopper runs (#205+#206, #251+#252, #253+#261 and more) had already shown two runs under one coordinator working, on improvised `-2`/`-3` names. One user channel for both runs is what those sessions were used for.
2. **Role names as member names, a number only for a second run** (`tech-lead`, then `tech-lead-2`) — rejected. That was the improvisation: `product-2`'s spec-gate message revived #204's released `tech-lead`, and nothing told a teammate which `validator` was its own. A rule that changes shape with the number of runs is a rule agents get wrong.
3. **`<role>-<ticket>` always** (chosen). Deterministic from two things every teammate knows; a one-run session pays one suffix. Worktree lock reasons and task titles already carried the ticket, so the name joins what was there.

## Consequences

- Coordinator §1.5 owns the second-run start: independence check, own run start, cap, run state and final report; no leftover cleanup while another run holds worktrees; the team ends after the last run.
- Teammates claim tasks by role **and** ticket, since both runs share one task list.
- Both runs' docs PRs touch `learnings.md`, the glossary and the repo map: tech-lead rebases its docs PR right before the validate task, and a conflict at the gate is the usual rebase round.
- Two runs is the working size; the coordinator says so before taking a third. The independence check reads the tickets' scope lines, so a wrong scope line shows up as a merge-round rebase, not earlier.
- `spawn-context` prints `member: <name>` in its header so the lock reason and the message tag use the exact name.
