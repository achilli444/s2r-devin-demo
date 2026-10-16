// axis_skid: 2-deep AXI-Stream skid buffer. Breaks the combinational path on TREADY:
// s_axis_tready is driven straight from a flip-flop and depends on nothing upstream.
//
// Two storage slots: the output register (m_*) and one skid register. s_axis_tready is
// simply "the skid slot is empty" (registered). While the sink stalls, the one word already
// in flight lands in the skid slot; when the sink resumes it drains first. Full throughput
// (one word per clock) when the sink is ready, no bubbles after a stall.
module axis_skid #(
  parameter int unsigned DATA_W = 32,
  parameter int unsigned USER_W = 1
) (
  input  logic              clk,
  input  logic              rst_n,
  // upstream
  input  logic [DATA_W-1:0] s_axis_tdata,
  input  logic [USER_W-1:0] s_axis_tuser,
  input  logic              s_axis_tlast,
  input  logic              s_axis_tvalid,
  output logic              s_axis_tready,
  // downstream
  output logic [DATA_W-1:0] m_axis_tdata,
  output logic [USER_W-1:0] m_axis_tuser,
  output logic              m_axis_tlast,
  output logic              m_axis_tvalid,
  input  logic              m_axis_tready
);
  localparam int unsigned W = DATA_W + USER_W + 1;

  logic [W-1:0] s_pkt, m_pkt, skid_pkt;
  logic         skid_valid;
  logic         in_fire, out_adv;

  assign s_pkt         = {s_axis_tlast, s_axis_tuser, s_axis_tdata};
  assign {m_axis_tlast, m_axis_tuser, m_axis_tdata} = m_pkt;

  assign s_axis_tready = ~skid_valid;             // registered: skid_valid is a flop
  assign in_fire       = s_axis_tvalid & s_axis_tready;
  assign out_adv       = m_axis_tready | ~m_axis_tvalid; // output slot free or draining this cycle

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_axis_tvalid <= 1'b0;
      skid_valid    <= 1'b0;
    end else begin
      if (out_adv) begin
        // output slot advances: drain the skid first, else take the input directly
        m_axis_tvalid <= skid_valid | in_fire;
        skid_valid    <= 1'b0;
      end else if (in_fire) begin
        // output stalled and a word is in flight: catch it (tready is still 1 this cycle)
        skid_valid    <= 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (out_adv) m_pkt <= skid_valid ? skid_pkt : s_pkt;
    if (in_fire && !out_adv) skid_pkt <= s_pkt;
  end

`ifdef FORMAL
  `include "axis_skid_props.svh"
`endif
endmodule
