  // Formal properties for axis_skid (included inside the module under `ifdef FORMAL).
  logic f_past_valid = 1'b0;
  always_ff @(posedge clk) f_past_valid <= 1'b1;
  initial assume (!rst_n);
  always_comb if (!f_past_valid) assume (!rst_n);

  // ---- AXI-Stream source contract (assumed on the upstream side)
  always_ff @(posedge clk) if (f_past_valid && $past(rst_n) && rst_n) begin
    if ($past(s_axis_tvalid && !s_axis_tready)) begin
      assume (s_axis_tvalid);
      assume ($stable(s_pkt));
    end
  end

  // ---- AXI-Stream contract on the downstream side (asserted)
  always_ff @(posedge clk) if (f_past_valid && $past(rst_n) && rst_n) begin
    if ($past(m_axis_tvalid && !m_axis_tready)) begin
      assert (m_axis_tvalid);
      assert ($stable(m_pkt));
    end
  end

  // ---- tready is a pure register: it never changes mid-cycle with upstream inputs (structural),
  //      and it only drops in the cycle after a word was caught in the skid slot
  always_ff @(posedge clk) if (f_past_valid && $past(rst_n) && rst_n) begin
    if (!s_axis_tready) assert ($past(in_fire && !out_adv) || $past(!s_axis_tready && !m_axis_tready));
  end

  // ---- occupancy == words in - words out, always 0..2, and no drop / no duplicate / in-order:
  //      a 2-entry shadow queue must always agree with what comes out.
  logic [W-1:0] f_q0, f_q1;
  logic [1:0]   f_cnt;
  logic         out_fire;
  assign out_fire = m_axis_tvalid & m_axis_tready;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) f_cnt <= '0;
    else begin
      case ({in_fire, out_fire})
        2'b10: begin f_cnt <= f_cnt + 1'b1; if (f_cnt == 0) f_q0 <= s_pkt; else f_q1 <= s_pkt; end
        2'b01: begin f_cnt <= f_cnt - 1'b1; f_q0 <= f_q1; end
        2'b11: begin if (f_cnt == 1) f_q0 <= s_pkt; else begin f_q0 <= f_q1; f_q1 <= s_pkt; end end
        default: ;
      endcase
    end
  end
  always_comb if (rst_n) begin
    assert (f_cnt <= 2);
    assert (f_cnt == 2'(m_axis_tvalid) + 2'(skid_valid));
    assert (!(f_cnt == 2 && s_axis_tready));                       // full => not ready
    if (m_axis_tvalid) assert (m_pkt == f_q0);                     // head of queue is what we present
    if (skid_valid)    assert (skid_pkt == f_q1 && m_axis_tvalid); // skid only holds the second word
  end

  // ---- covers: fill to 2, drain, and sustained back-to-back transfers
  always_ff @(posedge clk) if (rst_n) begin
    cover (f_cnt == 2 && out_fire && in_fire == 0);
    cover (f_past_valid && $past(f_cnt == 2) && f_cnt == 1 && out_fire);
    cover ($past(out_fire) && out_fire && $past(in_fire) && in_fire);
  end
