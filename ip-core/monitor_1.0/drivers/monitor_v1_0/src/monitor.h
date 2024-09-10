
#ifndef MONITOR_H
#define MONITOR_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xil_io.h"
#include "xstatus.h"

#define MONITOR_S00_AXI_SLV_REG0_OFFSET 0
#define MONITOR_S00_AXI_SLV_REG1_OFFSET 4
#define MONITOR_S00_AXI_SLV_REG2_OFFSET 8
#define MONITOR_S00_AXI_SLV_REG3_OFFSET 12

#define PUM_CONFIG_VREF             0x01    // in
#define PUM_CONFIG_2VREF            0x02    // in
#define PUM_START                   0x04    // in
#define PUM_STOP                    0x08    // in
#define PUM_AXI_SNIFFER_ENABLE_IN   0X20    // in
#define PUM_BUSY                    0X01    // out
#define PUM_DONE                    0X02    // out
#define PUM_AXI_SNIFFER_ENABLE_OUT  0X04    // out
#define PUM_POWER_ERRORS_OFFSET     0X03    // offset


/**************************** Type Definitions *****************************/
/**
 *
 * Write/Read 32 bit value to/from MONITOR user logic memory (BRAM).
 *
 * @param   Address is the memory address of the MONITOR device.
 * @param   Data is the value written to user logic memory.
 *
 * @return  The data from the user logic memory.
 *
 * @note
 * C-style signature:
 * 	void MONITOR_mWriteMemory(u32 Address, u32 Data)
 * 	u32 MONITOR_mReadMemory(u32 Address)
 *
 */
#define MONITOR_mWriteMemory(Address, Data) \
    Xil_Out32(Address, (u32)(Data))
#define MONITOR_mReadMemory(Address) \
    Xil_In32(Address)
#define MONITOR_mReadMemory_64(Address) \
    Xil_In64(Address)

/************************** Function Prototypes ****************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the MONITORinstance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus MONITOR_Mem_SelfTest(void * baseaddr_p);

/**
 *
 * Write a value to a MONITOR register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the MONITORdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void MONITOR_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define MONITOR_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a MONITOR register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the MONITOR device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 MONITOR_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define MONITOR_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

void MONITOR_config_vref(u32 BaseAddress);
void MONITOR_config_2vref(u32 BaseAddress);
void MONITOR_start(u32 BaseAddress);
void MONITOR_stop(u32 BaseAddress);
void MONITOR_mask(u32 BaseAddress, u32 mask);
void MONITOR_axi_mask(u32 BaseAddress, u32 mask);
u32 MONITOR_consumption_count(u32 BaseAddress);
u32 MONITOR_busy(u32 BaseAddress);
u32 MONITOR_done(u32 BaseAddress);
u32 MONITOR_power_utilization(u32 BaseAddress);
u32 MONITOR_traces_utilization(u32 BaseAddress);
u32 MONITOR_power_errors(u32 BaseAddress);

#endif // MONITOR_H
