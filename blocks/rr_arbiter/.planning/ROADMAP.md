# Roadmap: rr_arbiter

## Overview

Three short phases: write lint-clean parameterized RTL, prove it (simulation on two simulators + formal), then measure area on UltraScale+ and record metrics.

## Phases

- [ ] **Phase 1: RTL** - Parameterized round-robin arbiter, lint clean
- [ ] **Phase 2: Verification** - cocotb regression (Icarus + Verilator) and SymbiYosys proof
- [ ] **Phase 3: Synthesis** - Yosys UltraScale+ estimate, HARDWARE_METRICS.md

## Phase Details

### Phase 1: RTL
**Goal**: `rtl/rr_arbiter.sv` implementing INT-01..02, FUNC-01..06, RST-01, lint clean
**Depends on**: Nothing
**Requirements**: INT-01, INT-02, FUNC-01, FUNC-02, FUNC-03, FUNC-04, FUNC-05, FUNC-06, RST-01, VER-01
**Success Criteria**:
  1. `make lint` passes (Verilator -Wall + Verible) at N=8, N=3, N=16
  2. Grant path contains no flop (inspection + formal in Phase 2)
**Plans**: 1 plan
- [ ] 01-01: Write RTL and Makefile

### Phase 2: Verification
**Goal**: Behaviour proven by simulation and formal
**Depends on**: Phase 1
**Requirements**: VER-02, VER-03
**Success Criteria**:
  1. `make sim SIM=icarus` and `make sim SIM=verilator` pass all tests
  2. `make formal` → PASS for all asserts (prove mode)
**Plans**: 2 plans
- [ ] 02-01: cocotb tests + Python reference model
- [ ] 02-02: formal properties + sby config

### Phase 3: Synthesis
**Goal**: Area/depth numbers on UltraScale+
**Depends on**: Phase 2
**Requirements**: SYN-01
**Success Criteria**:
  1. `make synth` produces `synth/yosys_stat.txt` with 0 DSP/BRAM
  2. `.planning/HARDWARE_METRICS.md` filled in from real tool output
**Plans**: 1 plan
- [ ] 03-01: Yosys run + metrics report

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. RTL | 0/1 | Not started | - |
| 2. Verification | 0/2 | Not started | - |
| 3. Synthesis | 0/1 | Not started | - |
