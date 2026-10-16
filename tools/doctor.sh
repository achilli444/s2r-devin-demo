#!/usr/bin/env bash
# Print the version of every tool the flow uses. Exit 1 if a required one is missing.
req=(iverilog vvp verilator yosys sby python cocotb-config make)
opt=(verible-verilog-lint verible-verilog-format gtkwave surfer nextpnr-ecp5 vivado vsim quartus_sh)
miss=0
v() { case "$1" in
  iverilog) iverilog -V 2>/dev/null | head -1 ;;
  vvp) vvp -V 2>/dev/null | head -1 ;;
  verilator) verilator --version 2>/dev/null ;;
  yosys) yosys -V 2>/dev/null ;;
  sby) sby --version 2>/dev/null || echo "sby (present)" ;;
  python) python --version 2>&1 ;;
  cocotb-config) echo "cocotb $(cocotb-config --version 2>/dev/null)" ;;
  make) make --version 2>/dev/null | head -1 ;;
  verible-verilog-lint|verible-verilog-format) "$1" --version 2>/dev/null | head -1 ;;
  gtkwave) gtkwave --version 2>/dev/null | head -1 || echo "gtkwave (present)" ;;
  surfer) echo "surfer (present)" ;;
  nextpnr-ecp5) nextpnr-ecp5 --version 2>&1 | head -1 ;;
  vivado) vivado -version 2>/dev/null | head -1 ;;
  vsim) vsim -version 2>/dev/null | head -1 ;;
  quartus_sh) quartus_sh --version 2>/dev/null | head -1 ;;
esac; }
echo "required:"
for t in "${req[@]}"; do
  if command -v "$t" >/dev/null 2>&1; then printf '  ok      %-24s %s\n' "$t" "$(v "$t")"; else printf '  MISSING %-24s\n' "$t"; miss=1; fi
done
echo "optional / commercial:"
for t in "${opt[@]}"; do
  if command -v "$t" >/dev/null 2>&1; then printf '  ok      %-24s %s\n' "$t" "$(v "$t")"; else printf '  -       %-24s\n' "$t"; fi
done
python - <<'PY' 2>/dev/null || { echo "  MISSING python packages (cocotbext-axi/numpy/scipy)"; miss=1; }
import cocotbext.axi, numpy, scipy; print("  ok      python packages        cocotbext-axi numpy %s scipy %s" % (numpy.__version__, scipy.__version__))
PY
[ $miss = 0 ] && echo "all required tools present" || { echo "run: tools/install_eda.sh && source tools/env.sh"; exit 1; }
