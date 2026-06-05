# Power Consumption and Performance Traces Visualization Tool

This tool provides a comprehensive way to visualize power consumption and performance traces for FPGA-based systems obtained with the Monitoring IP.

## Prerequisites

Install system packages (virtualenv and PyQt6) and create a Python virtual environment with `virtualenv`:

```sh
sudo apt-get update
sudo apt-get install -y virtualenv python3-pyqt6
```

Create and activate a virtual environment, then install the Python requirements:

```sh
virtualenv env
source env/bin/activate
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

