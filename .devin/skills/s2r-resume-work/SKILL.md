---
name: s2r-resume-work
description: Resume work from previous session with full context restoration. Use when the user types `/s2r:resume-work` or asks for this step of the Spec2RTL hardware spec-driven flow.
---

> **Devin runtime.** This skill is a port of the Spec2RTL `/s2r:resume-work` command.
> Before following it, read `.devin/skills/s2r-core/SKILL.md` (tool mapping, path conventions, what to ignore).
> Any path under `.devin/skills/s2r-core/` or `.planning/` that this skill lists is a file you must read.
> `Task(...)` = spawn a subagent whose prompt starts with the named agent file from `.devin/skills/s2r-core/agents/`.
> `AskUserQuestion` = ask the user with `message_user` (`content_type=user_question`).
> `model=...` / model profiles are ignored on Devin.

Usage: `/s2r:resume-work`

<objective>
Restore complete project context and resume work seamlessly from previous session.

Routes to the resume-project workflow which handles:

- STATE.md loading (or reconstruction if missing)
- Checkpoint detection (.continue-here files)
- Incomplete work detection (PLAN without SUMMARY)
- Status presentation
- Context-aware next action routing
  </objective>

<execution_context>
Read `.devin/skills/s2r-core/workflows/resume-project.md`
</execution_context>

<process>
**Follow the resume-project workflow** from `.devin/skills/s2r-core/workflows/resume-project.md`.

The workflow handles all resumption logic including:

1. Project existence verification
2. STATE.md loading or reconstruction
3. Checkpoint and incomplete work detection
4. Visual status presentation
5. Context-aware option offering (checks CONTEXT.md before suggesting plan vs discuss)
6. Routing to appropriate next command
7. Session continuity updates
   </process>
