# AGENTS.md

This repository carries the **Spec2RTL** hardware spec-driven development system ported to Devin skills, plus demo material.

- Skills live in `.devin/skills/`. `s2r-core/SKILL.md` is the entry point; `s2r-<command>/SKILL.md` map 1:1 to the upstream `/s2r:<command>` slash commands.
- When the user types `/s2r:<command>` (or `/gsd:<command>`), or says "run the s2r <command> skill" in plain text (Devin Desktop's `/` opens its own command picker, so demo prompts use the plain-text form), follow `.devin/skills/s2r-<command>/SKILL.md`.
- Each hardware block under `blocks/<name>/` is an independent Spec2RTL project with its own `.planning/`. Run the workflow from inside that directory.
- Toolchain is open source only (Icarus, Verilator, cocotb, Verible, sby, Yosys, GTKWave). Never report simulation, lint, formal or synthesis results you did not actually run; paste the tool output.
- Do not edit generated skill text by hand; change `tools/port_spec2rtl.py` or `upstream/` and re-run `python3 tools/port_spec2rtl.py`.
