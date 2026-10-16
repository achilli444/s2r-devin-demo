"""cocotb regression for axis_skid using cocotbext-axi with randomized valid/ready backpressure."""
import itertools
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSink, AxiStreamSource


class TB:
    def __init__(self, dut):
        self.dut = dut
        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
        self.source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.rst_n, reset_active_level=False)
        self.sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.rst_n, reset_active_level=False)

    async def reset(self):
        self.dut.rst_n.value = 0
        await Timer(25, unit="ns")
        self.dut.rst_n.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

    def set_pause(self, src_gen=None, sink_gen=None):
        self.source.set_pause_generator(src_gen or itertools.repeat(False))
        self.sink.set_pause_generator(sink_gen or itertools.repeat(False))


def frames(n, rng, width_bytes):
    out = []
    for i in range(n):
        length = rng.randint(1, 8) * width_bytes
        out.append(AxiStreamFrame(bytes(rng.getrandbits(8) for _ in range(length)), tuser=i & 1))
    return out


async def send_and_check(tb, fr, name):
    for f in fr:
        await tb.source.send(f)
    for i, f in enumerate(fr):
        rx = await tb.sink.recv()
        assert rx.tdata == f.tdata, f"{name}: frame {i} data mismatch"
        assert rx.tuser[-1] if isinstance(rx.tuser, list) else rx.tuser == f.tuser, f"{name}: frame {i} tuser mismatch"
    assert tb.sink.empty(), f"{name}: extra frames at sink"
    tb.dut._log.info(f"{name}: {len(fr)} frames in order, no drop/dup")


@cocotb.test()
async def passthrough_full_rate(dut):
    """No backpressure: every word must move in one clock (throughput 1.0)."""
    tb = TB(dut)
    await tb.reset()
    tb.set_pause()
    width = len(dut.s_axis_tdata) // 8
    n_words = 200
    frame = AxiStreamFrame(bytes(range(256))[: n_words * width] * 1)
    frame = AxiStreamFrame(bytes((i & 0xFF) for i in range(n_words * width)))
    start = cocotb.utils.get_sim_time("ns")
    await tb.source.send(frame)
    rx = await tb.sink.recv()
    elapsed = cocotb.utils.get_sim_time("ns") - start
    assert rx.tdata == frame.tdata
    cycles = elapsed / 10
    assert cycles <= n_words + 4, f"throughput loss: {n_words} words took {cycles} cycles"
    dut._log.info(f"{n_words} words in {cycles:.0f} cycles")


@cocotb.test()
async def random_backpressure(dut):
    """Random sink stalls + random source gaps; data order and integrity preserved."""
    tb = TB(dut)
    await tb.reset()
    rng = random.Random(1)
    tb.set_pause(src_gen=(rng.random() < 0.3 for _ in itertools.count()),
                 sink_gen=(rng.random() < 0.5 for _ in itertools.count()))
    await send_and_check(tb, frames(60, rng, len(dut.s_axis_tdata) // 8), "random backpressure")


@cocotb.test()
async def sink_stall_bursts(dut):
    """Long sink stalls (fills the 2-deep buffer every time) with a source that never pauses."""
    tb = TB(dut)
    await tb.reset()
    rng = random.Random(2)

    def bursts():
        while True:
            for _ in range(rng.randint(1, 6)):
                yield True
            for _ in range(rng.randint(1, 3)):
                yield False

    tb.set_pause(sink_gen=bursts())
    await send_and_check(tb, frames(40, rng, len(dut.s_axis_tdata) // 8), "sink stall bursts")


@cocotb.test()
async def tready_is_registered(dut):
    """s_axis_tready must not change when m_axis_tready toggles within the same cycle (no combinational path).
    The buffer must be holding a word for this to be a real test: an empty buffer is ready regardless."""
    tb = TB(dut)
    await tb.reset()
    tb.set_pause(sink_gen=itertools.repeat(True))          # sink stalled
    await tb.source.send(AxiStreamFrame(bytes(len(dut.s_axis_tdata) // 8)))
    for _ in range(20):
        await RisingEdge(dut.clk)
        if int(dut.m_axis_tvalid.value):
            break
    assert int(dut.m_axis_tvalid.value), "buffer never filled"
    await Timer(1, unit="ns")
    for v in (1, 0, 1, 0):
        before = int(dut.s_axis_tready.value)
        dut.m_axis_tready.value = v                        # poke the sink handshake mid-cycle
        await Timer(1, unit="ns")
        assert int(dut.s_axis_tready.value) == before, "s_axis_tready changed combinationally with m_axis_tready"
    dut._log.info("s_axis_tready stable against same-cycle m_axis_tready changes while holding data")
