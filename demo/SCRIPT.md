# Demo script — Spec2RTL on Devin Desktop (pre-recorded, verbatim narration)

Format: **DO** = what you click/type/run. **SAY** = read verbatim. **SEE** = what should be on screen before you move on.
Recording tip: Devin's work in scenes 5–7 takes minutes; record it, then cut the waiting in post. Keep the terminal and editor both visible (editor left ~60%, terminal right). Finish the pre-demo checklist in `demo/RUNBOOK.md` §0 first (tools installed, caches warm, `blocks/axis_skid` reset to `SPEC.md` only, no `.planning/`).

Runtime target: 22–25 min after cuts.

---

## Scene 1 — Setup shot (1 min)

**DO** Devin Desktop open on the repo. Editor tabs, left to right: `README.md`, `.devin/skills/s2r-core/SKILL.md`, `.devin/skills/s2r-new-project/SKILL.md`, `blocks/axis_skid/SPEC.md`. Terminal in the repo root.

**SAY**
"This is Devin Desktop running on a laptop, with no cloud involved. The repository on screen has three things in it: the Spec2RTL methodology ported to Devin skills, an open-source hardware toolchain, and the three test blocks your team used in the original evaluation — the round-robin arbiter, the decimating FIR filter, and the AXI-Stream skid buffer. Same prompts, same blocks. What's different is what you'll see around them: requirements traceability, lint, formal proof, and synthesis numbers, all generated and run by Devin."

---

## Scene 2 — What Spec2RTL is, in the IDE (3 min)

**DO** Click tab `.devin/skills/s2r-core/SKILL.md`. Scroll slowly to the heading **"Tool mapping (Claude Code → Devin)"**.

**SAY**
"First, what Spec2RTL actually is. It is not a tool and it is not an integration — it is about sixty markdown documents: slash commands, agent roles, and templates that force a spec-driven discipline. Spec in, then requirements, then a roadmap, then a plan per phase, then execution and verification against the spec. The original plugin only knows how to install into Claude Code. We ported it to Devin skills: every `/s2r` command is now a `SKILL.md` file in this folder, and this table is the entire port — where the Claude-specific pieces map onto Devin's tools. Nothing is hidden in a binary; you can read every instruction Devin will follow."

**DO** Click tab `.devin/skills/s2r-new-project/SKILL.md`. Scroll through **Phase 1: Setup → Phase 3: Deep Questioning → Phase 4: Write PROJECT.md**.

**SAY**
"This is the one we'll run live in a minute: `new-project`. Read it top to bottom and it's a recipe. Set up the planning folder. Ask the engineer the questions the spec leaves open. Write `PROJECT.md`, `REQUIREMENTS.md`, and a `ROADMAP.md` with phases. That questioning step is the part your evaluator will care about — it's where 'ultra-low latency' turns into a measurable requirement like 'grant in zero clock cycles'."

**DO** In the file explorer, expand `.devin/skills/s2r-core/agents/`, open `s2r-verifier.md`; then `templates/hardware-metrics.md`. Five seconds each, no scrolling.

**SAY**
"The agents are the roles: an executor that writes code and runs the tools, a verifier that checks the result against the requirements — including hardware-specific checks like 'is this output real logic, or tied to zero?' — and a metrics template that records target versus actual for area and timing."

**DO** Terminal: `source tools/env.sh && make doctor`

**SEE** Each required tool reports OK; Vivado/Questa listed as optional/absent.

**SAY**
"The toolchain is entirely open source. Icarus Verilog — what your engineer used. Verilator, which is faster and also our linter. cocotb for Python testbenches. SymbiYosys for formal proof. Yosys for synthesis estimates. Surfer and GTKWave for waveforms. Questa and Vivado aren't installed here, and you'll see we never pretend they are: swapping in Questa is a Makefile variable, and for Vivado we generate the script you run on your side."

---

## Scene 3 — Pre-built block 1: round-robin arbiter (4 min)

**DO** Terminal: `cd blocks/rr_arbiter`. Open `.planning/REQUIREMENTS.md` in the editor.

**SAY**
"The arbiter and the FIR were built ahead of time through this same flow, so you can see the finished paper trail. This is the requirements file Devin produced from your one-sentence prompt. Each requirement has an ID, and the two that matter are here: the grant is combinational — zero cycles from request to grant — and the rotation is fixed, so no requester can starve."

**DO** Open `.planning/phases/02-verification/02-VERIFICATION.md`. Scroll to the pasted test output.

**SAY**
"And this is the verification report. Notice the tool output is pasted in verbatim. That's a rule in this repo: Devin never reports a result it didn't actually run."

**DO** Terminal: `make sim`

**SEE** `TESTS=5 PASS=5 FAIL=0`

**SAY**
"Let's run it now. Five cocotb tests on Icarus: reset state, zero-cycle latency, round-robin order, a fairness bound, and a randomized comparison against a Python reference model. Five of five."

**DO** Terminal: `make sim SIM=verilator`

**SEE** Same five tests, `PASS=5`.

**SAY**
"Same tests, now on Verilator. Not a line of the testbench changed — just the simulator variable. That variable also accepts `questa`. That's the portability argument in one command."

**DO** Terminal: `make formal`

**SEE** `successful proof by k-induction` and the cover task `DONE (PASS, rc=0)`.

**SAY**
"This is something the original evaluation didn't have. SymbiYosys just mathematically proved — for every possible request pattern, not a sample of them — that the grant is always one-hot, that it rotates correctly, and that no requester waits more than eight cycles. Fairness isn't tested here; it's proven."

**DO** Terminal: `make synth`. Then open `.planning/HARDWARE_METRICS.md`.

**SEE** Yosys stat: `LUT` lines totalling 28, `3 FDCE`, `5 CARRY4`, no DSP.

**SAY**
"And synthesis. Yosys maps the design onto UltraScale-Plus primitives: twenty-eight LUTs, three flip-flops, no DSPs. Devin records target versus actual in the metrics file. One honest caveat you'll hear me repeat: Yosys has no timing engine for this family, so there is no Fmax number here — the Vivado script in the `synth` folder is what produces the sign-off timing on your side."

---

## Scene 4 — Pre-built block 2: the FIR filter (4 min)

**DO** Terminal: `cd ../fir_decim2`. Open `rtl/fir_decim2.sv`; keep the header comment (first ~15 lines) on screen.

**SAY**
"The FIR is the one where synthesis numbers matter. Twenty-five taps, symmetric, decimate by two. The header comment is Devin's own explanation of the architecture: split the filter into even and odd polyphase branches, exploit the symmetry so twenty-five products collapse to thirteen multipliers, and code every multiplier as 'a plus d, times b' with registered operands — which is exactly the pattern Vivado needs to pull the DSP48E2 pre-adder in. That was the stated goal in your prompt."

**DO** Open `tools/gen_fir_coefs.py` briefly (3 s), then `tb/test_fir_decim2.py`, scroll to the test names.

**SAY**
"The coefficients come from SciPy, and the testbench compares the hardware bit-for-bit against a SciPy golden model: impulse response, random streams, streams with gaps, and a full-scale overflow check."

**DO** Terminal: `make sim`

**SEE** `TESTS=4 PASS=4 FAIL=0`

**SAY**
"Four of four, bit-exact."

**DO** Open `.planning/STATE.md`, scroll to **Accumulated Context**.

**SAY**
"I want to show you this because it's the compile-verify-iterate loop you asked about, on the record. During the build, the valid pipeline was one clock short — seven register stages in the data path, six in the valid. The impulse test caught it: the centre tap landed one sample late. Devin read the failure, fixed the pipeline depth, re-ran, and logged it here. That's the fix-and-repeat loop, with evidence."

**DO** Terminal: `make synth`

**SEE** Yosys stat includes `11 DSP48E2`, `408 FDCE`, `861 FDRE`.

**SAY**
"Synthesis: eleven DSP48E2 blocks. Not thirteen — two of the quantized coefficients came out to exactly zero, and Yosys deleted those multipliers. I point that out because it shows this is a real report, not a number copied from the spec. Devin documented the same thing in the metrics file."

**DO** Open `synth/vivado_synth.tcl`, then `synth/constraints.xdc`.

**SAY**
"And here is the hand-off. Yosys gives an estimate; Vivado gives the answer. This Tcl script targets the RFSoC part, reads the RTL, runs synthesis, and writes the utilization and timing reports. The constraints file sets a three-hundred-megahertz clock. You run it on your licensed machine, and the utilization report tells you whether the pre-adders were actually inferred and whether it closes at three hundred. Devin reads that report the same way it read the Yosys one, and iterates if it misses."

---

## Scene 5 — Live block: spec to requirements (5 min recorded, ~3 after cuts)

**DO** Terminal: `cd ../axis_skid && ls` (shows only `SPEC.md`). Click tab `blocks/axis_skid/SPEC.md`.

**SAY**
"Now the live one, from nothing. The skid buffer folder contains one file: the spec. At the top is your engineer's prompt, verbatim. Below it are the points the prompt leaves open — data width, which sideband signals to carry, reset style, and whether the output side is registered too — and the success criteria we expect to end up in the requirements."

**SAY**
"A skid buffer, for anyone new to it: AXI-Stream moves data with a valid-ready handshake. When the downstream block says 'not ready', something has to catch the word that's already in flight. A skid buffer holds two entries so the upstream doesn't have to react in the same clock cycle. That breaks a long combinational path on `tready`, and that's what lets the chip run faster."

**DO** In Devin's chat, paste exactly (no prompt in this script starts with `/` — a leading slash opens Desktop's own slash-command picker, which does not know the repo skills):

```
Run the s2r new-project skill in blocks/axis_skid. The spec is SPEC.md. Ask me the open questions, then write .planning/PROJECT.md, REQUIREMENTS.md and ROADMAP.md with 3 phases: RTL, verification, synthesis. Keep the questioning short.
```

**SAY** (while it reads the skill)
"Devin now follows the `new-project` skill we looked at. Watch the chat — it should come back with the open questions from the spec."

**SEE** Devin asks questions (data width, sidebands, reset, registered outputs, throughput, target clock).

**DO** Answer in one message:

```
DATA_W parameter default 32. Carry TLAST and a TUSER_W parameter default 1. No TKEEP. Active-low async reset. Both sides registered (full register slice). Must sustain one transfer per clock with the sink always ready. Target 300 MHz on UltraScale+.
```

**SAY**
"These are the decisions an engineer would make in a design review, and we make them here, on the record, before any RTL exists."

**SEE** `.planning/PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md` appear in the explorer.

**DO** Open `.planning/REQUIREMENTS.md`. Point at the must-haves.

**SAY**
"Here's the result. The one-line prompt is now a requirements list with IDs. The ones to notice: `s_axis_tready` must be driven from a register — no combinational path from the downstream `tready`. No word dropped, none duplicated, order preserved. Full throughput when the sink is ready. Every one of these is going to be checked by a test or a proof."

**DO** Open `.planning/ROADMAP.md`.

**SAY**
"And three phases: write the RTL, verify it, synthesize it."

---

## Scene 6 — Live: build, compile, simulate (8 min recorded, ~4 after cuts)

**DO** In Devin's chat:

```
Run the s2r execute-phase skill for phase 1, then again for phase 2. For verification use cocotb with cocotbext-axi (random source gaps and sink stalls, plus a test that s_axis_tready does not change when m_axis_tready toggles mid-cycle). Run make lint, make sim SIM=icarus and make sim SIM=verilator, paste the real output into the summary, and commit per task.
```

**DO** While Devin works, click tab `.devin/skills/s2r-execute-phase/SKILL.md`, then open `.devin/skills/s2r-core/agents/s2r-executor.md`.

**SAY**
"While it runs, this is the skill it's following, and this is the executor role. The rules that matter are in here: run the tools after each task, paste the real output, and make one atomic commit per task. So the git history becomes the audit trail."

**SEE** Devin creates `rtl/axis_skid.sv`, `tb/test_axis_skid.py`, `Makefile`; runs lint; runs sim on Icarus and Verilator.

**DO** When Devin reports, open `rtl/axis_skid.sv`. Point at the `s_axis_tready` assignment and the `always_ff` block.

**SAY**
"The RTL. Two storage slots — the output register and the skid slot. `s_axis_tready` comes straight from a flip-flop, which is the requirement. Lint is clean on Verilator and Verible."

**DO** Terminal: `make sim SIM=icarus`, then `make sim SIM=verilator`

**SEE** All tests pass on both — the count depends on what Devin wrote; the reference solution has four.

**SAY**
"Same testbench, both simulators, all passing. Random back-pressure on both sides, stall bursts, and a direct test that `tready` doesn't move when the downstream handshake toggles mid-cycle."

> **If a test fails on the first run — keep recording.** Say: "This is the loop. Devin reads the failing assertion, opens the waveform if it needs to, fixes the RTL, and re-runs." Let it iterate; `/s2r:debug` if it stalls. Cut the waiting, keep the fix.

---

## Scene 7 — Waveform (2 min)

**DO** Terminal: `make sim SIM=icarus WAVES=1 && make wave`. Surfer opens `sim_build/icarus/axis_skid.fst`. Add signals: `clk`, `s_axis_tvalid`, `s_axis_tready`, `m_axis_tvalid`, `m_axis_tready`. Zoom to a region where `m_axis_tready` drops while `s_axis_tvalid` is high.

**SAY**
"This is the simulation as a waveform — the view your engineer used with GTKWave. Here the downstream drops `ready`. On that same clock, the upstream is still being accepted — that word lands in the skid slot. One clock later, `s_axis_tready` drops. That one-clock delay is the whole point of the block: `tready` is coming from a register, not from the downstream signal, and the data wasn't lost."

---

## Scene 8 — The iterate loop, on purpose (3 min)

**DO** In Devin's chat:

```
An engineer suggests making s_axis_tready combinational — ~skid_valid & (m_axis_tready | ~m_axis_tvalid) — to save a cycle of latency. Try it, run make sim and the formal properties if present, and tell me whether it still meets REQUIREMENTS.md.
```

**SAY**
"Now let's break it deliberately, the way a well-meaning optimization would. Shave a cycle of latency by making `tready` combinational."

**SEE** `tready_is_registered` fails: `AssertionError: s_axis_tready changed combinationally with m_axis_tready`. Devin reports the requirement is violated and reverts.

**SAY**
"The test fails immediately, and Devin's answer isn't 'it's faster' — it's 'this violates requirement such-and-such, reverting.' The spec is enforceable, not advisory. That's the difference between spec-driven and prompt-and-hope."

---

## Scene 9 — Formal proof and synthesis (3 min recorded, ~2 after cuts)

**DO** In Devin's chat:

```
Run the s2r execute-phase skill for phase 3: add SymbiYosys properties — AXI-Stream contract on both sides, a 2-entry shadow queue proving no drop, no duplicate and in-order delivery, occupancy never above 2, and s_axis_tready registered — then run make formal and make synth and write .planning/HARDWARE_METRICS.md.
```

**DO** While it works, open `blocks/rr_arbiter/formal/rr_arbiter_props.svh` for 5 s as an example of what properties look like.

**SEE** Devin creates `formal/axis_skid_props.svh` + `axis_skid.sby`; runs `make formal`.

**DO** Terminal: `make formal`

**SEE** `successful proof by k-induction`; cover task `DONE (PASS, rc=0)`.

**SAY**
"Proven: for every legal input sequence, the buffer never drops a word, never duplicates one, never reorders, never exceeds two entries, and `tready` is registered. The cover run shows the proof isn't vacuous — the buffer really did fill, drain, and stream."

**DO** Terminal: `make synth`. Open `.planning/HARDWARE_METRICS.md`.

**SEE** Roughly 70 flip-flops, under 40 LUTs, zero DSP, zero BRAM. Last line: `vivado hand-off written: synth/vivado_synth.tcl, synth/constraints.xdc` — `make synth` generates the Vivado script for every block.

**SAY**
"Synthesis: about seventy flip-flops and under forty LUTs for a thirty-two-bit, two-deep buffer with sidebands. No DSPs, no block RAM. Target versus actual is recorded here, and again the Vivado Tcl in `synth` is the hand-off for the real timing number."

---

## Scene 10 — Close (2 min)

**DO** Terminal: `git log --oneline -- . | head -15`

**SAY**
"The commit history is the audit trail: one commit per task, each summary carrying the pasted tool output."

**DO** Click back to `README.md`.

**SAY**
"To wrap up. This is the same loop your engineer ran — spec, RTL, Icarus, GTKWave — with four things added: requirements you can trace, lint, formal proof, and synthesis numbers. All of it runs on a laptop with free tools, and all of it is in this public repo. Three things you can do with it today. One: clone it, run `make install`, and re-run everything yourself — nothing here needs a licence. Two: change `SIM=icarus` to `SIM=questa` and run the same tests on your production simulator. Three: run the two Vivado scripts on your side and send back the reports — that's the one result we honestly can't produce here, and it's the one that closes the loop on the DSP48 pre-adder question. Thanks."

---

## Appendix — recovery and reset

- Live run goes sideways → `cp -r demo/reference/axis_skid/* blocks/axis_skid/` and resume at Scene 6's `make sim`. The reference is verified: lint clean, cocotb 4/4 on both simulators, sby proof and cover pass, ~70 FF / 37 LUT.
- Reset between takes → `rm -rf blocks/axis_skid/.git && git checkout -- blocks/axis_skid && git clean -fdx blocks/axis_skid`; `git reset --hard origin/main` if Devin committed.
- Numbers quoted above were measured on Linux x86_64 with this repo; pass/fail and cell counts match on macOS, wall-clock times differ. If Devin's live run produces different test counts or cell counts, read the numbers off the screen — don't read the script's.
- Never quote Fmax/WNS. Never describe Yosys DSP counts as Vivado results.
