create_clock -period 3.333 -name clk [get_ports clk]   ;# 300 MHz target
set_input_delay  -clock clk 0.5 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk 0.5 [all_outputs]
