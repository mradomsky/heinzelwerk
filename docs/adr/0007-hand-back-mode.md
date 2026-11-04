# Without a team config, teammates report by hand-back and the plan comment is the task list

The Claude desktop app runs every teammate as a background subagent of the main session: it writes no `~/.claude/teams/<team>/config.json`, gives teammates no task tools, and ends a teammate's turn when it reports (found in the first workspace run, V-M-Pioneer-Trading/meta#140, with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` and `CLAUDE_CODE_ENABLE_TODO_TOOLS` both set). Coordinator detects this before the first spawn (no config carries this session's `leadSessionId`) and runs in **hand-back mode** (team-modes skill): each teammate reports through its hand-back, coordinator resumes teammates by name, every task operation is a `task …` line coordinator applies to the run state's snapshot, and task details live in tech-lead's plan comment. This amends ADR 0003, whose option 1 assumed teammates cannot be resumed: in this host they can, by `SendMessage`.

## Considered Options

1. **Refuse to run without a team config** — rejected. The desktop app is where the owner works, and the first run there finished with the same roles and gates once coordinator relayed.
2. **Coordinator emulates the task list with its own task tools** — rejected. The main session has them, teammates do not, so every teammate step would still be a message to coordinator; the tools would only add a second copy of the state.
3. **Hand-back lines plus the plan comment and run state** (chosen). Both already exist on GitHub, survive compaction and a new session, and a resumed run reads them as before.

## Consequences

- Coordinator's run state is the live task list in this mode and is edited on every relayed `task` line, not only at phase changes.
- The idle and silence clocks apply only while a spawn or resume runs without a hand-back.
- Every role's channel to coordinator is a hand-back, so roles that end their turn at each phase cost a resume each; the run in meta#140 took 20 minutes for one PR.
