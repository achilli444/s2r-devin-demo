# Requirements: rr_arbiter

**Defined:** 2026-10-16
**PPA Targets:** 0-cycle grant latency; grant within N cycles; logic-only area

## v1 Specifications

### Interfaces & I/O

- [x] **INT-01**: Ports `clk`, `rst_n`, `req[N-1:0]`, `grant[N-1:0]`, `grant_valid`, `grant_idx[$clog2(N)-1:0]`; parameter `N` default 8
- [x] **INT-02**: `grant_valid == |grant`; `grant_idx` is the index of the set bit of `grant` (don't-care when `grant_valid == 0`)

### Functional Logic

- [x] **FUNC-01**: `grant` is one-hot when `req != 0` and zero when `req == 0`
- [x] **FUNC-02**: `grant & ~req == 0` (never grant a non-requester)
- [x] **FUNC-03**: Zero-latency: `grant` is a combinational function of `req` and the internal pointer (changes within the same cycle `req` changes)
- [x] **FUNC-04**: Fixed rotation: the search for the next grant starts at `last_granted + 1 (mod N)`; pointer unchanged on cycles with no grant
- [x] **FUNC-05**: Fairness bound: a requester holding `req[i]` high is granted within N cycles
- [x] **FUNC-06**: Design is correct for any `N >= 2` (tested at N=8, lint-elaborated at N=3 and N=16)

### Clocking & Reset

- [x] **RST-01**: `rst_n` asynchronous assert / synchronous de-assert; after reset the pointer is 0 (requester 0 has priority)

### Verification & Quality

- [x] **VER-01**: `verilator --lint-only -Wall` and `verible-verilog-lint` report no warnings
- [x] **VER-02**: cocotb regression passes on Icarus and on Verilator without test changes
- [x] **VER-03**: SymbiYosys `prove` of FUNC-01/02/04/05 passes (unbounded, k-induction)
- [x] **SYN-01**: Yosys `synth_xilinx -family xcup` succeeds; 0 DSP / 0 BRAM; LUT/FF recorded in HARDWARE_METRICS.md

## v2 Specifications

- **FUNC-07**: Optional `lock`/multi-cycle grant hold
- **FUNC-08**: Registered-output variant for very high Fmax

## Out of Scope

| Feature | Reason |
|---------|--------|
| Weighted / programmable priority | Prompt specifies fixed rotation |
| Ack handshake | Single-cycle shared resource |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INT-01, INT-02, FUNC-01..06, RST-01, VER-01 | Phase 1 | Complete |
| VER-02, VER-03 | Phase 2 | Complete |
| SYN-01 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-10-16*
*Last updated: 2026-10-16 after roadmap*
