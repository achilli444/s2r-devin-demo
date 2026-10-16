# Hardware Metrics Report — rr_arbiter

**Phase:** 3 — Synthesis
**Date:** 2026-10-16
**Commit:** 6e241d3
**Tool:** Yosys 0.70+16, `synth_xilinx -family xcup -noiopad` (UltraScale+/RFSoC estimate). Vivado sign-off: `synth/vivado_synth.tcl` (customer side).

## 1. Timing Analysis

| Clock Domain | Frequency (MHz) | WNS (ns) | Status |
| :--- | :--- | :--- | :--- |
| `clk` | target 300 (assumed RFSoC fabric) | n/a — Yosys has no STA | UNVERIFIED (run Vivado tcl) |

Structural evidence: 3 flip-flops (the pointer) and a grant path of LUT + CARRY4 chain only; `req -> grant` is purely combinational (proven: formal `grant` asserts are in `always_comb`).

## 2. Resource Utilization (Area)

| Resource | Used | Note |
| :--- | :--- | :--- |
| LUTs | 28 (6 LUT2, 5 LUT3, 9 LUT4, 6 LUT5, 2 LUT6) | + 8 INV (absorbed into LUTs by Vivado) |
| CARRY4 | 5 | two `x & -x` priority encoders + pointer increment |
| Flip-Flops | 3 (FDCE) | rotation pointer, async clear |
| BRAM | 0 | |
| DSP Slices | 0 | |

Source: `synth/yosys_stat.txt` (45 cells total incl. 1 BUFG).

## 3. Power Estimation

Not estimated (no OSS power model for UltraScale+).

## 4. Verification Coverage

| Metric | Result | Status |
| :--- | :--- | :--- |
| cocotb regression (Icarus 14) | 5/5 tests PASS, 70,419 ns sim | ✓ |
| cocotb regression (Verilator 5.053) | 5/5 tests PASS, same tests unchanged | ✓ |
| SymbiYosys prove (smtbmc/yices, k-induction depth 12) | basecase PASS, induction PASS — "successful proof by k-induction" | ✓ |
| SymbiYosys cover | wrap-around grant N-2 -> N-1 reached at step 2 | ✓ |
| Observed worst wait under random traffic | < N cycles (bound asserted in test) | ✓ |

## 5. Linter Summary

*   Verilator `--lint-only -Wall` at N=8, N=3, N=16: 0 warnings
*   Verible lint: 0 findings
