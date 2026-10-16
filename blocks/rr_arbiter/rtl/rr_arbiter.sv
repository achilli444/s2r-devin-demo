// rr_arbiter: N-to-1 round-robin arbiter with combinational (0-cycle) grant.
//
// Rotation pointer `ptr` holds the highest-priority requester. Grant = lowest-index
// requester at or above `ptr`; if none, lowest-index requester overall (wrap).
// The pointer moves to grant_idx+1 whenever a grant is issued, so the granted
// requester becomes lowest priority for the next decision (fixed rotation).
module rr_arbiter #(
  parameter int unsigned N  = 8,
  localparam int unsigned IW = (N > 1) ? $clog2(N) : 1
) (
  input  logic          clk,
  input  logic          rst_n,
  input  logic [N-1:0]  req,
  output logic [N-1:0]  grant,
  output logic          grant_valid,
  output logic [IW-1:0] grant_idx
);

  logic [IW-1:0] ptr;

  // Requesters at or above the pointer.
  logic [N-1:0] above_mask;
  logic [N-1:0] req_above;
  always_comb begin
    for (int unsigned i = 0; i < N; i++) begin
      above_mask[i] = (i >= 32'(ptr));
    end
  end
  assign req_above = req & above_mask;

  // Lowest set bit (x & -x): a single priority encode, no loop.
  logic [N-1:0] sel_above, sel_any;
  assign sel_above = req_above & (~req_above + 1'b1);
  assign sel_any   = req       & (~req       + 1'b1);

  assign grant       = (req_above != '0) ? sel_above : sel_any;
  assign grant_valid = |req;

  // One-hot to index.
  always_comb begin
    grant_idx = '0;
    for (int unsigned i = 0; i < N; i++) begin
      if (grant[i]) grant_idx = IW'(i);
    end
  end

  // Pointer: next search starts just after the granted requester.
  logic [IW-1:0] ptr_next;
  assign ptr_next = (32'(grant_idx) == N - 1) ? '0 : grant_idx + 1'b1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)           ptr <= '0;
    else if (grant_valid) ptr <= ptr_next;
  end

`ifdef FORMAL
  `include "rr_arbiter_props.svh"
`endif

endmodule
