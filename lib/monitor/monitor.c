/*
 * Monitor runtime API
*
* Author      : Juan Encinas Anchústegui <juan.encinas@upm.es>
* Date        : February 2021
* Description : This file contains the Monitor runtime API, which can
*               be used by any application to monitor the power consumption
* 		 and performances of hardware accelerators.
*
*/


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <sys/mman.h>  // mmap()
#include <sys/ioctl.h> // ioctl()
#include <sys/poll.h>  // poll()
#include <sys/time.h>  // struct timeval, gettimeofday()

#include "drivers/monitor/monitor.h"
#include "monitor.h"
#include "monitor_hw.h"
#include "monitor_dbg.h"

#include <inttypes.h>


/*
* Monitor global variables
*
* @monitor_hw : user-space map of Monitor hardware registers
* @monitor_fd : /dev/monitor file descriptor (used to access kernels)
*
* @monitordata    : structure containing memory banks information
*
*/
static int monitor_fd;
uint32_t *monitor_hw = NULL;
#ifdef AU250
uint32_t *monitor_CMS = NULL;
static pthread_t *thread = NULL;
int CMS_flag = 0;
int num_power_measurements = 0;
#endif
static struct monitorData_t *monitordata = NULL;

#ifdef AU250
/**
 * @file monitor.c
 * @brief This file contains the definition of RW_MAX_SIZE constant.
 *
 * The RW_MAX_SIZE constant represents the maximum size for read/write operations.
 * It is defined as 0x7ffff000.
 */
#define RW_MAX_SIZE	0x7ffff000

/**
 * @brief Reads data from a file descriptor into a buffer.
 *
 * This function reads data from the specified file descriptor and stores it in the provided buffer.
 *
 * @param fname The name of the file being read.
 * @param fd The file descriptor to read from.
 * @param buffer The buffer to store the read data.
 * @param size The size of the buffer.
 * @param base The base offset for reading the file.
 *
 * @return The number of bytes read, or -1 if an error occurred.
 */
ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
            uint64_t base)
{
    ssize_t rc;
    uint64_t count = 0;
    char *buf = buffer;
    off_t offset = base;
    int loop = 0;

    while (count < size) {
        ssize_t bytes = size - count;

        if (bytes > RW_MAX_SIZE)
            bytes = RW_MAX_SIZE;

        if (offset) {
            rc = lseek(fd, offset, SEEK_SET);
            if (rc != offset) {
                fprintf(stderr, "%s, seek off 0x%lx != 0x%lx.\n",
                    fname, rc, offset);
                perror("seek file");
                return -EIO;
            }
        }

        /* read data from file into memory buffer */
        rc = read(fd, buf, bytes);
        if (rc < 0) {
            fprintf(stderr, "%s, read 0x%lx @ 0x%lx failed %ld.\n",
                fname, bytes, offset, rc);
            perror("read file");
            return -EIO;
        }

        count += rc;
        if (rc != bytes) {
            fprintf(stderr, "%s, read underflow 0x%lx/0x%lx @ 0x%lx.\n",
                fname, rc, bytes, offset);
            break;
        }

        buf += bytes;
        offset += bytes;
        loop++;
    }

    if (count != size && loop)
        fprintf(stderr, "%s, read underflow 0x%lx/0x%lx.\n",
            fname, count, size);
    return count;
}
#endif

/*
* Monitor init function
*
* This function sets up the basic software entities required to manage
* the Monitor low-level functionality (DMA transfers, registers access, etc.).
*
* Return : 0 on success, error code otherwise
*/
int monitor_init() {
    #ifdef AU250
    const char *filename = "/dev/xdma0_user";
    #else
    const char *filename = "/dev/monitor";
    #endif
    int ret;

    /*
    * NOTE: this function relies on predefined addresses for both control
    *       and data interfaces of the Monitor infrastructure.
    *       If the processor memory map is changed somehow, this has to
    *       be reflected in this file.
    *
    *       Zynq-7000 Devices
    *       Power memory bank  -> 0xb0100000
    *       Traces memory bank -> 0xb0180000
    *
    *       Zynq Ultrascale+ Devices
    *       Power memory bank  -> 0xb0100000
    *       Traces memory bank -> 0xb0180000
    * 
    *       Alveo U250 Devices
    *       ARTICo3 Control -> 0x40400000
    *       ARTICo3 Data    -> 0x80000000
    *
    */

    // Open Monitor device file
    monitor_fd = open(filename, O_RDWR);
    if (monitor_fd < 0) {
        monitor_print_error("[monitor-hw] open() %s failed\n", filename);
        return -ENODEV;
    }
    monitor_print_debug("[monitor-hw] monitor_fd=%d | dev=%s\n", monitor_fd, filename);

    // Obtain access to physical memory map using mmap()
    #ifdef AU250
    monitor_hw = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, monitor_fd, 0x2410000);
    #else
    monitor_hw = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, monitor_fd, 0);
    #endif
    if (monitor_hw == MAP_FAILED) {
        monitor_print_error("[monitor-hw] mmap() failed\n");
        ret = -ENOMEM;
        goto err_mmap;
    }
    monitor_print_debug("[monitor-hw] monitor_hw=%p\n", monitor_hw);

    #ifdef AU250
    // Memory map the device
    monitor_CMS = mmap (NULL , 0x40000 , PROT_READ | PROT_WRITE , MAP_SHARED , monitor_fd , 0x1000000);
    if (monitor_CMS == MAP_FAILED){
        perror ("mmap()");
        close(monitor_fd);
        return EXIT_FAILURE ;
    }
    if (monitor_CMS == MAP_FAILED) {
        monitor_print_error("[monitor-hw] mmap() failed\n");
        ret = -ENOMEM;
        goto err_mmap;
    }
    monitor_print_debug("[monitor-hw] monitor_CMS=%p\n", monitor_CMS);
    #endif

    // Initialize regions structure
    monitordata = malloc(sizeof *monitordata);
    if (!monitordata) {
        monitor_print_error("[monitor-hw] malloc() failed\n");
        ret = -ENOMEM;
        goto err_malloc_monitordata;
    }
    monitordata->power = NULL;
    monitordata->traces = NULL;
    monitor_print_debug("[monitor-hw] monitordata=%p\n", monitordata);

    return 0;

err_malloc_monitordata:
    munmap(monitor_hw, 0x10000);
    #ifdef AU250
    munmap(monitor_CMS, 0x40000);
    #endif
err_mmap:
    close(monitor_fd);

    return ret;
}

/*
* Monitor exit function
*
* This function cleans the software entities created by monitor_init().
*
*/
void monitor_exit() {

    // Release allocated memory for monitordata
    free(monitordata);

    // Release memory obtained with mmap()
    munmap(monitor_hw, 0x10000);
    #ifdef AU250
    munmap(monitor_CMS, 0x40000);
    #endif

    // Close ARTICo3 device file
    close(monitor_fd);
}

/*
* Monitor normal voltage reference configuration function
*
* This function sets the monitor ADC voltage reference to 2.5V.
*
*/
void monitor_config_vref(){

    monitor_hw_config_vref();

}

/*
* Monitor double voltage reference configuration function
*
* This function sets the monitor ADC voltage reference to 5V.
*
*/
void monitor_config_2vref(){

    monitor_hw_config_2vref();

}

/*
* Monitor CMS get power measurements function
*
* This function get power measurements from CMS.
*
*/
void monitor_CMS_get_power_measurements(){

    int max_data;
    
    uint32_t* CMS_reg = (monitor_CMS + 40960);
    max_data =  monitordata->power->size / sizeof(monitorpdata_t);

    while(CMS_flag == 1 && num_power_measurements < max_data){
        // Read power consumption
        ((monitorpdata_t *)monitordata->power->data)[num_power_measurements] = (CMS_reg[58]*CMS_reg[61]);
        // Print power consumption
        monitor_print_info("Board power consumption: %d W\n", ((monitorpdata_t *)monitordata->power->data)[num_power_measurements]);
        num_power_measurements++;

        // Wait for the CMS to finish
        usleep(120000);
    }

}

/*
* Monitor CMS start function
*
* This function starts the CMS acquisition.
*
*/
void monitor_CMS_start(){

    uint32_t* CMS_reset = (monitor_CMS + 32768);

    //Disable reset
    *CMS_reset = 1; 
    CMS_flag = 1;

    // Crear el hilo
    if (pthread_create(&thread, NULL, monitor_CMS_get_power_measurements,NULL) != 0) {
        perror("Error al crear el hilo");
        return 1;
    }

}

/*
* Monitor start function
*
* This function starts the monitor acquisition.
*
*/
void monitor_start(){

    monitor_hw_start();
    #ifdef AU250
    // Start CMS
    monitor_CMS_start();
    #endif

}

/*
* Monitor clean function
*
* This function cleans the monitor memory banks.
*
*/
void monitor_clean(){

    monitor_hw_clean();

}

/*
* Monitor CMS stop function
*
* This function stops the CMS acquisition.
*
*/
void monitor_CMS_stop(){

    uint32_t* CMS_reset = (monitor_CMS + 32768);

    //Disable reset & stop CMS
    CMS_flag = 0;
    *CMS_reset = 0; 

    // Wait for the thread to finish
    if (pthread_join(thread, NULL) != 0) {
        perror("Error al esperar a que el hilo termine");
        return 1;
    }
    
}

/*
* Monitor stop function
*
* This function stop the monitor acquisition. (only makes sense when power monitoring disabled)
*
*/
void monitor_stop(){
    
    // Return if monitor is already done, otherwise stop it
    if (monitor_hw_isdone() == 1){
        return;
    }
    monitor_hw_stop();
    #ifdef AU250
    // Stop CMS
    monitor_CMS_stop();
    #endif

}

/*
* Monitor set mask function
*
* @mask : Triggering mask
*
* This function sets a mask used to decide which signals trigger the monitor execution.
*
*/
void monitor_set_mask(int mask){

    monitor_hw_set_mask(mask);

}

/*
* Monitor set AXI mask function
*
* @mask : AXI triggering mask
*
* This function sets a mask used to decide which AXI communication triggers the monitor execution.
*
*/
void monitor_set_axi_mask(int mask){

    monitor_hw_set_axi_mask(mask);

}

/*
* Monitor get acquisition time function
*
* This function gets the acquisition elapsed cycles used for data plotting in post-processing.
*
* Return : Elapsed cycles
*
*/
int monitor_get_time(){

    return monitor_hw_get_time();

}

/*
* Monitor get power measurements function
*
* This function gets the number of power consumption measurements stored in the BRAM used in post-processing.
*
* Return : Number of power consupmtion measurements
*
*/
int monitor_get_number_power_measurements() {

    return monitor_hw_get_number_power_measurements();

}

/*
* Monitor get traces measurements function
*
* This function gets the number of probes events stored in the BRAM used in post-processing.
*
* Return : Number of probes events
*
*/
int monitor_get_number_traces_measurements() {

    return monitor_hw_get_number_traces_measurements();

}

/*
* Monitor is done function
*
* This function checks if the acquisition has finished.
*
* Return : 1 if acquisition finished, 0 otherwise
*
*/
int monitor_isdone(){

    return monitor_hw_isdone();

}

/*
* Monitor is busy function
*
* This function checks if the monitor is busy.
*
* Return : 1 if busy, 0 if idle
*
*/
int monitor_isbusy(){

    return monitor_hw_isbusy();

}

/*
* Monitor get number of power errors function
*
* This function return the number of incorrect power samples received from ADC
*
* Return : Number of errors [0,$number_power_measurements]
*
*/
int monitor_get_power_errors(){

    return monitor_hw_get_number_power_erros();

}


/*
* Monitor no busy-wait waiting function
*
* This function waits for the monitor to finish in a not busy-wait manner.
*
*/
void monitor_wait(){

    // Monitor management using interrupts and blocking system calls
    { struct pollfd pfd = { .fd = monitor_fd, .events = POLLIRQ, };  poll(&pfd, 1, -1); }

}


#ifndef AU250
/*
* Monitor power consumption read function
*
* This function reads the monitor power consumption data sampled.
*
* @ndata   : amount of data to be read from power memory bank
*
* Return : 0 on success, error code otherwise
*
*/
int monitor_read_power_consumption(unsigned int ndata) {
    struct dmaproxy_token token;
    monitorpdata_t *mem = NULL;

    struct pollfd pfd;
    pfd.fd = monitor_fd;
    pfd.events = POLLDMA;
   
    // Allocate DMA physical memory
    mem = mmap(NULL, ndata * sizeof *mem, PROT_READ | PROT_WRITE, MAP_SHARED, monitor_fd, sysconf(_SC_PAGESIZE));
    if (mem == MAP_FAILED) {
        monitor_print_error("[monitor-hw] mmap() failed\n");
        return -ENOMEM;
    }

    // Start DMA transfer
    token.memaddr = mem;
    token.memoff = 0x00000000;
    token.hwaddr = (void *)MONITOR_POWER_ADDR;
    token.hwoff = 0x00000000;
    token.size = ndata * sizeof *mem;
    ioctl(monitor_fd, MONITOR_IOC_DMA_HW2MEM_POWER, &token);

    // Wait for DMA transfer to finish
    poll(&pfd, 1, -1);


    if (!monitordata->power){
        monitor_print_error("[monitor-hw] no power region found (dma transfer)\n");
        return -1;
    }
    // Copy data from DMA-allocated memory buffer to userspace memory buffer

    memcpy(monitordata->power->data, mem, ndata * sizeof *mem);

    // Release allocated DMA memory
    munmap(mem, ndata * sizeof *mem);

    return 0;
}
#endif

/*
* Monitor traces read function
*
* This function reads the monitor traces data sampled.
*
* @ndata   : amount of data to be read from traces memory bank
*
* Return : 0 on success, error code otherwise
*
*/
int monitor_read_traces(unsigned int ndata) {
    struct dmaproxy_token token;
    monitortdata_t *mem = NULL;

    #ifdef AU250
    int fpga_fd;
    char *device = NULL;
    char *allocated = NULL;
    #else
    struct pollfd pfd;
    pfd.fd = monitor_fd;
    pfd.events = POLLDMA;
    #endif

    #ifdef AU250
    //DMA transfer parameters
    device = "/dev/xdma0_c2h_0";

    fpga_fd = open(device, O_RDWR);

    if (fpga_fd < 0) {
        fprintf(stderr, "unable to open device %s, %d.\n",
                device, fpga_fd);
        perror("open device");
                return -1;
    }

    token.size = ndata * sizeof *mem;
    token.memoff = 0x00000000;
    #endif

    // Allocate DMA physical memory
    #ifdef AU250
    posix_memalign((void **)&allocated, 4096 /*alignment */ , token.size + 4096);
    if (!allocated) {
        fprintf(stderr, "OOM %lu.\n", token.size + 4096);
        monitor_print_error("[artico3-hw] memalign() failed\n");
        return -ENOMEM;
        printf("Error allocation\n");
    }
    mem = (monitortdata_t *)allocated + token.memoff;

    monitor_print_debug("host buffer 0x%lx = %p\n", token.size + 4096, mem); 
    #else
    mem = mmap(NULL, ndata * sizeof *mem, PROT_READ | PROT_WRITE, MAP_SHARED, monitor_fd, 2 * sysconf(_SC_PAGESIZE));
    if (mem == MAP_FAILED) {
        monitor_print_error("[monitor-hw] mmap() failed\n");
        return -ENOMEM;
    }
    #endif

    // Start DMA transfer
    token.memaddr = mem;
    token.memoff = 0x00000000;
    token.hwaddr = (void *)MONITOR_TRACES_ADDR;
    token.hwoff = 0x00000000;
    token.size = ndata * sizeof *mem;
    #ifdef AU250
    read_to_buffer(device, fpga_fd, (char *)token.memaddr, (uint64_t)token.size, (uint64_t)(token.hwaddr+token.hwoff));
    #else
    ioctl(monitor_fd, MONITOR_IOC_DMA_HW2MEM_TRACES, &token);
    #endif

    // Wait for DMA transfer to finish
    #ifndef AU250
    poll(&pfd, 1, -1);
    #endif

    if (!monitordata->traces){
        monitor_print_error("[monitor-hw] no traces region found (dma transfer)\n");
        return -1;
    }

    // Copy data from DMA-allocated memory buffer to userspace memory buffer
    memcpy(monitordata->traces->data, mem, ndata * sizeof *mem);

    // Release allocated DMA memory
    #ifdef AU250
    free(allocated);
    close(fpga_fd);
    #else
    munmap(mem, ndata * sizeof *mem);
    #endif

    return 0;
}

/*
* Monitor allocate buffer memory
*
* This function allocates dynamic memory to be used as a buffer between
* the application and the local memories in the hardware kernels.
*
* @ndata   : amount of data to be allocated for the buffer
* @regname : memory bank name to associate this buffer with
* @regtype : memory bank type (power or traces)
*
* Return : pointer to allocated memory on success, NULL otherwise
*
*/
void *monitor_alloc(int ndata, const char *regname, enum monitorregtype_t regtype) {
    struct monitorRegion_t *region = NULL;

    // Search for port in port lists
    if (monitordata->power){
        if (regtype == MONITOR_REG_POWER){
            monitor_print_error("[monitor-hw] power region already exist\n");
            return NULL;
        }
        if (strcmp(monitordata->power->name, regname) == 0){
            monitor_print_error("[monitor-hw] a region has been found with name %s\n", regname);
            return NULL;
        }
    }
    if (monitordata->traces){
        if (regtype == MONITOR_REG_TRACES){
            monitor_print_error("[monitor-hw] traces region already exist\n");
            return NULL;
        }
        if (strcmp(monitordata->traces->name, regname) == 0){
            monitor_print_error("[monitor-hw] a region has been found with name %s\n", regname);
            return NULL;
        }
    }

    // Allocate memory for kernel port configuration
    region = malloc(sizeof *region);
    if (!region) {
        return NULL;
    }

    // Set port name
    region->name = malloc(strlen(regname) + 1);
    if (!region->name) {
        goto err_malloc_reg_name;
    }
    strcpy(region->name, regname);

    // Set port size
    if (regtype == MONITOR_REG_POWER)
        region->size = ndata * sizeof(monitorpdata_t);

    if (regtype == MONITOR_REG_TRACES)
        region->size = ndata * sizeof(monitortdata_t);

    // Allocate memory for application
    region->data = malloc(region->size);
    if (!region->data) {
        goto err_malloc_region_data;
    }

    // Check port direction flag : POWER
    if (regtype == MONITOR_REG_POWER)
        monitordata->power = region;

    // Check port direction flag : TRACES
    if (regtype == MONITOR_REG_TRACES)
        monitordata->traces = region;

    // Return allocated memory
    return region->data;

err_malloc_reg_name:
    free(region->name);
    region->name = NULL;

err_malloc_region_data:
    free(region);
    region = NULL;

    return NULL;
}


/*
* Monitor release buffer memory
*
* This function frees dynamic memory allocated as a buffer between the
* application and the hardware kernel.
*
* @regname : memory bank this buffer is associated with
*
* Return : 0 on success, error code otherwise
*
*/
int monitor_free(const char *regname) {
    struct monitorRegion_t *region = NULL;

    // Search for port in port lists
    if (monitordata->power != NULL){
        if (strcmp(monitordata->power->name, regname) == 0){
            region = monitordata->power;
            monitordata->power = NULL;
        }
    }
    if (monitordata->traces != NULL){
        if (strcmp(monitordata->traces->name, regname) == 0){
            region = monitordata->traces;
            monitordata->traces = NULL;
        }
    }

    if (region == NULL) {
        monitor_print_error("[monitor-hw] no region found with name %s\n", regname);
        return -ENODEV;
    }

    // Free application memory
    free(region->data);
    free(region->name);
    free(region);

    return 0;
}
