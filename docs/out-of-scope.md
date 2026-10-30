# Out of scope

Features and designs heinzelwerk itself has turned down, for reasons that still hold. Reviews (`prompts/review-plugin.md`), retro's team actions, and design sessions read this before proposing. A row is an answer, not a ban: when `revisit when` holds, propose again and say so. A rule that must always hold is an ADR in `docs/adr/`, not a row.

| proposal | rejected by | reason | revisit when |
|---|---|---|---|
| dedicated designer, QA, security, or docs agents | design session 2026-10 | each is covered by a doc plus a check plus the validator's review (design.md, checks, risk areas, docs PR); a role costs a full session on every turn | a retro shows a class of defects no check or review axis catches |
| a supervisor or guardian teammate watching the team | design session 2026-10-20 | only the main session can spawn, release, and see every teammate; a supervisor teammate would relay to it; folded into coordinator | the platform lets a teammate spawn or shut down others |
| headless (`claude -p`) team runs | 2026-10-20, 2026-10-30 | `-p` cannot spawn teammates; agent teams need an interactive session | the platform documents teammate spawning in print mode |
| sandcastle (or another container runner) as the run host | comparison 2026-10-30 | it drives `claude --print` per iteration, so it cannot host a team; it fits single-agent pieces (validator, retro, adopt-docs) only | a headless team run exists, or a single-agent night-run skill is designed |
| vendored skills synced from upstream automatically | design session 2026-10 | upstream renames things silently; copies are pinned and adapted by hand, marked `_(heinzelwerk …)_` | upstream publishes versioned releases |
| merging `to-spec` and `to-tickets` into `/shape` | design session 2026-10 | they stay typeable for odd cases (a spec written elsewhere); `/shape` drives them | nobody has typed them directly in three retros |
| renaming `/shape`; a `grill-with-docs` command | design session 2026-10 | one entry point; grilling and domain modeling are skills `/shape` loads | a second entry point is asked for by a user |
| a "Haiku needs a verifier" rule in model-selection | design session 2026-10 | Haiku is used only for breadth and mechanical batches whose output the spawner checks anyway | Haiku is given a judgement task |
| caveman voice in infra prompts | design session 2026-10 | Terraform plans and policy decisions need normal prose; voice rules apply to messages and done notes only | a token measurement shows infra messages dominate a run |
| non-empty `auto_apply_dirs` by default | design session 2026-10 | the apply gate is opt-in per environment; a default would apply on the first run after setup | never by default; setup asks |
| tech-lead waving through what `tf-gate` stops | design session 2026-10 | the gate is deterministic on purpose; tech-lead may only escalate to the user | never; a policy change on main is the only widening |
| `bin/` for the plugin scripts | directory prep 2026-10-26 | claude.ai and Cowork refuse a plugin with a top-level `bin/`; `scripts/` on PATH through the SessionStart hook does the same job | the directory accepts `bin/` |
| storing transcripts in the target repo (archive on run end) | 2026-10-30 | transcripts can hold secret values and are large; the done note's `session:` line points at the local file instead | a redacting exporter exists |
| a stand-in binary when the real tool or model is unavailable during validation | 2026-10-30 | partial evidence read as evidence; `inconclusive: <why>; verify on <where>` says what was not run | a repo's checks depend on a tool no machine in the team has |
| a `triage` skill for `needs-triage` issues | 2026-10-30 | not designed yet; retro files `needs-triage` candidates and a human triages | the `needs-triage` backlog outgrows the weekly retro |
| stack-tagged example lines in the setup templates | 2026-10-30 | the evidence rule (every line from the verified map, `path:line`) stopped the verbatim copies; examples are examples | a setup run on a non-Node repo copies a Node example again |
| tagged JSON copies of done notes and verdicts | 2026-10-30 | `check-note` validates the prose fields; a second copy drifts on fix rounds | retro or the gate needs a field the prose check cannot read reliably |
