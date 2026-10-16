# Customer-side sign-off synthesis for rr_arbiter (run on a licensed Vivado):
#   cd blocks/rr_arbiter/synth && vivado -mode batch -source vivado_synth.tcl
set part xczu28dr-ffvg1517-2-e   ;# ZCU111 RFSoC; override: -tclargs <part>
if {$argc > 0} { set part [lindex $argv 0] }
read_verilog -sv [glob ../rtl/*.sv]
read_xdc constraints.xdc
synth_design -top rr_arbiter -part $part -mode out_of_context
report_utilization   -file utilization.rpt
report_timing_summary -file timing_summary.rpt
report_design_analysis -logic_level_distribution -file logic_levels.rpt
puts "DONE: see utilization.rpt / timing_summary.rpt / logic_levels.rpt"
