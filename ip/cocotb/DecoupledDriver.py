#!/usr/bin/env python3

from cocotb.bus import TypedBus
from cocotb.decorators import coroutine
from cocotb.drivers import ValidatedBusDriver
from cocotb.triggers import ReadOnly, RisingEdge

from DecoupledMonitor import DecoupledBus

class DecoupledDriver(ValidatedBusDriver):
    """Driver for decoupled interfaces"""
    _bus_type = DecoupledBus

    @coroutine
    def _wait_ready(self):
        yield ReadOnly()
        while not self.bus.ready.value:
            yield RisingEdge(self.clock)
            yield ReadOnly()

    @coroutine
    def _driver_send(self, value, sync=True):
        if sync:
            yield RisingEdge(self.clock)

        if not self.on:
            self.bus.valid <= 0
            for _ in range(self.off):
                yield RisingEdge(self.clock)
            self._next_valids()

        if self.on is not True and self.on:
            self.on -= 1

        self.bus.valid <= 1

        for b in self.bus._bits:
            getattr(self.bus, b) <= value[b]

        self._wait_ready()
        yield RisingEdge(self.clock)
        self.bus.valid <= 0


