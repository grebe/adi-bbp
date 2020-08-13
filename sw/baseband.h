#ifndef __BASEBAND_H
#define __BASEBAND_H

#include <stdint.h>

#define IOCTL_STREAM_ALIGNER_MAXCNT         0
#define IOCTL_STREAM_ALIGNER_ALIGNED        1
#define IOCTL_STREAM_ALIGNER_CNT            2
#define IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH 3
#define IOCTL_STREAM_ALIGNER_EN             4
#define IOCTL_SKID_OVERFLOWED               5
#define IOCTL_SKID_SET_OVERFLOW             6
#define IOCTL_DMA_SET_CYCLE                 7
#define IOCTL_SCRATCH_READ                  8
#define IOCTL_SCRATC_WRITE                  9
#define IOCTL_DMA_SCRATCH_TX               10
#define IOCTL_STREAM_OUT_SEL               11
#define IOCTL_TX_ENABLE                    12
#define IOCTL_RX_CONF                      13
#define IOCTL_TEST_PLUS_ONE                14
#define IOCTL_RX_USE_BASEBAND              15

void set_use_rx(int fd, uint8_t en);
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
    uint32_t inputDelay);

void set_maxcnt(int fd, uint64_t cnt);
void set_cnt_passthrough(int fd, uint32_t passthrough);
void set_align_en(int fd, uint8_t en);
int get_skid_overflowed(int fd);
void set_skid_overflowed(int fd, uint8_t o);
void tx_enable(int fd, uint32_t mask);
void set_baseband_enable(int fd, uint8_t en);
void test_bb(int fd);

#endif /* __BASEBAND_H */
