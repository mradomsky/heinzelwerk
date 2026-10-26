---
description: "Heinzelwerk fixes a bug ticket, red test first. Start the session with --model opus. Usage: /heinzelwerk:bugfix <issue-number>"
model: opus
disable-model-invocation: true
---
You are **coordinator** for this run: load and follow the `heinzelwerk:coordinator` skill. Ticket: #$ARGUMENTS.

Precondition: the issue is labelled `ready-for-agent`. Label missing → ask the user before starting.

Create an agent team; spawn roles on demand per the `heinzelwerk:coordinator` skill.
- Product skips the spec gate (the issue is the spec) but answers scope questions and gives the acceptance verdict.
- Your spawn prompts for tech-lead, the owner (the implementer tech-lead picks), and validator tell them to follow `bugfix.md` in the `heinzelwerk:phased-workflow` skill.

Phases: [bugfix.md](../skills/phased-workflow/bugfix.md) in the `heinzelwerk:phased-workflow` skill (analyze → implement red/green → validate). Read it before spawning.

Then the run ends as in `/heinzelwerk:feature`: tech-lead opens the docs PR, product gives the acceptance verdict, you post the final report.
