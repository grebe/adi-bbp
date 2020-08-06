#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

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

void tx_enable(int fd, uint32_t mask) {
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

void test_bb(int fd) {
  uint32_t i, j;
  for (i = 0; i < 30; i++) {
    if ((j = ioctl(fd, IOCTL_TEST_PLUS_ONE, i)) != i + 1) {
      fprintf(stderr, "TEST IOCTL FAILED: wrote %u, read %u\n", i, j);
    }
  }
}

int main(int argc, const char* argv[])
{
  const char *baseband_file_name = "/dev/baseband";
  uint32_t *s2m, *m2s, i;
  int fd;
  fd = open(baseband_file_name, O_RDWR);
  if (fd == -1) {
    fprintf(stderr, "OPENING FILE ERROR\n");
    return -1;
  }

  // test_bb(fd);

  const uint64_t maxcnt = 4096; //1024;
  set_maxcnt(fd, maxcnt);
  // set_cnt_passthrough(fd, 0);
  set_cnt_passthrough(fd, 1);
  set_align_en(fd, 0);
  set_baseband_enable(fd, 0); // bypass bb, stream goes directly to DMA
  tx_enable(fd, 0x3);
  if (get_skid_overflowed(fd)) {
    fprintf(stderr, "WARNING: skid had overflowed previously\n");
    set_skid_overflowed(fd, 0);
  }
  if (get_skid_overflowed(fd)) {
    fprintf(stderr, "WARNING: skid still overflowing\n");
  }

  const uint64_t num_samples = 12 * 1024 * 1024;
  int read_result;
  s2m = malloc(num_samples * sizeof(uint32_t));
  // write(fd, s2m, 1024 * sizeof(uint32_t));
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
