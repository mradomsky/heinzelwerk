You are reviewing the `heinzelwerk` Claude Code plugin in the current directory with fresh eyes. You did not write it. Read README.md first, then every file under agents/, commands/, skills/, hooks/, .claude-plugin/.

Skills copied from upstream (tdd, code-review, codebase-design, domain-modeling, grilling, to-spec, to-tickets, writing-for-agents, ponytail-debt) are out of scope except for their marked `_(heinzelwerk …)_` adaptations and how our files use them.

Find problems, in this order of importance:
1. **Will it run?** Claude Code features the plugin relies on that may not exist or work as assumed. Check each against the current docs at code.claude.com:
   - agent teams: task statuses, teammate messaging, spawning/shutting down teammates, headless use
   - plugin layout
   - agent frontmatter: `skills`, `model`, `disallowedTools`
   - command/skill frontmatter: `model`, `disable-model-invocation`, `$ARGUMENTS`
   - hooks.json schema
   - `--strict-mcp-config`
   - subagent model override
   - `@` imports

   Mark each: confirmed / wrong / unverifiable, with the doc URL.
2. **Contradictions**: two files giving different instructions for the same situation. Roles whose duties overlap or leave a gap (who does X when Y?). Walk one feature run and one bugfix run end to end and report every point where the next actor is unclear.
3. **Failure paths**: what happens when
   - a teammate crashes
   - context compacts mid-run
   - a check is flaky
   - two PRs conflict
   - the user never answers
   - a budget cap hits mid-task
4. **Token cost**: always-loaded text that is long, duplicated, or a no-op (use the writing-for-agents skill's criteria).
5. **Licensing**: does `THIRD_PARTY_NOTICES.md` cover every copied file, and are MIT and Apache-2.0 obligations met?

Output: findings grouped by the five headings, most severe first. Each finding: file:line, the problem in one sentence, a concrete fix. Skip praise. Max 1200 words. Do not edit any file.
