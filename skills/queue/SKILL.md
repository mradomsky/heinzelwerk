---
name: queue
description: "heinzelwerk: several tickets in one session. Order, parallel runs, runs that build on an unmerged PR. Loaded by coordinator when a command names more than one ticket or a parent ticket, a ticket has an open blocker, or a run is already active."
user-invocable: false
---

# Queue

A **queue** is every ticket this session builds: the tickets one command names, the sub-issues of a parent ticket, and the tickets a later command adds. Each ticket is still one run in the same team (ADR 0007): coordinator §1–§4 apply per ticket, with its own run start, run cap, run-state comment, and final report. This skill decides which run starts when, and what it builds on.

Nothing here waits for a merge. Independent tickets run in parallel. A ticket that needs another ticket's work starts once that work is an open PR and builds on it (team-modes [stacked.md](../team-modes/stacked.md)); `stack-check` tells when the PR underneath moved.

## 1. Build the queue
1. **Tickets.** Take the numbers as typed (`#169/#171/#173`; commas or spaces work too, the `#` is optional), in that order. A ticket with sub-issues is a parent: its open sub-issues take its place, in number order:
   `gh api --paginate repos/<tracker>/issues/<n>/sub_issues --jq '.[] | select(.state == "open") | .number'`
   Check each ticket against the command's precondition. A ticket that fails it is left out: name it to the user in one line and go on with the rest.
2. **Edges.** Read every ticket with its blockers (the repo's issue-tracker doc, **Read an issue**). Ticket B **builds on** ticket A when:
   - A is an open blocker of B; or
   - neither blocks the other, and they are not independent: in single mode their scope paths share a file, in workspace mode they share a repo. Then the later ticket in queue order builds on the earlier one.

   A closed blocker is no edge. A cycle → stop and show it to the user.
3. **A blocker outside the queue**, still open:
   - its newest `## Heinzelwerk final report` lists PRs that are still open → B builds on those PRs;
   - anything else (never run, a run without PRs, an interrupted run) → B is not startable. Tell the user: add the blocker to the queue, or finish it first.
4. **Show the queue** to the user before the first spawn, one line per ticket: `#169 first · #171 builds on #169 · #173 independent · #175 not startable: blocker #160 has no PR`. Then start; no confirmation.

A later `/heinzelwerk:feature` or `/heinzelwerk:bugfix` adds its tickets to the queue: steps 1–4 for them, against the tickets already there. Never a second team.

## 2. Start runs
A ticket is **startable** when every ticket it builds on has all its code PRs open: every implement task of that run is completed, which you see from its `validate task created` messages against its plan comment's task table. A ticket that builds on nothing is startable at once.

- Start every startable ticket, in queue order, while fewer than **Parallel runs** runs are active (`team.md`; default 3; workspace mode: the lowest value across the queue's repos). A run is active from its start to its final report. The rest wait for a free slot.
- Starting a ticket is coordinator §1 steps 1–3 for it. **Clear leftovers** runs once, before the session's first run, never while a run is active: the other runs hold their worktrees.
- A run that builds on PRs: its tech-lead's spawn prompt carries a `## Builds on` block, one line per PR, read fresh with `gh pr view <PR> [-R <owner/repo>] --json number,headRefName,headRefOid`:
  `<owner/repo>#<PR> · branch <branch> · head <sha> · ticket #<n>`
  Which task stacks on which PR is tech-lead's call (tech-lead §1), never yours.
- Each run state gets a `queue:` line: `queue: builds on #169 (PRs #201, #202) · built on by #173`, or `queue: independent`.

## 3. While runs are active
Everything in the coordinator skill that says "the run" or "the ticket" is per ticket: the spawn table, release, both passes, the run state, the end. Members are `<role>-<ticket>`, so `product-169` and `product-171` coexist; every message, nudge, and hand-back forward goes to the member of the ticket it is about (a hand-back names its ticket in the report or the subagent's prompt).

Add these to the **system pass**, whenever a task completes:

| Event | You do |
|---|---|
| a ticket became startable, or a slot freed | start it (§2) |
| a validate task passed on a PR after a fix round (fix, rebase, review threads), and another run has an open PR built on that PR | `stack-check <dependent PR>` (workspace mode: `stack-check -C <repo dir> <owner/repo>#<PR>`) per dependent PR. `STACK STALE` → message that run's tech-lead `[team-lead] #<PR> moved: <dependent PR> is stale`, with the script's line; tech-lead opens the rebase round (tech-lead §3). Count it under `stale rebases:` in that run's state. A dependent task still in progress needs no message: its owner checks before the done note (stacked.md) |
| a run's merge task completed, or the run ended without one | message the tech-lead of every run that builds on it: `[team-lead] #<ticket> merged: <PRs>` or `[team-lead] #<ticket> not merged: <PR: reason, …>`. A dependent run's merge task waits for this message (tech-lead §4) |
| a run ended with no PR (spec-gate fail, `needs-info`, stopped) | tickets that build on it and have not started stay unstarted. Tell the user which, in one line |
| a PR another run builds on was closed unmerged, or its task abandoned | tell that run's tech-lead, who stops the tasks stacked on it; that run ends `stopped` with `caps_hit: blocker #<ticket>` |

A blocker that is stuck in fix rounds or waits for a human does not stop the runs built on it: they go on to validation, and their PRs wait, stacked, for the human. A run's cap keeps counting while it waits for the merge below it.

Several runs' docs PRs touch the same files (`learnings.md`, the glossary, the repo map): tech-lead rebases right before the validate task (tech-lead §6), and a merge-round skip for that is the usual rebase round.

Three runs strain your context. When it was compacted or feels heavy, post every run's full run state (coordinator **Run state**) before you start another.

## 4. End
Each run ends per coordinator §4 with its own final report. Release only that run's members; end the team after the last run's report. A run whose PRs stay unmerged because a PR below them is unmerged lists the stack in its final report, bottom first: `merge order: #201 → #214 → #220`.

After the last final report, tell the user once, one line per ticket: outcome, PRs, merged or waiting. For stacks left to a human, give the merge order, and say that asking you to merge makes you run `merge-gate` over them in that order (coordinator §2, **The user asks for a merge**): the gate retargets each stacked PR to main once the PR below it is merged.

## Resume
The user passes the same tickets again. Per ticket:
- a final report after its newest run state → done; only its open PRs still matter (§1.3);
- a run state with no final report after it → resume it (coordinator **Resume**);
- neither → a fresh run.

Then §2.
