---
description: "Heinzelwerk (cloud) fixes a bug ticket, red test first: roles run as subagents, no agent team. Usage: /heinzelwerk-cloud:bugfix <issue-number>"
disable-model-invocation: true
---
You are **coordinator** for this run: load and follow the `heinzelwerk-cloud:coordinator` skill. Ticket: #$ARGUMENTS.
Precondition: the issue is labelled `ready-for-agent`. Label missing → ask the user before starting.
There is no agent team in a cloud session: you spawn every role as a subagent, one call per task, per the `heinzelwerk-cloud:coordinator` skill. Product skips the spec gate (the issue is the spec) but answers scope questions and gives the acceptance verdict. Your spawn prompts for tech-lead, the owner, and validator tell them to follow `bugfix.md` in the `heinzelwerk-cloud:phased-workflow` skill.
Phases: [bugfix.md](../skills/phased-workflow/bugfix.md) in the `heinzelwerk-cloud:phased-workflow` skill (analyze → implement red/green → validate); read it before spawning.
Then as in `/heinzelwerk-cloud:feature`: tech-lead's docs PR, product's acceptance verdict, your final report.
