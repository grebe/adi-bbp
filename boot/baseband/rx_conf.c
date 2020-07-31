#include "rx_conf.h"

static uint32_t fixed_point_repr(double in, uint32_t bp)
{
  double result = 1.0;
  double scale = 2.0;
  while (bp) {
    if (bp & 0x1) {
      result = result * 2.0;
    }
    scale = scale * scale;
    bp = bp >> 1;
  }

  result = in * result;

  return (uit32_t)result;
}

void init_rx_conf(
    rx_conf *conf,
    double peak_threshold,
    double peak_offset,
    uint32_t size,
    uint32_t num_peaks,
    uint32_t packet_length,
    uint32_t input_delay)
{
  conf->autocorr_ff = 
  conf->peak_threshold
}
