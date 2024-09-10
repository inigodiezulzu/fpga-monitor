/*
 * Monitor low-level hardware API
 *
 * Author      : Juan Encinas Anchústegui <juan.encinas@upm.es>
 * Date        : February 2021
 * Description : This file contains the low-level functions required to
 *               work with the Monitor infrastructure (Monitor registers).
 *
 */


#ifndef _MONITOR_HW_H_
#define _MONITOR_HW_H_

extern uint32_t *monitor_hw;

#if ZYNQMP
// Zynq-7000 devices
#define PUM_POWER_ADDR  (0xb0100000)
#define PUM_TRACES_ADDR (0xb0180000)
#else
// Zynq Ultrascale+ devices
#define PUM_POWER_ADDR  (0x20000000)
#define PUM_TRACES_ADDR (0x20040000)

#endif

/*
 * Monitor infrastructure register offsets (in 32-bit words)
 *
 */
#define PUM_REG0    (0x00000000 >> 2)                     // REG 0
#define PUM_REG1    (0x00000004 >> 2)                     // REG 1
#define PUM_REG2    (0x00000008 >> 2)                     // REG 2
#define PUM_REG3    (0x0000000c >> 2)                     // REG 3

/*
 * Monitor infrastructure commands
 *
 */
#define PUM_CONFIG_VREF             0x01    // In
#define PUM_CONFIG_2VREF            0x02    // In
#define PUM_START                   0x04    // In
#define PUM_STOP                    0x08    // In
#define PUM_AXI_SNIFFER_ENABLE_IN   0x20    // In
#define PUM_BUSY                    0x01    // Out
#define PUM_DONE                    0x02    // Out
#define PUM_AXI_SNIFFER_ENABLE_OUT  0x04    // Out
#define PUM_POWER_ERRORS_OFFSET     0x03    // Offset


struct pumRegion_t {
    char *name;
    size_t size;  
    void *data;
};

struct pumData_t {
    struct pumRegion_t *power;
    struct pumRegion_t *traces;
};

/*
 * Monitor normal voltage reference configuration function
 *
 * This function sets the monitor ADC voltage reference to 2.5V.
 *
 */
void monitor_hw_config_vref();

/*
 * Monitor double voltage reference configuration function
 *
 * This function sets the monitor ADC voltage reference to 5V.
 *
 */
void monitor_hw_config_2vref();

/*
 * Monitor start function
 *
 * This function starts the monitor acquisition.
 *
 */
void monitor_hw_start();

/*
 * Monitor stop function
 *
 * This function cleans the monitor memory banks.
 *
 */
void monitor_hw_stop();

/*
 * Monitor set mask function
 *
 * @mask : Triggering mask
 *
 * This function sets a mask used to decide which signals trigger the monitor execution.
 *
 */
void monitor_hw_set_mask(int mask);

/*
 * Monitor set AXI mask function
 *
 * @mask : AXI triggering mask
 *
 * This function sets a mask used to decide which AXI communication triggers the monitor execution.
 *
 */
void monitor_hw_set_axi_mask(int mask);

/*
 * Monitor get acquisition time function
 *
 * This function gets the acquisition elapsed cycles used for data plotting in post-processing.
 *
 * Return : Elapsed cycles
 *
 */
int monitor_hw_get_time();

/*
 * Monitor get power measurements function
 *
 * This function gets the number of power consumption measurements stored in the BRAM used in post-processing.
 *
 * Return : Number of power consupmtion measurements
 *
 */
int monitor_hw_get_number_power_measurements();

/*
 * Monitor get traces measurements function
 *
 * This function gets the number of probes events stored in the BRAM used in post-processing.
 *
 * Return : Number of probes events
 *
 */
int monitor_hw_get_number_traces_measurements();

/*
 * Monitor get acquisition time function
 *
 * This function gets the acquisition elapsed cycles used for data plotting in post-processing.
 *
 * Return : Elapsed cycles
 *
 */
int monitor_hw_isdone();

/*
 * Monitor check busy function
 *
 * This function checks if the monitor is busy.
 *
 * Return : True -> Busy, False -> Idle
 *
 */
int monitor_hw_isbusy();

/*
 * Monitor get number of power measurement failed
 *
 * This function return the number of power samples gathered incorrectly from the ADC.
 *
 * Return : Number of errors
 *
 */
int monitor_hw_get_number_power_erros();

#endif /* _MONITOR_HW_H_ */
