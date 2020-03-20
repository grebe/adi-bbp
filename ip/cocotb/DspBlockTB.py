#!/usr/bin/env python3

import random
import logging

import cocotb
from cocotb.decorators import coroutine
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.drivers import BitDriver
from cocotb.drivers.amba import AXI4StreamMaster as STDriver
from cocotb.monitors.amba import AXI4StreamMonitor as STMonitor
from cocotb.drivers.amba import AXI4LiteMaster as MemMaster
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure

from cocotb.generators.byte import random_data, get_bytes
from cocotb.generators.bit import (wave, intermittent_single_cycles,
                                   random_50_percent)

def axi4_chisel_name_map(sig):
    if sig == "AWVALID": return "aw_valid"
    if sig == "AWADDR":  return "aw_bits_addr"
    if sig == "AWREADY": return "aw_ready"
    if sig == "WVALID":  return "w_valid"
    if sig == "WREADY":  return "w_ready"
    if sig == "WDATA":   return "w_bits_data"
    if sig == "WSTRB":   return "w_bits_strb"
    if sig == "BVALID":  return "b_valid"
    if sig == "BREADY":  return "b_ready"
    if sig == "BRESP":   return "b_bits_resp"
    if sig == "ARVALID": return "ar_valid"
    if sig == "ARREADY": return "ar_ready"
    if sig == "ARADDR":  return "ar_bits_addr"
    if sig == "RVALID":  return "r_valid"
    if sig == "RREADY":  return "r_ready"
    if sig == "RRESP":   return "r_bits_resp"
    if sig == "RDATA":   return "r_bits_data"

def axi4stream_chisel_name_map(sig):
    if sig == "TVALID": return "valid"
    if sig == "TREADY": return "ready"
    if sig == "TKEEP":  return "bits_keep"
    if sig == "TSTRB":  return "bits_strb"
    if sig == "TLAST":  return "bits_last"
    if sig == "TID":    return "bits_id"
    if sig == "TDEST":  return "bits_dest"
    if sig == "TUSER":  return "bits_user"
    if sig == "TDATA":  return "bits_data"

class DspBlockTB(object):
    def __init__(self, dut, debug=False):
        self.dut = dut
        self.stream_in = STDriver(dut, "ValNamein_0", dut.clock, name_map = axi4stream_chisel_name_map)
        self.backpressure = BitDriver(self.dut.out_0_ready, self.dut.clock)
        self.stream_out = STMonitor(dut, "out_0", dut.clock, name_map = axi4stream_chisel_name_map)

        self.csr = MemMaster(dut, "ValNameioMem_0", dut.clock, name_map = axi4_chisel_name_map)
        self.set_rotation(0)

        # Reconstruct the input transactions from the pins
        # and send them to our 'model'
        self.stream_in_recovered = STMonitor(dut, "ValNamein_0", dut.clock,
                                                   callback=self.model,
                                                   name_map = axi4stream_chisel_name_map)

        # Create a scoreboard on the stream_out bus
        self.pkts_sent = 0
        self.expected_output = []
        self.scoreboard = Scoreboard(dut)
        self.scoreboard.add_interface(self.stream_out, self.expected_output)

        # Set verbosity on our various interfaces
        level = logging.DEBUG if debug else logging.WARNING
        self.stream_in.log.setLevel(level)
        self.stream_in_recovered.log.setLevel(level)

    def set_rotation(self, rotation):
        self.rotation = rotation
        return self.csr.write(0, self.rotation)

    def model(self, transaction):
        """Model the DUT based on the input transaction"""
        ## TODO apply rotation
        self.expected_output.append(transaction)
        self.pkts_sent += 1

    @cocotb.coroutine
    def reset(self, duration=10):
        self.dut._log.debug("Resetting DUT")
        self.dut.reset <= 1
        self.stream_in.bus.TVALID <= 0
        yield Timer(duration, units='ns')
        yield RisingEdge(self.dut.clock)
        self.dut.reset <= 0
        self.dut._log.debug("Out of reset")

@coroutine
def run_test(dut, data_in=None, config_coroutine = None, idle_inserter=None, backpressure_inserter=None):
    cocotb.fork(Clock(dut.clock, 5, units='ns').start())
    tb = DspBlockTB(dut)

    yield tb.reset()
    dut.out_0_ready <= 1

    # Start off any optional coroutines
    if config_coroutine is not None:
        cocotb.fork(config_coroutine(tb))
    if idle_inserter is not None:
        tb.stream_in.set_valid_generator(idle_inserter())
    if backpressure_inserter is not None:
        tb.backpressure.start(backpressure_inserter())

    # Send in the packets
    for transaction in data_in():
        yield tb.stream_in.send(transaction)

    # Wait at least 5 cycles where output ready is low before ending the test
    for i in range(5):
        yield RisingEdge(dut.clock)
        while not dut.out_0_ready.value:
            yield RisingEdge(dut.clock)

    raise tb.scoreboard.result

def random_packet_sizes(min_size=1, max_size=150, npackets=10):
    """random string data of a random length"""
    for i in range(npackets):
        yield get_bytes(random.randint(min_size, max_size), random_data())

def sequence(npackets = 100):
    words = iter(map(chr, range(npackets * 100)))
    for i in range(npackets):
        yield get_bytes(64, words)

@cocotb.coroutine
def randomly_switch_config(tb):
    """Twiddle the byteswapping config register"""
    while True:
        yield tb.set_rotation(random.randint(0, 8))

factory = TestFactory(run_test)
factory.add_option("data_in",
                   [random_packet_sizes, sequence])
factory.add_option("config_coroutine",
                   [None, randomly_switch_config])
factory.add_option("idle_inserter",
                   [None, wave, intermittent_single_cycles, random_50_percent])
factory.add_option("backpressure_inserter",
                   [None, wave, intermittent_single_cycles, random_50_percent])
factory.generate_tests()

import cocotb.wavedrom

@cocotb.test()
def wavedrom_test(dut):
    cocotb.fork(Clock(dut.clock, 5, units='ns').start())
    yield RisingEdge(dut.clock)
    tb = DspBlockTB(dut)
    yield tb.reset()

    with cocotb.wavedrom.trace(dut.reset, tb.stream_out.bus, clk=dut.clock) as waves:
        yield RisingEdge(dut.clock)
        yield RisingEdge(dut.clock)
        for i in range(10):
            yield tb.stream_in.send(i)
        yield tb.csr.read(0)
        for _ in range(20):
            yield RisingEdge(dut.clock)
        dut._log.info(waves.dumpj(header = {'text':'WaveDrom example', 'tick':0}))
        waves.write('wavedrom.json', header = {'tick':0}, config = {'hscale':3})
