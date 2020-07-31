#include <linux/cdev.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/kdev_t.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/slab.h>
#include <linux/time.h>
#include <linux/uaccess.h>

#define BASEBAND_DEBUG 1

#define ADDRESS_SHIFT 2 // 32-bit words

#define DMA_BASE               0x0
#define DMA_EN                 (DMA_BASE + (0x0 << ADDRESS_SHIFT))
#define DMA_IDLE               (DMA_BASE + (0x1 << ADDRESS_SHIFT))
#define DMA_WATCHDOG           (DMA_BASE + (0x2 << ADDRESS_SHIFT))
#define DMA_INT                (DMA_BASE + (0x3 << ADDRESS_SHIFT))
#define DMA_S2M_BASE           (DMA_BASE + (0x4 << ADDRESS_SHIFT))
#define DMA_S2M_LENGTH         (DMA_BASE + (0x5 << ADDRESS_SHIFT))
#define DMA_S2M_CYCLES         (DMA_BASE + (0x6 << ADDRESS_SHIFT))
#define DMA_S2M_FIXED          (DMA_BASE + (0x7 << ADDRESS_SHIFT))
#define DMA_S2M_WGO_RREMAINING (DMA_BASE + (0x8 << ADDRESS_SHIFT))
#define DMA_M2S_BASE           (DMA_BASE + (0x9 << ADDRESS_SHIFT))
#define DMA_M2S_LENGTH         (DMA_BASE + (0xA << ADDRESS_SHIFT))
#define DMA_M2S_CYCLES         (DMA_BASE + (0xB << ADDRESS_SHIFT))
#define DMA_M2S_FIXED          (DMA_BASE + (0xC << ADDRESS_SHIFT))
#define DMA_M2S_WGO_RREMAINING (DMA_BASE + (0xD << ADDRESS_SHIFT))
#define DMA_ARPROT             (DMA_BASE + (0xE << ADDRESS_SHIFT))
#define DMA_AWPROT             (DMA_BASE + (0xF << ADDRESS_SHIFT))
#define DMA_ARCACHE            (DMA_BASE + (0x10 << ADDRESS_SHIFT))
#define DMA_AWCACHE            (DMA_BASE + (0x11 << ADDRESS_SHIFT))
#define DMA_BYTES_READ         (DMA_BASE + (0x12 << ADDRESS_SHIFT))
#define DMA_BYTES_WRITTEN      (DMA_BASE + (0x13 << ADDRESS_SHIFT))


#define STREAM_ALIGNER_BASE           0x100
#define STREAM_ALIGNER_EN             (STREAM_ALIGNER_BASE + (0x0 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_ALIGNED        (STREAM_ALIGNER_BASE + (0x1 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_CNT            (STREAM_ALIGNER_BASE + (0x2 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_MAXCNT         (STREAM_ALIGNER_BASE + (0x3 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_CNTPASSTHROUGH (STREAM_ALIGNER_BASE + (0x4 << ADDRESS_SHIFT))

#define SKID_BASE                0x200
#define SKID_EN                  (SKID_BASE + (0x0 << ADDRESS_SHIFT))
#define SKID_WATERSHED           (SKID_BASE + (0x1 << ADDRESS_SHIFT))
#define SKID_COUNT               (SKID_BASE + (0x2 << ADDRESS_SHIFT))
#define SKID_OVERFLOWED          (SKID_BASE + (0x3 << ADDRESS_SHIFT))
#define SKID_WOVERFLOWED         (SKID_BASE + (0x4 << ADDRESS_SHIFT))
#define SKID_DRAIN_WHEN_DISABLED (SKID_BASE + (0x5 << ADDRESS_SHIFT))

#define STREAM_OUT_BASE 0x0300
#define STREAM_OUT_SEL  (STREAM_OUT_BASE + (0x0 << ADDRESS_SHIFT))

#define TIME_RX_BASE 0x0400
#define TIME_RX_AUTOCORR_FF (TIME_RX_BASE + (0x0 << ADDRESS_SHIFT))
#define TIME_RX_PEAK_THRESHOLD (TIME_RX_BASE + (0x1 << ADDRESS_SHIFT))

#define TX_SCHEDULER_BASE 0x0800

#define SPLITTER_BASE 0x0900

#define ENABLE_TX  0x0A00

#define SCRATCHPAD_BASE 0x4000

#define RAM_BASE 0x4000

#define IOCTL_STREAM_ALIGNER_MAXCNT          0
#define IOCTL_STREAM_ALIGNER_ALIGNED         1
#define IOCTL_STREAM_ALIGNER_CNT             2
#define IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH  3
#define IOCTL_STREAM_ALIGNER_EN              4
#define IOCTL_SKID_OVERFLOWED                5
#define IOCTL_SKID_SET_OVERFLOW              6
#define IOCTL_DMA_SET_CYCLE                  7
#define IOCTL_SCRATCH_READ                   8
#define IOCTL_SCRATCH_WRITE                  9
#define IOCTL_DMA_SCRATCH_TX                10
// #define IOCTL_STREAM_OUT_SEL                11
#define IOCTL_TX_ENABLE                     12
#define IOCTL_RX_CONF                       13

MODULE_LICENSE("Dual BSD/GPL");
MODULE_AUTHOR("Paul Rigge");
MODULE_DESCRIPTION("A driver for baseband peripheral");
MODULE_VERSION("0.01");

static struct of_device_id baseband_of_match[] =
{
  { .compatible = "berkeley,baseband", },
  {}
};

MODULE_DEVICE_TABLE(of, baseband_of_match);

/**
 * Variables for mapping CSRs
 */
static void __iomem *baseband_registers = NULL;
static struct resource baseband_res;
static struct cdev c_dev;
static struct class* cl;
static dev_t dev;

static struct device baseband_dev;

static int baseband_open(struct inode *inode, struct file *file)
{
  return 0;
}

static u64 estimate_max_time(size_t size)
{
  u64 words, nseconds;
  // 16-bit real+complex
  words = size >> 2;
  // assume 5msps, which is 5 samples / usecond, which is 0.005 samples / ns
  // dividing by 0.005 is multiplying by 200
  nseconds = words * 200 * 2;
  // add five seconds of buffer, just to be really conservative
  nseconds += 5000000000LL;
  return nseconds;
}

static int baseband_read(struct file *file, char __user *user_buffer, size_t size, loff_t *offset)
{
  void *kbuf;
  dma_addr_t dbuf;
  int err;
  u32 begin_bytes_written, current_bytes_written;
  struct timespec init_time, current_time;
  u64 max_time, sec_diff, nsec_diff;

  kbuf = dma_alloc_coherent(&baseband_dev, size, &dbuf, GFP_KERNEL);
  max_time = estimate_max_time(size);
  pr_err("Max time = %lld\n", max_time);
  begin_bytes_written = ioread32(baseband_registers + DMA_BYTES_WRITTEN);

  if (kbuf == NULL) {
    pr_err("Could not kmalloc");
    err = -EINVAL;
    goto err_alloc;
  }

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "KBUF=%#x\n", (u32)kbuf);
  printk(KERN_INFO "DMAHANDLE=%#x\n", (u32)dbuf);
#endif /* BASEBAND_DEBUG */

  // configure the dma
  iowrite32(0, baseband_registers + DMA_EN);
  iowrite32((u32)dbuf, baseband_registers + DMA_S2M_BASE);
  iowrite32(((size + 3) >> 2) - 1, baseband_registers + DMA_S2M_LENGTH);
  // iowrite32(0, baseband_registers + DMA_S2M_CYCLES);
  // iowrite32(0, baseband_registers + DMA_S2M_FIXED);

  // disable aligner, will turn back on after dma enabled
  iowrite32(0, baseband_registers + STREAM_ALIGNER_EN);
  // flush the queues in front of the dma by disabling the skid
  iowrite32(1, baseband_registers + SKID_DRAIN_WHEN_DISABLED);
  iowrite32(0, baseband_registers + SKID_EN);
  iowrite32(0, baseband_registers + SKID_OVERFLOWED);
  while (ioread32(baseband_registers + SKID_COUNT) > 0) {
    pr_err("Skid draining (%d remaining)\n", ioread32(baseband_registers + SKID_COUNT));
  }
  // wait for things to flush
  udelay(10);
  // start the dma engine
  iowrite32(0, baseband_registers + DMA_S2M_WGO_RREMAINING);
  // enable the dma, skid, and aligner to feed the dma
  iowrite32(1, baseband_registers + DMA_EN);
  iowrite32(1, baseband_registers + SKID_EN);
  iowrite32(1, baseband_registers + STREAM_ALIGNER_EN);

  getnstimeofday(&init_time);

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "remaining = %d\n", ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING));
  printk(KERN_INFO "initiated dma, now waiting\n");
#endif /* BASEBAND_DEBUG */

  while (
      ( (current_bytes_written = ioread32(baseband_registers + DMA_BYTES_WRITTEN)) - begin_bytes_written) < size - 4
      // ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING) != 0 &&
      // ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING) != 0
      ) {
  // while (!ioread32(baseband_registers + DMA_IDLE)) {
    // ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING) != 0) { // && wait_cnt < 1000000) {
    // pr_err("waiting for 0x%x bytes", current_bytes_written - begin_bytes_written);
    // udelay(1);
    getnstimeofday(&current_time);
    sec_diff = current_time.tv_sec - init_time.tv_sec;
    nsec_diff = current_time.tv_nsec - init_time.tv_nsec;
    nsec_diff += sec_diff * 1000000000;
    if (nsec_diff >= max_time) {
      pr_err("TIMEOUT: waited %lld ns\n", nsec_diff);
      goto err_dma_timeout;
    }
    // pr_err("REMAINING = %d\n", ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING));
  }
  // waiting is done, disable skid so it doesn't overflow
  iowrite32(0, baseband_registers + SKID_EN);
  // also disable aligner
  iowrite32(0, baseband_registers + STREAM_ALIGNER_EN);

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "remaining = %d\n", ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING));
  printk(KERN_INFO "done polling, now mapping\n");
  if (ioread32(baseband_registers + SKID_OVERFLOWED)) {
    pr_err("skid buffer overflowed");
  }
  // printk(KERN_INFO "IDLE = %d\n", ioread32(baseband_registers + DMA_IDLE));
#endif /* BASEBAND_DEBUG */

  rmb();
  if (copy_to_user(user_buffer, kbuf, size)) {
    err = -EFAULT;
    goto err_copy;
  }

  dma_free_coherent(&baseband_dev, size, kbuf, dbuf);

  return size;

err_dma_timeout:
  pr_err("DMA Timeout");
  err = -EFAULT;
err_copy:
  dma_free_coherent(&baseband_dev, size, kbuf, dbuf);
err_alloc:
  return err;
}

static int baseband_write(
    struct file *file,
    const char __user *user_buffer,
    size_t size,
    loff_t * offset)
{
  void *kbuf;
  static dma_addr_t dbuf;
  unsigned long wait_cnt;
  int i;

  kbuf = dma_alloc_coherent(&baseband_dev, size, &dbuf, GFP_KERNEL);

  if (kbuf == NULL) {
    pr_err("Could not kmalloc");
    goto err_alloc_coherent_fail;
  }

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "KBUF=%#x\n", (u32)kbuf);
  printk(KERN_INFO "DBUF=%#x\n", (u32)dbuf);
#endif /* BASEBAND_DEBUG */

  // copy into buffer
  if (copy_from_user(kbuf, user_buffer, size)) {
    goto err_copy_from_user_fail;
  }
  wmb();

#ifdef BASEBAND_DEBUG
  for (i = 0; i < 4; i++) {
    printk(KERN_INFO "k[%d] = %d\n", i, ((u32*)kbuf)[i]);
  }
#endif

  // do the dma
  iowrite32(1, baseband_registers + DMA_EN);
  iowrite32((u32)dbuf, baseband_registers + DMA_M2S_BASE);
  iowrite32(((size + 3) >> 2) - 1, baseband_registers + DMA_M2S_LENGTH);
  iowrite32(0, baseband_registers + DMA_M2S_WGO_RREMAINING);

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "remaining = %d\n", ioread32(baseband_registers + DMA_M2S_WGO_RREMAINING));
  printk(KERN_INFO "initiated dma, now waiting\n");
#endif /* BASEBAND_DEBUG */

  wait_cnt = 0;
  while (
      ioread32(baseband_registers + DMA_M2S_WGO_RREMAINING) != 0 &&
      ioread32(baseband_registers + DMA_M2S_WGO_RREMAINING) != 0
      ) {
    udelay(1);
    wait_cnt++;
  }
  if (wait_cnt == 1000000) {
    pr_err("timeout on dma (remaining)");
    goto err_timeout;
  }

  dma_free_coherent(&baseband_dev, size, kbuf, dbuf);
  return size;

err_timeout:
err_copy_from_user_fail:
  dma_free_coherent(&baseband_dev, size, kbuf, dbuf);
err_alloc_coherent_fail:
  return -EINVAL;
}

static int baseband_release(struct inode *inode, struct file *file)
{
  return 0;
}

/*
void baseband_mmap_open(struct vm_area_struct *vma)
{
}

void baseband_mmap_close(struct vm_area_struct *vma)
{
}

struct vm_operations_struct baseband_mmap_vm_ops = {
  .open = baseband_mmap_open,
  .close = baseband_mmap_close,
};
*/

static int baseband_mmap(struct file *file, struct vm_area_struct *vma)
{
  unsigned long len = vma->vm_end - vma->vm_start;
  void *kbuf;
  // static dma_addr_t dma_handle;
  unsigned long wait_cnt;
  int i;

  kbuf = kmalloc(len, GFP_KERNEL);

  if (kbuf == NULL) {
    pr_err("Could not kmalloc");
    return -EINVAL;
  }

  printk(KERN_INFO "kmalloc success\n");

  // prepare memory range for dma
  // dma_handle = dma_map_single(&baseband_dev, kbuf, len, DMA_FROM_DEVICE, 0);
  // if (dma_mapping_error(&baseband_dev, dma_handle)) {
  //   pr_err("dma mapping error\n");
  //   kfree(kbuf);
  //   kbuf = NULL;
  //   return -EIO;
  // }

  // do the dma
  iowrite32(1, baseband_registers + DMA_EN);
  iowrite32((u32)kbuf, baseband_registers + DMA_S2M_BASE);
  iowrite32((len >> 2) - 1, baseband_registers + DMA_S2M_LENGTH);
  // iowrite32(0, baseband_registers + DMA_S2M_CYCLES);
  // iowrite32(0, baseband_registers + DMA_S2M_FIXED);
  mb();
  iowrite32(0, baseband_registers + DMA_S2M_WGO_RREMAINING);
  mb();
  pr_err("IDLE=%d\n", ioread32(baseband_registers + DMA_IDLE));

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "initiated dma, now waiting\n");
#endif /* BASEBAND_DEBUG */

  wait_cnt = 0;
  while (ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING) != 0 && wait_cnt < 1000000) {
    udelay(10);
    wait_cnt++;
  }
  if (wait_cnt == 1000000) {
    pr_err("timeout on dma (remaining)");
  }

  // wait_cnt = 0;
  // while (ioread32(baseband_registers + DMA_IDLE) == 0 && wait_cnt < 1000) {
  //   udelay(10);
  //   wait_cnt++;
  // }
  // if (wait_cnt == 1000) {
  //   pr_err("timeout on dma (idle)");
  // }

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "remaining = %d\n", ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING));
  printk(KERN_INFO "done polling, now mapping\n");
#endif /* BASEBAND_DEBUG */

  // dma is over
  // dma_unmap_single(&baseband_dev, dma_handle, len, DMA_FROM_DEVICE);
  // vma->vm_private_data = kbuf; // save for freeing later

  for (i = 0; i < 4; i++) {
    printk(KERN_INFO "kbuf[%d] = %x", i, ((u32*)kbuf)[i]);
  }

  ((u32*)kbuf)[0] = 0xDEADBEEF;

  // map to users
  if (remap_pfn_range(vma, vma->vm_start, (uint32_t)kbuf, len, vma->vm_page_prot) < 0) {
    pr_err("Could not map addresses");
    return -EIO;
  }

  return 0;
}

static long baseband_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
  u32 *kbuf = NULL;
  u32 i;
#ifdef BASEBAND_DEBUG
  unsigned long temp;
#endif /* BASEBAND_DEBUG */

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "Handling ioctl\n");
#endif /* BASEBAND_DEBUG */
  switch (cmd) {
    case IOCTL_STREAM_ALIGNER_MAXCNT:
#ifdef BASEBAND_DEBUG
      printk(KERN_INFO "Set maxcnt\n");
#endif /* BASEBAND_DEBUG */
      iowrite32(arg, baseband_registers + STREAM_ALIGNER_MAXCNT);

#ifdef BASEBAND_DEBUG
      temp = ioread32(baseband_registers + STREAM_ALIGNER_MAXCNT);
      if (temp != arg) {
        printk(KERN_INFO "maxcnt wrong (expected %lu, got %lu)\n", arg, temp);
      }
#endif /* BASEBAND_DEBUG */
      break;
    case IOCTL_STREAM_ALIGNER_ALIGNED:
      return ioread32(baseband_registers + STREAM_ALIGNER_ALIGNED);
    case IOCTL_STREAM_ALIGNER_CNT:
      return ioread32(baseband_registers + STREAM_ALIGNER_CNT);
    case IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH:
      iowrite32(arg, baseband_registers + STREAM_ALIGNER_CNTPASSTHROUGH);
#ifdef BASEBAND_DEBUG
      temp = ioread32(baseband_registers + STREAM_ALIGNER_CNTPASSTHROUGH);
      if (temp != arg) {
        printk(KERN_INFO "cntpassthrough wrong (expected %lu, got %lu)\n", arg, temp);
      }
#endif /* BASEBAND_DEBUG */
      break;
    case IOCTL_STREAM_ALIGNER_EN:
      iowrite32(arg, baseband_registers + STREAM_ALIGNER_EN);
      break;

    case IOCTL_SKID_OVERFLOWED:
      return ioread32(baseband_registers + SKID_OVERFLOWED);

    case IOCTL_SKID_SET_OVERFLOW:
      iowrite32(arg, baseband_registers + SKID_OVERFLOWED);
      break;

    case IOCTL_DMA_SET_CYCLE:
      iowrite32(arg, baseband_registers + DMA_M2S_CYCLES);
      break;

    case IOCTL_SCRATCH_READ:
      kbuf = kmalloc(4096 * sizeof(u32), GFP_KERNEL);
      for (i = 0; i < 4096; i++) {
        kbuf[i] = ioread32(baseband_registers + RAM_BASE + i);
      }
      copy_to_user((void*)arg, kbuf, 4096 * sizeof(u32));
      kfree(kbuf);
      break;

    case IOCTL_SCRATCH_WRITE:
      kbuf = kmalloc(4096 * sizeof(u32), GFP_KERNEL);
      copy_from_user(kbuf, (void*)arg, 4096 * sizeof(u32));
      for (i = 0; i < 4096; i++) {
        iowrite32(kbuf[i], baseband_registers + RAM_BASE + (i << ADDRESS_SHIFT));
      }
      kfree(kbuf);
      break;

    case IOCTL_DMA_SCRATCH_TX:
      iowrite32(1, baseband_registers + DMA_EN);
      iowrite32(0x79044000L, baseband_registers + DMA_M2S_BASE);
      iowrite32((u32)arg, baseband_registers + DMA_M2S_LENGTH);
      iowrite32(0, baseband_registers + DMA_M2S_WGO_RREMAINING);
      break;

    // case IOCTL_STREAM_OUT_SEL:
    //   iowrite32((u32)arg, baseband_registers + STREAM_OUT_SEL);
    //   break;

    case IOCTL_TX_ENABLE:
      // if arg > 1, we don't write, we just return the current value
      // otherwise, we write and then return the current value
      if (arg <= 0x1) {
        iowrite32(arg, baseband_registers + ENABLE_TX);
      }
      return ioread32(baseband_registers + ENABLE_TX);

    case IOCTL_RX_CONF:
      kbuf = kmalloc(4 * 10, GFP_KERNEL);
      copy_from_user(kbuf, (void*)arg, 4 * 10);
      for (i = 0; i < 10; i++) {
        iowrite32(kbuf[i], baseband_registers + TIME_RX_BASE + (i << ADDRESS_SHIFT));
      }
      kfree(kbuf);
      break;

    default:
      return -ENOTTY;
  }
  return 0;
}

const static struct file_operations baseband_fops = {
  .owner = THIS_MODULE,
  .open = baseband_open,
  .read = baseband_read,
  .write = baseband_write,
  .release = baseband_release,
  .unlocked_ioctl = baseband_ioctl,
  .mmap = baseband_mmap,
};

static int baseband_drv_probe(struct platform_device *op)
{
  const struct of_device_id *match;
  int rc;

  match = of_match_device(baseband_of_match, &op->dev);

  if (!match) {
    rc = -EINVAL;
    goto err_pre_alloc;
  }
  baseband_dev = op->dev;

  rc = of_address_to_resource(op->dev.of_node, 0, &baseband_res);
  if (rc) {
    rc = -ENODEV;
    goto err_pre_alloc;
  }

  if (!request_mem_region(baseband_res.start, resource_size(&baseband_res), "baseband")) {
    rc = -ENODEV;
    goto err_pre_alloc;
  }

  baseband_registers = of_iomap(op->dev.of_node, 0);
  if (!baseband_registers) {
    rc = -ENODEV;
    goto err_pre_alloc;
  }
  printk(KERN_INFO "Mapped baseband registers\n");

  if (alloc_chrdev_region(&dev, 0, 1, "baseband") < 0) {
    rc = -EINVAL;
    goto err_pre_alloc;
  }

  if ( (cl = class_create(THIS_MODULE, "baseband")) == NULL) {
    rc = -EINVAL;
    goto err_class_create;
  }

  if (device_create(cl, NULL, dev, NULL, "baseband") == NULL) {
    rc = -EINVAL;
    goto err_device_create;
  }

  cdev_init(&c_dev, &baseband_fops);
  if (cdev_add(&c_dev, dev, 1) == -1) {
    rc = -EINVAL;
    goto err_cdev_add;
  }

  return 0;

err_cdev_add:
  device_destroy(cl, dev);
err_device_create:
  class_destroy(cl);
err_class_create:
  unregister_chrdev_region(dev, 1);
err_pre_alloc:
  return rc;
}

static int baseband_drv_remove(struct platform_device *op)
{
  if (baseband_registers != NULL) {
    iounmap(baseband_registers);
    baseband_registers = NULL;
  }

  release_mem_region(baseband_res.start, resource_size(&baseband_res));

  cdev_del(&c_dev);
  device_destroy(cl, dev);
  class_destroy(cl);
  unregister_chrdev_region(dev, 1);

  printk(KERN_INFO "Baseband: unregistered");

  return 0;
}

static struct platform_driver baseband_platform_driver =
{
  .probe = baseband_drv_probe,
  .remove = baseband_drv_remove,
  .driver = {
    .name = "baseband",
    .owner = THIS_MODULE,
    .of_match_table = baseband_of_match,
  },
};

static int __init baseband_init(void)
{
  printk(KERN_INFO "Baseband: loading\n");
  platform_driver_register(&baseband_platform_driver);
  return 0;
}

static void __exit baseband_exit(void)
{
  printk(KERN_INFO "Baseband: unloading\n");
  platform_driver_unregister(&baseband_platform_driver);
}

module_init(baseband_init);
module_exit(baseband_exit);
