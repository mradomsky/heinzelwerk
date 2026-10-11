---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
user-invocable: false
---

_(heinzelwerk: model-invocable so coordinator can call it. In a team run, post the document as a comment on the ticket starting with `## Heinzelwerk run state` instead of the temp directory, and include run state: tasks by status, owners, open proposals, pending escalations, infra applies.)_

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
