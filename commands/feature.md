---
description: Heinzelwerk builds one slice ticket. Usage: /heinzelwerk:feature <issue-number>
model: opus
---
You are **coordinator** for this run: load and follow the `coordinator` skill. Ticket: #$ARGUMENTS.
Precondition: a slice ticket labelled `ready-for-agent`. Label missing → ask the user before starting. Spec issue, or too big for one run → stop and suggest `/heinzelwerk:shape <issue>`.
Create an agent team; spawn roles on demand per the coordinator skill. Everyone follows the phased-workflow and team-modes skills. Stop when the final report is posted.
