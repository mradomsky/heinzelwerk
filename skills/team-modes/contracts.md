# Contract changes

Read when your task, or **Contracts** in `docs/agents/heinzelwerk/team.md`, names a contract your change touches. The shared rules are in [SKILL.md](SKILL.md).

**Contracts**: the paths under **Contracts** in `docs/agents/heinzelwerk/team.md`, plus cross-repo interfaces in workspace mode.
**Provider**: the role named there. For shared types, the provider is the task's named owner. In workspace mode, the provider is the role of the repo marked provider in `docs/agents/heinzelwerk/workspace.md` **Who calls whom**.
**Consumers**: the roles whose code reads the contract.

- **Backward compatible by default.** Compatible means every existing consumer still works unchanged; examples: new optional inputs, a required input made optional, new outputs. Never rename, remove, retype, narrow, or make something required. A new enum value in an output is breaking, because consumers that match exhaustively fail. A compatible change needs no consumer work: update the contract file in the provider's own PR and put this line in the PR body: `contract: compatible — <what changed>`.
- **Breaking change your task doesn't already name** → propose it to tech-lead **before coding** it, as a proposed task naming the consumers it breaks. Hold the breaking part until tech-lead answers; keep working on the rest of your task. Contract proposals don't count against the proposal budget. If accepted, that proposed task becomes the contract task; the breaking part goes there, not in your current PR. Tech-lead decides:
  - consumer update in scope → tech-lead accepts the contract task and adds the consumer task, blocked by the contract task. Consumer role not running → tech-lead tells coordinator to spawn it.
  - scope unclear → product rules **in** (previous bullet) or **out** (next bullet).
  - out of scope → product picks one: drop the breaking part (stay compatible), or keep a compatible shim and file a `needs-triage` issue for the consumer update. Tech-lead tells the proposer the choice and rejects the proposed task; the compatible version goes in the proposer's current PR.
- **Consumer needs a contract change mid-task** (missing endpoint, field, or output) → propose it to tech-lead as a proposed task, with the provider as owner hint; it doesn't count against the proposal budget. Tech-lead accepts it as the contract task and makes your task blocked-by it. Keep working on what doesn't depend on the change. Once the contract PR is open:
  - same repo → `git fetch origin && git rebase origin/<contract-branch>` in your worktree;
  - other repo → add `Depends on owner/provider-repo#<PR>` to your PR body.

  Provider: when the contract PR opens, message the consumer task's owner (or tech-lead if that owner isn't running).
- Never break a consumer that has no task in this run.
