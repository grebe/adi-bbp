#!/usr/bin/env python3

from cocotb.bus import TypedBus
from cocotb.decorators import coroutine
from cocotb.monitors import BusMonitor
from cocotb.triggers import ReadOnly, RisingEdge

class DecoupledBus(TypedBus):
    def __init__(self, entity, name, **kwargs):
        prefix = name + "_bits"
        self._bits = [d[len(name)+1:] for d in dir(entity) if d.startswith(prefix)]

        self._signals = ["ready", "valid"] + self._bits
        TypedBus.__init__(self, entity, name, **kwargs)

class DecoupledMonitor(BusMonitor):
    """Monitor for decoupled interfaces"""
    _bus_type = DecoupledBus

    @coroutine
    def _monitor_recv(self):
        while True:
            yield RisingEdge(self.clock)
            yield ReadOnly()
            if self.bus.valid.value and self.bus.ready.value:
                self._recv({b: getattr(self.bus, b).value.signed_integer for b in self.bus._bits})
