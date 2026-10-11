---
name: phased-workflow
description: Rules for heinzelwerk agents on how work is typed, handed off, tracked on GitHub, validated, and finished. Use whenever creating, claiming, or completing a task in an agent team run.
---
# Phased workflow

## Ticket vs task
- **Ticket = GitHub issue.** Durable. Carries context across runs. One ticket spans all phases.
- A team run takes one **slice ticket**: a tracer bullet from `to-tickets`, labelled `ready-for-agent`, usually a sub-issue of a spec issue. Spec issues are never run directly.
- **Task = agent-team task.** Disposable, gone after the run. Always references its ticket (`#N` in title).
- Where tickets live, how refs, branches, worktrees, and PRs look → **team-modes skill**. It differs between single-repo and workspace mode; follow it exactly.
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
| implement | change code or contract | red → green at the task's seams (`tdd` skill), checks pass locally, PR open. Infra: fmt/validate/lint green, plan saved, tf-gate output in PR. UI: screenshots of changed screens in PR | task moved to under review (= validate request) |
| validate | test, review, verify; last one: slice acceptance on integrated branches | verdict with evidence | pass → done; fail → needs work back to implementer with repro |

## Task lifecycle
`proposed → open → in progress → under review → (needs work → in progress)* → done`
- **Proposed** = discovered work awaiting triage. Only lead moves a task from proposed to open (or rejects it). Nobody starts a proposed task.
- Lead's seeded tasks start at open.
- Implementer never closes own task. Under review → validator decides.
- Needs work → fix in same branch, back to under review. Max 3 rounds, then message lead.

## Discovering work (branching)
Found something while working? Don't silently fix it, don't drop it. **Propose** it:
1. **Dedup first**: same goal or same files in task list or open issues → comment there instead.
2. Else create a task with status **proposed**:
```
phase: analyze | implement | validate
title: #<ticket> <verb> <thing>
why: <what you saw, file:line or failing output>
done when: <concrete, checkable>
handoff: <what task/verdict you will leave behind>
blocks / blocked-by: <task ids>
owner hint: product | lead | backend | frontend | infra | validator
scope guess: in | out | unsure — <one line why>
model: default | opus: <trigger> | haiku: <what>   (optional, see model-selection)
```
3. Message lead: `[repo@branch] proposed #<task>: <title>`. Continue your own task; never switch mid-way because of a discovery.

**Triage path** (who decides what):
```
proposer → lead
  technical + clearly in scope → accept: open, owner, blockers
  scope unclear → product decides:
      in scope → lead accepts
      out of scope → product files a `needs-triage` issue, task rejected
      needs the user → product → coordinator → user
  duplicate → merged | not worth it → rejected, one-line reason on the task
accepted for a role not running → lead tells coordinator → coordinator spawns it
```
The proposer's `scope guess` is input, never the decision. Scope is product's call.

**Not a proposal**: validator's needs-work feedback goes straight to the implementer (same task, not new work). Answers to questions follow the routing in team-modes.

## Budget
Max 3 proposals per agent per run (contract-change proposals exempt, team-modes **Contract changes**). Cap hit → leftovers go into your done note.

## Done note (required on every task you finish)
```
did: <what changed, files>
evidence: <command + result summary, or PR link>
handoff: <task id / verdict created>
left: <anything not done, discoveries not filed>
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
- **Reading**: repo map first, then `grep`/`glob` to locate, then read the line range you need. Whole files only when small or when you change most of them. Never re-read a file you just wrote.
- **Messages and done notes**: conclusions and evidence, never transcripts or full logs. Quote the shortest decisive line of an error.
