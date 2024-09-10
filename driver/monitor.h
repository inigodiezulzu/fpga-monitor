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
 *     - [DMA] Targets memcpy operations (requires src and dst addresses)
 *     - [DMA] Relies on Device Tree (Open Firmware) to get DMA engine info
 *
 */

#ifndef _MONITOR_DRIVER_H_
#define _MONITOR_DRIVER_H_

#include <linux/ioctl.h>


/*
 * Basic data structure to use DMA proxy devices via ioctl()
 *
 * @memaddr - memory address
 * @memoff  - memory address offset
 * @hwaddr  - hardware address
 * @hwoff   - hardware address offset
 * @size    - number of bytes to be transferred
 *
 */
struct dmaproxy_token {
    void *memaddr;
    size_t memoff;
    void *hwaddr;
    size_t hwoff;
    size_t size;
};

/*
 * IOCTL definitions for DMA proxy devices
 *
 * dma_hw2mem_power  - start transfer from power region of the hardware device to main memory
 * dma_hw2mem_traces - start transfer from traces region of the hardware device to main memory
 *
 */

#define MONITOR_IOC_MAGIC 'x'

#define MONITOR_IOC_DMA_HW2MEM_POWER  _IOW(MONITOR_IOC_MAGIC, 0, struct dmaproxy_token)
#define MONITOR_IOC_DMA_HW2MEM_TRACES _IOW(MONITOR_IOC_MAGIC, 1, struct dmaproxy_token)

#define MONITOR_IOC_MAXNR 1


/*
 * poll() definitions for Monitor
 *
 * polldma - wait for DMA transfer to finish
 * pollirq - wait for Monitor to finish
 *
 */

#define POLLDMA 0x0001
#define POLLIRQ 0x0002

/*
 * Hardware definitions for Monitor
 *
 * done - position of the Done bit
 * reg0 - Reg0 offset
 *
 */

#define MONITOR_DONE    0x02
#define MONITOR_REG0    (0x00000000)
// You may add more defines for accessing other registers


#endif /* _MONITOR_DRIVER_H_ */
