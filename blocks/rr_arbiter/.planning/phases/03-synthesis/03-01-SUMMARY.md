---
phase: 03-synthesis
plan: 01
subsystem: synthesis
tags: [yosys, ultrascale+, rfsoc]
area: 28 LUT / 3 FF / 5 CARRY4 / 0 DSP / 0 BRAM (Yosys xcup estimate)
fmax: unverified (no OSS STA for UltraScale+; Vivado tcl provided)
completed: 2026-10-16
---
# Phase 3: Synthesis Summary
**Logic-only arbiter: 28 LUTs, 3 FFs, 0 DSP/BRAM on UltraScale+ (Yosys estimate).**
See HARDWARE_METRICS.md. Vivado sign-off: `cd synth && vivado -mode batch -source vivado_synth.tcl`.
