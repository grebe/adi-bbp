#include <stdio.h>
#include <sys/ioctl.h>

#include "baseband.h"

void set_maxcnt(int fd, uint64_t cnt)
{
  if (ioctl(fd, IOCTL_STREAM_ALIGNER_MAXCNT, cnt) < 0) {
    fprintf(stderr, "MAXCNT IOCTL ERROR\n");
  }
}

void set_cnt_passthrough(int fd, uint32_t passthrough)
{
  if (ioctl(fd, IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH, passthrough) < 0) {
    fprintf(stderr, "CNTPASSTHROUGH IOCTL ERROR\n");
  }
}

void set_align_en(int fd, uint8_t en)
{
  if (ioctl(fd, IOCTL_STREAM_ALIGNER_EN, en != 0) < 0) {
    fprintf(stderr, "ALIGNER EN IOCTL ERROR\n");
  }
}

int get_skid_overflowed(int fd)
{
  return ioctl(fd, IOCTL_SKID_OVERFLOWED, 0);
}

void set_skid_overflowed(int fd, uint8_t o)
{
  if (ioctl(fd, IOCTL_SKID_SET_OVERFLOW, o) < 0) {
    fprintf(stderr, "SKID OVERFLOW SET ERROR\n");
  }
}

void tx_enable(int fd, uint32_t mask)
{
  if (ioctl(fd, IOCTL_TX_ENABLE, mask) != mask) {
    fprintf(stderr, "ERROR SETTING TX ENABLE\n");
  }
}

void set_baseband_enable(int fd, uint8_t en)
{
  if (ioctl(fd, IOCTL_RX_USE_BASEBAND, en) < 0) {
    fprintf(stderr, "RX USE BASEBAND IOCTL ERROR\n");
  }
}

void test_bb(int fd)
{
  uint32_t i, j;
  for (i = 0; i < 30; i++) {
    if ((j = ioctl(fd, IOCTL_TEST_PLUS_ONE, i)) != i + 1) {
      fprintf(stderr, "TEST IOCTL FAILED: wrote %u, read %u\n", i, j);
    }
  }
}

struct rx_config
{
  uint32_t autocorrFF;
  uint32_t peakThreshold;
  uint32_t peakOffset;
  uint32_t freqMultiplier;
  uint32_t autocorrDepthApart;
  uint32_t autocorrDepthOverlap;
  uint32_t peakDetectNumPeaks;
  uint32_t peakDetectPeakDistance;
  uint32_t packetLength;
  uint32_t samplesToDrop;
  uint32_t inputDelay;
};

static uint32_t fixed_point_representation(double x, uint32_t bp)
{
  int32_t x_i = (int32_t)(x * (1 << bp));
  return (uint32_t)x_i;
}

void set_rx_config(
    int fd,
    double autocorrFF,
    double peakThreshold,
    double peakOffset,
    double freqMultiplier,
    uint32_t autocorrDepthApart,
    uint32_t autocorrDepthOverlap,
    uint32_t peakDetectNumPeaks,
    uint32_t peakDetectPeakDistance,
    uint32_t packetLength,
    uint32_t samplesToDrop,
    uint32_t inputDelay)
{
  struct rx_config conf;
  conf.autocorrFF = fixed_point_representation(autocorrFF, 17);
  conf.peakThreshold = fixed_point_representation(peakThreshold, 17);
  conf.peakOffset = fixed_point_representation(peakOffset, 17);
  conf.freqMultiplier = fixed_point_representation(freqMultiplier, 17);
  conf.autocorrDepthApart = autocorrDepthApart;
  conf.autocorrDepthOverlap = autocorrDepthOverlap;
  conf.peakDetectNumPeaks = peakDetectNumPeaks;
  conf.peakDetectPeakDistance = peakDetectPeakDistance;
  conf.packetLength = packetLength;
  conf.samplesToDrop = samplesToDrop;
  conf.inputDelay = inputDelay;

  if (ioctl(fd, IOCTL_RX_CONF, &conf) < 0) {
    fprintf(stderr, "Error configuring rx\n");
  }
}

void set_use_rx(int fd, uint8_t en)
{
  if (ioctl(fd, IOCTL_RX_USE_BASEBAND, en) < 0) {
    fprintf(stderr, "Error with ioctl configuring baseband\n");
  }
}
