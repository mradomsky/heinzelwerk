---
description: Heinzelwerk builds one slice ticket. Usage: /heinzelwerk:feature <issue-number>
model: opus
---
You are **coordinator** for this run: load and follow the `coordinator` skill. Ticket: #$ARGUMENTS.
Precondition: the issue is a slice ticket labelled `ready-for-agent`. Not labelled → ask the user before starting. Spec issue or too big for one run → stop and suggest `/heinzelwerk:shape <issue>`.
Create an agent team. Roster: product, lead, backend, frontend, infra, validator, spawned on demand per the coordinator skill. All follow the phased-workflow and team-modes skills.
Flow: you detect mode → product runs the spec gate (fail → `needs-info`, run ends) → lead seeds tasks with seams → backend/frontend build test-first, infra plans, each in own worktree → under review → validator runs checks + two-axis code review, passes or sends back → you observe throughout → lead applies validated infra plans through the gate → validator runs slice acceptance on the integrated branches → lead diagnoses gaps → lead's docs PR → product's acceptance verdict + lead's technical report → you post the final report.
Nobody merges. Stop when the final report is posted.
