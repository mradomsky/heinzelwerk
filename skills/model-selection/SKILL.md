---
name: model-selection
description: "heinzelwerk model tiers and effort for subagents. Use inside /heinzelwerk:shape, retro, setup, or adopt-docs; team runs use the triggers in their role prompts."
---

# Choosing a model tier

Pick the tier from what catches a mistake in the output, not from how much the work matters. Almost all work matters; what differs is whether an error would be noticed.

## The one question: what checks this output?

| What checks the output | Tier |
|---|---|
| **Something mechanical**: a compiler, type checker, test suite, schema, a deterministic script, a later review step | The cheapest tier that usually gets close. The check does the quality work; paying for a stronger generator buys little. |
| **Nothing**: the output is itself the verdict, or it is acted on as is | The strongest tier. Here the model's judgement is the deliverable. |

Everything below applies that question.

## Three tiers

- **Haiku**: wide and shallow. Searches, inventories, call-site lists, mechanical edits that tests will check, first-pass sorting whose results a stronger pass looks at, condensing text already in hand.
- **Sonnet**: the default for building. Well-defined multi-step work with checks behind it: implementing a task test-first, routine review, drafting docs a human merges.
- **Opus**: depth where nothing else catches the error:
  - designs where several constraints pull against each other and the failure is a wrong trade-off, not a red build;
  - refuting a plausible "this is safe" in data loss, auth, money, or migrations;
  - a defect that two cheaper attempts did not explain;
  - effects you cannot see from the edit site (callers, shared code);
  - judging whether evidence supports a conclusion;
  - anything published or acted on without another check.

**Escalate one tier at a time.** A failed attempt moves the next attempt up one tier, not straight to the top. Exception: work already in an Opus category above goes straight to Opus. Two failures at the same tier mean the problem is depth, not effort.

## Mistakes to avoid

- **Opus on volume.** A wide sweep at the top tier. Split it: cheap finders, one strong pass over what they found.
- **A cheap tier as the final check.** If nothing after it can catch its error, the saving is fake: the check is gone and only its appearance remains.
- **One model writing and grading.** A grader with the writer's blind spots approves its mistakes. Keep the check independent; prefer a deterministic check over any model.
- **A cheap sorter that can wave things through.** A cheap classifier may send work *up* for review; only a deterministic rule may skip a review.
- **Guessing the tier.** Try the cheap tier on cases with known answers first (for a review: known findings, measure recall). Keep it if it holds.
- **Many tiny subagents.** Each one pays its own start-up context. Batch similar small jobs into one subagent.

## Effort

Effort follows the same question. High effort pays where the answer is a judgement with consequences. On mechanical work it only adds latency. Set `model` and `effort` per subagent; a workflow where everything runs at the top setting is almost always mis-tuned.

## Say what you picked

For any non-obvious choice, say in one clause which tier and why ("Haiku finders, Opus verifier: the verify step is the precision step"). That makes it reviewable and a bad default visible.

## Heinzelwerk defaults

- **Haiku effort per subtask**: low for searches and mechanical edits; medium for batches with local judgement; high for a summary or classification that feeds a decision.
- Outside the risk areas in `docs/agents/heinzelwerk/team.md`, a Sonnet or a low-effort Opus reviews what Sonnet built. Risk areas get a normal-/high-effort Opus review. Effort setting depends on the complexity of the reviewed work. Retro adds an area wherever Sonnet let something through.
