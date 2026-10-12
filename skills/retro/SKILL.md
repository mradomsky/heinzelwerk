---
name: retro
description: "Weekly retrospective over recent heinzelwerk runs: what went well, what went wrong, concrete changes to the project's agent environment and to the team itself, plus an architecture survey for deepening opportunities."
disable-model-invocation: true
model: opus
---

The user has asked for a **retrospective**. You are suggesting improvements to the coding agents' **environment** (this project) and to the **team** (the heinzelwerk plugin) to improve future runs. Evidence first: every finding cites a run, PR, or comment.

## Steps

1. Call the Skill tool with `heinzelwerk:writing-for-agents` for the writing style guide.

2. **Scope.** Default: everything since the last retro (newest file in `docs/agents/heinzelwerk/retros/`; workspace: in the tickets repo). The user may give a date or ticket list instead. Read the last retro's actions: did each one happen, and did it help?

3. **Gather primary sources** for runs in scope:
   - Final reports (posted by coordinator): `gh search issues "heinzelwerk-metrics in:comments" --repo <tickets repo>`, then read each report and its metrics block.
   - PRs from those runs: state (merged / closed / open), review comments, needs-work rounds.
   - **Human edits**: on each merged agent branch, commits after the run's final report or without the agent's `Co-Authored-By` trailer are probably the human's fixes (a human fixing with Claude Code also carries the trailer, so confirm the list with the user). Read those diffs: they are the strongest signal.
   - Issues the team filed (`needs-triage`, `needs-info`) and what the human did with them.
   - Docs PRs: what the human accepted, edited, or dropped from glossary, ADR, and learnings candidates.
   - Session logs on this machine, when the user points at them or a finding needs detail.
   - Token usage: ask the user once; never estimate.
   - Shortcut debt: run the `heinzelwerk:ponytail-debt` skill; compare with the ledger in the last retro record.

4. **Look for candidates for improvement** in these categories.

**Environment** (the project):

- **Navigation**: how easy was it for the agent to find the right files? Are there hidden dependencies between files? Would a **navigation pointer** make it easier? _Use when_ the session took a long time to find a piece of information.
- **Automated checks**: are there automated checks that could catch errors the agent made? Linting, typing, tests, filesystem linters? Read the repo's own check command first (its `package.json`/build-tool `lint`/`check` scripts, its CI workflow), so a check that already exists but sits unwired or silently broken is the finding, not a reinvention. A repo with no **guardrail** (no pre-commit hook and no CI job running its lint/typecheck/test command) is itself a finding: an un-linted repo is a standing missed opportunity, not a neutral default. _Use when_ the agent made a mistake an automated check could have caught, or the repo has no guardrail at all.
- **Coding standards**: should the **reviewer agent** be given a new rule to enforce? Should an existing rule be removed or clarified? Classify the violation first: a **mechanical** one (a fixed syntactic pattern, a banned API, an import shape, a file-location rule) gets a deterministic check, full stop: a custom rule in the repo's own linter, a new pre-commit hook, or a new CI job, whichever the repo's language and existing guardrail make cheapest. Default to building the check over writing the rule. Reserve `CODING_STANDARDS.md` for genuine **judgement calls** (cross-file consistency, "matches the surrounding style," anything no guardrail could ever substitute for). _Use when_ the reviewer agent failed to catch a mistake.
- **Global AGENTS.md**: are there any steering instructions that should be moved to coding standards (or automated checks) instead? _Use when_ the AGENTS.md file is particularly large - in the repo OR the user's global scope.
- **Tool economy**: did the agent make expensive tool calls that could be streamlined? Is there any custom tooling (CLI's, MCP's) that is particularly token-inefficient? _Use when_ the agent made an expensive tool call.
- **No-ops**: look for instructions in steering files that don't modify the agent's behavior. _Use when_ the steering files are large and unwieldy.
- **Information access**: look for opportunities to increase the agent's access to information. Teeing dev server logs, readonly access to third-party services. _Use when_ a crucial piece of information was not available to the agent.

**Team** (the heinzelwerk plugin):

- **Role prompts**: did a role act outside its job, miss its job, or need the same correction twice? _Use when_ the human or tech-lead corrected one role repeatedly.
- **Task splitting**: were tasks too big (many review rounds, diagnose rounds), too small (many tasks, little per PR), or overlapping (file conflicts, duplicates)? _Use when_ review rounds or diagnose rounds are high.
- **Discovery**: how many proposals were accepted vs rejected, and did accepted ones matter? Many rejections → proposers need a sharper bar; many escalations to product → slices too vague. Tech-lead slow to triage → bottleneck signal. _Use when_ proposals appear in metrics.
- **Handoffs and phases**: did work stall between phases, or did a done note miss what the next agent needed? _Use when_ a teammate sat idle or redid work.
- **Plan depth**: read the plan comments' Decisions, Pre-mortem, and Critique lines. Did an `obvious:` call turn out wrong? Did a chosen option cause fix rounds or human edits? Did critique points or pre-mortems catch something real, or only cost tokens? Move the "hard to reverse" list or the critique trigger accordingly. _Use when_ a run had fix rounds, diagnose rounds, or human edits.
- **Spec gate**: did product pass slices that later failed on spec, or block runnable ones? _Use when_ validator's Spec axis found gaps product should have caught.
- **Validator**: did merged PRs need human fixes the validator should have caught? Classify each: mechanical → a check (environment category), judgement → a coding-standards rule. _Use when_ human edits exist on validator-passed PRs.
- **Coordinator**: count nudges that changed what an agent did versus noise; were escalations to the user necessary, or answerable by product or tech-lead? _Use when_ nudges or escalations appear in metrics.
- **Model choice**: did Opus escalations find what Sonnet missed? Did Haiku subagents produce work that later failed? Did a Sonnet review let something through in an area that should be a risk area? → propose adding it to `team.md`. Judge with the `heinzelwerk:model-selection` anti-patterns. _Use when_ escalations appear in metrics or human edits cluster in one role.
- **Acceptance**: did slice acceptance fail on things per-PR validation passed? Did you find integration issues after merge it missed? _Use when_ `acceptance` appears in metrics.
- **UI**: did you have to fix visual or UX issues after merge? Missing design rules → propose additions to `design.md`; screenshots missing or useless → tighten the frontend step. _Use when_ human edits touch UI code.
- **Infra**: gate fails and tech-lead escalations: real catches or policy too strict? Any auto-apply you had to undo? Propose policy changes (`infra-policy.json`) with evidence: widen only what proved safe. Infra PRs closed unmerged that carry a `heinzelwerk: applied` comment are unreverted dev drift → `ready-for-agent` issue. _Use when_ `infra_applies` appears in metrics.
- **Shortcut debt**: new `shortcut:` markers since last retro, and any with `no-trigger`. A marker whose upgrade trigger has fired → finding with a `ready-for-agent` issue. Growing ledger with no triggers firing → fine; growing `no-trigger` count → tighten the implementer prompts. _Use when_ the ledger changed.
- **Budget caps**: were caps hit, and did hitting them help or cut off good work? _Use when_ caps appear in metrics.
- **Docs flow**: are glossary terms, ADRs, and learnings landing, or piling up as dropped candidates? Is the learnings file near its cap with stale lines? _Use when_ docs PRs were edited heavily or skipped.
- **Wins**: what worked well enough to protect? Name it, so a later change doesn't break it.

4b. **Architecture survey.** Run the `heinzelwerk:improve-codebase-architecture` skill's explore and report steps (not its grilling loop yet). Direction: the code that changed since the last retro, weighted by the friction step 4 found (modules with many review rounds, human edits, diagnose rounds, or repeated proposals). Haiku subagents walk the code (`heinzelwerk:model-selection`); judging candidates stays with you. Never change code here.

5. **Present** findings to the user in order of severity, wins last; architecture candidates as their own group with the report path. Each: evidence, proposed change, where it goes. The user picks which to act on.

6. **Write**, for the picked findings only:
   - Retro record: `docs/agents/heinzelwerk/retros/<YYYY-MM-DD>.md` (workspace: tickets repo): metrics table summed over runs in scope, wins, problems, actions with owner, architecture candidates filed, shortcut ledger summary (count, no-trigger count, new since last retro), and the follow-up on last retro's actions. Max 60 lines.
   - **Environment actions**: doc changes (pointers, learnings prune and consolidate, team rules, coding standards) on a fresh branch from main `docs/retro-<YYYY-MM-DD>`, one PR with the retro record. Code changes (a new check, a hook, a CI job) become issues labelled `ready-for-agent` or `ready-for-human`, never edited here.
   - **Architecture candidates**: every **Strong** and **Worth exploring** candidate becomes an issue labelled `needs-triage` and `heinzelwerk-survey` (`gh label create heinzelwerk-survey -f` first; title in `heinzelwerk:codebase-design` vocabulary; body: problem, solution, benefits, files, strength), whether or not the user picked it now. Dedup against open issues; comment on an existing one instead. List them in the retro record.
   - **Team actions**: issues in the plugin repo: `gh issue create -R mradomsky/heinzelwerk`, title `<role or skill>: <change>`, body = evidence + proposed wording.
   - Do not merge.

7. **Explore one candidate** (optional): ask which architecture candidate to explore now. Picked → the `heinzelwerk:improve-codebase-architecture` grilling loop. Otherwise the user shapes it later with `/heinzelwerk:shape <issue>`.

## Reference

### Implementation vs Review

Remember that all work goes through two stages: implementation and review. The implementation agent has the most **context pressure**. They are responsible for exploration, writing code, and debugging failures.

The review agent has the least context pressure - it receives a diff, so no exploration needed. It often does not need to write code or debug.

This means that the review agent should be responsible for imposing coding standards, not the implementation agent.

### Files

You have access to several files in the repo:

- `CLAUDE.md`/`AGENTS.md`: these files are pushed to the context window of any agent working in this repo. They should be used incredibly sparingly, usually only for **navigation pointers** to other files.
- `CODING_STANDARDS.md`: this file is read during review, not implementation. Add **navigation pointers** to docs folders if the standards file gets more than 1,000 lines long.
- Docs: use docs as references files, pointed to by other files. Look for existing docs before writing new ones.
- Skills: use skills for docs (since their description goes into the agent's context window), or for user-invoked commands. Follow the advice in the `heinzelwerk:writing-for-agents` skill.
