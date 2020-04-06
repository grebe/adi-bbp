#!/usr/bin/env python3

import random
import logging

import cocotb
from cocotb.decorators import coroutine
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, First, ReadOnly, RisingEdge, Timer
from cocotb.drivers import BitDriver
from cocotb.drivers.amba import AXI4StreamMaster as STDriver
from cocotb.monitors.amba import AXI4StreamMonitor as STMonitor
from cocotb.monitors.amba import AXI4WriteMonitor as WriteMonitor
from cocotb.drivers.amba import AXI4LiteMaster as MemMaster
from cocotb.drivers.amba import AXI4Slave as MemSlave
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure

from cocotb.generators.byte import random_data, get_bytes
from cocotb.generators.bit import (wave, intermittent_single_cycles,
                                   random_50_percent)

import matplotlib.pyplot as plt
import numpy as np

from DecoupledMonitor import DecoupledMonitor
import tx

from ChannelModel import SISOChannel

stream_names = {
    'TVALID': 'valid',
    'TDATA': 'data',
    'TUSER': 'user',
    'TREADY': 'ready',
}

axi_names = [
    "ARREADY", "ARVALID", "ARADDR",             # Read address channel
    "ARLEN",   "ARSIZE",  "ARBURST", "ARPROT",
    "RREADY",  "RVALID",  "RDATA",   "RLAST",   # Read response channel

    "AWREADY", "AWADDR",  "AWVALID",            # Write address channel
    "AWPROT",  "AWSIZE",  "AWBURST", "AWLEN",

    "WREADY",  "WVALID",  "WDATA",
    "WLAST",   "WSTRB",
    "BVALID",  "BREADY",  "BRESP",   "RRESP",
    "RCOUNT",  "WCOUNT",  "RACOUNT", "WACOUNT",
    "ARLOCK",  "AWLOCK",  "ARCACHE", "AWCACHE",
    "ARQOS",   "AWQOS",   "ARID",    "AWID",
    "BID",     "RID",     "WID"
]
lower_axi = { i: i.lower() for i in axi_names }

axil_names = [
    "AWVALID", "AWADDR", "AWREADY",        # Write address channel
    "WVALID", "WREADY", "WDATA", "WSTRB",  # Write data channel
    "BVALID", "BREADY", "BRESP",           # Write response channel
    "ARVALID", "ARADDR", "ARREADY",        # Read address channel
    "RVALID", "RREADY", "RRESP", "RDATA"]  # Read data channel
lower_axil = { i: i.lower() for i in axil_names }


def lower_case_names(bus_type):
    mapping = { i: i.lower() for i in bus_type._signals}
    mapping.update({ i: i.lower() for i in bus_type._optional_signals })
    return mapping

class LowerCaseNames(object):
    def __contains__(self, attr):
        return type(attr) is str
    def __getitem__(self, attr):
        if type(attr) is str:
            return attr.lower()
        else:
            raise ValueError(f"{attr} is not a string")

class IntRepresentation(object):
    def __call__(self, value):
        return int(value)

class FixedPointRepresentation(object):
    def __init__(self, bp=0):
        self._bp = bp
    def __call__(self, value):
        return int(np.round(value * (2 ** self._bp)))

class BasebandTB(object):
    def __init__(self, dut, debug=False):
        self.dut = dut
        self.csrBase = 0x79400000
        self.stream_in = STDriver(dut, "adc_0", dut.clock, big_endian=False, **stream_names)
        self.csr = MemMaster(dut, "s_axi", dut.s_axi_aclk, **lower_axil)
        self.memory = np.arange(1024 * 1024 * 1024, dtype=np.dtype('b'))
        self.mem = MemSlave(dut, "m_axi", dut.s_axi_aclk, memory = self.memory, **lower_axi)

        # self.stream_in_recovered = STMonitor(dut, "adc_0", dut.clock, **stream_names)
        self.stream_out = STMonitor(dut, "dac_0", dut.clock, **stream_names) #, callback = self.append_channel)
        self.expected_output = []
        self.txdata = []
        self.write_monitor = WriteMonitor(dut, "m_axi", dut.s_axi_aclk, **lower_axi)
        eq_block = dut.sAxiIsland.freqRx.freqRx.eq
        self.eq_monitor_in = DecoupledMonitor(eq_block, "in", eq_block.clock, reset=eq_block.reset)

        self.scoreboard = Scoreboard(dut)
        # self.scoreboard.add_interface(self.stream_out, self.expected_output)
        # self.scoreboard.add_interface(self.write_monitor, self.txdata)
        level = logging.DEBUG if debug else logging.WARNING
        self.stream_in.log.setLevel(level)
        self.csr.log.setLevel(level)
        self.mem.log.setLevel(level)
        # self.stream_in_recovered.log.setLevel(level)

        self.channel_model = SISOChannel()

    @cocotb.coroutine
    def append_channel(self):
        yield ReadOnly()
        while True:
            if self.dut.dac_0_valid.value:
                data = self.dut.dac_0_data.value.get_value()
            else:
                data = 0
            # print("append_channel")
            self.channel_model.push_packed_sample(data)
            yield RisingEdge(self.dut.clock)
            yield ReadOnly()

    @cocotb.coroutine
    def get_channel(self):
        dataword = BinaryValue(n_bits=32)
        # self.stream_in.bus.TVALID <= 1
        while True:
            # print("get_channel")
            # dataword.assign(str(self.channel_model.pop_packed_sample()))
            # self.stream_in.bus.TDATA <= dataword
            yield self.stream_in._driver_send(data=self.channel_model.pop_packed_sample(), sync=False)
            # yield RisingEdge(self.dut.clock)

    @cocotb.coroutine
    def dma_to_mm(self, *, base = 0, size = None):
        if size is None:
            size = len(self.memory) // 4
        # base
        yield self.csr.write(self.csrBase + 4 * 4, base)
        # length
        yield self.csr.write(self.csrBase + 5 * 4, size - 1)
        # cycles
        yield self.csr.write(self.csrBase + 6 * 4, 0)
        # fixed
        yield self.csr.write(self.csrBase + 7 * 4, 0)
        # go
        yield self.csr.write(self.csrBase + 8 * 4, 1)

        while True:
            bytesLeft = yield self.csr.read(self.csrBase + 8 * 4)
            if not bytesLeft:
                break

    @cocotb.coroutine
    def dma_mm_to_dac(self, *, base = 0, size = None):
        if size is None:
            size = len(self.memory) // 4
        # base
        yield self.csr.write(self.csrBase + 0x9 * 4, base)
        # length
        yield self.csr.write(self.csrBase + 0xA * 4, size - 1)
        # cycles
        yield self.csr.write(self.csrBase + 0xB * 4, 100)
        # fixed
        yield self.csr.write(self.csrBase + 0xC * 4, 0)

        # skid disable
        yield self.csr.write(self.csrBase + 0x200, 0)
        # skid drain upstream queue
        yield self.csr.write(self.csrBase + 0x200 + 0x5 * 4, 1)
        # skid clear overflow register
        yield self.csr.write(self.csrBase + 0x200 + 0x3 * 4, 0)

        # go
        yield self.csr.write(self.csrBase + 0xD * 4, 0)
        # enable
        yield self.csr.write(self.csrBase + 0x0, 1)

        # skid enable
        yield self.csr.write(self.csrBase + 0x200, 1)

    @cocotb.coroutine
    def set_aligner(self, base = 0x100, *, en = True, cnt = 1, cntPassthrough = False):
        if cntPassthrough:
            cntPassthrough = 1
        else:
            cntPassthrough = 0
        if en:
            en = 1
        else:
            en = 0
        if base < 0x70000000:
            base = base + self.csrBase
        yield self.csr.write(base + 0xC, cnt)
        yield self.csr.write(base + 0x10, cntPassthrough)
        yield self.csr.write(base, 1)

    @cocotb.coroutine
    def set_input_splitter_mux(self, base = 0x900):
        #if base < 0x70000000:
        #    base = base + self.csrBase
        yield self.csr.write(base, 0)

    @cocotb.coroutine
    def set_input_stream_mux(self, base = 0x300):
        yield self.csr.write(base, 0)
        # yield self.csr.write(base + 4, 0)

    @cocotb.coroutine
    def set_schedule(self, base=0x800, *, length, time):
        yield self.csr.write(base, length)
        yield self.csr.write(base + 0x4, time)
        yield self.csr.write(base + 0xC, 1) # go!

    @cocotb.coroutine
    def set_timerx(self, base=0x400, **kwargs):
        settings = {
            'autocorrFF': 0.9,
            'peakThreshold': 0.0,
            'peakOffset': 3.0,
            'freqMultiplier': 0.0,
            'autocorrDepthApart': 64,
            'autocorrDepthOverlap': 64,
            'peakDetectNumPeaks': 3,
            'peakDetectPeakDistance': 64,
            'packetLength': 1024,
        }
        representations = {
            'autocorrFF': FixedPointRepresentation(bp = 17),
            'peakThreshold': FixedPointRepresentation(bp  = 17),
            'peakOffset': FixedPointRepresentation(bp = 17),
            'freqMultiplier': FixedPointRepresentation(bp = 17),
            'autocorrDepthApart': IntRepresentation(),
            'autocorrDepthOverlap': IntRepresentation(),
            'peakDetectNumPeaks': IntRepresentation(),
            'peakDetectPeakDistance': IntRepresentation(),
            'packetLength': IntRepresentation()
        }

        settings = { **settings, **kwargs}
        for key in settings.keys():
            kwargs.pop(key, None)
        if len(kwargs) != 0:
            raise TypeError(f"Unexpected kwargs {kwargs}")

        for idx, (key, val) in enumerate(settings.items()):
            # print(f"Writing {representations[key](val)} ({val}) to {base + idx * 4}")
            yield self.csr.write(base + idx * 4, representations[key](val))
        # write globalCycleEn
        yield self.csr.write(base + len(settings) * 4, 1)

    @cocotb.coroutine
    def transmit(self, data):
        txdata = encode_tx(data, addPreamble = True)
        # txdata = encode_linear_seq(222)
        self.txdata.extend(data)

        for i in range(len(txdata)):
            self.memory[i] = txdata[i]

        yield self.dma_mm_to_dac(base = 0, size = len(txdata) // 4 - 1)
        # self.dma_to_mm(base = 0 * 1024 * 4, size = len(txdata))

    @cocotb.coroutine
    def handle_packet_detect(self, *, base = 0x400):
        while True:
            # check if an interrupt has fired
            if not self.dut.skid_ints_0.value:
                # if not, wait for one
                yield RisingEdge(self.dut.skid_ints_0)
            time = yield self.csr.read(base + 12 * 4)
            print(f"Saw packet at time {time.signed_integer}")

    @cocotb.coroutine
    def reset(self, duration=5):
        self.dut._log.debug("Resetting DUT")
        self.dut.reset <= 1
        self.dut.s_axi_aresetn <= 0
        self.stream_in.bus.TVALID <= 0
        for i in range(duration):
            yield RisingEdge(self.dut.clock)
        self.dut.reset <= 0
        yield RisingEdge(self.dut.s_axi_aclk)
        self.dut.s_axi_aresetn <= 1
        self.dut.dac_0_ready <= 1
        self.dut.dac_1_ready <= 1
        self.dut._log.debug("Setting registers to drain input streams")
        yield self.csr.write(self.csrBase + 0x200 + 0x5 * 4, 1)
        yield self.csr.write(self.csrBase + 0x200, 0)
        yield self.csr.write(self.csrBase + 0x100, 0)
        self.dut._log.debug("Out of reset")

def encode_linear_seq(n):
    out = tx.encode_linear_seq(n)
    print([hex(i) for i in out])
    return b''.join([i.to_bytes(4, 'little') for i in out])

def encode_tx(data, *, addPreamble = True):
    out = []
    if addPreamble:
        out += tx.get_stf()
    out += tx.encode(data, {"src": 2, "dst": 3})
    # convert to byte string
    out = b''.join([i.to_bytes(4, 'little') for i in out])
    return out

@coroutine
def run_test(dut, data_in=None, config_coroutine=None, idle_inserter=None, backpressure_inserter=None):
    cocotb.fork(Clock(dut.clock, 50, units='ns').start())
    cocotb.fork(Clock(dut.s_axi_aclk, 11, units='ns').start())
    tb = BasebandTB(dut) #, debug=True)

    print("RESET STARTING")
    yield tb.reset()
    print("RESET DONE")

    yield tb.stream_in.send(b'0000000000000000')

    # Start off optional coroutines
    if config_coroutine is not None:
        cocotb.fork(config_coroutine(tb))
    if idle_inserter is not None:
        tb.stream_in.set_valid_generator(idle_inserter())
    if backpressure_inserter is not None:
        tb.backpressure.start(backpressure_inserter())
    cocotb.fork(tb.append_channel())
    cocotb.fork(tb.get_channel())

    print("COROUTINES STARTED")

    # Wait 5 cycles before starting test
    for i in range(5):
        yield RisingEdge(dut.s_axi_aclk)

    yield tb.set_timerx()
    # yield tb.set_schedule(length=128, time=128)
    yield tb.set_input_stream_mux()
    yield tb.set_input_splitter_mux()
    yield tb.set_aligner()

    # get tx packet
    print("STARTING MM -> DAC")
    yield tb.transmit([0] * 20)

    cocotb.fork(tb.handle_packet_detect())

    print("STARTING RX -> MM")
    rx = cocotb.fork(tb.dma_to_mm(base = 1024 * 4, size = 128//4 - 1))
    timeout = yield ClockCycles(dut.clock, 2000)

    # wait
    yield First(rx, timeout)


    print(tb.eq_monitor_in[0])
    plt.plot(range(len(tb.eq_monitor_in)), [i["bits_14_real"] for i in tb.eq_monitor_in])
    plt.show()

    # for i in range(len(tb.eq_monitor_in)):
    #     print(tb.eq_monitor_in[i])


    raise tb.scoreboard.result

def simple_input():
    words = iter(map(chr, range(100 * 64)))
    for i in range(100):
        yield get_bytes(2, words)

factory = TestFactory(run_test)
# factory.add_option("data_in",
#         [simple_input])

factory.generate_tests()
