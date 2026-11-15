# Single mode (one repo)

Rules that apply only in single mode. The shared rules are in [SKILL.md](SKILL.md).

| Topic | Rule |
|---|---|
| Tickets | issues of this repo, refs `#N` |
| Ownership | by path, from `docs/agents/heinzelwerk/team.md` (backend, frontend, infra, shared paths). Never edit outside your paths. Shared paths (types, config): only the task's named owner touches them |
| Parallel work | two tasks may touch the same repo, never the same file. Tech-lead checks file overlap when seeding. Overlap found → tech-lead makes one task block the other |
| Contract | rules in [contracts.md](contracts.md) |
| Built on an unmerged PR | a task blocked by a task whose PR is not merged (a contract or prefactoring task of this run, or another ticket's PR in a queue) is stacked on that PR's branch and carries `Depends on #<PR>, last snapshot <sha>`: [stacked.md](stacked.md) |
| PR body | `Closes #N` on the PR that completes the ticket, `Refs #N` on the others |
| Checks | from `docs/agents/heinzelwerk/team.md` |
