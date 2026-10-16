# Spec2RTL → Devin skills

[Spec2RTL](https://github.com/Cirkitly/spec2rtl-plugin) is a spec-driven RTL development system (spec → requirements → roadmap → plan → execute → verify)
shipped as Claude Code / OpenCode / Gemini CLI prompts. This repo ports it to **Devin repo skills** so Devin (Cloud or Desktop) can drive the
same compile-verify-iterate loop with any EDA toolchain.

```
.devin/skills/s2r-core/        shared agents, workflows, templates, references + Devin runtime notes
.devin/skills/s2r-<command>/   one skill per /s2r:<command>
upstream/spec2rtl-plugin/      pinned upstream snapshot (see PIN)
tools/port_spec2rtl.py         regenerates .devin/skills from upstream
```

Use: open the repo in Devin, `cd` into a block directory, and say `/s2r:new-project` (or "start a new Spec2RTL project from specs/x.md").
Devin reads `.devin/skills/s2r-core/SKILL.md` for the tool mapping and follows the command skill.

Update: bump `upstream/`, re-run `python3 tools/port_spec2rtl.py`, commit.

## Demo

`demo/RUNBOOK.md` is the Devin Desktop run of show (setup checklist, which `SKILL.md` to have open at each step, exact prompts, expected tool output, reset and recovery). Blocks:

| Block | State | Evidence |
|---|---|---|
| `blocks/rr_arbiter` | pre-built | cocotb 5/5 (Icarus + Verilator), sby proof + cover, Yosys 28 LUT / 3 FF |
| `blocks/fir_decim2` | pre-built | cocotb 4/4 bit-exact vs scipy (Icarus + Verilator), Yosys 11 DSP48E2, Vivado tcl |
| `blocks/axis_skid` | spec only — built live | reference solution in `demo/reference/axis_skid` |

Toolchain: `make install` (OSS CAD Suite + Verible + cocotb venv), `source tools/env.sh`, `make doctor`, then `make lint|sim|formal|synth [SIM=icarus|verilator|questa]`.
