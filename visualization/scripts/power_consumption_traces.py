import struct
import os
import shutil
# Low-pass filter
import numpy as np
from scipy.signal import butter, lfilter, freqz, savgol_filter
import re
from shutil import copyfile

# Parse power consumption binary file
def parse_file():

    i = 0

    # Make temporal directory for parsed data
    os.makedirs(os.getcwd() + "/parsed_data")

    # Open a file to store power data after converting them from binary to integer
    power_store_file = open("parsed_data/con.txt", "w+")

    # Open power binary file in binary mode
    with open("../CON.BIN", "rb") as power_binary_file:

        # Each power data has one 4-bytes data (power)
        power = power_binary_file.read(4)

        # If f.read() return false means EOF
        while power:

            # If the first byte is 0 it means there's no more power data
            #if struct.unpack('I', power)[0] != 0 :
                # Format "iter, power"
            power_store_file.writelines("{}, {}\n".format(i,struct.unpack('I', power)[0]))

            # Each power data has one 4-bytes data (power)
            power = power_binary_file.read(4)
            # Next data
            i += 1

    # Close power consumption store file
    power_store_file.close()

# Butterworth lowpass funtions
def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a

def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y

# Butterworth lowpass filtering
def power_data_filtering(file,enabled,order,fs,cutoff):

    if enabled is True:
        data_raw = open("parsed_data/" + file, "r").read()
        data = re.findall(r'(?:\d, )(.*?)(?:\n)', data_raw)
        data = list(map(int, data))
        data_filtered = savgol_filter(data, window_length=31, polyorder=3, mode="nearest")

        #data_raw = open("parsed_data/" + file, "r").read()
        #data = re.findall(r'(?:\d, )(.*?)(?:\n)', data_raw)
        #data = list(map(int, data))

        #data_filtered = butter_lowpass_filter(data, cutoff, fs, order)

        with open("parsed_data/" + file[:-7] + "filtered.txt", "w+") as file: # Use file to refer to the file object

            for element in data_filtered:
                file.write("x,{}\n".format(element))
    else:
        copyfile("parsed_data/" + file, "parsed_data/" + file[:-7] + "filtered.txt")


def plot_power_mono(config_parameters, ax):

    # Read power consumption parsed file
    with open("parsed_data/con.txt", "r") as f:

        lines = f.readlines()

    # Pop last file value which contains
    # "total number of samples, total_number of cycles elapsed
    total_samples_consumption,total_cycles_consumption = lines.pop().split(",")

    # Write all power data in a new file (without popped data)
    with open("parsed_data/con_raw.txt", "w") as f:
        f.writelines(lines)

    # Filter power data
    power_data_filtering(\
        "con_raw.txt",\
        config_parameters["filter_enabled"],\
        int(config_parameters["filter_order"]),\
        int(config_parameters["filter_fs"]),\
        int(config_parameters["filter_cutoff"]))

    # Plot Power Traces (if adc_measurement_board is True, rshunt_index=0)
    if config_parameters["adc_measurement_board"] is True:
        return plot_power_traces(False, config_parameters,"con_filtered.txt",ax,total_cycles_consumption,total_samples_consumption,rshunt_index=0)
    else:
        return plot_power_traces(False, config_parameters,"con_filtered.txt",ax,total_cycles_consumption,total_samples_consumption,rshunt_index=None)



def plot_power_dual(config_parameters, ax1,ax2):

    # Read power consumption parsed file
    with open("parsed_data/con.txt", "r") as f:

        lines = f.readlines()

    # Pop last file value which contains
    # "total number of samples, total_number of cycles elapsed
    total_samples_consumption,total_cycles_consumption = lines.pop().split(",")

    # Samples are interleaved, so the number of samples is actually a half
    total_samples_consumption = int(total_samples_consumption) / 2

    # Separate both power traces
    top_traces = lines[0::2]
    bottom_traces = lines[1::2]

    # Write all power data in a new file (without popped data)
    with open("parsed_data/con_top_raw.txt", "w") as f:
        f.writelines(top_traces)

    # Write all power data in a new file (without popped data)
    with open("parsed_data/con_bottom_raw.txt", "w") as f:
        f.writelines(bottom_traces)

    # Filter power data
    power_data_filtering(\
        "con_top_raw.txt",\
        config_parameters["filter_enabled"],\
        int(config_parameters["filter_order"]),\
        int(config_parameters["filter_fs"]),\
        int(config_parameters["filter_cutoff"]))

    # Filter power data
    power_data_filtering(\
        "con_bottom_raw.txt",\
        config_parameters["filter_enabled"],\
        int(config_parameters["filter_order"]),\
        int(config_parameters["filter_fs"]),\
        int(config_parameters["filter_cutoff"]))

    # Plot Power Traces
    plot_power_traces(True, config_parameters,"con_top_filtered.txt",ax1,total_cycles_consumption,total_samples_consumption,rshunt_index=0)
    return plot_power_traces(True, config_parameters,"con_bottom_filtered.txt",ax2,total_cycles_consumption,total_samples_consumption,rshunt_index=1)



def plot_power_traces(dual, config_parameters,file,ax, total_cycles_consumption,total_samples_consumption,rshunt_index):


    cycles = 1
    x_values = []
    y_values = []

    # Read power filtered data
    graph_data = open("parsed_data/" + file, "r").read()
    lines = graph_data.split("\n")

    # Ask for the system sampling frequency
    # used to convert elapsed cycles to time
    freq_sys_mhz = config_parameters["freq_sys_mhz"]
    if freq_sys_mhz == None:
        freq_sys_mhz = input("Introduce the sample frequency (MHz): ")

    cycles_per_consumption_sample = int(total_cycles_consumption) / int(total_samples_consumption)
    time_per_consumption_sample_us = cycles_per_consumption_sample / freq_sys_mhz #us

    time_adc = 0.0

    # Power conversion formula
    if rshunt_index == None:
        # TODO: implement this case
        raise NotImplementedError
    else:
        adc_reference_voltage = float(config_parameters["adc_reference_voltage"])
        adc_gain = float(config_parameters["adc_gain"])
        adc_resolution = int(config_parameters["adc_resolution"])
        if rshunt_index == 0:
            shunt_resistor = float(config_parameters["shunt_resistor"] / 1000) # convert from mOhm to Ohm
        else:
            shunt_resistor = float(config_parameters["shunt_resistor_2"] / 1000) # convert from mOhm to Ohm

        vdd = float(config_parameters["vdd"])

        #                              Vref * READ_VALUE
        # P = VDD * Ishunt = VDD * --------------------------- = CONVERSION_FACTOR * READ_VALUE
        #                           2^resolucion * K * Rshunt

        power_conversion_factor = (vdd * adc_reference_voltage) / (2**adc_resolution * adc_gain * shunt_resistor)

    for line in lines:

        if len(line) > 1:
            # line format "iteration (not needed), power"
            _, power = line.split(",")

            # x value = time; y value = power
            # power has to be converted from adc digital value to watts
            x_values.append(time_adc)
            y_values.append(float(power) * power_conversion_factor)

            # Increment cycles and calculate next time value
            cycles +=1
            time_adc = cycles * time_per_consumption_sample_us / 1000 # ms

    # Clear the plot
    ax.clear()

    y_max = max(y_values)
    y_min = min(y_values)
    y_range = y_max - y_min

    # Set y limit a bit bigger than y range
    ax.set_ylim([y_min - 0.2*y_range, y_max + 0.2*y_range])
    # Set x limit according to time
    ax.set_xlim([0,time_adc])

    if dual == True:
        ax.set_ylabel(str(file.split("_")[1].capitalize() + " Rail\nPower (W)"), fontsize=15)
    else:
        ax.set_ylabel("Power (W)", fontsize=15)
    ax.plot(x_values, y_values)

    return time_adc, freq_sys_mhz


