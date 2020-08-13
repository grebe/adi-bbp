#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include "baseband.h"
#include "tx.h"

int main(int argc, const char* argv[])
{
  uint8_t data[20] = { 0x66 };
  const char *baseband_file_name = "/dev/baseband";
  uint32_t *s2m, *m2s, i;
  int fd;
  fd = open(baseband_file_name, O_RDWR);
  if (fd == -1) {
    fprintf(stderr, "OPENING FILE ERROR\n");
    return -1;
  }

  uint16_t cc_constr[] = { 0x1, 0x3 }; 
  pilot_tone pilots[] = {
    [0 ... 7].real = 1.0,
    [0 ... 7].imag = 1.0,
    [0].pos = 4,
    [1].pos = 12,
    [2].pos = 20,
    [3].pos = 28,
    [4].pos = 36,
    [5].pos = 44,
    [6].pos = 52,
    [7].pos = 60,
  };
  tx_info_t tx_conf = {
    .src = 0,
    .dst = 1,
    .time = 0,
    .r0 = 2,
    .r1 = 3,
    .r2 = 4,
    .cc_length = 2,
    .cc_constr = cc_constr,
    .num_pilots = 8,
    .pilots = pilots,
  };

  // test_bb(fd);


  const uint64_t maxcnt = 4096; //1024;
  set_maxcnt(fd, maxcnt);
  set_cnt_passthrough(fd, 0);
  // set_cnt_passthrough(fd, 1);
  set_align_en(fd, 0);
  // set_baseband_enable(fd, 0); // bypass bb, stream goes directly to DMA
  set_baseband_enable(fd, 1);
  tx_enable(fd, 0x3);
  if (get_skid_overflowed(fd)) {
    fprintf(stderr, "WARNING: skid had overflowed previously\n");
    set_skid_overflowed(fd, 0);
  }
  if (get_skid_overflowed(fd)) {
    fprintf(stderr, "WARNING: skid still overflowing\n");
  }

  set_rx_config(fd, 0.9, 0 * 0.05, 0.0, 0.0, 65, 63, 16, 32, 222 + 7, 128 + 16 + 0, 74-8);
  set_use_rx(fd, 1);
  // return 0; // just configure bb

  const uint64_t num_samples = 20; //12 * 1024 * 1024;
  int read_result;
  s2m = malloc(num_samples * sizeof(uint32_t));
  m2s = (uint32_t*)malloc(222 * sizeof(uint32_t));
  encode(data, m2s, &tx_conf);
  // write(fd, m2s, 222 * sizeof(uint32_t));
  read_result = read(fd, s2m, num_samples * sizeof(uint32_t));
  if (read_result != num_samples * sizeof(uint32_t)) {
    fprintf(stderr, "bad read: %d\n", read_result);
  }

  if (get_skid_overflowed(fd)) {
    fprintf(stderr, "WARNING: Got skid overflow during read\n");
  }

  const int verbose = 1;
  int16_t real, imag;
  int numwarn = 0;
  for (i = 0; i < num_samples - 1; i++) {
    fprintf(stdout, "0x%x\n", s2m[i]);
    continue;

    if (s2m[i] != i % maxcnt && !verbose) {
      fprintf(stderr, "WARNING: index %d was %d\n", i, s2m[i]);
      numwarn++;
    } else if (verbose) {
      real = s2m[i] & 0xFFFF;
      imag = (s2m[i] >> 16) & 0xFFFF;
      fprintf(stderr, "%d: %d + i %d\n", i, real, imag);
      numwarn++;
    }
    if (numwarn > 15) {
      if (!verbose) { fprintf(stderr, "TOO MANY WARNINGS\n"); }
      break;
    }
  }


  close(fd);
  puts("That's all, folks!\n");
  return 0;
}
