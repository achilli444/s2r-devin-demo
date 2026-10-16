# Top-level helpers. Per-block targets live in blocks/<name>/Makefile (see mk/block.mk).
BLOCKS := $(notdir $(wildcard blocks/*))
SIM ?= icarus

.PHONY: help doctor install lint sim formal synth clean $(BLOCKS)

help:
	@echo "make install          install OSS CAD Suite + Python venv (tools/install_eda.sh)"
	@echo "make doctor           show which tools are on PATH (source tools/env.sh first)"
	@echo "make lint|sim|formal|synth [SIM=icarus|verilator|questa]   run for every block"
	@echo "make <block> TARGET=sim     run one target for one block; blocks: $(BLOCKS)"
	@echo "cd blocks/<name> && make help    per-block targets"

install:
	tools/install_eda.sh

doctor:
	@tools/doctor.sh

lint sim formal synth:
	@for b in $(BLOCKS); do echo "=== $$b: $@"; $(MAKE) -C blocks/$$b $@ SIM=$(SIM) || exit 1; done

$(BLOCKS):
	$(MAKE) -C blocks/$@ $(or $(TARGET),sim) SIM=$(SIM)

clean:
	@for b in $(BLOCKS); do $(MAKE) -C blocks/$$b clean; done
