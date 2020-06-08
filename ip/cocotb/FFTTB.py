#!/usr/bin/env python3

import logging

import cocotb
from cocotb.decorators import coroutine
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, First, ReadOnly, RisingEdge, Timer
from cocotb.drivers.amba import AXI4StreamMaster as STDriver
from cocotb.monitors.amba import AXI4StreamMonitor as STMonitor
from cocotb.drivers import BitDriver
from cocotb.regression import TestFactory
from cocotb.scoreboard import Scoreboard
from cocotb.result import TestFailure
from cocotb.generators.byte import random_data, get_bytes
from cocotb.generators.bit import (wave, intermittent_single_cycles,
                                   random_50_percent)

import numpy as np
from FFTMonitor import *
from DecoupledDriver import *

class FFTTB:
    def __init__(self, dut, debug:bool=False):
        self._dut = dut
        self._fft_in = DecoupledDriver(self._dut, "in", self._dut.clock)
        self._fft_mon = FFTMonitor(self._dut, self._dut.clock)
        self._backpressure = BitDriver(self._dut.out_ready, self._dut.clock)

        self._scoreboard = Scoreboard(self._dut)
        self._scoreboard.add_interface(self._fft_mon._mon_out, self._fft_mon._expected_output)

        # level = logging.DEBUG if debug else logging.WARNING
        # self._fft_in.setLevel(level)
        # self._fft_mon.setLevel(level)


@coroutine
def run_test(dut, data_in=None, idle_inserter=None, backpressure_inserter=None):
    cocotb.fork(Clock(dut.clock, 1, units='ns').start())
    tb = FFTTB(dut)

    if idle_inserter is not None:
        tb._fft_in.set_valid_generator(idle_inserter())
    if backpressure_inserter is not None:
        tb._backpressure.start(backpressure_inserter())

    for transaction in data_in():
        yield tb._fft_in.send(transaction)

    yield ClockCycles(tb._dut.clock, 50)

    raise tb._scoreboard.result


def tone_input(freq=0.0, bp:int=17):
    import math
    import numpy as np
    i = 0
    x_i = np.exp(2*math.pi*i*1j*freq) * (2.0 ** bp)
    yield {
        'bits_real': int(round(x_i.real)),
        'bits_imag': int(round(x_i.imag))
    }

factory = TestFactory(run_test)
factory.add_option("data_in", [lambda: tone_input(freq=0), lambda: tone_input(freq=1.0/64)])
factory.add_option("idle_inserter",
                   [None, wave, intermittent_single_cycles, random_50_percent])
factory.add_option("backpressure_inserter",
                   [None, wave, intermittent_single_cycles, random_50_percent])
factory.generate_tests()
