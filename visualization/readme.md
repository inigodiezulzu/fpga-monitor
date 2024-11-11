# Power Consumption and Performance Traces Visualization Tool

This tool provides a comprehensive way to visualize power consumption and performance traces for FPGA-based systems obtained with the Monitoring IP.

## Prerequisites

Ensure you have the required Python packages installed. You can install them using the following command:

```sh
pip install -r requirements.txt
```

## Setup

1. Place the `CON.BIN` and `SIG.BIN` traces files obtained with the Monitoring IP in a known directory.
2. Modify the `config/config.yaml` configuration file to match your setup.

## Usage

To run the visualization tool, execute the following command:

```sh
python visualize.py -i <path_to_traces_directory>
```

