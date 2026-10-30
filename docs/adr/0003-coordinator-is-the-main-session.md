# The coordinator is the main session; there is no supervisor teammate

Process (spawning, releasing, observing, the user channel, the final report) belongs to the session the user started. Product owns what, tech-lead owns how, and no third teammate watches the team.

## Considered Options

1. **A supervisor or guardian teammate** — rejected. Only the main session can spawn and shut down teammates, read every notification, and talk to the user; a supervisor would relay each of those to it. Nested teams, delegate mode, and `/resume` of teammates do not exist.
2. **Tech-lead as coordinator** — rejected. Tech-lead's context fills with design; the process role must stay light enough to survive a long run and post the run state when compaction comes.
3. **Coordinator as a skill the main session loads** (chosen). The platform names that session `team-lead`; the role name stays `coordinator` to keep it apart from `tech-lead`, which was renamed from `lead` for the same reason.

## Consequences

- Runs are interactive: a `-p` session cannot spawn teammates, so unattended runs need an outer runner that starts an interactive session, not a headless loop. See `docs/out-of-scope.md`.
- Hand-backs from a teammate's subagent land on the coordinator by platform accident; it forwards them (coordinator §2).
