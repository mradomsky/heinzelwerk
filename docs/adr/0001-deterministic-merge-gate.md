# Merging is a deterministic script in the plugin, never an agent's call

Agents open PRs; the only thing that merges one is `scripts/merge-gate`, which reads `merge-policy.json` from `main`, the validator's `heinzelwerk: validated <sha>` line, CI, and mergeability. No role, prompt, or PR comment can merge another way, and the guard hook blocks `gh pr merge`.

## Considered Options

1. **Validator merges on pass** — rejected. The validator is a model under a shared `gh` login; a sentence in a ticket could talk it into merging, and the retro could not tell a judgement from a slip.
2. **Gate script committed into each target repo** — rejected. A PR could change the gate that judges it, and every fix would need a PR per repo.
3. **Gate script in the plugin's `scripts/`, policy in the target repo's `main`** (chosen). The code ships with the plugin and no PR can touch it; the policy stays with the project and only a human merge changes it.

## Consequences

- The validated line is a protocol marker, not an authorization: any role could post it. Acceptable while `main` is not production; the README says so.
- Policy files, `.claude/settings*.json`, and workflows always wait for a human, whatever the policy says.
