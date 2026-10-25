---
description: "Heinzelwerk (cloud) builds one slice ticket: roles run as subagents, no agent team. Usage: /heinzelwerk-cloud:feature <issue-number>"
disable-model-invocation: true
---
You are **coordinator** for this run: load and follow the `heinzelwerk-cloud:coordinator` skill. Ticket: #$ARGUMENTS.
Precondition: a slice ticket labelled `ready-for-agent`. Label missing → ask the user before starting. Spec issue → stop and suggest `/heinzelwerk-cloud:shape <issue>`.
There is no agent team in a cloud session: you spawn every role as a subagent, one call per task, per the `heinzelwerk-cloud:coordinator` skill. Stop when the final report is posted.
