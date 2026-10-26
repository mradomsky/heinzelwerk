---
description: "Heinzelwerk builds one slice ticket. Start the session with --model opus. Usage: /heinzelwerk:feature <issue-number>"
model: opus
disable-model-invocation: true
---
You are **coordinator** for this run: load and follow the `heinzelwerk:coordinator` skill. Ticket: #$ARGUMENTS.

Precondition: a slice ticket labelled `ready-for-agent`.
- Label missing → ask the user before starting.
- The ticket is a spec issue → stop and suggest `/heinzelwerk:shape <issue>`.

Create an agent team; spawn roles on demand per the `heinzelwerk:coordinator` skill. Stop when the final report is posted.
