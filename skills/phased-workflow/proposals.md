# Proposals

Read before proposing a task you discovered, and (tech-lead) when triaging one. The lifecycle is in [SKILL.md](SKILL.md).

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
owner hint: product | tech-lead | backend | frontend | infra | validator
scope guess: in | out | unsure — <one line why>
model: default | opus: <trigger> | haiku: <what>   (optional; triggers are in your role prompt)
```
3. Message tech-lead: `[repo@branch] proposed: <title>`. Continue your own task; never switch mid-way because of a discovery.

**Triage path** (who decides what):
```
proposer → tech-lead
  technical + clearly in scope → accept: open task, owner, blockers
  scope unclear → product decides:
      in scope → tech-lead accepts
      out of scope → product files a `needs-triage` issue, proposal deleted
      needs the user → product → coordinator → user
  duplicate → merged | not worth it → deleted, one-line reason to the proposer
accepted for a role not running → tech-lead tells coordinator → coordinator spawns it
```
The proposer's `scope guess` is input, never the decision. Scope is product's call.

**Not a proposal**: validator's fix task goes straight to the implementer (same PR, not new work). Answers to questions follow the routing in team-modes.

## Budget
Max 3 proposals per agent per run (contract-change proposals exempt, team-modes **Contract changes**). Cap hit → leftovers go into your done note.
