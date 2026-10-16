# source this file:  source tools/env.sh
_S2R_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
EDA_DIR="${EDA_DIR:-$HOME/eda}"
export EDA_DIR
[ -d "$EDA_DIR/verible/bin" ] && PATH="$EDA_DIR/verible/bin:$PATH"
[ -d "$EDA_DIR/oss-cad-suite/bin" ] && PATH="$EDA_DIR/oss-cad-suite/bin:$PATH"
# simulator shims without the suite's PYTHONHOME, so cocotb can embed the .venv python (see install_eda.sh)
[ -d "$EDA_DIR/bin-nopy" ] && PATH="$EDA_DIR/bin-nopy:$PATH"
[ -d "$_S2R_ROOT/.venv/bin" ] && PATH="$_S2R_ROOT/.venv/bin:$PATH" && VIRTUAL_ENV="$_S2R_ROOT/.venv" && export VIRTUAL_ENV
export PATH
unset _S2R_ROOT
