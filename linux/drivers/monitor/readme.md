# Monitor Linux Driver

This folder contains the Linux driver for the Monitor infrastructure. The driver allows interaction with the Monitor hardware on a Linux-based system.

### Folder Structure

- `monitor.c`: Source code of the Monitor Linux driver.
- `monitor.h`: Header file for the Monitor Linux driver.
- `Makefile`: Makefile to compile the Monitor Linux driver.

## Instructions

1. Set up the cross-compilation environment:
    ```sh
    export CROSS_COMPILE="arm-xilinx-linux-gnueabi"
    export ARCH="arm"
    export KDIR="/home/<user>/linux-xlnx"
    ```
2. Compile the Monitor Linux driver:
    ```sh
    make
    ```
3. Copy the compiled driver to the target platform.
4. Load the driver on the target platform using the appropriate commands (more info [here](../../../setup_monitor/readme.md)).

For detailed information on how to use the Monitor infrastructure, refer to the main [Readme](../../../../readme.md).
