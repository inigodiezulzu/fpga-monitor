/*
 * Monitor test application
 * Dummy application (HIGH in bit 0 and LOW in bit 1 of the hardware)
 *
 * Author : Juan Encinas <juan.encinas@upm.es>
 * Date   : November 2024
 *
 * Main application
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h> // struct timeval, gettimeofday()
#include <time.h>     // time()

#include <fcntl.h>    /* For O_RDWR */
#include <unistd.h>   /* For open(), creat() */

#include "monitor.h"

#define POWER_SAMPLES  (64)
#define TRACES_SAMPLES (64)

int main() {

    int fd_power, fd_traces, iter;

    // Load Monitor overlay and driver
    printf("Monitor linux setup return: %d\n",system("./setup_monitor/setup_monitor.sh"));

    // Initialize Monitor infrastructure
    monitor_init();

    // Allocate data buffers for MONITOR
    monitorpdata_t *power  = monitor_alloc(POWER_SAMPLES, "power", MONITOR_REG_POWER);
    monitortdata_t *traces = monitor_alloc(TRACES_SAMPLES, "traces", MONITOR_REG_TRACES);

    // Send start command to MONITOR
    monitor_start();

    /* Execution of you logic... */

    // Wait for the interruption that signals the end of the monitor execution
    monitor_wait();  // Note: use monitor_stop() if power is not monitored

    // Read number of power errors
    int number_power_errors = monitor_get_power_errors();

    // Read number of power consupmtion and traces measurements stored in the BRAMS
    unsigned int number_power_samples = monitor_get_number_power_measurements();
    unsigned int number_traces_samples = monitor_get_number_traces_measurements();
    printf("Number of power samples : \t%d\n", number_power_samples);
    printf("Number of power errors : (%d/%d)\n", number_power_errors, number_power_samples);
    printf("Number of traces samples : \t%d\n", number_traces_samples);

    if (monitor_read_power_consumption(number_power_samples + number_power_samples%4) != 0){
        printf("Error reading power\n\n\r");
    goto monitor_err;
    }
    if (monitor_read_traces(number_traces_samples + number_traces_samples%4) != 0){
        printf("Error reading traces\n\n\r");
    goto monitor_err;
    }

    for(iter = 0; iter < 5; iter++){
    printf("| Power #%2d : %u |\n\r", iter, power[iter]);
    }
    printf("\n\n---------------------------------------\n\n\r");
    for(iter = 0; iter < 5; iter++){
        printf("| Trace #%2d : Time -> %10u | Signals -> %10llu |\n\r", iter, traces[iter] & 0xffffffff, traces[iter] >> 32);
    }
    printf("\n\n---------------------------------------\n\n\r");

    unsigned elapsed_time = monitor_get_time();
    printf("Elapsed time : \t%d\n\r", elapsed_time);

    // Store power and traces for further processing
    fd_power = open("CON.BIN", O_WRONLY | O_CREAT, 0644);
    if(fd_power< 0){
        printf("Error! CON file cannot be opened.\n\n");
    goto monitor_err;
    }
    fd_traces = open("SIG.BIN", O_WRONLY | O_CREAT, 0644);
    if(fd_traces < 0){
        printf("Error! SIG file cannot be opened.\n\n");
    goto trace_open_err;
    }

    write(fd_power, power, sizeof(monitorpdata_t) * (number_power_samples));
    write(fd_power, &elapsed_time, sizeof(elapsed_time));   // stores elapsed time at the end of the CON.BIN file
    write(fd_traces, traces, sizeof(monitortdata_t) * number_traces_samples);

    close(fd_power);

    trace_open_err:
    close(fd_traces);

    monitor_err:
    monitor_clean();

    // Free monitor data buffers
    monitor_free("power");
    monitor_free("traces");

    // Clean monitor setup
    monitor_exit();

    // Load Monitor overlay and driver
    printf("Monitor linux removal return: %d\n",system("./setup_monitor/remove_monitor.sh"));

    return 0;
}