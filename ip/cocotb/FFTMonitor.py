#!/usr/bin/env python3

from DecoupledMonitor import DecoupledMonitor

import numpy as np

class FFTMonitor(object):
    def __init__(self, entity, clock, *, in_bp=17, out_bp=17, reset=None, nfft=64):
        self._in_bp = in_bp
        self._out_bp = out_bp
        self._mon_in = DecoupledMonitor(entity, "in", clock, reset=reset)
        self._mon_out = DecoupledMonitor(entity, "out", clock, reset=reset, callback=self.update_expected_output)
        self._nfft = nfft
        self._expected_output = []

    def actual_output(self):
        outvec = np.array([i['bits_real'] + 1j * i['bits_imag'] for i in self._mon_out])
        outvec = outvec * (2.0 ** (-self._in_bp))
        return outvec

    def update_expected_output(self, transaction):
        if len(self._mon_out) % self._nfft == 0:
            self._expected_output = self.expected_output()

    def expected_output(self):
        invec = np.array([i['bits_real'] + 1j * i['bits_imag'] for i in self._mon_in])
        invec = invec * (2.0 ** (-self._in_bp))
        nsym = len(invec) // self._nfft
        invec = invec[:nsym*self._nfft]

        invec = np.reshape(invec, (self._nfft, nsym))
        outvec = np.fft.fft(invec)
        return np.reshape(outvec, (self._nfft*nsym))

    def setLevel(self, level):
        self._mon_in.setLevel(level)
        self._mon_out.setLevel(level)

