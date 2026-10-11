---
name: phased-workflow
description: How heinzelwerk tasks are typed, handed off, tracked on GitHub, validated, and finished, plus the shared implementer rules. Use whenever creating, claiming, or completing a task in a team run.
user-invocable: false
---
# Phased workflow

## Ticket vs task
- **Ticket = GitHub issue.** Durable. Carries context across runs. One ticket spans all phases.
- A team run takes one **slice ticket**: a tracer bullet from `to-tickets`, labelled `ready-for-agent`, usually a sub-issue of a spec issue. Spec issues are never run directly.
- **Task = agent-team task.** Disposable, gone after the run. Title: `#<ticket> <role> <kind>: <what>`, e.g. `#19 backend implement: anomaly webhook`, `#19 validate backend: anomaly webhook`, `#19 frontend fix 1: anomaly webhook`, `#19 validate: slice acceptance`, `#19 lead analyze: locate bug`. The role in the title is the owner; nothing else in the task list says who owns it.
- Where tickets live, how refs, branches, worktrees, and PRs look → **team-modes skill**. It differs between single-repo and workspace mode.
- Anything the next run must know goes on GitHub, never only in a task:
  - decisions, rejected approaches, blockers → `gh issue comment N`
  - code → PR with `Closes #N` (or `Refs #N` if partial) in body; commits reference `#N`
  - task state change that matters (blocked, needs work, abandoned) → issue comment with one-line reason

## Phases
Every task has exactly one phase. Roles say WHO, phases say WHAT KIND of work.
A task is not done until its handoff exists. Phases chain by handoff, not by someone pushing.

| Phase | Kind of work | Done when | Handoff (part of done) |
|---|---|---|---|
| analyze | understand, plan, investigate, decide | conclusion posted on ticket | next tasks created, or "no action" stated on ticket |
| implement | change code or contract | red → green at the task's seams (`tdd` skill), checks pass locally, PR open. Infra: fmt/validate/lint green, plan saved, tf-gate output in PR. UI: screenshots of changed screens in PR | done note in the task's details, then a **validate task** for this PR created |
| validate | test, review, verify; last one: slice acceptance on integrated branches | verdict with evidence | pass → nothing more; fail → a **fix task** for the implementer with the repro |

## Task lifecycle
The task list has three states: pending, in progress, completed. A task's title never changes after creation; a new state means a new task.

- **Open** = pending with a role in the title. Lead's seeded tasks start here, blockers set as task dependencies. The owner claims it (in progress).
- **Implement task done** = PR open, done note written into the task's details (`TaskUpdate`), task completed, and `#N validate <role>: <what>` created (pending). The implementer completes its own implement task; the validate task is the quality gate.
- **Validate task**: validator claims it, posts the verdict, completes it. Fail → create `#N <role> fix <k>: <what>` (pending; k counts rounds) with the repro in its details, and message the owner. The owner fixes on the same branch, writes its done note, completes the fix task, creates the next validate task. Max 3 fix tasks per PR, then validator messages lead: split, reassign, or stop.
- **Proposal** = `[proposed] #N <what>` (pending; owner hint and the fields below in its details). Only lead acts on it: accept = create the open task (owner role in the title, blockers as dependencies, seams in details) and delete the proposal; reject = delete it with a one-line reason to the proposer. Nobody claims a proposal.
- **Abandoned** (cannot finish, needs a human): done note says `abandoned: <why>`, task completed, one-line reason on the ticket, lead told.
- "Under review" elsewhere means a pending or in-progress validate task exists for the PR; "needs work" means a fix task exists.

## Implementers (backend, frontend, infra)
- **Before coding**: the docs the `## Docs` section names; frontend also `docs/agents/heinzelwerk/design.md`, infra also `docs/agents/heinzelwerk/infra-policy.json`.
- **Smallest complete change**: reuse what the codebase has, then the standard library, then an installed dependency. No abstraction, option, config, or "for later" code nobody asked for. Finish every part the change touches: callers, tests, fixtures. Keep validation at trust boundaries, error handling, security, and accessibility. A shortcut with a known limit gets a code comment `shortcut: <limit>, <when to upgrade>`.
- **Interfaces**: deep modules, small interfaces.
- **Subagents**: Opus when the root cause is still unknown after two failed passes, or when you change shared code whose callers you can't see from the edit site; Haiku for call-site searches and mechanical batches. Your role prompt may add triggers. State both in `escalations:`.
- **Done**: branch, worktree, commits, PR body per team-modes. PR open → done note into the task's details, complete the task, create `#N validate <role>: <what>`. A fix task from validator → same branch, same loop.

## Discovering work (branching)
Found something while working? Don't silently fix it, don't drop it. **Propose** it:
1. **Dedup first**: same goal or same files in task list or open issues → comment there instead.
2. Else create `[proposed] #N <what>` with these fields in its details:
```
phase: analyze | implement | validate
why: <what you saw, file:line or failing output>
done when: <concrete, checkable>
handoff: <what task/verdict you will leave behind>
blocks / blocked-by: <task ids>
owner hint: product | lead | backend | frontend | infra | validator
scope guess: in | out | unsure — <one line why>
model: default | opus: <trigger> | haiku: <what>   (optional; triggers are in your role prompt)
```
3. Message lead: `[repo@branch] proposed: <title>`. Continue your own task; never switch mid-way because of a discovery.

**Triage path** (who decides what):
```
proposer → lead
  technical + clearly in scope → accept: open task, owner, blockers
  scope unclear → product decides:
      in scope → lead accepts
      out of scope → product files a `needs-triage` issue, proposal deleted
      needs the user → product → coordinator → user
  duplicate → merged | not worth it → deleted, one-line reason to the proposer
accepted for a role not running → lead tells coordinator → coordinator spawns it
```
The proposer's `scope guess` is input, never the decision. Scope is product's call.

**Not a proposal**: validator's fix task goes straight to the implementer (same PR, not new work). Answers to questions follow the routing in team-modes.

## Budget
Max 3 proposals per agent per run (contract-change proposals exempt, team-modes **Contract changes**). Cap hit → leftovers go into your done note.

## Done note (required on every task you finish)
Write it into the task's details before completing the task; the `did:` and `evidence:` lines also go in the PR body.
```
did: <what changed, files>
evidence: <command + result summary, or PR link>
handoff: <task id / verdict created>
left: <anything not done, discoveries not filed; lead collects these into the technical report>
term: <optional: domain concept that is missing from or contradicts GLOSSARY.md>
adr: <optional: decision you made that is hard to reverse, surprising, and a real trade-off>
learning: <optional: one line worth remembering next run: warning | discovery | codebase>
escalations: <none | opus subagent: why | haiku subagents: what, effort>
risk: <optional: area that deserves an Opus review but isn't in team.md's risk areas, and why>
```

## Docs
Before starting, follow the `## Agent skills (heinzelwerk)` pointers in CLAUDE.md (or AGENTS.md): domain docs, team rules, learnings. Name things with `GLOSSARY.md` vocabulary; flag ADR conflicts explicitly.
`GLOSSARY.md`, `docs/adr/`, and learnings change only through lead's docs PR at the end of a run. Your job is to leave candidates in your done note (`term:`, `adr:`, `learning:`, `risk:`).

## Token discipline
Every token you read is paid again on every later turn. Keep context small:
- **Commands**: run with quiet or summary flags (`--silent`, `-q`, dot/summary reporters). Long output → `2>&1 | tail -40`. On failure, rerun only the failing test or step for detail.
- **Reading**: repo map first, then `grep`/`glob` to locate, then read the line range you need. Whole files only when small or when you change most of them.
- **Messages and done notes**: conclusions and evidence, never transcripts or full logs. Quote the shortest decisive line of an error.
