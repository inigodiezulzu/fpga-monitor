#!/usr/bin/env python3

import os
import shutil
import scripts.power_consumption_traces as power
import scripts.performance_traces as performance
import scripts.performance_traces_axi as performance_axi
import scripts.traces_plotter as traces_plotter
import scripts.traces_plotter_axi as traces_plotter_axi
import yaml

# Validate the yaml config file
def validate_yaml(file_path):

    config_parameters = {}

    with open(file_path, "r") as f:
        config_yaml = yaml.safe_load(f)

        config_parameters["filter_enabled"]         = config_yaml['TOOL']['FILTERING']["ENABLED"]
        config_parameters["filter_order"]           = config_yaml['TOOL']['FILTERING']["ORDER"]
        config_parameters["filter_fs"]              = config_yaml['TOOL']['FILTERING']["FS"]
        config_parameters["filter_cutoff"]          = config_yaml['TOOL']['FILTERING']["CUTOFF"]
        config_parameters["axi_bus_enabled"]        = config_yaml['TOOL']['OPTIONAL_PARAMETERS']['AXI_BUS_ENABLED']
        config_parameters["dual_monitor_enabled"]   = config_yaml['TOOL']['OPTIONAL_PARAMETERS']['DUAL_MONITOR_ENABLED']
        config_parameters["freq_sys_mhz"]           = config_yaml['TOOL']['OPTIONAL_PARAMETERS']['SAMPLING_FREQUENCY_MHZ']
        config_parameters["number_signals"]         = config_yaml['TOOL']['OPTIONAL_PARAMETERS']['NUMBER_SIGNALS']
        config_parameters["number_axi_events"]      = config_yaml['TOOL']['OPTIONAL_PARAMETERS']['NUMBER_AXI_EVENTS']
        config_parameters["adc_reference_voltage"]  = config_yaml['MEASUREMENT_BOARD']['ADC_REFERENCE_VOLTAGE']
        config_parameters["adc_gain"]               = config_yaml['MEASUREMENT_BOARD']['ADC_GAIN']
        config_parameters["adc_resolution"]         = config_yaml['MEASUREMENT_BOARD']['ADC_RESOLUTION']
        config_parameters["shunt_resistor"]         = config_yaml['MEASUREMENT_BOARD']['SHUNT_RESISTOR']
        config_parameters["shunt_resistor_2"]       = config_yaml['MEASUREMENT_BOARD']['SHUNT_RESISTOR_2']
        config_parameters["vdd"]                    = config_yaml['MEASUREMENT_BOARD']['VDD']
       
        if config_parameters["filter_enabled"] is None:
            print("Config file error: [TOOL > FILTERING > ENABLED]")
            exit(0)

        if config_parameters["filter_order"] is None:
            print("Config file error: [TOOL > FILTERING > ORDER]")
            exit(0)

        if config_parameters["filter_fs"] is None:
            print("Config file error: [TOOL > FILTERING > FS]")
            exit(0)

        if config_parameters["filter_cutoff"] is None:
            print("Config file error: [TOOL > FILTERING > CUTOFF]")
            exit(0)
            
        if config_parameters["adc_reference_voltage"] is None:
            print("Config file error: [MEASUREMENT_BOARD > ADC_REFERENCE_VOLTAGE]")
            exit(0)
            
        if config_parameters["adc_gain"] is None:
            print("Config file error: [MEASUREMENT_BOARD > ADC_GAIN]")
            exit(0)
            
        if config_parameters["adc_resolution"] is None:
            print("Config file error: [MEASUREMENT_BOARD > ADC_RESOLUTION]")
            exit(0)
            
        if config_parameters["shunt_resistor"] is None:
            print("Config file error: [MEASUREMENT_BOARD > SHUNT_RESISTOR]")
            exit(0)
            
        if config_parameters["vdd"] is None:
            print("Config file error: [MEASUREMENT_BOARD > VDD]")
            exit(0)

        return config_parameters

# Get config file
config_parameters = validate_yaml("config/config.yaml")

print(config_parameters)


# Remove old temporal directories if exist (due to a previous runtime exception) 
try:
    shutil.rmtree(os.getcwd() + '/tmp')
except:
    pass
try:
    shutil.rmtree(os.getcwd() + '/parsed_data')
except:
    pass

# Parse power consumption binary file
power.parse_file()

# User indicates if Bus Monitorization capabilities are enabled
bus_monitoring_user_input = config_parameters["axi_bus_enabled"]
if bus_monitoring_user_input == None:
    bus_monitoring_user_input = raw_input("\nAXI Bus Monitorization Enabled? (y/n): ")

# Execute trace parser and data ploter scripts coherent with user's selection
if(bus_monitoring_user_input in ['y','Y',True]):
    performance_axi.parse_file()
    traces_plotter_axi.plot_traces(config_parameters)
elif(bus_monitoring_user_input in ['n','N',False]):
    performance.parse_file()
    traces_plotter.plot_traces(config_parameters)
else:
    print("\n'{}' is wrong option. Try again.".format(bus_monitoring_user_input))

# Remove temporal parsed data directory
shutil.rmtree(os.getcwd() + '/parsed_data')





