# Demo runbook — Spec2RTL on Devin Desktop (open-source EDA)

Audience: eval engineer + manager. Length: ~35 min. Everything runs locally in Devin Desktop; nothing in Devin Cloud.
Story: the same spec -> requirements -> RTL -> compile/simulate -> fix -> formal -> synthesis loop their engineer ran with
Icarus + GTKWave, now driven by Devin following the Spec2RTL skills, with lint/formal/synthesis evidence their eval didn't have.

## 0. Pre-demo setup (macOS, do the day before)

```bash
git clone https://github.com/achilli444/s2r-devin-demo
cd s2r-devin-demo       # every command below runs from inside the repo
make install            # OSS CAD Suite (~1 GB) + Verible into ~/eda, Python venv in .venv; 5-10 min
# macOS Gatekeeper: if any tool dies with "cannot be opened because the developer cannot be verified":
xattr -dr com.apple.quarantine ~/eda
source tools/env.sh && make doctor     # every "required" line must be OK
make lint sim formal synth             # warms caches on the two pre-built blocks (~2 min); read the output once
cd blocks/rr_arbiter && make wave      # opens Surfer/GTKWave once so it is instant on camera; close it
```

Devin Desktop:
1. Open the repo folder. Devin reads `AGENTS.md` and discovers `.devin/skills/s2r-*`.
2. New conversation, send `Run /s2r:help and list the Spec2RTL commands.` — the ported command list should print. Typing `/` opens Desktop's own slash-command picker (e.g. `/acp-commands:help`); the s2r skills are repo skills, not Desktop commands, so dismiss the picker (Esc) or start the message with a word, never pick an entry from it. Same for every `/s2r:` prompt below. If Devin says it does not know s2r, say "read .devin/skills/s2r-core/SKILL.md and list the s2r commands".
3. Pin these editor tabs (left to right): `blocks/axis_skid/SPEC.md`, `.devin/skills/s2r-new-project/SKILL.md`, `.devin/skills/s2r-core/SKILL.md`, `blocks/rr_arbiter/.planning/HARDWARE_METRICS.md`.
4. Do one timed dry run of section 3, then reset (section 5). Every number in the "expected" columns below was produced on Linux x86_64 with this repo; macOS arm64 gives the same pass/fail and cell counts, only wall-clock times differ.

## 1. Opening (3 min) — what Spec2RTL is, in the IDE

Open and scroll, don't read aloud:
- `.devin/skills/s2r-core/SKILL.md` — "Spec2RTL is ~60 markdown instructions, this is the Devin port; the Claude-only parts map to Devin tools here" (point at the Runtime mapping table).
- `.devin/skills/s2r-new-project/SKILL.md` — the questioning -> PROJECT.md -> REQUIREMENTS.md -> ROADMAP.md recipe.
- `.devin/skills/s2r-core/templates/hardware-metrics.md` and `agents/s2r-verifier.md` — the hardware-specific checklists ("is this output real logic or tied off?").
- `tools/env.sh` + `make doctor` in the terminal: Icarus, Verilator, Yosys, sby, cocotb, GTKWave — all free. One line: "Questa/Vivado are a Makefile variable and a tcl file away; nothing else changes."

## 2. Pre-built blocks (7 min) — the paper trail a manager compares against the old eval

**Arbiter** (`blocks/rr_arbiter/`):
- Show `.planning/REQUIREMENTS.md` (traceable IDs), `.planning/phases/02-verification/02-VERIFICATION.md`, `.planning/HARDWARE_METRICS.md`.
- Terminal: `make sim` (expect `TESTS=5 PASS=5`), `make sim SIM=verilator` (same 5 tests, no edits), `make formal` (expect `successful proof by k-induction` + cover reached), `make synth` (expect 28 LUT / 3 FDCE / 5 CARRY4 / 0 DSP).
- Say: fairness is *proven* for all request patterns, not sampled.

**FIR** (`blocks/fir_decim2/`):
- Show `rtl/fir_decim2.sv` header comment (polyphase + symmetry -> 13 multipliers coded as (a+d)*b), `.planning/HARDWARE_METRICS.md`.
- Terminal: `make sim` (expect `TESTS=4 PASS=4`, bit-exact vs scipy), `make synth` (expect **11 DSP48E2** — 13 minus two taps that quantize to zero; say that out loud, it shows the report is real).
- Open `synth/vivado_synth.tcl`: "this is the hand-off — run it on your Vivado, you get the DSP48E2 pre-adder confirmation and WNS at 300 MHz that Yosys can't give." Also show `.planning/STATE.md` "Accumulated Context": the out_valid-one-clock-early bug the tests caught during the build.

## 3. Live: AXI-Stream skid buffer (20 min)

Keep `blocks/axis_skid/SPEC.md` and `.devin/skills/s2r-new-project/SKILL.md` visible side by side while Devin works.

**3a. Spec -> requirements (5 min).** In Devin Desktop:

> `/s2r:new-project` in `blocks/axis_skid`. The spec is `SPEC.md`. Ask me the open questions, then write `.planning/PROJECT.md`, `REQUIREMENTS.md` and `ROADMAP.md` (3 phases: RTL, verification, synthesis). Keep the questioning short.

Answers to give on camera (the spec's "open questions"): data width parameter default 32; TUSER width parameter default 1, carry TLAST; no TKEEP; active-low async reset; target 300 MHz on UltraScale+; full throughput required. Then open the three generated files in the IDE and point at the must-haves: "TREADY must be driven from a register", "no drop / no duplicate / in order", "one word per clock when the sink is ready".

**3b. Build + compile + simulate (7 min).**

> `/s2r:execute-phase 1` then `/s2r:execute-phase 2`. For verification use cocotb with cocotbext-axi (random source gaps and sink stalls), run `make lint`, `make sim SIM=icarus` and `make sim SIM=verilator`, and paste the real output into the summary. Commit per task.

While it runs: show `.devin/skills/s2r-execute-phase/SKILL.md` and `s2r-core/agents/s2r-executor.md` — the "run the tools, paste the output, atomic commit" rules Devin is following. Expect: lint clean; `TESTS=4 PASS=4` (or however many tests Devin writes) on both simulators. If a test fails first time, that is the demo: let Devin read the log, open the waveform (`make wave`) and fix; `/s2r:debug` if it stalls.

**3c. Waveform (2 min).** `cd blocks/axis_skid && make wave` — opens `sim_build/icarus/axis_skid.fst` in Surfer (or GTKWave). Add `clk, s_axis_tvalid, s_axis_tready, m_axis_tvalid, m_axis_tready`; find a sink stall: `m_axis_tready` drops, one more word is accepted, *then* `s_axis_tready` drops one clock later — "that's the skid, and that one-clock delay is the registered TREADY the spec asked for."

**3d. The iterate loop (4 min).** Make Devin break it on purpose and catch it:

> An engineer suggests making `s_axis_tready` combinational (`~skid_valid & (m_axis_tready | ~m_axis_tvalid)`) to save a cycle of latency. Try it, run `make sim` and `make formal`, and tell me whether it still meets REQUIREMENTS.md.

Expected (verified with the reference solution): the cocotb `tready_is_registered` test fails with "s_axis_tready changed combinationally with m_axis_tready", and sby's prove task fails on the registered-TREADY assert. Devin should revert and say the requirement is violated. Punchline: "the spec is enforceable, not advisory."

**3e. Formal + synthesis (2 min).**

> `/s2r:execute-phase 3`: add SymbiYosys properties (AXI-Stream contract on both sides, 2-entry shadow queue proving no drop/dup/in-order, occupancy 0..2), run `make formal` and `make synth`, write `.planning/HARDWARE_METRICS.md`.

Expect: `successful proof by k-induction`, 3 covers reached; Yosys ~70 FF / ~37 LUT / 0 DSP. Open `HARDWARE_METRICS.md` as the closer.

## 4. Close (3 min)

- `git log --oneline blocks/axis_skid` — atomic commits per task, each with pasted tool output.
- "Clone it, `make install`, re-run everything; swap `SIM=questa`; run the two Vivado tcl files on your side and send me the reports — Devin reads those the same way to decide whether to iterate."

## 5. Reset after a dry run

```bash
rm -rf blocks/axis_skid/.git && git checkout -- blocks/axis_skid && git clean -fdx blocks/axis_skid    # back to SPEC.md only (also drops a nested repo if an older skill version ran git init there)
git reset --hard origin/main     # if Devin committed during the dry run
```

## 6. If the live run goes sideways

`demo/reference/axis_skid/` is a complete, verified solution (RTL, cocotb, sby, Makefile): `cp -r demo/reference/axis_skid/* blocks/axis_skid/` and continue from 3c. Measured there: lint clean, cocotb 4/4 on Icarus and Verilator, sby prove + cover pass, Yosys 70 FF / 37 LUT.

## 7. Do not say / caveats

- Do not quote Fmax or WNS: Yosys has no timing engine for UltraScale+. Say "structurally pipelined; Vivado tcl gives the number."
- Yosys DSP mapping approximates Vivado's; the counts can differ. The FIR's 11 is an estimate, the tcl is the sign-off.
- Icarus = what their engineer used; Verilator = faster + real SystemVerilog + lint; same cocotb tests on both is the portability proof for Questa (cocotb supports Questa natively).
- Spec2RTL's sub-agent spawning (`Task`) runs inline on Devin Desktop — same artifacts, sequential. Model profiles and the Claude update/Discord commands are not ported.
- Devin Desktop needs the terminal environment: `source tools/env.sh` in any shell you open yourself (Devin does it via `make`).
