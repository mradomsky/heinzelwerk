# Dependent work builds on open PRs and records a snapshot; nothing waits for a merge

A task or ticket that needs another PR's change starts as soon as that PR is open. In the same repo its branch is cut from the PR's branch and its PR is **stacked** on it; across repos it stays on main and names the PR. Either way the PR body carries `Depends on <PR>, last snapshot <sha>`: the dependency's head at the time. `stack-check` compares the snapshot with the dependency's head, the merge gate refuses a PR whose snapshot is stale, and a stale snapshot opens a rebase round (`git rebase --onto <new head> <old snapshot>`). Several tickets in one session are a **queue** (`heinzelwerk:queue`): independent ones run in parallel up to `Parallel runs` (default 3), dependent ones in sequence under this rule.

This replaces the precondition of ADR 0007 that tickets in one team must be independent: a ticket that is not independent now builds on the other one instead of being refused.

## Considered Options

1. **A dependent ticket waits until its blocker is merged** — rejected. It was the rule up to v0.44: `/heinzelwerk:feature` per ticket, the frontier worked by hand. A chain of three slices cost three sessions and two waits for a human or the gate, although the second slice needs only the first one's code, not its merge.
2. **Start the dependent once the blocker's PR passed validation** — rejected (user decision, 2026-11-15). Fewer rebase rounds, but the dependent sits idle through every validation of the blocker. Starting at "PR open" costs one rebase round per fix round of the blocker; the rebase round waits for the blocker's new head to pass, so nobody chases a head that is still moving.
3. **One integration branch per queue, every ticket merged into it** — rejected. One PR per task is what the validator, the gate, and the human review; an integration branch hides which task broke what and needs its own merge to main.
4. **The snapshot in a PR comment, a new one per rebase** — rejected (user decision). The gate already reads `Depends on` from the body; one line edited in place is one source of truth, and the body is what `spawn-context` hands the validator.
5. **Stacked PR with a snapshot line in the body, checked by a script** (chosen). The snapshot is also the fork point: `git rebase --onto` moves exactly the task's own commits, which is what makes a squash-merged dependency painless.

## Consequences

- `stack-check` is a plugin script like `review-gate`; `merge-gate` calls it, so a stacked PR without the line, or with a stale snapshot, never merges. Target repos need `Bash(stack-check *)` in their settings (setup writes it).
- The same rule covers what was a special case before: a consumer task stacked on a same-repo contract branch, and a cross-repo consumer's `Depends on` line. Both now carry a snapshot.
- A plan row has a `base`. Blocked-by means "starts once the blocker's PR is open".
- A rebase round caused by a moved dependency does not count against the fix-task cap.
- A dependent run's merge task waits for coordinator's `merged` message about the run below it; when that run is left to a human, so is the stack above it, with the merge order in the final report.
- A stacked PR may show no CI until the gate retargets it (workflows that run only for PRs into main). The verdict then says `inconclusive: stacked: <check>; CI runs after the retarget`, and the gate requires green CI after the retarget.
- The coordinator's context is the limit on parallel runs; `Parallel runs` in `team.md` sets it, three by default.
