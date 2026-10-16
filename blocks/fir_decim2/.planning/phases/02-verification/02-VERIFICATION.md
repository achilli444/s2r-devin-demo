---
phase: 02-verification
verified: 2026-10-16T01:55:00Z
status: passed
score: 3/3 must-haves verified
---
# Phase 2: Verification Report

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Bit-exact vs scipy golden model on Icarus | ✓ VERIFIED | `make sim SIM=icarus`: TESTS=4 PASS=4 FAIL=0 (impulse_response, random_stream, random_with_gaps, full_scale_no_overflow) |
| 2 | Same tests pass on Verilator unchanged | ✓ VERIFIED | `make sim SIM=verilator`: TESTS=4 PASS=4 FAIL=0 |
| 3 | Tests are substantive, not stubs | ✓ VERIFIED | impulse test checks even/odd coefficient sets directly; 2000-sample random stream compared element-wise |

## Bug found by this phase
First run: all 4 tests FAIL, "first mismatch at output 6: got 0, expected 65647". Root cause: `out_valid` asserted one clock before `out_data` (6-stage valid pipe vs 7 data registers). Fix: `vpipe` widened to 7. (Earlier coefficient set used cutoff 0.5 -> half-band -> all even taps zero, which masked the bug for outputs 0-5.)

## Requirements Coverage
VER-01 ✓, VER-02 ✓, VER-03 ✓ (lint in Phase 1); FUNC-01..06 exercised.

## Task Commits
- bad9b19 test(02-01) cocotb regression
