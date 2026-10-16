// Formal properties for rr_arbiter (included inside the module under `ifdef FORMAL).
// Proven with SymbiYosys in prove mode (BMC + k-induction).

  // Track reset so we only assert after the first reset release.
  logic f_past_valid = 1'b0;
  always_ff @(posedge clk) f_past_valid <= 1'b1;
  initial assume (!rst_n);

  // FUNC-01: one-hot when requested, zero when idle.
  always_comb begin
    if (req == '0) assert (grant == '0);
    else           assert ($onehot(grant));
    // FUNC-02: subset of req.  INT-02: valid/idx consistency.
    assert ((grant & ~req) == '0);
    assert (grant_valid == |req);
    if (grant_valid) assert (grant[grant_idx]);
    assert (32'(ptr) < N);
  end

  // FUNC-04: rotation — the grantee is the first requester at/after ptr (wrapping):
  // its distance from ptr is <= the distance of every other requester.
  logic [31:0] f_d_g;
  assign f_d_g = (32'(grant_idx) >= 32'(ptr)) ? 32'(grant_idx) - 32'(ptr) : 32'(grant_idx) + N - 32'(ptr);
  always_comb begin
    for (int unsigned i = 0; i < N; i++) begin
      if (grant_valid && req[i])
        assert (f_d_g <= ((i >= 32'(ptr)) ? i - 32'(ptr) : i + N - 32'(ptr)));
    end
  end

  // FUNC-05: fairness bound for an arbitrary fixed requester — waits at most N-1 cycles.
  (* anyconst *) logic [IW-1:0] f_who;
  logic [IW:0] f_wait = '0;
  always_ff @(posedge clk) begin
    if (!rst_n || !req[f_who] || grant[f_who]) f_wait <= '0;
    else                                       f_wait <= f_wait + 1'b1;
  end
  always_comb begin
    assume (32'(f_who) < N);
    assert (32'(f_wait) < N);
  end

  // Pointer only moves on a grant, and moves to grantee+1.
  always_ff @(posedge clk) begin
    if (f_past_valid && $past(rst_n) && rst_n) begin
      if (!$past(grant_valid)) assert (ptr == $past(ptr));
      else                     assert (ptr == $past(ptr_next));
    end
  end

  // Cover: all N requesters granted back to back, and a wrap-around.
  always_ff @(posedge clk) begin
    if (f_past_valid && rst_n) cover (grant_valid && grant_idx == IW'(N-1) && $past(grant_idx) == IW'(N-2));
  end
