---
name: s2r-set-profile
description: Switch model profile for Spec2RTL agents (quality/balanced/budget). Use when the user types `/s2r:set-profile` or asks for this step of the Spec2RTL hardware spec-driven flow.
---

> **Devin runtime.** This skill is a port of the Spec2RTL `/s2r:set-profile` command.
> Before following it, read `.devin/skills/s2r-core/SKILL.md` (tool mapping, path conventions, what to ignore).
> Any path under `.devin/skills/s2r-core/` or `.planning/` that this skill lists is a file you must read.
> `Task(...)` = spawn a subagent whose prompt starts with the named agent file from `.devin/skills/s2r-core/agents/`;
> if no subagent tool is available, read that agent file and do its work inline, one Task at a time.
> `AskUserQuestion` = ask the user with `message_user` (`content_type=user_question`).
> `model=...` / model profiles are ignored on Devin.

Usage: `/s2r:set-profile`

<objective>
Switch the model profile used by Spec2RTL agents. This controls which Claude model each agent uses, balancing quality vs token spend.
</objective>

<profiles>
| Profile | Description |
|---------|-------------|
| **quality** | Opus everywhere except read-only verification |
| **balanced** | Opus for planning, Sonnet for execution/verification (default) |
| **budget** | Sonnet for writing, Haiku for research/verification |
</profiles>

<process>

## 1. Validate argument

```
if $ARGUMENTS.profile not in ["quality", "balanced", "budget"]:
  Error: Invalid profile "$ARGUMENTS.profile"
  Valid profiles: quality, balanced, budget
  STOP
```

## 2. Check for project

```bash
ls .planning/config.json 2>/dev/null
```

If no `.planning/` directory:
```
Error: No Spec2RTL project found.
Run /s2r:new-project first to initialize a project.
```

## 3. Update config.json

Read current config:
```bash
cat .planning/config.json
```

Update `model_profile` field (or add if missing):
```json
{
  "model_profile": "$ARGUMENTS.profile"
}
```

Write updated config back to `.planning/config.json`.

## 4. Confirm

```
✓ Model profile set to: $ARGUMENTS.profile

Agents will now use:
[Show table from model-profiles.md for selected profile]

Next spawned agents will use the new profile.
```

</process>

<examples>

**Switch to budget mode:**
```
/s2r:set-profile budget

✓ Model profile set to: budget

Agents will now use:
| Agent | Model |
|-------|-------|
| s2r-planner | sonnet |
| s2r-executor | sonnet |
| s2r-verifier | haiku |
| ... | ... |
```

**Switch to quality mode:**
```
/s2r:set-profile quality

✓ Model profile set to: quality

Agents will now use:
| Agent | Model |
|-------|-------|
| s2r-planner | opus |
| s2r-executor | opus |
| s2r-verifier | sonnet |
| ... | ... |
```

</examples>
