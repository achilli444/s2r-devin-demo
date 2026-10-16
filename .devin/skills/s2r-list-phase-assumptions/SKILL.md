---
name: s2r-list-phase-assumptions
description: Surface Claude's assumptions about a phase approach before planning. Use when the user types `/s2r:list-phase-assumptions` or asks for this step of the Spec2RTL hardware spec-driven flow.
---

> **Devin runtime.** This skill is a port of the Spec2RTL `/s2r:list-phase-assumptions` command.
> Before following it, read `.devin/skills/s2r-core/SKILL.md` (tool mapping, path conventions, what to ignore).
> Any path under `.devin/skills/s2r-core/` or `.planning/` that this skill lists is a file you must read.
> `Task(...)` = spawn a subagent whose prompt starts with the named agent file from `.devin/skills/s2r-core/agents/`.
> `AskUserQuestion` = ask the user with `message_user` (`content_type=user_question`).
> `model=...` / model profiles are ignored on Devin.

Usage: `/s2r:list-phase-assumptions [phase]`

<objective>
Analyze a phase and present Devin's assumptions about technical approach, implementation order, scope boundaries, risk areas, and dependencies.

Purpose: Help users see what Devin thinks BEFORE planning begins - enabling course correction early when assumptions are wrong.
Output: Conversational output only (no file creation) - ends with "What do you think?" prompt
</objective>

<execution_context>
Read `.devin/skills/s2r-core/workflows/list-phase-assumptions.md`
</execution_context>

<context>
Phase number: $ARGUMENTS (required)

**Load project state first:**
Read `.planning/STATE.md`
**Load roadmap:**
Read `.planning/ROADMAP.md`
</context>

<process>
1. Validate phase number argument (error if missing or invalid)
2. Check if phase exists in roadmap
3. Follow list-phase-assumptions.md workflow:
   - Analyze roadmap description
   - Surface assumptions about: technical approach, implementation order, scope, risks, dependencies
   - Present assumptions clearly
   - Prompt "What do you think?"
4. Gather feedback and offer next steps
</process>

<success_criteria>

- Phase validated against roadmap
- Assumptions surfaced across five areas
- User prompted for feedback
- User knows next steps (discuss context, plan phase, or correct assumptions)
  </success_criteria>
