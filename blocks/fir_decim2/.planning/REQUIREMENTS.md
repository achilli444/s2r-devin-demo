# Requirements — fir_decim2 v1

## Interface
- [x] **INT-01** `in_data[15:0]` signed + `in_valid`; `out_data[38:0]` signed + `out_valid`; `clk`, `rst_n` async-low.
- [x] **INT-02** One output per two accepted input samples; outputs aligned so y[m] = sum_k h[k] x[2m-k].

## Functional
- [x] **FUNC-01** Bit-exact vs golden model for impulse, random, random-with-gaps, full-scale (`tb/test_fir_decim2.py`).
- [x] **FUNC-02** 25 taps, symmetric, from `fir_coefs_pkg`; coefficients regenerable with `make coefs`.
- [x] **FUNC-03** Polyphase: even/odd branches, each symmetric, <= 13 multipliers.
- [x] **FUNC-04** Sample-driven: in_valid gaps do not change output values.
- [x] **FUNC-05** No overflow: 17-bit pre-add, 35-bit product, 39-bit accumulate.
- [x] **FUNC-06** Constant latency: 7 clocks from accepting x[2m] to out_valid.

## Verification
- [x] **VER-01** cocotb regression passes on Icarus (`make sim SIM=icarus`).
- [x] **VER-02** Same regression passes on Verilator (`make sim SIM=verilator`).
- [x] **VER-03** Verilator -Wall and Verible lint clean.

## Synthesis
- [x] **SYN-01** Yosys xcup estimate recorded in HARDWARE_METRICS.md; DSP count <= 13.
- [ ] **SYN-02** Vivado RFSoC sign-off: DSP48E2 count, pre-adder usage, WNS at 300 MHz — customer side (`synth/vivado_synth.tcl`).

## Out of scope (v2)
- Programmable coefficients (AXI-Lite), DSP cascade (PCIN) variant, saturation/rounding to 16-bit output, AXI-Stream wrapper.

## Traceability
| Req | Phase | Status |
|---|---|---|
| INT-*, FUNC-* | 1 RTL | Complete |
| VER-* | 2 Verification | Complete |
| SYN-01 | 3 Synthesis | Complete |
| SYN-02 | 3 Synthesis | Pending (customer Vivado) |
