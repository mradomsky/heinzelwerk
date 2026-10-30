# heinzelwerk

The plugin's own vocabulary: the words its skills, agents, and scripts use for the run, the people in it, and the things they hand each other. Target repos keep their domain in their own `GLOSSARY.md`; this file is about the plugin. Plugin reviews (`prompts/review-plugin.md`) flag the _Avoid_ words in plugin text.

## People in a run

**Coordinator**:
The main session of a team run. Owns process: the user channel, spawning and releasing teammates, observation, the final report. Never does task work.
_Avoid_: team-lead (the platform's name for the same session; use it only where the platform shows it, as in message tags), lead, supervisor, orchestrator

**Tech-lead**:
The teammate that owns how: the plan, tasks and seams, proposal triage, diagnose, infra apply through the gate, the docs PR.
_Avoid_: lead, team-lead, architect

**Product**:
The teammate (or the main session in `/shape`) that owns what: scope, acceptance criteria, the spec gate, the acceptance verdict.
_Avoid_: PO, owner, PM

**Implementer**:
Backend, frontend, or infra: a teammate that builds one task test-first and opens its PR.
_Avoid_: developer, worker, builder, coder

**Validator**:
The teammate that runs checks and the two-axis review, posts verdicts, runs slice acceptance and the merge task. Never fixes code.
_Avoid_: reviewer, QA, tester

**Teammate**:
Any agent-team member other than coordinator. Spawned by coordinator as `heinzelwerk:<role>`, named `<role>` or `<role>-N`.
_Avoid_: agent (too wide: subagents and the user's own sessions are agents too), worker, bot

**Subagent**:
A short-lived agent a role spawns in the foreground for one report (an Opus critique, a Haiku search). Hands back to its spawner, or to coordinator by platform accident.
_Avoid_: helper, child, sub-task

## Work

**Ticket**:
A GitHub issue. Durable; carries context across runs.
_Avoid_: issue (when the GitHub object is meant as a unit of work), story, card

**Spec**:
The issue `/shape` writes from the grilled idea: scope, out-of-scope, acceptance criteria. Never run directly.
_Avoid_: PRD, design doc, epic

**Slice**:
A `ready-for-agent` ticket, usually a sub-issue of a spec: one tracer bullet a run can build end to end.
_Avoid_: feature, story, task (that word is taken), sprint item

**Task**:
An agent-team task: disposable, gone after the run. Titled `#<ticket> <role> <kind>: <what>`; carries one phase.
_Avoid_: ticket, todo, job, work item, issue

**Phase**:
What kind of work a task is: analyze, implement, or validate. One per task.
_Avoid_: stage, step, status

**Proposal**:
A `[proposed] #N <what>` task for work someone discovered. Nobody claims it; tech-lead accepts or rejects it.
_Avoid_: suggestion, idea, finding (that word is retro's)

**Fix round**:
One validator fail and the fix task it opens, on the same branch and PR. Capped at three per PR.
_Avoid_: iteration, retry, loop, needs-work cycle

**Out-of-scope row**:
A line in `docs/agents/heinzelwerk/out-of-scope.md`: a proposal turned down for a reason that outlives one run, with the condition under which to revisit it.
_Avoid_: wontfix (that is a ticket label), rejection list, blacklist

## Things handed over

**Done note**:
The fixed-field block an agent writes into the PR body and the task's details when it finishes a task (`did:`, `evidence:`, `checks:`, …, `session:`). `check-note note` verifies it.
_Avoid_: summary, report, handoff note, completion message

**Verdict**:
Validator's pass or fail on a PR, posted as a review comment. A pass ends with the validated line.
_Avoid_: review (the two-axis review is one input to it), approval, result

**Validated line**:
`heinzelwerk: validated <40-hex sha>`, the last line of a pass verdict. A protocol marker the merge gate matches against the PR head; not an authorization.
_Avoid_: approval, sign-off, LGTM

**Plan comment**:
Tech-lead's comment on the ticket: decisions, pre-mortem, critique answers, the task table with branches and worktrees.
_Avoid_: plan (alone, when the comment is meant), breakdown, design

**Run state**:
Coordinator's `## Heinzelwerk run state` comment on the ticket, edited by id: counts and the task snapshot. A run with a run state and no final report after it is interrupted and resumable.
_Avoid_: status, progress comment, checkpoint

**Final report**:
Coordinator's `## Heinzelwerk final report` comment: outcome, verdicts, PRs, leftovers, the metrics block.
_Avoid_: summary, retro (that is the weekly skill), status

**Context block**:
The `## Context` section of a spawn prompt, printed by `spawn-context`: ticket, plan and run-state comments, team rules, agent-skills pointers, the PR for validator.
_Avoid_: briefing, preamble, prompt header

**Footer**:
The line `— heinzelwerk` that ends every comment, review, and PR body an agent posts. Tells agent text from the user's under the shared login.
_Avoid_: signature, disclaimer, trailer (that is the commit line)

## Places and gates

**Main checkout**:
The repo directory Claude Code was started in (or a child of the workspace folder). Read-only reference during a run; every edit happens in a worktree.
_Avoid_: repo (ambiguous with the remote), root, working copy

**Worktree**:
A git worktree under `<repo>/.claude/worktrees/heinzelwerk/<branch>`, one per task, locked with the owner's role, ticket, and run start while held.
_Avoid_: checkout, clone, branch (a worktree holds a branch), sandbox

**Workspace mode**:
A run started from a folder of sibling repos with a `CLAUDE.workspace.md`; one repo (`meta`) holds tickets and workspace docs.
_Avoid_: monorepo, multi-repo (as a noun), multi-mode

**Merge gate**:
`merge-gate`, the plugin script that merges a PR only when `merge-policy.json` on main, the validated line, CI, and mergeability all allow it.
_Avoid_: auto-merge (the setting is called that; the actor is the gate), merger, bot merge

**Infra gate**:
`tf-gate`, the plugin script that checks a saved Terraform plan against `infra-policy.json` on main and applies it.
_Avoid_: terraform wrapper, apply script, auto-apply

**Guard**:
`hooks/guard.sh`, the PreToolUse hook that blocks pushes to main, merges, `--force`, hook skipping, secret files, raw `terraform apply`.
_Avoid_: firewall, sandbox, policy (that is the gates' input)

## Time

**Run**:
One `/heinzelwerk:feature` or `/heinzelwerk:bugfix` invocation on one slice, from spawn to final report.
_Avoid_: session (the Claude Code process; a run is one session, a session can hold a shaping conversation instead), sprint, job, iteration

**Run cap**:
The wall-clock limit per run from `team.md`. Past it coordinator spawns nothing new and ends the run as `stopped`.
_Avoid_: timeout, budget (that word is for tokens), deadline

**Silence**:
The minutes a teammate may hold an in-progress task with no message, commit, or task change before coordinator asks for its state. From `team.md`, default 20.
_Avoid_: idle timeout, heartbeat, watchdog

**Retro**:
The weekly `/heinzelwerk:retro`: reads the period's runs and outcomes, writes a retro record and a docs PR, files team issues.
_Avoid_: review (the two-axis review and the plugin reviews are other things), post-mortem, report
