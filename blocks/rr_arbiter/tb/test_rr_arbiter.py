"""cocotb regression for rr_arbiter. Runs unchanged on Icarus, Verilator, Questa (SIM=...)."""
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer


class RRArbModel:
    """Reference model: lowest requester at/after ptr, pointer rotates past the grantee."""

    def __init__(self, n):
        self.n, self.ptr = n, 0

    def grant(self, req):
        for k in range(self.n):
            i = (self.ptr + k) % self.n
            if (req >> i) & 1:
                return i
        return None

    def clock(self, req):
        g = self.grant(req)
        if g is not None:
            self.ptr = (g + 1) % self.n
        return g


def n_of(dut):
    return len(dut.req)


async def reset(dut):
    dut.req.value = 0
    dut.rst_n.value = 0
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await Timer(25, unit="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


def check_shape(dut, req):
    """FUNC-01/02, INT-02: one-hot-or-zero, subset of req, valid/idx consistent."""
    g = int(dut.grant.value)
    assert g & ~req == 0, f"grant {g:#x} not subset of req {req:#x}"
    if req == 0:
        assert g == 0 and int(dut.grant_valid.value) == 0
    else:
        assert g != 0 and (g & (g - 1)) == 0, f"grant {g:#x} not one-hot for req {req:#x}"
        assert int(dut.grant_valid.value) == 1
        assert int(dut.grant_idx.value) == g.bit_length() - 1
    return g


@cocotb.test()
async def reset_state(dut):
    """RST-01: after reset, requester 0 has priority."""
    await reset(dut)
    dut.req.value = 0b1111_1111
    await FallingEdge(dut.clk)
    assert check_shape(dut, 0xFF) == 1


@cocotb.test()
async def zero_latency(dut):
    """FUNC-03: grant follows req within the same cycle (no clock edge in between)."""
    await reset(dut)
    await FallingEdge(dut.clk)
    for req in (0b0000_0100, 0b0100_0100, 0b0000_0000, 0b1000_0000):
        dut.req.value = req
        await Timer(1, unit="ns")  # settle combinational logic, still before the next edge
        check_shape(dut, req)
    dut.req.value = 0


@cocotb.test()
async def round_robin_order(dut):
    """FUNC-04: with all requesting, grants rotate 0,1,...,N-1,0,..."""
    await reset(dut)
    n = n_of(dut)
    dut.req.value = (1 << n) - 1
    await FallingEdge(dut.clk)
    for expect in [i % n for i in range(3 * n)]:
        assert int(dut.grant_idx.value) == expect, f"expected {expect}, got {int(dut.grant_idx.value)}"
        await FallingEdge(dut.clk)


@cocotb.test()
async def fairness_bound(dut):
    """FUNC-05: a held request is granted within N cycles under random competing traffic."""
    await reset(dut)
    n = n_of(dut)
    rng = random.Random(1)
    waits = {i: 0 for i in range(n)}
    worst = 0
    await FallingEdge(dut.clk)
    for _ in range(2000):
        req = rng.getrandbits(n)
        dut.req.value = req
        await Timer(1, unit="ns")
        g = check_shape(dut, req)
        for i in range(n):
            if (req >> i) & 1 and not (g >> i) & 1:
                waits[i] += 1
                worst = max(worst, waits[i])
                assert waits[i] < n, f"requester {i} starved for {waits[i]} cycles"
            else:
                waits[i] = 0
        await FallingEdge(dut.clk)
    dut._log.info(f"worst observed wait: {worst} cycles (bound {n-1})")


@cocotb.test()
async def random_vs_model(dut):
    """FUNC-01..05 against the Python reference model, 5000 random cycles incl. idle gaps."""
    await reset(dut)
    n = n_of(dut)
    model = RRArbModel(n)
    rng = random.Random(42)
    await FallingEdge(dut.clk)
    for cyc in range(5000):
        req = 0 if rng.random() < 0.15 else rng.getrandbits(n)
        dut.req.value = req
        await Timer(1, unit="ns")
        g = check_shape(dut, req)
        exp = model.clock(req)
        got = None if g == 0 else g.bit_length() - 1
        assert got == exp, f"cycle {cyc}: req={req:#04x} expected grant {exp}, got {got}"
        await FallingEdge(dut.clk)
