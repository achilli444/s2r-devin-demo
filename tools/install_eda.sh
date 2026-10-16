#!/usr/bin/env bash
# Install the open-source EDA stack used by this repo on macOS or Linux.
#   - YosysHQ OSS CAD Suite: iverilog/vvp, verilator, yosys, sby + solvers, gtkwave, surfer, nextpnr
#   - Python venv (.venv) with cocotb, cocotbext-axi, numpy, scipy, pytest
#   - Verible (lint/format), best effort
# Usage: tools/install_eda.sh            # installs to $EDA_DIR (default ~/eda)
#        OSS_CAD_TAG=2026-10-14 tools/install_eda.sh   # pin a release
# Afterwards:  source tools/env.sh && make doctor
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EDA_DIR="${EDA_DIR:-$HOME/eda}"
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Linux-x86_64)  PLAT=linux-x64 ;;
  Linux-aarch64) PLAT=linux-arm64 ;;
  Darwin-arm64)  PLAT=darwin-arm64 ;;
  Darwin-x86_64) PLAT=darwin-x64 ;;
  *) echo "unsupported platform $OS-$ARCH"; exit 1 ;;
esac

mkdir -p "$EDA_DIR"; cd "$EDA_DIR"

# ---- OSS CAD Suite -----------------------------------------------------------
if [ ! -x "$EDA_DIR/oss-cad-suite/bin/yosys" ]; then
  TAG="${OSS_CAD_TAG:-$(curl -fsSL https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')}"
  TARBALL="oss-cad-suite-${PLAT}-${TAG//-/}.tgz"
  URL="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/${TAG}/${TARBALL}"
  echo ">> downloading OSS CAD Suite ${TAG} (${PLAT}) ~1 GB"
  curl -fL --progress-bar -o "$TARBALL" "$URL"
  echo ">> extracting"
  tar xzf "$TARBALL" && rm -f "$TARBALL"
  if [ "$OS" = Darwin ]; then
    xattr -dr com.apple.quarantine oss-cad-suite 2>/dev/null || true
    [ -x oss-cad-suite/activate ] && ./oss-cad-suite/activate || true
  fi
  echo "$TAG" > oss-cad-suite/VERSION_TAG
else
  echo ">> OSS CAD Suite already present at $EDA_DIR/oss-cad-suite ($(cat oss-cad-suite/VERSION_TAG 2>/dev/null || echo unknown))"
fi

# ---- Verible (optional) ------------------------------------------------------
if ! command -v verible-verilog-lint >/dev/null 2>&1 && [ ! -x "$EDA_DIR/verible/bin/verible-verilog-lint" ]; then
  echo ">> installing Verible"
  if [ "$OS" = Darwin ] && command -v brew >/dev/null 2>&1; then
    brew install verible || echo "!! brew install verible failed; lint will skip Verible"
  elif [ "$OS" = Linux ] && [ "$ARCH" = x86_64 ]; then
    VTAG="$(curl -fsSL https://api.github.com/repos/chipsalliance/verible/releases/latest | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
    VURL="https://github.com/chipsalliance/verible/releases/download/${VTAG}/verible-${VTAG}-linux-static-x86_64.tar.gz"
    if curl -fL --progress-bar -o verible.tgz "$VURL"; then
      rm -rf verible && mkdir verible && tar xzf verible.tgz -C verible --strip-components=1 && rm -f verible.tgz
    else
      echo "!! Verible download failed; lint will skip Verible"
    fi
  else
    echo "!! no Verible binary for $PLAT; lint will skip Verible"
  fi
fi

# ---- Python venv with cocotb -------------------------------------------------
cd "$REPO_DIR"
if [ ! -x .venv/bin/python ]; then
  echo ">> creating .venv"
  if command -v uv >/dev/null 2>&1; then
    uv venv -q -p 3.12 .venv || uv venv -q .venv
  else
    PY="$(command -v python3.12 || command -v python3.11 || command -v python3)"
    "$PY" -m venv .venv
  fi
fi
if command -v uv >/dev/null 2>&1; then
  uv pip install -q -p .venv/bin/python -r tools/requirements.txt
else
  .venv/bin/python -m pip install -q -r tools/requirements.txt
fi

echo
echo ">> done. Next:   source tools/env.sh && make doctor"
