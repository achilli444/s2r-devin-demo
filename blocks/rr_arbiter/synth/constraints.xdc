create_clock -period 3.333 -name clk [get_ports clk]   ;# 300 MHz target
set_input_delay  -clock clk 0.5 [get_ports {req rst_n}]
set_output_delay -clock clk 0.5 [get_ports {grant grant_valid grant_idx}]
