# Hardware Metrics Report — fir_decim2

**Phase:** 3 — Synthesis
**Date:** 2026-10-16
**Commit:** bad9b19
**Tool:** Yosys 0.70+16, `synth_xilinx -family xcup -noiopad` (UltraScale+/RFSoC **estimate**). Sign-off: `synth/vivado_synth.tcl` on the customer's Vivado.

## 1. Timing Analysis

| Clock Domain | Frequency (MHz) | WNS (ns) | Status |
| :--- | :--- | :--- | :--- |
| `clk` | target 300 | n/a — Yosys has no STA | UNVERIFIED (Vivado) |

Structural: every multiplier has registered inputs, a pre-add register and a product register (the DSP48E2 A/D, AD, M register pattern); adder tree is one 39-bit add per stage.

## 2. Resource Utilization (Area)

| Resource | Used | Target | Note |
| :--- | :--- | :--- | :--- |
| DSP48E2 | **11** | <= 13 | 13 multipliers coded; h[2], h[7] quantize to 0 so two products are constant 0 and removed. Pre-adder use must be confirmed in Vivado (`dsp_properties.rpt`). |
| Flip-Flops | 1269 (408 FDCE + 861 FDRE) | — | 400 FFs are the 25x16 delay lines; Vivado will absorb most pre/prod registers into the DSP48E2s, Yosys keeps them in fabric |
| LUT2 | 473 | — | adder tree + pre-adders (Yosys does not pack DSP post-adders) |
| CARRY4 | 133 | — | |
| SRL16E | 34 | — | part of delay lines |
| BRAM | 0 | — | |

Source: `synth/yosys_stat.txt` (1923 cells).

## 3. Verification Coverage

| Metric | Result | Status |
| :--- | :--- | :--- |
| cocotb vs scipy golden model (Icarus 14) | 4/4 PASS, bit-exact | ✓ |
| cocotb vs scipy golden model (Verilator 5.053) | 4/4 PASS, bit-exact | ✓ |
| Lint (Verilator -Wall, Verible) | clean | ✓ |

## 4. Open items for Vivado sign-off
1. DSP48E2 count and `USE_PREADD`/ADREG settings — expect 11 with pre-adder on the 10 paired taps.
2. WNS at 300 MHz; if negative, first lever is `-retiming` (already in tcl), second is a DSP cascade (v2).
