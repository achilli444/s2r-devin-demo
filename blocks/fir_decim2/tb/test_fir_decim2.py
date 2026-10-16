"""cocotb regression for fir_decim2 against a scipy/numpy golden model (bit-exact integer)."""
import random

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scipy.signal import lfilter

from fir_coefs import COEF

H = np.array(COEF, dtype=np.int64)
IN_W = 16


def golden(x):
    """y[m] = sum_k h[k] x[2m-k]  (decimate-by-2 of the full-rate FIR), exact integers."""
    y = lfilter(H.astype(float), [1.0], np.asarray(x, dtype=float))
    return np.rint(y[::2]).astype(np.int64)


def to_signed(v, w):
    v = int(v)
    return v - (1 << w) if v >> (w - 1) else v


async def reset(dut):
    dut.in_data.value = 0
    dut.in_valid.value = 0
    dut.rst_n.value = 0
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await Timer(25, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def run(dut, x, gap=0.0, rng=None):
    """Stream x (one sample/clock, optional idle gaps), collect every out_valid sample."""
    out = []

    async def collect():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.out_valid.value):
                out.append(to_signed(dut.out_data.value, len(dut.out_data)))

    mon = cocotb.start_soon(collect())
    for s in x:
        while rng is not None and rng.random() < gap:
            dut.in_valid.value = 0
            await RisingEdge(dut.clk)
        dut.in_data.value = int(s)
        dut.in_valid.value = 1
        await RisingEdge(dut.clk)
    dut.in_valid.value = 0
    for _ in range(12):
        await RisingEdge(dut.clk)
    mon.kill()
    return np.array(out, dtype=np.int64)


def compare(dut, got, exp, name):
    assert len(got) == len(exp), f"{name}: got {len(got)} outputs, expected {len(exp)}"
    bad = np.nonzero(got != exp)[0]
    assert len(bad) == 0, f"{name}: first mismatch at output {bad[0]}: got {got[bad[0]]}, expected {exp[bad[0]]}"
    dut._log.info(f"{name}: {len(got)} outputs bit-exact vs golden model")


@cocotb.test()
async def impulse_response(dut):
    """Decimated impulse response equals the even-indexed coefficients; shifted impulse the odd ones."""
    await reset(dut)
    x = [1] + [0] * 60
    got = await run(dut, x)
    compare(dut, got, golden(x), "impulse")
    assert list(got[:13]) == COEF[0::2], "even-phase coefficients wrong"
    await reset(dut)
    x = [0, 1] + [0] * 60
    got = await run(dut, x)
    compare(dut, got, golden(x), "shifted impulse")
    assert list(got[1:13]) == COEF[1::2], "odd-phase coefficients wrong"


@cocotb.test()
async def random_stream(dut):
    """2000 random full-range samples, continuous streaming."""
    await reset(dut)
    rng = np.random.default_rng(7)
    x = rng.integers(-(1 << (IN_W - 1)), (1 << (IN_W - 1)), size=2000)
    compare(dut, await run(dut, x), golden(x), "random continuous")


@cocotb.test()
async def random_with_gaps(dut):
    """Same filter with random in_valid gaps: output must be identical (sample-driven, not clock-driven)."""
    await reset(dut)
    rng = np.random.default_rng(8)
    x = rng.integers(-(1 << (IN_W - 1)), (1 << (IN_W - 1)), size=600)
    compare(dut, await run(dut, x, gap=0.4, rng=random.Random(3)), golden(x), "random with gaps")


@cocotb.test()
async def full_scale_no_overflow(dut):
    """Alternating +/- full scale and DC full scale: no wrap in pre-adders or accumulator."""
    await reset(dut)
    fs = (1 << (IN_W - 1)) - 1
    x = [fs] * 80 + [-fs - 1] * 80 + [fs if i % 2 else -fs - 1 for i in range(80)]
    compare(dut, await run(dut, x), golden(x), "full scale")
