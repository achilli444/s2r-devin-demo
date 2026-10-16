create_clock -period 3.333 -name clk [get_ports clk]   ;# 300 MHz target (RFSoC fabric)
set_input_delay  -clock clk 0.5 [get_ports {in_data in_valid rst_n}]
set_output_delay -clock clk 0.5 [get_ports {out_data out_valid}]
