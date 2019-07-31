#include <linux/cdev.h>
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

#define BASEBAND_DEBUG 1

#define ADDRESS_SHIFT 3 // 64-bit words

#define STREAM_ALIGNER_BASE           0x100
#define STREAM_ALIGNER_EN             (STREAM_ALIGNER_BASE + (0x0 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_ALIGNED        (STREAM_ALIGNER_BASE + (0x1 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_CNT            (STREAM_ALIGNER_BASE + (0x2 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_MAXCNT         (STREAM_ALIGNER_BASE + (0x3 << ADDRESS_SHIFT))
#define STREAM_ALIGNER_CNTPASSTHROUGH (STREAM_ALIGNER_BASE + (0x4 << ADDRESS_SHIFT))

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

#define IOCTL_STREAM_ALIGNER_MAXCNT         0
#define IOCTL_STREAM_ALIGNER_ALIGNED        1
#define IOCTL_STREAM_ALIGNER_CNT            2
#define IOCTL_STREAM_ALIGNER_CNTPASSTHROUGH 3
#define IOCTL_STREAM_ALIGNER_EN             4
#define IOCTL_PALLOC                        5
#define IOCTL_PFREE                         6

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

static struct device baseband_dev = {
};

static int baseband_open(struct inode *inode, struct file *file)
{
  return 0;
}

static int baseband_read(struct file *file, char __user *user_buffer, size_t size, loff_t *offset)
{

  return -EINVAL;
}

static int baseband_write(
    struct file *file,
    const char __user *user_buffer,
    size_t size,
    loff_t * offset)
{
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
  unsigned char *kbuf;
  static dma_addr_t dma_handle;
  unsigned long wait_cnt;


  kbuf = kmalloc(len, GFP_KERNEL);

  if (kbuf == NULL) {
    pr_err("Could not kmalloc");
    return -EINVAL;
  }

  printk(KERN_INFO "kmalloc success\n");

  // prepare memory range for dma
  dma_handle = dma_map_single(&baseband_dev, kbuf, len, DMA_FROM_DEVICE);
  if (dma_mapping_error(&baseband_dev, dma_handle)) {
    pr_err("dma mapping error\n");
    kfree(kbuf);
    kbuf = NULL;
    return -EIO;
  }

  // do the dma
  iowrite32(1, baseband_registers + DMA_EN);
  iowrite32(dma_handle, baseband_registers + DMA_S2M_BASE);
  // iowrite32((u32)kbuf, baseband_registers + DMA_S2M_BASE);
  // iowrite64(kbuf, baseband_registers + DMA_S2M_BASE);
  iowrite32((len >> 2) - 1, baseband_registers + DMA_S2M_LENGTH);
  iowrite32(0, baseband_registers + DMA_S2M_CYCLES);
  iowrite32(0, baseband_registers + DMA_S2M_FIXED);
  iowrite32(0, baseband_registers + DMA_S2M_WGO_RREMAINING);

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "initiated dma, now waiting\n");
#endif /* BASEBAND_DEBUG */

  wait_cnt = 0;
  while (ioread32(baseband_registers + DMA_S2M_WGO_RREMAINING) != 0 && wait_cnt < 1000) {
    wait_cnt++;
  }

  if (wait_cnt == 1000) {
    pr_err("timeout on dma");
  }

#ifdef BASEBAND_DEBUG
  printk(KERN_INFO "done polling, now mapping\n");
#endif /* BASEBAND_DEBUG */

  // dma is over
  dma_unmap_single(&baseband_dev, dma_handle, len, DMA_FROM_DEVICE);
  vma->vm_private_data = kbuf; // save for freeing later

  // map to users
  if (remap_pfn_range(vma, vma->vm_start, (uint32_t)kbuf, len, vma->vm_page_prot) < 0) {
    pr_err("Could not map addresses");
    return -EIO;
  }

  return 0;
}

static long baseband_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
  static char *kbuf = NULL;
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

    case IOCTL_PALLOC:
      kbuf = kmalloc(arg, GFP_KERNEL);

      if (kbuf == NULL) {
        pr_err("Could not kmalloc");
        return -EINVAL;
      }
      return (long)kbuf;

    case IOCTL_PFREE:
      kfree((void *)arg);
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
    return -EINVAL;
  }

  rc = of_address_to_resource(op->dev.of_node, 0, &baseband_res);
  if (rc) {
    /* Fail */
    return -ENODEV;
  }

  if (!request_mem_region(baseband_res.start, resource_size(&baseband_res), "baseband")) {
    /* Fail */
    return -ENODEV;
  }

  baseband_registers = of_iomap(op->dev.of_node, 0);
  if (!baseband_registers) {
    /* Fail */
    return -ENODEV;
  }
  printk(KERN_INFO "Mapped baseband registers\n");

  if (alloc_chrdev_region(&dev, 0, 1, "baseband") < 0) {
    return -EINVAL;
  }

  if ( (cl = class_create(THIS_MODULE, "baseband")) == NULL) {
    unregister_chrdev_region(dev, 1);
    return -EINVAL;
  }

  if (device_create(cl, NULL, dev, NULL, "baseband") == NULL) {
    class_destroy(cl);
    unregister_chrdev_region(dev, 1);
    return -EINVAL;
  }

  cdev_init(&c_dev, &baseband_fops);
  if (cdev_add(&c_dev, dev, 1) == -1) {
    device_destroy(cl, dev);
    class_destroy(cl);
    unregister_chrdev_region(dev, 1);
    return -EINVAL;
  }

  return 0;
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