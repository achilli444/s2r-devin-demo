---
phase: 01-rtl
plan: 01
subsystem: rtl
tags: [arbiter, round-robin, systemverilog, verilator, verible]
provides:
  - rtl/rr_arbiter.sv — parameterized N-to-1 round-robin arbiter, combinational grant
  - Makefile — lint/sim/formal/synth via mk/block.mk
key-decisions:
  - "Masked lowest-set-bit (x & -x) selection with unmasked fallback: two encoders, shallow carry-chain logic"
  - "Pointer advances to grant_idx+1 only on cycles with a grant"
completed: 2026-10-16
---
# Phase 1: RTL Summary
**Parameterized RR arbiter with 0-cycle grant, lint clean at N=3/8/16.**

## Verification Performed
`make lint`: `verilator --lint-only -Wall` (N=8, -GN=3, -GN=16) and `verible-verilog-lint` — no warnings.

## Task Commits
- 7d0f4b6 feat(01-01): rr_arbiter RTL
