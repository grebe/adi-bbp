#ifndef __RX_CONF_H
#define __RX_CONF_H

#include <stdint.h>

struct rx_conf {
  uint32_t autocorr_ff;
  uint32_t peak_threshold;
  uint32_t peak_offset;
  uint32_t freq_multiplier;
  uint32_t autocorr_depth_apart;
  uint32_t autocorr_depth_overlap;
  uint32_t peak_detect_num_peaks;
  uint32_t peak_detect_peak_distance;
  uint32_t packet_length;
  uint32_t samples_to_drop;
  uint32_t input_delay;
};

// void init_rx_conf(
//     rx_conf *conf,
//     double peakThreshold,
//     double peakOffset,
//     uint32_t size,
//     uint32_t num_peaks,
//     uint32_t packet_length,
//     uint32_t input_delay);

#endif /* __RX_CONF_H */
