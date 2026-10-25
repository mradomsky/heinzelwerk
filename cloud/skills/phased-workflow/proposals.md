# Proposals (cloud)

Read before proposing a task you discovered, and (tech-lead) when triaging one. The lifecycle is in [SKILL.md](SKILL.md).

## Discovering work (branching)
Found something while working? Don't silently fix it, don't drop it. **Propose** it:
1. **Dedup first**: same goal or same files in tech-lead's plan, coordinator's run state, or open issues → comment there instead.
2. Else put a `proposed: #N <what>` block in your report with these fields:
```
phase: analyze | implement | validate
why: <what you saw, file:line or failing output>
done when: <concrete, checkable>
handoff: <what task/verdict you will leave behind>
blocks / blocked-by: <task titles>
owner hint: product | tech-lead | backend | frontend | infra | validator
scope guess: in | out | unsure — <one line why>
model: default | opus: <trigger> | haiku: <what>   (optional; triggers are in your role prompt)
```
3. Continue your own task; never switch mid-way because of a discovery. Coordinator hands the proposal to tech-lead.

**Triage path** (who decides what):
```
proposer → coordinator → tech-lead
  technical + clearly in scope → accept: a task block (owner, blockers, seams) for coordinator to spawn
  scope unclear → product decides (coordinator spawns product with the proposal):
      in scope → tech-lead accepts
      out of scope → product files a `needs-triage` issue, proposal dropped
      needs the user → product → coordinator → user
  duplicate → merged | not worth it → dropped, one-line reason for the proposer
```
The proposer's `scope guess` is input, never the decision. Scope is product's call.

**Not a proposal**: validator's fix block goes straight back to the implementer (same PR, not new work). Answers to
questions follow the routing in team-modes.

## Budget
Max 3 proposals per agent per run (contract-change proposals exempt, team-modes **Contract changes**). Cap hit →
leftovers go into your done note's `left:` line.
