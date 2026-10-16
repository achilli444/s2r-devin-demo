# Shared per-block Makefile. A block Makefile sets:
#   TOP        top-level module name
#   SRCS       RTL sources (relative to block dir)
#   TESTS      cocotb test module(s) in tb/  (python module names)
#   SBY        formal config(s) in formal/ (optional)
#   SYNTH_TOP  synthesis top if different from TOP (optional)
# then: include ../../mk/block.mk
#
# Simulator selection: SIM=icarus (default) | verilator | questa | xcelium | vcs ...
# Anything cocotb supports works unchanged -> that is how the customer plugs Questa in.
SIM        ?= icarus
WAVES      ?= 1
TOPLEVEL_LANG = verilog
TOPLEVEL   = $(TOP)
SYNTH_TOP  ?= $(TOP)
BLOCK_DIR  := $(abspath .)
ROOT_DIR   := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)
VERILOG_SOURCES = $(abspath $(SRCS))
COCOTB_TEST_MODULES = $(TESTS)
SIM_BUILD  = sim_build/$(SIM)
COCOTB_RESULTS_FILE = results_$(SIM).xml
export PYTHONPATH := $(BLOCK_DIR)/tb:$(ROOT_DIR)/tools/py:$(PYTHONPATH)

ifeq ($(SIM),icarus)
  COMPILE_ARGS += -g2012 -Wall -Wno-timescale
endif
ifeq ($(SIM),verilator)
  EXTRA_ARGS += --timing -Wall -Wno-fatal
endif

.PHONY: help lint lint-verilator lint-verible sim wave formal synth synth-vivado clean-block
help:
	@echo "make lint          verilator --lint-only -Wall (+ verible if installed)"
	@echo "make sim [SIM=icarus|verilator|questa] [TESTS=...] [COCOTB_TESTCASE=...]"
	@echo "make wave          open the last waveform in surfer/gtkwave"
	@echo "make formal        sby -f formal/*.sby"
	@echo "make synth         yosys synth_xilinx -family xcup -> synth/yosys_stat.txt"
	@echo "make synth-vivado  run synth/vivado_synth.tcl if vivado is on PATH (customer side)"

lint: lint-verilator lint-verible
lint-verilator:
	verilator --lint-only -Wall --top-module $(TOP) $(LINT_ARGS) $(SRCS)
lint-verible:
	@if command -v verible-verilog-lint >/dev/null 2>&1; then \
	  verible-verilog-lint --rules_config=$(ROOT_DIR)/.rules.verible_lint $(SRCS); \
	else echo "verible-verilog-lint not installed; skipping"; fi

# cocotb's own makefile provides the `sim` target
include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	@f=$$(ls -t $(SIM_BUILD)/*/*.fst $(SIM_BUILD)/*/*.vcd $(SIM_BUILD)/*.fst $(SIM_BUILD)/*.vcd dump.fst dump.vcd 2>/dev/null | head -1); \
	[ -n "$$f" ] || { echo "no waveform found; run make sim WAVES=1"; exit 1; }; \
	echo "opening $$f"; \
	if command -v surfer >/dev/null 2>&1; then surfer "$$f" & elif command -v gtkwave >/dev/null 2>&1; then gtkwave "$$f" & else echo "no viewer installed"; fi

formal:
ifeq ($(SBY),)
	@echo "$(TOP): no SBY file (no formal properties) — skipping"
else
	@[ -n "$(SBY)" ] || { echo "no SBY configs for this block"; exit 1; }
	@for s in $(SBY); do echo "=== sby $$s"; (cd formal && sby -f $$(basename $$s)) || exit 1; done
endif

synth:
	@mkdir -p synth
	yosys -q -l synth/yosys.log -p "read_verilog -sv $(SRCS); hierarchy -top $(SYNTH_TOP); synth_xilinx -family xcup -noiopad -top $(SYNTH_TOP); tee -q -o synth/yosys_stat.txt stat; write_json synth/$(SYNTH_TOP).json"
	@grep -v "^$$" synth/yosys_stat.txt | grep -v "Printing statistics\|^===\|Local Count\|^ *| *$$"

synth-vivado:
	@if command -v vivado >/dev/null 2>&1; then (cd synth && vivado -mode batch -source vivado_synth.tcl); \
	else echo "vivado not on PATH. On a licensed machine run:  cd $(BLOCK_DIR)/synth && vivado -mode batch -source vivado_synth.tcl"; fi

clean:: clean-block
clean-block:
	rm -rf sim_build obj_dir results_*.xml dump.fst dump.vcd __pycache__ tb/__pycache__ synth/yosys.log synth/*.json
	@for s in $(SBY); do rm -rf formal/$$(basename $$s .sby); done
