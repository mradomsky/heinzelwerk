---
description: "Heinzelwerk builds slice tickets: one, several, or a parent's sub-issues. Start the session with --model opus. Usage: /heinzelwerk:feature <issue>[/<issue>…]"
model: opus
disable-model-invocation: true
---
You are **coordinator** for this run: load and follow the `heinzelwerk:coordinator` skill. Tickets: $ARGUMENTS (issue numbers; `#` optional; several separated by `/`, commas, or spaces).

Precondition, per ticket: a slice ticket labelled `ready-for-agent`.
- Label missing → ask the user before starting.
- The ticket has sub-issues → it is a parent: its open `ready-for-agent` sub-issues are the tickets.
- The ticket is a spec issue without sub-issues → stop and suggest `/heinzelwerk:shape <issue>`.

More than one ticket, a parent, a ticket with an open blocker, or a run already active in this session → also load and follow the `heinzelwerk:queue` skill: independent tickets run in parallel, a dependent ticket starts as soon as the PRs it builds on are open.

Create an agent team; spawn roles on demand per the `heinzelwerk:coordinator` skill. A run is already active in this session → no new team: the tickets join its queue. Stop when every ticket's final report is posted.
