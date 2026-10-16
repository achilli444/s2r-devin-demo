---
name: s2r-core
description: Shared runtime notes, agents, workflows, templates and references for the Spec2RTL hardware spec-driven development system ported to Devin. Read this first whenever any `s2r-*` skill or `/s2r:*` command is used, or when the user asks for spec-driven RTL development (spec → requirements → roadmap → plan → execute → verify) with Verilator/Icarus/Yosys/cocotb/Vivado/Questa.
---

# Spec2RTL on Devin — core

Spec2RTL (https://github.com/Cirkitly/spec2rtl-plugin, MIT) is a prompt-only methodology: slash commands orchestrate
specialised sub-agents that write RTL, testbenches, formal properties and PPA reports, keeping project memory in `.planning/`.
Upstream installs for Claude Code / OpenCode / Gemini CLI. This directory is a mechanical port to Devin skills
(`tools/port_spec2rtl.py`); the methodology text is unchanged, only runtime bindings differ.

## Layout

| Upstream | Here |
|---|---|
| `~/.claude/commands/s2r/<cmd>.md` | `.devin/skills/s2r-<cmd>/SKILL.md` |
| `~/.claude/agents/s2r-*.md` | `.devin/skills/s2r-core/agents/s2r-*.md` |
| `~/.claude/spec2rtl/workflows/` | `.devin/skills/s2r-core/workflows/` |
| `~/.claude/spec2rtl/templates/` | `.devin/skills/s2r-core/templates/` |
| `~/.claude/spec2rtl/references/` | `.devin/skills/s2r-core/references/` |
| `.planning/` (project memory) | `.planning/` — unchanged, lives in the project directory |

A Spec2RTL *project* is any directory containing `.planning/`. In a repo with several hardware blocks, each block
directory (e.g. `blocks/axis_skid_buffer/`) is its own project: `cd` there before running any `/s2r:*` command.

## Tool mapping (Claude Code → Devin)

| In the skill text | Do this on Devin |
|---|---|
| `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash` | Normal file and shell tools |
| A bare path on its own line (`Read .devin/skills/s2r-core/...`, `.planning/STATE.md`) | Read that file before continuing — these were `@include`s |
| `Task(prompt=..., subagent_type="s2r-X")` | `run_subagent` whose prompt is `agents/s2r-X.md` followed by the given prompt. Spawn the Tasks listed in one wave in parallel; wait for all. `subagent_type="general-purpose"` = a subagent with no agent preamble |
| `AskUserQuestion` with header/question/options | `message_user` with `content_type=user_question`, `block_on_user=true`; the options become the clickable choices |
| `TodoWrite` | `task_create` / `task_update` |
| `model="..."`, model profiles (`quality`/`balanced`/`budget`), `/s2r:set-profile` | Ignore; Devin has one model. Keep `config.json` keys so upstream files stay valid |
| `/s2r:<cmd>` | Invoke skill `s2r-<cmd>` (the user may type the slash form literally) |
| Hooks, statusline, `/s2r:update`, `/s2r:join-discord`, `~/.claude/cache` | Not ported; nothing to do |
| `claude --dangerously-skip-permissions` | N/A |

## Conventions that still apply

- Atomic git commit after every task, conventional prefix with phase-plan id: `feat(02-01): add skid buffer output register`.
- Never claim verification you did not run. Run the simulator/linter/synthesis command and quote its output in `SUMMARY.md` / `VERIFICATION.md`.
- EDA commands: `references/eda-tools.md`. Verification heuristics (stub detection, connectivity): `references/verification-patterns.md`.
- Keep `.planning/STATE.md` current; it is the memory across sessions.

## Open-source toolchain assumed by this repo

Icarus Verilog (`iverilog -g2012`/`vvp`), Verilator 5 (`--lint-only -Wall`, `--binary --timing --trace`), cocotb 2 + cocotbext-axi,
Verible (`verible-verilog-lint`/`-format`), SymbiYosys (`sby`), Yosys (`synth_xilinx -family xcup` for RFSoC estimates),
GTKWave/Surfer. Commercial equivalents (Questa, Vivado, Quartus, SynplifyPro) are drop-in: same cocotb tests via `SIM=questa`,
Vivado via the generated `synth.tcl`. When a required tool is missing, say so and stop; do not fake results.
