#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include "baseband.h"
#include "tx.h"

int main(int argc, const char* argv[])
{
  uint32_t *m2s;
  int write_result;
  uint32_t num_samples = 160 /* STF */ + 222 /* DATA */;
  uint8_t data[20] = { 0x66 };
  const char *baseband_file_name = "/dev/baseband";
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

  tx_enable(fd, 0x3);
  m2s = (uint32_t*)malloc(num_samples * sizeof(uint32_t));
  get_stf(m2s);
  encode(data, m2s + 160, &tx_conf);
  int i;
  // for (i = 0; i < num_samples; i++) {
  //   fprintf(stdout, "\t%x\n", m2s[i]);
  // }
  if ((write_result = write(fd, m2s, num_samples * sizeof(uint32_t))) != num_samples * sizeof(uint32_t)) {
    fprintf(stderr, "bad write: %d != %d\n", write_result);
  }

  close(fd);
  free(m2s);

  return 0;
}
