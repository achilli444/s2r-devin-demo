# Customer-side sign-off synthesis for fir_decim2 (run on a licensed Vivado, RFSoC part):
#   cd blocks/fir_decim2/synth && vivado -mode batch -source vivado_synth.tcl [-tclargs <part>]
# Answers the questions Yosys cannot: exact DSP48E2 count, pre-adder (A+D) usage, timing at 300 MHz.
set part xczu28dr-ffvg1517-2-e   ;# ZCU111 RFSoC
if {$argc > 0} { set part [lindex $argv 0] }
read_verilog -sv ../rtl/fir_coefs_pkg.sv
read_verilog -sv ../rtl/fir_decim2.sv
read_xdc constraints.xdc
synth_design -top fir_decim2 -part $part -mode out_of_context -retiming
report_utilization    -file utilization.rpt
report_timing_summary -file timing_summary.rpt
# Which DSP48E2 features were used (look for AREG/ADREG/MREG/PREG = 1 and USE_PREADD): 
report_property -file dsp_properties.rpt [get_cells -hier -filter {REF_NAME == DSP48E2}]
puts "DONE: see utilization.rpt (DSP48E2 row), timing_summary.rpt (WNS), dsp_properties.rpt (pre-adder)"
