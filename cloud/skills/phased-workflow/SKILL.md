---
name: phased-workflow
description: "heinzelwerk-cloud task lifecycle, done notes, implementer rules. Use for every task in a run."
user-invocable: false
---
# Phased workflow (cloud)

## Ticket vs task
- **Ticket = GitHub issue.** Durable. Carries context across runs. One ticket spans all phases.
- A run takes one **slice ticket**: a tracer bullet from `heinzelwerk-cloud:to-tickets`, labelled `ready-for-agent`,
  usually a sub-issue of a spec issue. Spec issues are never run directly.
- **Task = one subagent spawn.** Disposable, gone after the run. There is no shared task list in cloud: tech-lead's plan
  comment seeds the tasks, coordinator's run-state comment on the ticket tracks them, reports move them. Title:
  `#<ticket> <role> <kind>: <what>`, e.g. `#19 backend implement: anomaly webhook`, `#19 validate backend: anomaly webhook`,
  `#19 frontend fix 1: anomaly webhook`, `#19 validate: slice acceptance`, `#19 tech-lead analyze: locate bug`. The role in
  the title is the owner; every `validate` task is validator's.
- Where tickets live, how refs, branches, worktrees, PRs, and reports look → **team-modes skill**.
- Anything the next run must know goes on GitHub, never only in a report (REST forms in team-modes `gh-rest.md`):
  - decisions, rejected approaches, blockers → comment on the ticket
  - code → PR with `Closes #N` (or `Refs #N` if partial) in body; commits reference `#N`
  - task state change that matters (blocked, needs work, abandoned) → issue comment with one-line reason

## Phases
Every task has exactly one phase: **analyze** (understand, decide; ends with a conclusion on the ticket and the next
tasks), **implement** (ends with a PR and a validate request), **validate** (ends with a verdict: pass, or a fix block
with the repro). Roles say WHO, phases say WHAT KIND of work. A task is not done until its handoff exists in the
report; phases chain by handoff, coordinator spawns the next one. Bugfix runs: [bugfix.md](bugfix.md).

## Task lifecycle
- **Spawned** by coordinator with the task block from tech-lead's plan in the prompt. You work only that task: never
  the next one, never another role's.
- **Implement task done** = PR open, done note in your report, `spawn: validator: #N validate <role>: <what>` as its
  last line. The validate task is the quality gate.
- **Validate task**: validator posts the verdict on the PR. Fail → the report carries a fix block
  (`fix <k>: <what>`, k counts rounds, the repro, file:line); coordinator respawns the owner on the same branch. The
  owner fixes, reports a new done note and a new validate request. **Fix cap: 3 per PR.** A fail after the third →
  validator's report says `escalate: tech-lead: fix cap` instead; tech-lead splits, reassigns, or stops. The
  `validated` line lives on the PR the gate merges: a re-landed or re-opened PR is a new PR and gets a new validate task.
- **Proposal** = `proposed: #N <what>` block in a report (fields in [proposals.md](proposals.md)). Coordinator holds it
  and hands it to tech-lead, the only role that triages: accept = a task block for coordinator to spawn; reject = a
  one-line reason.
- **Abandoned** (cannot finish, needs a human): `abandoned: <why>` in the report, one-line reason on the ticket.
- "Under review" elsewhere means a validate task is pending or running for the PR; "needs work" means a fix is open.

## Implementers (backend, frontend, infra)
- **Before coding**: the docs the `## Docs` section names; frontend also `docs/agents/heinzelwerk/design.md`, infra also
  `docs/agents/heinzelwerk/infra-policy.json`.
- **Smallest complete change**: reuse what the codebase has, then the standard library, then an installed dependency. No
  abstraction, option, config, or "for later" code nobody asked for. Finish every part the change touches: callers,
  tests, fixtures. Keep validation at trust boundaries, error handling, security, and accessibility. A shortcut with a
  known limit gets a code comment `shortcut: <limit>, <when to upgrade>`.
- **No subagents** in cloud. Where your role prompt would send work to Opus (root cause unknown after two failed
  passes, shared code whose callers you can't see from the edit site) or Haiku (call-site sweeps, mechanical batches):
  do the small version yourself, or stop at a clean point, commit, push, and report `escalate: opus|haiku: <what, why>`;
  coordinator reruns that part on that tier and respawns you with the result. State it in `escalations:`.
- **Questions**: what you can't settle from the ticket, spec, glossary, ADRs, team rules, or code → finish everything
  that doesn't depend on it, commit, push, report `question: <product|tech-lead>: <one question>`; you get respawned with
  the answer.
- **Done**: branch, worktree, commits, PR body per team-modes (`did:` and `evidence:` lines in the PR body). PR open →
  report: `[<repo>@<branch>]`, done note, `spawn: validator: #N validate <role>: <what>`. A fix task → same branch, same loop.

## Discovering work
Found something while working? Don't silently fix it, don't drop it: a `proposed:` block in your report, and continue
your own task. The fields, the dedup rule, the triage path, and the budget (3 per agent per run) are in
[proposals.md](proposals.md).

## Done note (required in every report)
The `did:` and `evidence:` lines also go in the PR body.
```
did: <what changed, files>
evidence: <command + result summary, or PR link>
handoff: <spawn: line / verdict / tasks created>
left: <anything not done, discoveries not filed; tech-lead collects these into the technical report>
term: <optional: domain concept that is missing from or contradicts GLOSSARY.md>
adr: <optional: decision you made that is hard to reverse, surprising, and a real trade-off>
learning: <optional: one line worth remembering next run: warning | discovery | codebase>
escalations: <none | asked opus: why | asked haiku: what>
risk: <optional: area that deserves an Opus review but isn't in team.md's risk areas, and why>
```

## Docs
Before starting, follow the `## Agent skills (heinzelwerk)` pointers in CLAUDE.md (or AGENTS.md): domain docs, team
rules, learnings. Name things with `GLOSSARY.md` vocabulary; flag ADR conflicts explicitly.
`GLOSSARY.md`, `docs/adr/`, and learnings change only through tech-lead's docs PR at the end of a run. Your job is to
leave candidates in your done note (`term:`, `adr:`, `learning:`, `risk:`).

## Token discipline
Every token you read is paid again on every later turn, and your whole report lands in coordinator's context:
- **Commands**: quiet or summary flags (`--silent`, `-q`, dot/summary reporters). Long output → `2>&1 | tail -40`. On
  failure, rerun only the failing test or step for detail.
- **Reading**: repo map first, then `grep`/`glob` to locate, then read the line range you need. Whole files only when
  small or when you change most of them.
- **Reports**: conclusions and evidence, never transcripts or full logs. Quote the shortest decisive line of an error.
