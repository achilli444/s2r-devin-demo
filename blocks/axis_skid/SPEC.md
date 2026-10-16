# Spec: parameterized AXI-Stream skid buffer (live demo block)

## Customer prompt (verbatim)

> A parameterized AXI-Stream skid buffer designed to break combinational paths on the `TREADY` signal to facilitate timing closure. This is a fixed-depth (2-deep) synchronization primitive.

## Open points to settle in `/s2r:new-project` (answer on camera)

- Data width parameter (`DATA_W`, default 32) and which sidebands to carry (`TLAST`, `TKEEP`, `TUSER` width).
- Reset style (async-assert/sync-deassert active-low `aresetn` per AXI).
- Must `s_axis_tready` be a registered output (yes — that is the point of the block) and must `m_axis_tvalid`/`tdata` also be registered (full "register slice" vs. only breaking `tready`)?
- Throughput requirement: must sustain one transfer per clock with no bubbles when the sink is always ready.

## Success criteria (to be written into REQUIREMENTS.md by the flow)

- Lint clean.
- cocotb test with `cocotbext-axi` (`AxiStreamSource`/`AxiStreamSink` with random valid/ready back-pressure) passes on Icarus and Verilator: no drop, no duplicate, in-order, full throughput when `tready` held high.
- Waveform shows `s_axis_tready` driven by a flop (no same-cycle dependence on `m_axis_tready`).
- SymbiYosys proves: `tready` registered (no comb path), AXI-Stream rule "valid&!ready ⇒ data stable and valid held", 2-deep occupancy never exceeded, no data loss (via a shadow counter / two-packet trace).
- Yosys stat: FF/LUT count, 0 DSP/BRAM.

Reference implementations the audience may know: ZipCPU `wb2axip/rtl/skidbuffer.v` (+ its formal properties), alexforencich `verilog-axis/rtl/axis_register.v`.
