# rr_arbiter — 8-to-1 round-robin arbiter

## What This Is

A parameterized (N=8) round-robin arbiter granting a shared single-cycle resource to one of N level-sensitive requesters.
Grant logic is purely combinational from `req` and a registered rotation pointer, so a request is granted in the same cycle it is asserted.

## PPA Targets (Core Value)

- Latency: 0 cycles `req -> grant` (combinational).
- Fairness: any held request is granted within N cycles.
- Area: pure logic (no DSP/BRAM); LUT/FF reported, logic depth of the grant path documented.

## Hardware Specifications

### Interfaces & Protocols
- [x] `req[N-1:0]` level inputs, `grant[N-1:0]` one-hot-or-zero output, `grant_valid`, `grant_idx[$clog2(N)-1:0]`
- [x] No ack/busy handshake: one grant per clock while any request is pending

### Clocking & Reset
- [x] Single clock `clk`
- [x] `rst_n` asynchronous assert, synchronous de-assert, active low

## Verification Strategy

### Validated
(None yet)

### Active Requirements (RTL & TB)
- [ ] cocotb regression on Icarus and Verilator against a Python reference model
- [ ] SymbiYosys unbounded proof of one-hot/subset invariants and the N-cycle fairness bound
- [ ] Yosys synth_xilinx (UltraScale+) resource report

### Out of Scope
- Weighted / programmable priority — customer prompt specifies fixed rotation
- Multi-cycle grants / lock — single-cycle resource assumed (open question for v2)

## Context

- Target: AMD UltraScale+ / RFSoC fabric (Yosys `synth_xilinx -family xcup` estimate; Vivado for sign-off)
- Tools: OSS CAD Suite 2026-10-14 (Icarus 14, Verilator 5.053, Yosys 0.70, SBY 0.69), cocotb 2.1
- Spec source: `SPEC.md` (customer prompt verbatim + interface answers)

## Constraints

- **Latency (cycles)**: grant must not depend on a register stage — Why: "combinational grant logic for ultra-low latency"
- **Parameterization**: correct for any N >= 2 — Why: reuse beyond the 8-requester case

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pointer advances to `grant_idx+1` only when a grant is issued | Classic fixed-rotation RR; idle cycles do not rotate priority | — Pending |
| Grant selection via masked lowest-set-bit (`x & -x`) on `req & mask(ptr)` with fallback to unmasked | Two priority encoders, shallow logic; maps to carry-chain friendly LUTs | — Pending |
| `grant_idx` derived combinationally from one-hot `grant` | Avoids a second encoder path diverging from `grant` | — Pending |

---
*Last updated: 2026-10-16 after initialization*
