# Monitor Integration in the ARTICo³ project

This repository contains scripts and tools to integrate the Monitor infrastructure into the ARTICo³ project.

## Overview

[ARTICo³](https://github.com/des-cei/artico3.git) is a framework for hardware acceleration implementation on FPGAs. This repository provides the necessary scripts and tools to integrate the Monitoring infrastructure into ARTICo³, including a Linux driver, a device tree overlay, a software library, and an ARTICo³ hardware template for various target platforms.

## Repository Structure

- `files_to_integrate/`: Contains files that need to be added to the ARTICo³ framework to support the Monitor infrastructure.
- `patches/`: Contains patches that need to be applied to the ARTICo³ toolchain to support the Monitor infrastructure.
- `monitor_integration_artico3.sh`: Script that clones the ARTICo³ repository, copies the required files, and applies the appropriate patches.

## Installation

To set up the Monitor infrastructure on ARTICo³, run the following script:

```sh
source monitor_integration_artico3.sh
```

## Usage

After installation, you can create an ARTICo³ application following the design flow described in the [ARTICo³ Repository](https://github.com/des-cei/artico3.git). To enable the Monitor infrastructure, remember to:
1. Select the appropriate ARTICo³ template in the `build.cfg` file of the application.
2. Export the Monitor software library with `export_sw -m`.

_Note: The software app (`main.c`) must be updated with the appropriate Monitor library functions to perform trace acquisition at runtime._

In `files_to_integrate/demos/`, you can find a set of ARTICo³ demo applications with these monitoring capabilities enabled. Those apps will also appear in `artico3/demos/` after the [Installation process](#installation) has been performed.




