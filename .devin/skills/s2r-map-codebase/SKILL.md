---
name: s2r-map-codebase
description: Analyze codebase with parallel mapper agents to produce .planning/codebase/ documents. Use when the user types `/s2r:map-codebase` or asks for this step of the Spec2RTL hardware spec-driven flow.
---

> **Devin runtime.** This skill is a port of the Spec2RTL `/s2r:map-codebase` command.
> Before following it, read `.devin/skills/s2r-core/SKILL.md` (tool mapping, path conventions, what to ignore).
> Any path under `.devin/skills/s2r-core/` or `.planning/` that this skill lists is a file you must read.
> `Task(...)` = spawn a subagent whose prompt starts with the named agent file from `.devin/skills/s2r-core/agents/`.
> `AskUserQuestion` = ask the user with `message_user` (`content_type=user_question`).
> `model=...` / model profiles are ignored on Devin.

Usage: `/s2r:map-codebase [optional: specific area to map, e.g., 'api' or 'auth']`

<objective>
Analyze existing codebase using parallel s2r-codebase-mapper agents to produce structured codebase documents.

Each mapper agent explores a focus area and **writes documents directly** to `.planning/codebase/`. The orchestrator only receives confirmations, keeping context usage minimal.

Output: .planning/codebase/ folder with 7 structured documents about the codebase state.
</objective>

<execution_context>
Read `.devin/skills/s2r-core/workflows/map-codebase.md`
</execution_context>

<context>
Focus area: $ARGUMENTS (optional - if provided, tells agents to focus on specific subsystem)

**Load project state if exists:**
Check for .planning/STATE.md - loads context if project already initialized

**This command can run:**
- Before /s2r:new-project (brownfield codebases) - creates codebase map first
- After /s2r:new-project (greenfield codebases) - updates codebase map as code evolves
- Anytime to refresh codebase understanding
</context>

<when_to_use>
**Use map-codebase for:**
- Brownfield projects before initialization (understand existing code first)
- Refreshing codebase map after significant changes
- Onboarding to an unfamiliar codebase
- Before major refactoring (understand current state)
- When STATE.md references outdated codebase info

**Skip map-codebase for:**
- Greenfield projects with no code yet (nothing to map)
- Trivial codebases (<5 files)
</when_to_use>

<process>
1. Check if .planning/codebase/ already exists (offer to refresh or skip)
2. Create .planning/codebase/ directory structure
3. Spawn 4 parallel s2r-codebase-mapper agents:
   - Agent 1: tech focus → writes STACK.md, INTEGRATIONS.md
   - Agent 2: arch focus → writes ARCHITECTURE.md, STRUCTURE.md
   - Agent 3: quality focus → writes CONVENTIONS.md, TESTING.md
   - Agent 4: concerns focus → writes CONCERNS.md
4. Wait for agents to complete, collect confirmations (NOT document contents)
5. Verify all 7 documents exist with line counts
6. Commit codebase map
7. Offer next steps (typically: /s2r:new-project or /s2r:plan-phase)
</process>

<success_criteria>
- [ ] .planning/codebase/ directory created
- [ ] All 7 codebase documents written by mapper agents
- [ ] Documents follow template structure
- [ ] Parallel agents completed without errors
- [ ] User knows next steps
</success_criteria>
