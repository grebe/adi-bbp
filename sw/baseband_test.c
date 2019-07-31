#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

#define IOCTL_STREAM_ALIGNER_MAXCNT         0
#define IOCTL_STREAM_ALIGNER_ALIGNED        1
#define IOCTL_STREAM_ALIGNER_CNT            2
#define IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH 3
#define IOCTL_STREAM_ALIGNER_EN             4
#define IOCTL_PALLOC                        5
#define IOCTL_PFREE                         6

const char mem_name[] = "/dev/mem";
static int mem_fd = 0;
static volatile uint32_t *volatile baseband_regs = NULL;
static uint64_t paddr;

void init_mem(void)
{
  mem_fd = open(mem_name, O_RDWR | O_SYNC);
  if (mem_fd < 0) {
    fprintf(stderr, "Error opening mem");
  }
}

void init_baseband(void)
{
  if (mem_fd == 0) {
    init_mem();
  }
  baseband_regs = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, 0x79040000);
  if (baseband_regs == MAP_FAILED) {
    fprintf(stderr, "Error mmapping baseband_regs");
  }
}

void *palloc(int fd, size_t size)
{
  void *ptr;
  paddr = ioctl(fd, IOCTL_PALLOC, size);
  printf("Addr = %lld\n", paddr);
  ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, mem_fd, paddr);
  if (ptr == MAP_FAILED) {
    fprintf(stderr, "Error mmapping /dev/mem\n");
  }
  return ptr;
}

void pfree(int fd)
{
  ioctl(fd, IOCTL_PFREE, paddr);
  paddr = 0;
}

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

void set_align_en(int fd, bool en)
{
  if (ioctl(fd, IOCTL_STREAM_ALIGNER_EN, en != 0) < 0) {
    fprintf(stderr, "ALIGNER EN IOCTL ERROR\n");
  }
}

int main(int argc, const char* argv[])
{
  const char *baseband_file_name = "/dev/baseband";
  uint32_t *s2m, i;
  int fd;
  fd = open(baseband_file_name, O_RDWR);
  if (fd == -1) {
    fprintf(stderr, "OPENING FILE ERROR\n");
    return -1;
  }
  // init_mem();
  // init_baseband();

  // uint32_t *buf = NULL; // palloc(fd, 64);

  // buf[0] = 10;
  // buf[1] = 20;

  // set_maxcnt(fd, 53);
  // set_maxcnt(fd, 55);
  set_maxcnt(fd, 57);
  set_cnt_passthrough(fd, 1);
  // set_cnt_passthrough(fd, 0);
  // set_cnt_passthrough(fd, 1);

  // baseband_regs[0x40 + 0x3] = 52;
  // __sync_synchronize();
  // baseband_regs[0x40 + 0x4] = 1;
  // baseband_regs[0x40 + 0x0] = 1;
  // __sync_synchronize();

  // baseband_regs[0x0 + 0x10] = paddr;
  // baseband_regs[0x0 + 0x5] = 100 * 4;
  // printf("%lu\n", baseband_regs[0x0 + 0x5]);
  // baseband_regs[0x0 + 0x18] = 0;
  // baseband_regs[0x0 + 0x1C] = 0;
  // baseband_regs[0x0 + 0x0] = 1;
  // baseband_regs[0x0 + 0x20] = 0;

  // __sync_synchronize();

  // while(!baseband_regs[0x0 + 0x4]) {
  // }

  // for (i = 0; i < 100; i++) {
  //   printf("%d: %d\n", i, buf[i]);
  // }
  // set_maxcnt(fd, 53);
  // set_cnt_passthrough(fd, 1);

  s2m = mmap(NULL, 100 * sizeof(uint32_t), PROT_READ, MAP_SHARED, fd, 0);

  for (i = 0; i < 100; i++) {
    printf("%d: %d\n", i, s2m[i]);
  }

  // munmap(s2m, 100 * sizeof(uint32_t));

  // pfree(fd);
  close(fd);
  puts("That's all, folks!\n");
  return 0;
}
