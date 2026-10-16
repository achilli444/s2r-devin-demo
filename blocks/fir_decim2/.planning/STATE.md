# State — fir_decim2

## Current Position
Phase: 3 of 3 (Synthesis) — all phases complete
Status: Milestone v1 complete
Last activity: 2026-10-16 — synthesis metrics recorded
Progress: [██████████] 100%

## Accumulated Context
- Found and fixed during Phase 2: out_valid was one clock early (valid pipe had 6 stages for a 7-register data path); caught by the impulse test, which showed the centre tap landing in y[7] instead of y[6].
- Yosys SV limitations shaped the package: no `import` in modules, no array localparams in packages -> flat coefficient vector + `pkg::name` references.
- Tap h[2] and h[7] quantize to 0 -> 11 live multipliers, not 13.

## Next
`/s2r:complete-milestone`, or `/s2r:new-milestone` for v2 (AXI-Stream wrapper, programmable coefficients). SYN-02 pending on the customer's Vivado.
