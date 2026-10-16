TOP   = rr_arbiter
SRCS  = rtl/rr_arbiter.sv
TESTS = test_rr_arbiter
SBY   = formal/rr_arbiter.sby
include ../../mk/block.mk

# FUNC-06: elaborate at other widths
lint-params:
	verilator --lint-only -Wall --top-module $(TOP) -GN=3  $(SRCS)
	verilator --lint-only -Wall --top-module $(TOP) -GN=16 $(SRCS)
lint: lint-params
