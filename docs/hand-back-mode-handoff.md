# Handoff: design hand-back mode (heinzelwerk on the Claude desktop app)

You are picking up one design problem in the heinzelwerk plugin. Read this whole file before you touch anything.

## The task

**Goal.** A heinzelwerk team run (`/heinzelwerk:feature`, `/heinzelwerk:bugfix`) should finish in the Claude desktop app with no manual relaying by the user or the coordinator. Today it finishes only because the coordinator improvises.

**Repo.** `mradomsky/heinzelwerk`, owned by Max (mradomsky). The local clone is `C:\Users\max\work\heinzelwerk`. Max merges plugin PRs himself; never merge one.

**Branch.** `wip/hand-back-mode-draft` holds the rejected draft (commits 87675d5 and 75bc97e). Do not merge it. Read it as input. Start your real work from `origin/main`, and only after PR #42 has merged: #42 carries the rest of that draft (workspace merge, the `ci` token, main-only acceptance) and bumps the plugin to 0.43.0, so this work is 0.44.0.

**Done when:**
1. The design is settled with Max *before* the prose is written. Use the `heinzelwerk:grilling` skill on the open questions below, and record the outcome as an ADR (the next free number on main; the draft's `0007-hand-back-mode.md` here is input, not the answer).
2. One PR implements it. The PR covers:
   - the prompts and skills;
   - scripts and their `scripts/tests/*-test.sh` suites, wherever a rule can be checked by a script instead of prose;
   - the GLOSSARY entry, the README "Session shape" note, and the test-run-plan row.
3. A fresh Opus review of that PR finds no BLOCKER or MAJOR. Run a new reviewer each round, never the same one.
4. A shakedown run in the desktop app finishes on a real ticket in the spacetraders workspace (`C:\Users\max\work\spacetraders`, tickets in `V-M-Pioneer-Trading/meta`). Every role must report, get resumed, validate and merge with no relaying by hand. Write run notes like `docs/runs/2026-11-04-spacetraders-140.md`.

## What the host actually does (observed, meta#140, 2026-11-04)

These facts were observed in the Claude desktop app (Code tab) on Windows, with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` set in user settings:

- No `~/.claude/teams/session-<first 8 of session id>/config.json` is written for the session. Stale configs from other (CLI) sessions do exist in `~/.claude/teams/`.
- Teammates spawned with `Agent` (type `heinzelwerk:<role>`, with a name) run as **background subagents** of the main session.
- Teammates have no TaskCreate, TaskUpdate, TaskList or TaskGet. The main session does have them, as deferred tools.
- A teammate's report arrives through `SubagentHandback`, and that ends the teammate's turn. Every phase report ("plan posted", "validate task created", …) ended a turn.
- The main session is addressed as `main` in `SendMessage`, not `team-lead`. Backend's `SendMessage` to `team-lead` failed.
- Product and tech-lead could `SendMessage` each other by name.
- Coordinator resumed a finished teammate with `SendMessage` by name, and the teammate kept its context.
- The run took 20 minutes for one docs-only PR, with 0 fix rounds. The coordinator's manual relaying is what made it work.

**Not verified yet:** check these before you design on them.
- Does a crashed teammate's hand-back carry the API error?
- Where does a teammate's own nested subagent hand back: to the teammate or to `main`?
- Does `git worktree lock` on an already locked worktree error out?
- Does a usage or rate limit surface differently from other errors?

## Why the draft was pulled

The draft tried to rebuild the agent-team task list in prose:
- every task operation became a `task <verb>: <title> | <owner> | <branch> | <detail>` line in a hand-back;
- coordinator applied those lines to a snapshot in the run-state comment;
- task details lived in tech-lead's plan comment.

Two fresh reviews each found a blocker. Every patch exposed the next gap. Round-2 findings that still apply to that design:

1. **BLOCKER: no blocked-by.** Coordinator spawns the owner of every `task create` line at once. So slice acceptance, `tech-lead apply`, consumer tasks and `validate: merge` all start before their blockers finish. Nothing fills or releases the snapshot's blocked-by column.
2. **No claim, no ids.** The line format has no "claim" verb and tasks have no id, but the snapshot and tech-lead's `tasks created: <ids>` both expect one.
3. **A validator fail has no home.** Its repro and done note go "in the task details", which don't exist. Validator cannot message tech-lead, so the owner is resumed with one line and no repro.
4. **Unlock order.** phased-workflow says "message coordinator, then unlock the worktree". In this host the message is the hand-back, which ends the turn, so the worktree stays locked and the next fix round's `worktree lock` fails.
5. **Crash rules contradict each other.** The draft's "API error → respawn `<role>-N` at once" conflicts with coordinator §3, which says to stop on a usage or rate limit, and otherwise retry once and then have tech-lead abandon and recreate the task.
6. **Run-state cadence.**
   - Write one PATCH per hand-back, not one per line.
   - The run-state comment id has to be found again by its heading after compaction.
   - Tech-lead's plan-comment edits need the PATCH-by-id rule, because `--edit-last` can hit another role's comment.
   - spawn-context's 80-line cap cuts the Tasks section first.
7. **Idle turns and proposals.** A resumed turn that has nothing for coordinator needs a defined no-op hand-back, such as `[role] waiting on <role>`. A proposal's eight fields (proposals.md) need a home, for example a ticket comment that the line links to.
8. **Detection.** Test the exact path `~/.claude/teams/session-<first 8 of $CLAUDE_CODE_SESSION_ID>/config.json`. An unset variable must stop and ask, not fall into the mode. A CLI with agent teams disabled lands in the same state; the README should say so.
9. **ADR hygiene.** The draft's claim that it "amends ADR 0003" was wrong: 0003's option 1 is about session `/resume`. What really changes is 0003's Consequence that hand-backs reach coordinator "by platform accident". Edit 0003 in place (no back-compat), and open the new ADR with the decision sentence.
10. **Naming.** The draft's `main` vs `team-lead`, and the "final message" vs `SubagentHandback` wording, conflicted across team-modes, coordinator (`[team-lead]` tags at §2 and §3), phased-workflow **Subagents**, and the GLOSSARY.

The full round-2 report is on this branch at `docs/reviews/2026-11-04-pr42-round-2.md` (its line numbers point into 75bc97e). The commits on this branch show the draft text: `git show 75bc97e -- skills/team-modes/SKILL.md skills/coordinator/SKILL.md docs/adr/0007-hand-back-mode.md`.

## Options to weigh first (grill these with Max)

Don't start with the prose. Pick the state model first.

- **A. Coordinator keeps the real task list with its own task tools.** The main session has TaskCreate, TaskUpdate, TaskList and TaskGet, with native blocked-by, owner and details.
  - Teammates report task operations in their hand-backs, and coordinator applies them to that list.
  - Blocked-by, ids, claim and details then come from the platform, which kills findings 1–3.
  - The task list dies with the session, so the run-state snapshot still has to be kept for resume.
  - The draft's ADR rejected this as "a second copy". Re-judge it now that the prose version has failed twice.
- **B. The draft's approach: run state plus plan comment as the store.** Fixable, but each fix is more prose for coordinator to execute by hand, and reviews keep finding holes.
- **C. Don't run teams in the desktop app's agent host.**
  - In the desktop app, coordinator stops and tells the user to start `claude` in the app's Terminal panel, a real CLI session with agent teams.
  - This is the cheapest to build, and the CLI path is already designed and tested.
  - Max works in the desktop app, so ask whether a terminal tab inside it is acceptable.
- **D. Hybrid.** C as the default, with A behind it for users who insist.

Whatever you pick, also decide:
- the channel rules (hand-back tool, the `main` name, who may `SendMessage` whom);
- crash and usage-limit handling, consistent with coordinator §3;
- the worktree unlock order;
- where a validator fail's repro lives;
- how observation works when every teammate sits idle between resumes;
- the cost: one resume per phase report.

## Rules of this repo and this user

- **Docs.** Read `README.md`, `docs/GLOSSARY.md` (use its words, flag its _Avoid_ words), `docs/adr/`, `docs/out-of-scope.md`, `prompts/review-plugin.md`, and the `heinzelwerk:writing-for-agents` skill before you write plugin text.
- **No back-compat.** Edit docs and ADRs in place. No version-history notes inside decisions.
- **Testing.** Every behaviour a script can check gets a regression case in `scripts/tests/`. Show that a new test bites: it must fail against the previous script.
- **Subagents.**
  - Never use the Fable model.
  - Use Opus for design and for every reviewer, and Sonnet only for fully specified implementation. Verify that Sonnet's tests bite.
- **Merging.**
  - Never `git stash`; use a WIP commit or a worktree.
  - Never wrap or run `gh pr merge`.
  - Every PR gets a fresh reviewer before Max merges it.
- **Commits.** Use conventional commits with the `Co-Authored-By` trailer.
- **Windows Git Bash.** Prefix `git show ref:path` with `MSYS_NO_PATHCONV=1`. Watch `sed` eating backslashes, and JS `String.replace` expanding `$'`.
- **Communication style.** Max wants terse, compressed answers (caveman style).
