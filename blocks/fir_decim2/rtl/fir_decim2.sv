// fir_decim2: 25-tap symmetric low-pass FIR, decimate-by-2, polyphase, DSP48E2-friendly.
//
// Polyphase split: y[m] = sum_j he[j]*xe[m-j] + sum_j ho[j]*xo[m-j]
//   xe[m] = x[2m] (even samples, 13-tap branch he[j] = h[2j]),
//   xo[m] = x[2m-1] (odd samples, 12-tap branch ho[j] = h[2j+1]).
// Both branches are themselves symmetric, so the 25 products collapse to 13 multipliers:
//   6 pre-added even pairs + 1 even centre tap + 6 pre-added odd pairs.
// Each multiplier is coded as (a + d) * b with registered a/d, pre-add register, product
// register -> Vivado infers DSP48E2 with the pre-adder. Products are summed in a pipelined
// adder tree (fabric), chosen over a systolic DSP cascade for lower latency.
//
// Streaming: one input sample per clock when in_valid; one output every second input sample.
// Latency: 7 clocks from the edge that accepts the even sample x[2m] to out_valid (shift reg + pre-add + mult + 4 adder-tree stages).
module fir_decim2 #(
  parameter int unsigned IN_W  = 16,
  // full precision: 17-bit pre-add x 18-bit coef = 35 bits, 13 terms -> +4 bits = 39
  parameter int unsigned OUT_W = IN_W + 1 + fir_coefs_pkg::COEF_W + 4
) (
  input  logic                    clk,
  input  logic                    rst_n,
  input  logic signed [IN_W-1:0]  in_data,
  input  logic                    in_valid,
  output logic signed [OUT_W-1:0] out_data,
  output logic                    out_valid
);
  // Scoped references instead of `import`: Yosys only supports pkg::name access.
  localparam int unsigned NTAPS  = fir_coefs_pkg::NTAPS;
  localparam int unsigned COEF_W = fir_coefs_pkg::COEF_W;
  localparam logic [NTAPS*COEF_W-1:0] COEF_FLAT = fir_coefs_pkg::COEF_FLAT;

  localparam int unsigned NE = (NTAPS + 1) / 2;   // 13 even-phase taps
  localparam int unsigned NO = NTAPS / 2;         // 12 odd-phase taps
  localparam int unsigned NP = NO / 2;            // 6 symmetric pairs per branch
  localparam int unsigned NM = NP + 1 + NP;       // 13 multipliers
  localparam int unsigned PA_W = IN_W + 1;
  localparam int unsigned PR_W = PA_W + COEF_W;

  // ---------------------------------------------------------------- phase split + delay lines
  logic phase;                                   // 0: next sample is even x[2m]
  logic signed [IN_W-1:0] xe [NE];
  logic signed [IN_W-1:0] xo [NO];
  logic trig;                                    // an even sample just landed -> compute y[m]

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      phase <= 1'b0;
      for (int unsigned i = 0; i < NE; i++) xe[i] <= '0;
      for (int unsigned i = 0; i < NO; i++) xo[i] <= '0;
    end else if (in_valid) begin
      phase <= ~phase;
      if (!phase) begin
        xe[0] <= in_data;
        for (int unsigned i = 1; i < NE; i++) xe[i] <= xe[i-1];
      end else begin
        xo[0] <= in_data;
        for (int unsigned i = 1; i < NO; i++) xo[i] <= xo[i-1];
      end
    end
  end
  assign trig = in_valid & ~phase;

  // ---------------------------------------------------------------- stage 1: pre-adders (DSP48E2 A+D)
  logic signed [PA_W-1:0] pre [NM];
  logic signed [COEF_W-1:0] coef [NM];
  always_comb begin
    for (int unsigned j = 0; j < NP; j++) begin
      coef[j]      = COEF_FLAT[(2*j)*COEF_W   +: COEF_W];   // even pair j : h[2j]   == h[24-2j]
      coef[NP+1+j] = COEF_FLAT[(2*j+1)*COEF_W +: COEF_W];   // odd pair j  : h[2j+1] == h[23-2j]
    end
    coef[NP] = COEF_FLAT[(NTAPS/2)*COEF_W +: COEF_W];       // centre tap h[12] (even branch, xe[6])
  end

  always_ff @(posedge clk) begin
    for (int unsigned j = 0; j < NP; j++) begin
      pre[j]      <= PA_W'(xe[j]) + PA_W'(xe[NE-1-j]);
      pre[NP+1+j] <= PA_W'(xo[j]) + PA_W'(xo[NO-1-j]);
    end
    pre[NP] <= PA_W'(xe[NE/2]);
  end

  // ---------------------------------------------------------------- stage 2: multipliers (DSP48E2 M)
  logic signed [PR_W-1:0] prod [NM];
  always_ff @(posedge clk) begin
    for (int unsigned j = 0; j < NM; j++) prod[j] <= pre[j] * coef[j];
  end

  // ---------------------------------------------------------------- stages 3-6: pipelined adder tree 13->7->4->2->1
  logic signed [OUT_W-1:0] s1 [7];
  logic signed [OUT_W-1:0] s2 [4];
  logic signed [OUT_W-1:0] s3 [2];
  logic signed [OUT_W-1:0] s4;
  always_ff @(posedge clk) begin
    for (int unsigned j = 0; j < 6; j++) s1[j] <= OUT_W'(prod[2*j]) + OUT_W'(prod[2*j+1]);
    s1[6] <= OUT_W'(prod[12]);
    for (int unsigned j = 0; j < 3; j++) s2[j] <= s1[2*j] + s1[2*j+1];
    s2[3] <= s1[6];
    s3[0] <= s2[0] + s2[1];
    s3[1] <= s2[2] + s2[3];
    s4    <= s3[0] + s3[1];
  end
  assign out_data = s4;

  // ---------------------------------------------------------------- valid pipeline: matches delay line + pre + mult + 4 tree stages
  logic [6:0] vpipe;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) vpipe <= '0;
    else        vpipe <= {vpipe[5:0], trig};
  end
  assign out_valid = vpipe[6];

endmodule
