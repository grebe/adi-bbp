#!/usr/bin/env python3

from collections import deque
import math
import numpy as np

def unpack(packed: str, width: int=2, bp: int=15) -> complex:
    packed = packed.to_bytes(width * 2, 'little')
    # print(f"packed = {packed}")
    # print(packed[:width])
    # print(packed[width:])
    xr = int.from_bytes(packed[:width], byteorder='little', signed=True) * math.pow(2.0, -bp)
    xi = int.from_bytes(packed[width:], byteorder='little', signed=True) * math.pow(2.0, -bp)
    # print(f"xr = {xr}\t\txi = {xi}")
    return xr + 1j * xi

def pack(sample: complex, width: int=2, bp: int=15) -> bytes:
    # print(f"packing {sample}")
    outr = int(np.round(sample.real * math.pow(2.0, bp))).to_bytes(width, byteorder='little', signed=True)
    outi = int(np.round(sample.imag * math.pow(2.0, bp))).to_bytes(width, byteorder='little', signed=True)
    return int.from_bytes(outr + outi, byteorder='little', signed=False)

if __name__ == "__main__":
    a = int.from_bytes(bytes([0x01, 0x00, 0xFF, 0xFF]), byteorder='little', signed=False)
    print(a)
    print(unpack(a))
    print(pack(unpack(a)))


class SISOChannel(object):
    """A single-tap, single-input single-output channel"""
    def __init__(self, tap=1.0+0.0j, cfo=0.0, fc=2.45e9, fs=20.0e6, delay=20):
        self.tap = tap
        self.cfo = cfo
        self.fc = fc
        self.fs = fs
        self._delay = delay
        self._queue = deque(maxlen=self._delay + 1)
        self._rotation = 1.0 + 0.0j

        # pre-fill the queue with dummy entries to create a delay
        for i in range(self._delay):
            self._queue.append(0.0 + 0.0j) # (i/100.0) + 0.0j)

    def push_packed_sample(self, sample: str, width: int=2, bp: int=15):
        print(f"Pushing {sample}")
        sample = unpack(sample, width=width, bp=bp)
        sample = sample * self.tap * self._rotation
        self._rotation = self._rotation * np.exp(1j * self.cfo * self.fc / self.fs)
        # normalize
        self._rotation = self._rotation / np.abs(self._rotation)
        print(f"Pushing {sample}")
        self._queue.append(sample)

    def pop_packed_sample(self, width:int=2, bp:int=15) -> bytes:
        sample = self._queue.pop()
        print(f"Popping {sample}")
        return pack(sample, width=width, bp=bp)

class ChannelTX(object):
    def __init__(self, taps=[1], cfo=0.0, fc = 2.45e9, fs = 20.0e6, tx_delay=20):
        self.cfo = cfo
        self.fc = fc
        self.rot_per_sample = np.exp(1j * cfo * fc / fs)
        self.rotation = 1.0+0j
        self.taps = np.array(taps)
        self.samples = np.zeros(tx_delay + len(taps), dtype=np.complex128)
    def push_packed_sample(self, sample, width=2, bp=15):
        print(sample)
        sample = bytes(sample, encoding='utf-8')
        print(sample)
        xr = int.from_bytes(sample[:width], byteorder='little') * math.pow(2.0, -bp)
        xi = int.from_bytes(sample[width:], byteorder='little') * math.pow(2.0, -bp)
        self.samples[-1] = xr + 1j * xi
    def pop_sample(self):
        out = np.dot(self.samples[:len(self.taps)], self.taps[::-1])
        out = out * self.rotation
        self.rotation = self.rotation * self.rot_per_sample
        self.samples[:self.samples.size-1] = self.samples[1:]
        return out

class ChannelModel(object):
    def __init__(self, channels = []):
        self.channel_sources = channels
        self.channel_sinks = channels
    def push_packed_sample(self, width=2, bp=15):
        pass

    def pop_packed_sample(self, width=2, bp=15):
        output = sum([c.pop_sample() for c in self.channel_sources])
        outr = int(np.round(output.real * math.pow(2.0, bp))).to_bytes(width, byteorder='little')
        outi = int(np.round(output.imag * math.pow(2.0, bp))).to_bytes(width, byteorder='little')
        return outr + outi

