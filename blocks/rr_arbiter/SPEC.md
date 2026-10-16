# Spec: 8-to-1 round-robin arbiter

## Customer prompt (verbatim)

> A high-performance 8-to-1 round-robin arbiter providing fair access to a shared resource. It implements a fixed rotation priority scheme with combinational grant logic for ultra-low latency.

## Interface (answers given during `/s2r:new-project` questioning)

| Signal | Dir | Width | Notes |
|---|---|---|---|
| `clk` | in | 1 | rising edge |
| `rst_n` | in | 1 | async assert, sync de-assert, active low |
| `req` | in | 8 | one bit per requester, level |
| `grant` | out | 8 | one-hot or zero, **combinational from `req` and the pointer** (0-cycle latency) |
| `grant_valid` | out | 1 | `|grant` |
| `grant_idx` | out | 3 | index of the granted requester |

Parameter `N = 8` (design must stay correct for any `N >= 2`).

## Behaviour

- Fixed rotation: after requester *i* is granted, the next search starts at *i+1* (mod N). Pointer only advances on a cycle where a grant is issued.
- Fairness: any continuously asserting requester is granted within N cycles.
- `grant` is exactly one-hot when `req != 0`, zero otherwise; `grant` is a subset of `req`.
- No `ack`/`busy` handshake: one grant per clock while `req != 0` (single-cycle resource).

## Success criteria

- `verilator --lint-only -Wall` clean; Verible lint clean.
- cocotb tests pass on Icarus **and** Verilator: one-hot, subset-of-req, zero-latency grant, round-robin order, N-cycle fairness bound, random stress vs. a Python reference model.
- SymbiYosys proves (unbounded, k-induction): one-hot/subset invariants and the N-cycle fairness bound.
- Yosys `synth_xilinx -family xcup`: no DSP/BRAM, report LUT/FF, logic depth of `req -> grant` documented.
