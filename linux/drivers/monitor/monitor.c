/*
 * Monitor kernel module
 *
 * Author   : Juan Encinas Anchústegui <juan.encinas@upm.es>
 * Date     : February 2021
 *
 * Features :
 *     - Platform driver + character device
 *     - mmap()  : provides 1) memory allocation (direct access
 *                 from user-space virtual memory to physical memory) for
 *                 data transfers using a DMA engine, and 2) direct access
 *                 to Monitor configuration registers in the FPGA
 *     - ioctl() : enables command passing between user-space and
 *                 character device (e.g., to start DMA transfers)
 *     - poll()  : enables passive (i.e., sleep-based) waiting capabilities
 *                 for 1) DMA interrupts and 2) Monitor interrupts
 *     - [DMA] Targets memcpy operations (requires src and dst addresses)
 *     - [DMA] Relies on Device Tree (Open Firmware) to get DMA engine info
 *
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/poll.h>
#include <linux/mm.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/spinlock.h>
#include <linux/interrupt.h>
#include <linux/workqueue.h>
#include <linux/of_irq.h>
#include <linux/ioport.h>
#include <linux/completion.h>
#include <linux/version.h>

#include "monitor.h"
#define DRIVER_NAME "monitor"

#define dev_info(...)
#define pr_info(...)

MODULE_DESCRIPTION("Monitor kernel module");
MODULE_AUTHOR("Juan Encinas Anchústegui <juan.encinas@upm.es>");
MODULE_LICENSE("GPL");


// Monitor hardware information
struct monitor_hw {
    void __iomem *regs;        		// Hardware registers in Monitor
    uint32_t done_bit;     			// Current done bit value
    uint32_t dma_irq_flag;
};

// Custom monitor device data structure
struct monitor_device {
    dev_t devt;
    struct cdev cdev;
    struct device *dev;
    struct platform_device *pdev;
    struct dma_chan *chan;
    dma_cookie_t cookie;
    struct mutex mutex;
    struct list_head head;
    spinlock_t lock;
    wait_queue_head_t queue;
    unsigned int irq;
    struct monitor_hw hw;
};

// Custom data structure to store allocated memory regions
struct monitor_vm_list {
    struct monitor_device *monitor_dev;
    void *addr_usr;
    void *addr_ker;
    dma_addr_t addr_phy;
    size_t size;
    pid_t pid;
    struct list_head list;
};

// Char device parameters
static dev_t devt;
static struct class *monitor_class;


/* IRQ MANAGEMENT */

// Monitor ISR
static irqreturn_t monitor_isr(unsigned int irq, void *data) {

    struct monitor_device *monitor_dev = data;
    unsigned long flags;

    //~ dev_info(monitor_dev->dev, "[ ] monitor_isr()");
    spin_lock_irqsave(&monitor_dev->lock, flags);

        // Read current done
        if ( (ioread32(monitor_dev->hw.regs + MONITOR_REG0) & MONITOR_DONE) > 0 ) {
            // Set Done bit
            monitor_dev->hw.done_bit = 1;
            // Inform poll() queue
            wake_up(&monitor_dev->queue);
        }

    spin_unlock_irqrestore(&monitor_dev->lock, flags);
    //~ dev_info(monitor_dev->dev, "[+] monitor_isr()");

    return IRQ_HANDLED;
}


/* DMA MANAGEMENT */

// DMA asynchronous callback function
static void monitor_dma_callback(void *data) {
	struct monitor_device *monitor_dev = data;
	dev_info(monitor_dev->dev,"[ ] monitor_dma_callback()");
	// Inform poll() queue
	monitor_dev->hw.dma_irq_flag = 1;
	wake_up(&monitor_dev->queue);
	dev_info(monitor_dev->dev,"[+] monitor_dma_callback()");
}

// DMA transfer function
static int monitor_dma_transfer(struct monitor_device *monitor_dev, dma_addr_t dst, dma_addr_t src, size_t len) {
    struct dma_device *dma_dev = monitor_dev->chan->device;
    struct dma_async_tx_descriptor *tx = NULL;

    enum dma_ctrl_flags flags = DMA_CTRL_ACK | DMA_PREP_INTERRUPT;
    int res = 0;

    dev_info(dma_dev->dev, "[ ] DMA transfer");
    dev_info(dma_dev->dev, "[i] source address      = %p", (void *)src);
    dev_info(dma_dev->dev, "[i] destination address = %p", (void *)dst);
    dev_info(dma_dev->dev, "[i] transfer length     = %d bytes", len);
    dev_info(dma_dev->dev, "[i] aligned transfer?   = %d", is_dma_copy_aligned(dma_dev, src, dst, len));

    // Initialize asynchronous DMA descriptor
    dev_info(dma_dev->dev, "[ ] device_prep_dma_memcpy()");
    tx = dma_dev->device_prep_dma_memcpy(monitor_dev->chan, dst, src, len, flags);
    if (!tx) {
        dev_err(dma_dev->dev, "[X] device_prep_dma_memcpy()");
        res = -ENOMEM;
        goto err_tx;
    }
    dev_info(dma_dev->dev, "[+] device_prep_dma_memcpy()");

    // Set asynchronous DMA transfer callback
    tx->callback = monitor_dma_callback;
    tx->callback_param = monitor_dev;

    // Submit DMA transfer
    dev_info(dma_dev->dev, "[ ] dmaengine_submit()");
    monitor_dev->cookie = dmaengine_submit(tx);
    res = dma_submit_error(monitor_dev->cookie);
    if (res) {
        dev_err(dma_dev->dev, "[X] dmaengine_submit()");
        goto err_cookie;
    }
    dev_info(dma_dev->dev, "[+] dmaengine_submit()");

    // Start pending transfers
    dma_async_issue_pending(monitor_dev->chan);

err_cookie:
    // Free descriptors
    dmaengine_desc_free(tx);

err_tx:
    dev_info(dma_dev->dev, "[+] DMA transfer");
    return res;
}

// Set up DMA subsystem
static int monitor_dma_init(struct platform_device *pdev) {
    int res;
    struct dma_chan *chan = NULL;
    const char *chan_name = ""; // e.g. "pl-dma"

    // Retrieve custom device info using platform device (private data)
    struct monitor_device *monitor_dev = platform_get_drvdata(pdev);

    // Get device tree node pointer from platform device structure
    struct device_node *node = pdev->dev.of_node;

    dev_info(&pdev->dev, "[ ] monitor_dma_init()");

    // Read DMA channel info from device tree (only the first occurrence is used)
    dev_info(&pdev->dev, "[ ] of_property_read_string()");
    res = of_property_read_string(node, "dma-names", &chan_name);
    if (res) {
        dev_err(&pdev->dev, "[X] of_property_read_string()");
        return res;
    }
    dev_info(&pdev->dev, "[+] of_property_read_string() -> %s", chan_name);

    // Request DMA channel
    dev_info(&pdev->dev, "[ ] dma_request_slave_channel()");
    chan = dma_request_slave_channel(&pdev->dev, chan_name);
    if (IS_ERR(chan) || (!chan)) {
        dev_err(&pdev->dev, "[X] dma_request_slave_channel()");
        return -EBUSY;
    }
    dev_info(&pdev->dev, "[+] dma_request_slave_channel() -> %s", chan_name);
    dev_info(chan->device->dev, "[i] dma_request_slave_channel()");

    monitor_dev->chan = chan;

    dev_info(&pdev->dev, "[+] monitor_dma_init()");
    return 0;
}

// Clean up DMA subsystem
static void monitor_dma_exit(struct platform_device *pdev) {

    // Retrieve custom device info using platform device (private data)
    struct monitor_device *monitor_dev = platform_get_drvdata(pdev);

    dev_info(&pdev->dev, "[ ] monitor_dma_exit()");
    dma_release_channel(monitor_dev->chan);
    dev_info(&pdev->dev, "[+] monitor_dma_exit()");
}

/* CHARACTER DEVICE */

static int monitor_open(struct inode *inodep, struct file *file)
{
    struct monitor_device *monitor_dev;
    // Set device structure as file private data structure
    monitor_dev = container_of(inodep->i_cdev, struct monitor_device, cdev);
    file->private_data = monitor_dev;

    dev_info(monitor_dev->dev, "[ ] monitor_open()");
    dev_info(monitor_dev->dev, "[+] monitor_open()");

    return 0;
}

static int
monitor_release(struct inode *inodep, struct file *file)
{
    struct monitor_device *monitor_dev = container_of(inodep->i_cdev, struct monitor_device, cdev);
    file->private_data = NULL;
    dev_info(monitor_dev->dev, "[ ] monitor_release()");
    dev_info(monitor_dev->dev, "[+] monitor_release()");

    return 0;
}

// File operation on char device: ioctl
static long monitor_ioctl(struct file *fp, unsigned int cmd, unsigned long arg) {
    struct monitor_device *monitor_dev = fp->private_data;
    struct monitor_vm_list *vm_list, *backup;
    struct dmaproxy_token token;
    struct platform_device *pdev = monitor_dev->pdev;
    resource_size_t address, size;
    int res;
    int retval = 0;
    struct resource *rsrc;

    dev_info(monitor_dev->dev, "[ ] ioctl()");
    dev_info(monitor_dev->dev, "[i] ioctl() -> magic   = '%c'", _IOC_TYPE(cmd));
    dev_info(monitor_dev->dev, "[i] ioctl() -> command = %d", _IOC_NR(cmd));

    // Command precheck - step 1
    if (_IOC_TYPE(cmd) != MONITOR_IOC_MAGIC) {
        dev_err(monitor_dev->dev, "[X] ioctl() -> magic does not match");
        return -ENOTTY;
    }

    // Command precheck - step 2
    if (_IOC_NR(cmd) > MONITOR_IOC_MAXNR) {
        dev_err(monitor_dev->dev, "[X] ioctl() -> command number exceeds limit");
        return -ENOTTY;
    }

    // Command decoding
    switch (cmd) {

        case MONITOR_IOC_DMA_HW2MEM_POWER:

            // Lock mutex (released in monitor_poll() after DMA transfer)
            mutex_lock(&monitor_dev->mutex);

            // Copy data from user
            dev_info(monitor_dev->dev, "[ ] copy_from_user()");
            res = copy_from_user(&token, (void *)arg, sizeof token);
            if (res) {
                dev_err(monitor_dev->dev, "[X] copy_from_user()");
                return -ENOMEM;
            }
            dev_info(monitor_dev->dev, "[+] copy_from_user() -> token");

            dev_info(monitor_dev->dev, "[i] DMA from hardware to memory");
            dev_info(monitor_dev->dev, "[i] DMA -> memory address   = %p", token.memaddr);
            dev_info(monitor_dev->dev, "[i] DMA -> memory offset    = %p", (void *)token.memoff);
            dev_info(monitor_dev->dev, "[i] DMA -> hardware address = %p", token.hwaddr);
            dev_info(monitor_dev->dev, "[i] DMA -> hardware offset  = %p", (void *)token.hwoff);
            dev_info(monitor_dev->dev, "[i] DMA -> transfer size    = %d bytes", token.size);

            // Search if the requested memory region is allocated
            list_for_each_entry_safe(vm_list, backup, &monitor_dev->head, list) {
                if ((vm_list->pid == current->pid) && (vm_list->addr_usr == token.memaddr)) {
                    // Memory check
                    if (vm_list->size < (token.memoff + token.size)) {
                        dev_err(monitor_dev->dev, "[X] DMA -> requested transfer out of memory region");
                        retval = -EINVAL;
                        break;
                    }
                    // Get resource info
                    rsrc = platform_get_resource_byname(monitor_dev->pdev, IORESOURCE_MEM, "power");
                    dev_info(&pdev->dev, "[i] resource name  = %s", rsrc->name);
                    dev_info(&pdev->dev, "[i] resource start = %lx", rsrc->start);
                    dev_info(&pdev->dev, "[i] resource end   = %lx", rsrc->end);
                    // Get memory map base address and size
                    address = rsrc->start;
                    size = rsrc->end - rsrc->start + 1;
                    // Hardware check
                    if (size < (token.hwoff + token.size)) {
                        dev_err(monitor_dev->dev, "[X] DMA Slave -> requested transfer out of hardware region");
                        retval = -EINVAL;
                        break;
                    }
                    // Address check
                    dev_info(monitor_dev->dev, "[i] hardware memory map start = %x", address);
                    if ((void *)address != token.hwaddr) {
                        dev_err(monitor_dev->dev, "[X] DMA Slave -> hardware address does not match");
                        retval = -EINVAL;
                        break;
                    }
                    // Perform transfer
                    retval = monitor_dma_transfer(monitor_dev, vm_list->addr_phy + token.memoff, address + token.hwoff, token.size);
                    break;
                }
            }

            break;

        case MONITOR_IOC_DMA_HW2MEM_TRACES:

            // Lock mutex (released in monitor_poll() after DMA transfer)
            mutex_lock(&monitor_dev->mutex);

            // Copy data from user
            dev_info(monitor_dev->dev, "[ ] copy_from_user()");
            res = copy_from_user(&token, (void *)arg, sizeof token);
            if (res) {
                dev_err(monitor_dev->dev, "[X] copy_from_user()");
                return -ENOMEM;
            }
            dev_info(monitor_dev->dev, "[+] copy_from_user() -> token");

            dev_info(monitor_dev->dev, "[i] DMA from hardware to memory");
            dev_info(monitor_dev->dev, "[i] DMA -> memory address   = %p", token.memaddr);
            dev_info(monitor_dev->dev, "[i] DMA -> memory offset    = %p", (void *)token.memoff);
            dev_info(monitor_dev->dev, "[i] DMA -> hardware address = %p", token.hwaddr);
            dev_info(monitor_dev->dev, "[i] DMA -> hardware offset  = %p", (void *)token.hwoff);
            dev_info(monitor_dev->dev, "[i] DMA -> transfer size    = %d bytes", token.size);

            // Search if the requested memory region is allocated
            list_for_each_entry_safe(vm_list, backup, &monitor_dev->head, list) {
                if ((vm_list->pid == current->pid) && (vm_list->addr_usr == token.memaddr)) {
                    // Memory check
                    if (vm_list->size < (token.memoff + token.size)) {
                        dev_err(monitor_dev->dev, "[X] DMA -> requested transfer out of memory region");
                        retval = -EINVAL;
                        break;
                    }
                    // Get resource info
                    rsrc = platform_get_resource_byname(monitor_dev->pdev, IORESOURCE_MEM, "traces");
                    dev_info(&pdev->dev, "[i] resource name  = %s", rsrc->name);
                    dev_info(&pdev->dev, "[i] resource start = %lx", rsrc->start);
                    dev_info(&pdev->dev, "[i] resource end   = %lx", rsrc->end);
                    // Get memory map base address and size
                    address = rsrc->start;
                    size = rsrc->end - rsrc->start + 1;
                    // Hardware check
                    if (size < (token.hwoff + token.size)) {
                        dev_err(monitor_dev->dev, "[X] DMA Slave -> requested transfer out of hardware region");
                        retval = -EINVAL;
                        break;
                    }
                    // Address check
                    dev_info(monitor_dev->dev, "[i] hardware memory map start = %x", address);
                    if ((void *)address != token.hwaddr) {
                        dev_err(monitor_dev->dev, "[X] DMA Slave -> hardware address does not match");
                        retval = -EINVAL;
                        break;
                    }
                    // Perform transfer
                    retval = monitor_dma_transfer(monitor_dev, vm_list->addr_phy + token.memoff, address + token.hwoff, token.size);
                    break;
                }
            }

            break;

        default:
            dev_err(monitor_dev->dev, "[i] ioctl() -> command %x does not exist", cmd);
            retval = -ENOTTY;

    }

    dev_info(monitor_dev->dev, "[+] ioctl()");
    return retval;
}

// mmap close function (required to free allocated memory) - DMA transfers
static void monitor_mmap_dma_close(struct vm_area_struct *vma) {
    struct monitor_vm_list *token = vma->vm_private_data;
    struct monitor_device *monitor_dev = token->monitor_dev;
    struct dma_device *dma_dev = monitor_dev->chan->device;

    dev_info(monitor_dev->dev, "[ ] munmap()");
    dev_info(monitor_dev->dev, "[i] vma->vm_start = %p", (void *)vma->vm_start);
    dev_info(monitor_dev->dev, "[i] vma->vm_end   = %p", (void *)vma->vm_end);
    dev_info(monitor_dev->dev, "[i] vma size      = %ld bytes", vma->vm_end - vma->vm_start);

    dma_free_coherent(dma_dev->dev, token->size, token->addr_ker, token->addr_phy);

    // Critical section: remove region from dynamic list
    mutex_lock(&monitor_dev->mutex);
    list_del(&token->list);
    mutex_unlock(&monitor_dev->mutex);

    kfree(token);
    vma->vm_private_data = NULL;

    dev_info(monitor_dev->dev, "[+] munmap()");
}

// mmap specific operations - DMA transfers
static struct vm_operations_struct monitor_mmap_dma_ops = {
    .close = monitor_mmap_dma_close,
};

// File operation on char device: mmap - DMA transfers
static int monitor_mmap_dma(struct file *fp, struct vm_area_struct *vma) {
    struct monitor_device *monitor_dev = fp->private_data;
    struct dma_device *dma_dev = monitor_dev->chan->device;
    void *addr_vir = NULL;
    dma_addr_t addr_phy;
    struct monitor_vm_list *token = NULL;
    int res;

    dev_info(monitor_dev->dev, "[ ] mmap_dma()");
    dev_info(monitor_dev->dev, "[i] vma->vm_start = %p", (void *)vma->vm_start);
    dev_info(monitor_dev->dev, "[i] vma->vm_end   = %p", (void *)vma->vm_end);
    dev_info(monitor_dev->dev, "[i] vma size      = %ld bytes", vma->vm_end - vma->vm_start);

    // Allocate memory in kernel space  (podría hacerse con zalloc al parecer)
    dev_info(dma_dev->dev, "[ ] dma_alloc_coherent()");
    addr_vir = dma_alloc_coherent(dma_dev->dev, vma->vm_end - vma->vm_start, &addr_phy, GFP_KERNEL);
    if (IS_ERR(addr_vir)) {
        dev_err(dma_dev->dev, "[X] dma_alloc_coherent()");
        return PTR_ERR(addr_vir);
    }
    dev_info(dma_dev->dev, "[+] dma_alloc_coherent()");
    dev_info(dma_dev->dev, "[i] dma_alloc_coherent() -> %p (virtual)", addr_vir);
    dev_info(dma_dev->dev, "[i] dma_alloc_coherent() -> %p (physical)", (void *)addr_phy);
    dev_info(dma_dev->dev, "[i] dma_alloc_coherent() -> %ld bytes", vma->vm_end - vma->vm_start);

    // Set virtual memory structure operations
    vma->vm_ops = &monitor_mmap_dma_ops;
    // Set virtual memory structure page protections (quitra para tenerla cacheada?)
    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);

    // Map kernel-space memory to user-space
    dev_info(monitor_dev->dev, "[ ] remap_pfn_range()");
    res = remap_pfn_range(vma, vma->vm_start, (unsigned long)addr_phy >> PAGE_SHIFT, vma->vm_end - vma->vm_start, vma->vm_page_prot);
    if (res < 0) {
        dev_err(monitor_dev->dev, "[X] remap_pfn_range() %d", res);
        goto err_dma_mmap;
    }
    dev_info(dma_dev->dev, "[+] dma_mmap_coherent()");

    // Create data structure with allocated memory info
    dev_info(monitor_dev->dev, "[ ] kmalloc() -> token");
    token = kmalloc(sizeof *token, GFP_KERNEL);
    if (!token) {
        dev_err(monitor_dev->dev, "[X] kmalloc() -> token");
        res = -ENOMEM;
        goto err_kmalloc_token;
    }
    dev_info(monitor_dev->dev, "[+] kmalloc() -> token");

    // Set values in data structure
    token->monitor_dev = monitor_dev;
    token->addr_usr = (void *)vma->vm_start;
    token->addr_ker = addr_vir;
    token->addr_phy = addr_phy;
    token->size = vma->vm_end - vma->vm_start;
    token->pid = current->pid;
    //INIT_LIST_HEAD(&token->list); No tiene sentido crear esta lista

    // Critical section: add new region to dynamic list
    mutex_lock(&monitor_dev->mutex);
    list_add(&token->list, &monitor_dev->head);
    mutex_unlock(&monitor_dev->mutex);

    // Pass data to virtual memory structure (private data) to enable proper cleanup
    vma->vm_private_data = token;

    dev_info(monitor_dev->dev, "[+] mmap_dma()");
    return 0;

err_kmalloc_token:

err_dma_mmap:
    dma_free_coherent(monitor_dev->dev, vma->vm_end - vma->vm_start, addr_vir, addr_phy);
    return res;
}

// mmap specific operations - HW access
static struct vm_operations_struct monitor_mmap_hw_ops = {
#ifdef CONFIG_HAVE_IOREMAP_PROT
    .access = generic_access_phys,
#endif
};

static int monitor_mmap_hw(struct file *file, struct vm_area_struct *vma) {
    struct monitor_device *monitor_dev = (struct monitor_device * ) file->private_data;
    struct resource *rsrc;

    dev_info(monitor_dev->dev, "[ ] mmap_hw()");
    dev_info(monitor_dev->dev, "[i] vma->vm_start = %p", (void *)vma->vm_start);
    dev_info(monitor_dev->dev, "[i] vma->vm_end   = %p", (void *)vma->vm_end);
    dev_info(monitor_dev->dev, "[i] vma size      = %ld bytes", vma->vm_end - vma->vm_start);

    vma->vm_private_data = monitor_dev;
    vma->vm_ops = &monitor_mmap_hw_ops;
    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);

    rsrc = platform_get_resource_byname(monitor_dev->pdev, IORESOURCE_MEM, "ctrl");
    dev_info(monitor_dev->dev, "[i] resource name  = %s", rsrc->name);
    dev_info(monitor_dev->dev, "[i] resource start = 0x%x", rsrc->start);
    dev_info(monitor_dev->dev, "[i] resource end   = 0x%x", rsrc->end);

    dev_info(monitor_dev->dev, "[+] mmap_hw()");

    // Return a user-space virtual address asociated with the monitor registers physical address
    return remap_pfn_range(vma, vma->vm_start, rsrc->start >> PAGE_SHIFT, vma->vm_end - vma->vm_start, vma->vm_page_prot);
}

static int monitor_mmap(struct file *file, struct vm_area_struct *vma) {
    struct monitor_device *monitor_dev = (struct monitor_device * ) file->private_data;
    int res;
    int mem_idx = (int)vma->vm_pgoff;   // Get which region is going to be mapped

    dev_info(monitor_dev->dev, "[ ] monitor_mmap()");
    dev_info(monitor_dev->dev, "[i] memory index : %d", mem_idx);

    switch(mem_idx) {
        case 0:
            dev_info(monitor_dev->dev, "[i] monitor control map");
            res = monitor_mmap_hw(file, vma);
            break;
        case 1:
            dev_info(monitor_dev->dev, "[i] monitor power map");
            res = monitor_mmap_dma(file, vma);
            break;
        case 2:
            dev_info(monitor_dev->dev, "[i] monitor traces map");
            res = monitor_mmap_dma(file, vma);
            break;
    }
    dev_info(monitor_dev->dev, "[+] monitor_mmap()");

    return res;
}

// File operation on char device: poll
static unsigned int monitor_poll(struct file *fp, struct poll_table_struct *wait) {
    struct monitor_device *monitor_dev = fp->private_data;
    unsigned long flags;
    unsigned int ret, id;
    enum dma_status status;

    dev_info(monitor_dev->dev, "[ ] poll()");
    poll_wait(fp, &monitor_dev->queue, wait);
    spin_lock_irqsave(&monitor_dev->lock, flags);
        // Set default return value for poll()
        ret = 0;

        //
        // DMA check
        //
        // NOTE: this implementation does not consider errors in the data
        //       transfers.  If the callback is executed, it is assumed
        //       that the following check will always render DMA_COMPLETE.
        status = dma_async_is_tx_complete(monitor_dev->chan, monitor_dev->cookie, NULL, NULL);
        if (monitor_dev->hw.dma_irq_flag == 1 && status == DMA_COMPLETE) {
            dev_info(monitor_dev->dev, "[i] poll() : ret |= POLLDMA");
            ret |= POLLDMA;
		    monitor_dev->hw.dma_irq_flag = 0;
            // Release mutex (acquired in monitor_ioctl() before DMA transfer)
            mutex_unlock(&monitor_dev->mutex);
        }

        //
        // IRQ/Ready check
        //
		if (monitor_dev->hw.done_bit == 1) {
            dev_info(monitor_dev->dev, "[i] poll() : ret |= POLLIRQ");
            ret |= POLLIRQ;
			monitor_dev->hw.done_bit = 0;
        }
    spin_unlock_irqrestore(&monitor_dev->lock, flags);

    dev_info(monitor_dev->dev, "[+] poll()");
    return ret;
}

static const struct file_operations monitor_fops = {
    .owner = THIS_MODULE,
    .open = monitor_open,
    .release = monitor_release,
    .mmap = monitor_mmap,
    .unlocked_ioctl = monitor_ioctl,
    .poll           = monitor_poll,
};

// Creates a char device to act as user-space entry point
static int monitor_cdev_create(struct platform_device *pdev) {
    int res;

    // Retrieve custom device info using platform device (private data)
    struct monitor_device *monitor_dev = platform_get_drvdata(pdev);

    dev_info(&pdev->dev, "[ ] monitor_cdev_create()");

    // Set device structure parameters
    monitor_dev->devt = MKDEV(MAJOR(devt), 1);

    // Add char device to the system
    dev_info(&pdev->dev, "[ ] cdev_add()");
    cdev_init(&monitor_dev->cdev, &monitor_fops);
    res = cdev_add(&monitor_dev->cdev, monitor_dev->devt, 1);
    if (res) {
        dev_err(&pdev->dev, "[X] cdev_add() -> %d:%d", MAJOR(monitor_dev->devt), MINOR(monitor_dev->devt));
        return res;
    }
    dev_info(&pdev->dev, "[+] cdev_add() -> %d:%d", MAJOR(monitor_dev->devt), MINOR(monitor_dev->devt));

    // Create char device (initialization)
    dev_info(&pdev->dev, "[ ] device_create()");
    monitor_dev->dev = device_create(monitor_class, &pdev->dev, monitor_dev->devt, monitor_dev, "%s", DRIVER_NAME);
    if (IS_ERR(monitor_dev->dev)) {
        dev_err(&pdev->dev, "[X] device_create() -> %d:%d", MAJOR(monitor_dev->devt), MINOR(monitor_dev->devt));
        res = PTR_ERR(monitor_dev->dev);
        goto err_device;
    }
    dev_info(&pdev->dev, "[+] device_create() -> %d:%d", MAJOR(monitor_dev->devt), MINOR(monitor_dev->devt));
    dev_info(monitor_dev->dev, "[i] device_create()");

    dev_info(&pdev->dev, "[+] monitor_cdev_create()");
    return 0;

err_device:
    cdev_del(&monitor_dev->cdev);
    return res;
}

// Deletes a char device that acted as user-space entry point
static void monitor_cdev_destroy(struct platform_device *pdev) {

    // Retrieve custom device info using platform device (private data)
    struct monitor_device *monitor_dev = platform_get_drvdata(pdev);

    dev_info(&pdev->dev, "[ ] monitor_cdev_destroy()");

    dev_info(monitor_dev->dev, "[i] monitor_cdev_destroy()");

    // Destroy device
    device_destroy(monitor_class, monitor_dev->devt);
    cdev_del(&monitor_dev->cdev);

    dev_info(&pdev->dev, "[+] monitor_cdev_destroy()");
}

// Initializes char device support
static int monitor_cdev_init(void) {

    int res;

    pr_info("[%s] [ ] monitor_cdev_init()\n", DRIVER_NAME);

    // Dynamically allocate major number for char device
    pr_info("[%s] [ ] alloc_chrdev_region()\n", DRIVER_NAME);
    res = alloc_chrdev_region(&devt, 0, 1, DRIVER_NAME);
    if (res < 0) {
        pr_err("[%s] [X] alloc_chrdev_region()\n", DRIVER_NAME);
        return res;
    }

    pr_info("[%s] [+] alloc_chrdev_region()-> %d:%d-%d\n", DRIVER_NAME, MAJOR(devt), MINOR(devt), MINOR(devt));

    // create sysfs class
    pr_info("[%s] [ ] class_create()\n", DRIVER_NAME);
    // class_create has been modified after Linux 6.4 (https://community.intel.com/t5/Analyzers/redhat9-5-14-0-kernal-header-changes-break-sepdk-build/m-p/1605740)
    #if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 4, 0)
    monitor_class = class_create(DRIVER_NAME);
    #else
    monitor_class = class_create(THIS_MODULE, DRIVER_NAME);
    #endif

    if (IS_ERR(monitor_class)) {
        pr_err("[%s] [X] class_create()\n", DRIVER_NAME);
        res = PTR_ERR(monitor_class);
        goto err_class;
    }
    pr_info("[%s] [+] class_create() -> /sys/class/%s\n", DRIVER_NAME, DRIVER_NAME);

    pr_info("[%s] [+] monitor_cdev_init()\n", DRIVER_NAME);

    return 0;

err_class:
    unregister_chrdev_region(devt, 1);
    return res;
}

// Cleans up char device support
static void monitor_cdev_exit(void) {

    pr_info("[%s] [ ] monitor_cdev_exit()\n", DRIVER_NAME);

    // Destroy sysfs class
    class_destroy(monitor_class);

    // Unregister char device
    unregister_chrdev_region(devt, 1);

    pr_info("[%s] [+] monitor_cdev_exit()\n", DRIVER_NAME);
}

/* PLATFORM DRIVER */

// Actions to perform when the device is added (shows up in the device tree)
static int monitor_probe(struct platform_device *pdev) {
    int res;
    struct monitor_device *monitor_dev = NULL;
    struct resource *rsrc;

    dev_info(&pdev->dev, "[ ] monitor_probe()\n");

    // Allocate memory for custom device structure
    dev_info(&pdev->dev, "[ ] kmalloc()\n");
    monitor_dev = kmalloc(sizeof *monitor_dev, GFP_KERNEL);
    if (!monitor_dev) {
        dev_err(&pdev->dev, "[X] kmalloc() -> monitor_dev");
        res = -ENOMEM;
    }
    dev_info(&pdev->dev, "[+] kmalloc() -> monitor_dev");

    // Initialize list head
    INIT_LIST_HEAD(&monitor_dev->head);

    // Pass platform device pointer to custom device structure
    monitor_dev->pdev = pdev;

    // Pass newly created custom device to platform device (as private data)
    platform_set_drvdata(pdev, monitor_dev);

    // Initialize DMA subsystem
    res = monitor_dma_init(pdev);
    if (res) {
        dev_err(&pdev->dev, "[X] monitor_dma_init()");
        goto err_dma_init;
    }

    // Create char device
    res = monitor_cdev_create(pdev);
    if (res) {
        dev_err(&pdev->dev, "[X] monitor_cdev_create()");
        goto err_cdev_create;
    }

    // Initialize synchronization primitives
    mutex_init(&monitor_dev->mutex);
    spin_lock_init(&monitor_dev->lock);
    init_waitqueue_head(&monitor_dev->queue);

    // Initialize hardware information
    dev_info(&pdev->dev, "[ ] ioremap()");
    rsrc = platform_get_resource_byname(monitor_dev->pdev, IORESOURCE_MEM, "ctrl");
    dev_info(&pdev->dev, "[i] resource name  = %s", rsrc->name);
    dev_info(&pdev->dev, "[i] resource start = %lx", rsrc->start);
    dev_info(&pdev->dev, "[i] resource end   = %lx", rsrc->end);
    monitor_dev->hw.regs = ioremap(rsrc->start, rsrc->end - rsrc->start);
    if (!monitor_dev->hw.regs) {
        dev_err(&pdev->dev, "[X] ioremap()");
        res = -ENOMEM;
        goto err_ioremap;
    }
    monitor_dev->hw.done_bit = 0x00000000;

    // DMA IRQ flag initialization
    monitor_dev->hw.dma_irq_flag = 0;

    // You can do an initialization of the regs (maybe place a triggering mask)
    dev_info(&pdev->dev, "[+] ioremap()");

    // Register IRQ (TODO: check why platform_get_resource_byname() returns NULL in kernel tag xilinx-v2023.1)
    dev_info(&pdev->dev, "[ ] request_irq()");
    // rsrc = platform_get_resource_byname(monitor_dev->pdev, IORESOURCE_IRQ, "irq");
    // dev_info(&pdev->dev, "[i] resource name  = %s", rsrc->name);
    // dev_info(&pdev->dev, "[i] resource start = %lx", rsrc->start);
    // dev_info(&pdev->dev, "[i] resource end   = %lx", rsrc->end);
    // monitor_dev->irq = rsrc->start;
    monitor_dev->irq = platform_get_irq_byname(monitor_dev->pdev, "irq");  // Workaround to platform_get_resource_byname()
    res = request_irq(monitor_dev->irq, (irq_handler_t)monitor_isr, IRQF_TRIGGER_RISING, "monitor", monitor_dev);
    if (res) {
        dev_err(&pdev->dev, "[X] request_irq()");
        goto err_irq;
    }
    dev_info(&pdev->dev, "[+] request_irq()");

    dev_info(&pdev->dev, "[+] monitor_probe()");
    return 0;

err_irq:
    iounmap(monitor_dev->hw.regs);

err_ioremap:
    monitor_cdev_destroy(pdev);

err_cdev_create:
    monitor_dma_exit(pdev);

err_dma_init:
    kfree(monitor_dev);
    return res;
}

// Actions to perform when the device is removed (dissappears from the device tree)
static int monitor_remove(struct platform_device *pdev) {

    // Retrieve custom device info using platform device (private data)
    struct monitor_device *monitor_dev = platform_get_drvdata(pdev);

    dev_info(&pdev->dev, "[ ] monitor_remove()");

    free_irq(monitor_dev->irq, monitor_dev);
    iounmap(monitor_dev->hw.regs);
    mutex_destroy(&monitor_dev->mutex);
    monitor_cdev_destroy(pdev);
    monitor_dma_exit(pdev);
    kfree(monitor_dev);

    dev_info(&pdev->dev, "[+] monitor_remove()");
    return 0;
}

// Device tree (Open Firmware) matching table
static const struct of_device_id monitor_of_match[] = {
    { .compatible = "cei.upm,monitor-1.00.a", },
    {}
};

// Driver structure
static struct platform_driver monitor_driver = {
    .probe  = monitor_probe,
    .remove = monitor_remove,
    .driver = {
        .name           = DRIVER_NAME,
        .of_match_table = monitor_of_match,
    },
};

/* KERNEL MODULE */

// Module initialization
static int monitor_init(void) {

    int res;

    pr_info("[%s] [ ] monitor_init()\n", DRIVER_NAME);

    // Initialize char device
    res = monitor_cdev_init();
    if(res){
        pr_err("[%s] [X] monitor_cdev_init()\n", DRIVER_NAME);
        return res;
    }

    // Register platform driver
    pr_info("[%s] [ ] platform_driver_register()\n", DRIVER_NAME);
    res = platform_driver_register(&monitor_driver);
    if (res) {
        pr_err("[%s] [X] platform_driver_register()\n", DRIVER_NAME);
        goto err_driver;
    }
    pr_info("[%s] [+] platform_driver_register()\n", DRIVER_NAME);

    pr_info("[%s] [+] monitor_init()\n", DRIVER_NAME);

    return 0;

err_driver:
    monitor_cdev_exit();
    return res;
}

// Module cleanup
static void monitor_exit(void) {

    pr_info("[%s] [ ] monitor_exit()\n", DRIVER_NAME);

    // Unregister platform device
    platform_driver_unregister(&monitor_driver);

    // Clean up char device
    monitor_cdev_exit();

    pr_info("[%s] [+] monitor_exit()\n", DRIVER_NAME);
}

module_init(monitor_init);
module_exit(monitor_exit);
