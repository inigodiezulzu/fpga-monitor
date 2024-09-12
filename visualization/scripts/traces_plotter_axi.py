from __future__ import division
import matplotlib.pyplot as pyplot
from matplotlib import gridspec
from matplotlib.widgets import MultiCursor, Cursor
from matplotlib.backend_tools import ToolBase
pyplot.rcParams["toolbar"] = "toolmanager"
import os
import shutil
import warnings
import pandas as pd
from tabulate import tabulate
import webbrowser
# Low-pass filter
import scripts.power_consumption_traces as power_module

#toolbase rise a warning, this removes it
warnings.simplefilter("ignore")

def plot_signal(signal_number, time_adc, signal_label=None):

    # X axis values
    x_values = []
    # Y axis values
    y_values = []
    # Set Y lower value, each signal must be places in top of the previous one
    y_values_lower_limit = []

    # Open file storing actual signal data
    file = open("tmp/signal_#" + str(signal_number) + ".txt", "r")

    graph_data = file.read()
    lines = graph_data.split("\n")

    for line in lines:
        if len(line) > 1:
	    # Stored data format "iter(not needed), timestamp, value"
            _,timestamp, value = line.split(",")

        x_values.append(float(timestamp))

        # Y value  = y_actual_value + offset
        # offset is the space needed to place to place this signal
        # on top of the previous one
        y_values.append(int(value) + (signal_number * 2))

	# Y_lower_limit = offset
        y_values_lower_limit.append(signal_number * 2)

    # Ploting horizontal lines to delimit the signal space
    pyplot.hlines(signal_number * 2 - 0.1, 0, time_adc, linestyle = "dashed")
    pyplot.hlines(signal_number * 2 + 1.1, 0, time_adc, linestyle = "dashed")

    # Plot a step function
    # where="post" indicates in interval (x[i],x[i+1]) the value is y[i]
    pyplot.step(x_values, y_values, where="post")

    # Add color to the signal
    pyplot.fill_between(x_values, y_values_lower_limit, y_values, alpha = 0.2, step = "post")

    file.close()

    # User user defined label if exist, otherwise user the signal number
    if signal_label is not None:
	    label = signal_label
    else:
    	label = "Signal #" + str(signal_number)
    return label


def plot_axi_event(event_masks, mask_number, signal_position):# mask_number es el numero asociado a la mascara, signal_position es la posicion en altura del bit que se va a dibujar, se usa para calcular bien el valor de la senyal (si es el  bit 4 seran valores de 8 a 9)

    # X axis values
    x_values = []
    # Y axis values
    y_values = []
    # Set Y lower value, each signal must be places in top of the previous one
    y_values_lower_limit = []

    # Open file storing actual axi event data
    file = open("tmp/axi_event_#" + str(mask_number) + ".txt", "r")

    graph_data = file.read()
    lines = graph_data.split("\n")

    for line in lines:
        if len(line) > 1:
	        # Stored data format "iter(not needed), timestamp, value"
            _,timestamp, value = line.split(",")

        x_values.append(float(timestamp))

        # Y value  = y_actual_value + offset
        # offset is the space needed to place to place this signal
        # on top of the previous one
        y_values.append(int(value) + (signal_position * 2))

	    # Y_lower_limit = offset
        y_values_lower_limit.append(signal_position * 2)

    # Ploting horizontal lines to delimit the signal space
    pyplot.hlines(signal_position * 2 - 0.1, 0, len(lines), linestyle = "dashed")
    pyplot.hlines(signal_position * 2 + 1.1, 0, len(lines), linestyle = "dashed")

    # Plot a step function
    # where="post" indicates in interval (x[i],x[i+1]) the value is y[i]
    pyplot.step(x_values, y_values, where="post")

    # Add color to the signal
    pyplot.fill_between(x_values, y_values_lower_limit, y_values, alpha = 0.2, step = "post")

    file.close()

    # AXI hex event mask is used as the label
    label = "AXI Event\n(" + str(hex(event_masks[mask_number])) + ")"
    return label

# Plotting traces
def plot_traces(config_parameters):

    ####################### Consumption Ploter ###############################

    adc_enabled = config_parameters["adc_enabled"]

    if adc_enabled not in ['y','Y',True]:

        # Create a window with 1 plot
        fig = pyplot.figure(tight_layout=True)
        fig.canvas.set_window_title("Signal Monitor")
        gs = gridspec.GridSpec(1, 1)
        subplot = fig.add_subplot(gs[0])

        # Ask for the system sampling frequency
        # used to convert elapsed cycles to time
        freq_sys_mhz = config_parameters["freq_sys_mhz"]
        if freq_sys_mhz == None:
            freq_sys_mhz = input("Introduce the sample frequency (MHz): ")

        print(freq_sys_mhz, type(freq_sys_mhz))

    else:

        # User indicates if dual monitorization is enabled
        dual_monitoring_user_input = config_parameters["dual_monitor_enabled"]
        if dual_monitoring_user_input == None:
            dual_monitoring_user_input = raw_input("\nDual Monitorization Enabled? (y/n): ")

        # Dual monitoring indicatos
        dual = False

        if(dual_monitoring_user_input in ['y','Y',True]):
            dual = True
        elif(dual_monitoring_user_input in ['n','N',False]):
            dual = False
        else:
            print("\n'{}' is wrong option. Try again.".format(dual_monitoring_user_input))
            exit(1)

        # Execute trace parser and data ploter scripts coherent with user's selection
        if dual:

            # Create a window with 3 plots in a 1/1/2 ratio
            fig = pyplot.figure(tight_layout=True)
            fig.canvas.set_window_title("Signal Monitor")
            gs = gridspec.GridSpec(3, 1, height_ratios=[1, 1, 2])
            ax1 = fig.add_subplot(gs[0])
            ax2 = fig.add_subplot(gs[1],sharex = ax1)

            # Add a subplot to the main window and set limits and x label
            subplot = fig.add_subplot(gs[2],sharex = ax1)

            # Plot power consumption traces
            time_adc, freq_sys_mhz = power_module.plot_power_dual(config_parameters,ax1,ax2)

            # Remove x tickvalues from power subplot (they are already in the other)
            pyplot.setp(ax1.get_xticklabels(), visible=False)
            pyplot.setp(ax2.get_xticklabels(), visible=False)

        else :

            # Create a window with 2 plots in a 3/1 ratio
            fig = pyplot.figure(tight_layout=True)
            fig.canvas.set_window_title("Signal Monitor")
            gs = gridspec.GridSpec(2, 1, height_ratios=[1, 3])
            ax1 = fig.add_subplot(gs[0])

            # Add a subplot to the main window and set limits and x label
            subplot = fig.add_subplot(gs[1],sharex = ax1)

            # Plot power consumption traces
            time_adc, freq_sys_mhz = power_module.plot_power_mono(config_parameters,ax1)

            # Remove x tickvalues from power subplot (they are already in the other)
            pyplot.setp(ax1.get_xticklabels(), visible=False)


    ########################### Traces Ploter ################################


    signal_file = []
    subplots = []
    signal_monitor_labels = []

    # Read traces
    graph_data = open("parsed_data/sig.txt", "r").read()
    lines = graph_data.split("\n")

    # Ask user how many traces to be displayed (names can also be introduced)
    input_aux = config_parameters["number_signals"]
    if input_aux == None:
        input_aux = list(str(raw_input("Introduce amount of signals monitored: ")).split())
    else:
        input_aux = list(str(input_aux).split())
    print(input_aux)

    # Get fist user input value, is the number of signals to display
    signals = int(input_aux.pop(0))

    # Generate an initial label array with "num_signals" None values
    signals_label = [None] * signals

    # If the user has introduced trace labels add them to the trace labels
    if len(input_aux) > 0:
        for i in range(len(input_aux)):
            if i < signals:
                signals_label[i] = input_aux[i]

    # Ask user how many AXI events to monitor
    num_axi_plots = config_parameters["number_axi_events"]
    if num_axi_plots == None:
        num_axi_plots = input("\nIntroduce the number of specific AXI events to be monitored: ")

    # Add a subplot to the main window and set limits and x label
    if dual:
        subplot = fig.add_subplot(gs[2],sharex = ax1)
    else:
        subplot = fig.add_subplot(gs[1],sharex = ax1)

    # y limit depends on the number of traces
    subplot.set_ylim([-0.5,((signals + num_axi_plots) * 2) - 0.5])

    subplot.set_xlabel("Time (ms)", fontsize=15)

    # Make a temporal directory to store trace files
    os.makedirs(os.getcwd()+"/tmp")

    ## Trace temporal files generation ##

    cont = 1

    # Open a file per signal and generate an array with each file manager
    for i in range(signals):
        signal_file.append( open("tmp/signal_#" + str(i) + ".txt", "w+") )

    # Process signals
    for iteration, line in enumerate(lines):

        if len(line) > 1:
            # line format "iteration (not needed), timestamp, probes, empty"
            _,timestamp,probes,empty = line.split(",")

            # Time = timestamp (cycles) / sampling_frequency (Hz)
            time = float(timestamp) / (freq_sys_mhz * 1000) # freq_sys_mhz in MHz

            # First data is initial value, the other are events
            if cont == 1 :
                prev_values  = int(probes)
                event_values = 0
            else :
                event_values = int(probes)

            # Regenerate the events
            signal_values = event_values ^ prev_values
            prev_values = signal_values

            # Loop over each signal to get its correcponding bit and
            # write it to its temporal file
            for i in range(signals):

                signal_value_bit = (signal_values & (0x1 << i)) >> i

                # writing format "cont,time,signal_value_bit\n"
                signal_file[i].writelines(str(cont) + "," + str(time) + "," + str(signal_value_bit) + "\n")

                # last iteration have and "end" flag when written
                # (have in mind iterations starts at 0 and the last line is \n)
                if iteration == len(lines)-2 :
                    if adc_enabled in ['y','Y',True]:
                        signal_file[i].writelines("end" + "," + str(time_adc) + "," + str(signal_value_bit) + "\n")
                    else:
                        signal_file[i].writelines("end" + "," + str(time+0.2) + "," + str(signal_value_bit) + "\n")

            cont +=1

    # Close all signal files
    for i in range(signals):
        signal_file[i].close()


    ## AXI Events Processing ##


    # Open a temporal file to store AXI sniffer data
    axi_sniffing_file = open("tmp/AXI_Sniffing.txt", "w+")

    axi_files = []

    axi_event_masks = []

    cont = 1

    # Open a file per AXI event introduced by user
    # and generate an array with each file manager
    for i in range(num_axi_plots):
        axi_event_masks.append(int(input("\nIntroduce AXI event mask #"+str(i)+" in hex (0x42): ")))
        axi_files.append( open("tmp/axi_event_#" + str(i) + ".txt", "w+") )

    # Process AXI events
    for iteration, line in enumerate(lines):

        if len(line) > 1:
            # line format "iteration (not needed), timestamp, empty, value"
            _,timestamp,empty,value = line.split(",")

            # Time = timestamp (cycles) / sampling_frequency (Hz)
            time = float(timestamp) / (freq_sys_mhz * 1000) # freq_sys_mhz in MHz

            # First data is initial value, the other are events
            if cont == 1 :
                prev_values  = int(value)
                event_values = 0
            else :
                event_values = int(value)

            # Regenerate the events
            signal_values = event_values ^ prev_values
            prev_values = signal_values

            axi_addr_value_bits = (signal_values & 0xFFFFFC00) >> 10	# Nos quedamos con los bits 31 downto 10 y desplazamos 10 a la dcha
            axi_data_value_bits = (signal_values & 0x3FC) >> 2   		# Nos quedamos con los bits 9 downto 2 y desplazamos 2 a la dcha
            axi_valid_value_bits = (signal_values & 0x2) >> 1  			# Nos quedamos con el bit 1 y desplazamos 1 a la dcha
            axi_ready_value_bits = (signal_values & 0x1)   				# Nos quedamos con el bit 0

            # Guardamos los datos en un fichero temporal
            axi_sniffing_file.writelines(str(cont) + "," + str(time) + "," + str(hex(axi_addr_value_bits)) + "," + str(hex(axi_data_value_bits)) + "," + str(axi_valid_value_bits) + "," + str(axi_ready_value_bits) + "\n")

            if iteration == len(lines)-2 : # -2 porque hay un /n al final y ademas empieza en 0 la iteracion
                if adc_enabled in ['y','Y',True]:
                    axi_sniffing_file.writelines("end" + "," + str(time_adc) + "," + str(hex(axi_addr_value_bits)) + "," + str(hex(axi_data_value_bits)) + "," + str(axi_valid_value_bits) + "," + str(axi_ready_value_bits) + "\n")
                else:
                    axi_sniffing_file.writelines("end" + "," + str(time+0.2) + "," + str(hex(axi_addr_value_bits)) + "," + str(hex(axi_data_value_bits)) + "," + str(axi_valid_value_bits) + "," + str(axi_ready_value_bits) + "\n")

            # Loop over each axi event to check if matches actual events and
            # write it to its temporal file
            for i in range(num_axi_plots):

                signal_value_bit = 1 if signal_values == axi_event_masks[i] else 0  # high value if events match mask

                # writing format "cont,time,signal_value_bit\n"
                axi_files[i].writelines(str(cont) + "," + str(time) + "," + str(signal_value_bit) + "\n")

                # last iteration have and "end" flag when written
                # (have in mind iterations starts at 0 and the last line is \n)
                if iteration == len(lines)-2 :
                    if adc_enabled in ['y','Y',True]:
                        axi_files[i].writelines("end" + "," + str(time_adc) + "," + str(signal_value_bit) + "\n")
                    else:
                        axi_files[i].writelines("end" + "," + str(time+0.2) + "," + str(signal_value_bit) + "\n")

            cont +=1

    # Close AXI data file
    axi_sniffing_file.close()

    # Close all axi_event files
    for i in range(num_axi_plots):
        axi_files[i].close()

    # Plot each signal and add labels
    for i in range(signals):
        if adc_enabled in ['y','Y',True]:
            signal_monitor_labels.append(plot_signal(i, time_adc, signals_label[i]))
        else:
            signal_monitor_labels.append(plot_signal(i, time + 0.2, signals_label[i]))
        # Each signal takes two rows, so the upper one needs an empty label
        signal_monitor_labels.append("")

    # x limit depends on the adqusition time
    if adc_enabled in ['y','Y',True]:
        subplot.set_xlim([0,time_adc])
    else:
        subplot.set_xlim([0,time+0.2])

    ## Plot AXI masks and generate AXI info html file ##

    # Increment i to place AXI event on top of signals
    i+=1

    # Plot each AXI Event and add labels
    for j in range(num_axi_plots):
        signal_monitor_labels.append(plot_axi_event(axi_event_masks, j, j+i))   # El numero empieza en cero, para la posicion hay que tener en cuenta las senyales dibujadas anteriormente
        # Each signal takes two rows, so the upper one needs an empty label
        signal_monitor_labels.append("")

    # Generate pandas dataframe with AXI bus communications
    axi_header_list = ["Index","Time(ms)","Address","Data","Valid","Ready"]
    axi_communications_df = pd.read_csv("tmp/AXI_Sniffing.txt", names=axi_header_list)
    axi_communications_df.drop(columns=["Index"],inplace = True)

    # Apply highlight format to each communication that matches an AXI event mask
    axi_events_selector = ""
    for mask in axi_event_masks:
        axi_events_selector = ( axi_communications_df["Address"] == hex((mask & 0xFFFFFC00) >> 10) ) & ( axi_communications_df["Data"] == hex((mask & 0x3FC) >> 2) ) & ( axi_communications_df["Valid"] == ((mask & 0x2) >> 1) ) & ( axi_communications_df["Ready"] == (mask & 0x1) )
        # Highlight in red
        axi_communications_df.loc[axi_events_selector] = axi_communications_df.loc[axi_events_selector].applymap('<span style="color: green"><b>{}</b></span>'.format)

    # Apply bold format to each communication with valid and ready high
    axi_valid_ready_selector = (axi_communications_df["Valid"] == 1) & (axi_communications_df["Ready"] == 1)
    axi_communications_df.loc[axi_valid_ready_selector] = axi_communications_df.loc[axi_valid_ready_selector].applymap('<b>{}</b>'.format)

    # Convert dataframe to html
    axi_communications_html = axi_communications_df.to_html(index_names=False, justify="center",index=False,escape=False)

    #write html to file
    text_file = open("tmp/axi_communication.html", "w")

    html_header = "\
    <!DOCTYPE html>\n\
    <html>\n\
        <head>\n\
            <style>\n\
                table, th, td {\n\
                    border: 1px solid black;\n\
                }\n\
                th, td {\n\
                    padding: 10px;\n\
                }\n\
            </style>\n\
        </head>\n\
    <body>\n\n"

    text_file.write(html_header)
    text_file.write(axi_communications_html)
    text_file.close()


    ####################### Matplot Configuration ############################

    # Remove x tickvalues from power subplot (they are already in the other)
    if adc_enabled in ['y','Y',True]:
        pyplot.setp(ax1.get_xticklabels(), visible=False)

    # Each trace has two tick values, hence, the overall tickvalues are the
    # range of 2 * number of signals
    subplot.set_yticks(range(2*(signals+num_axi_plots)))

    subplot.set_yticklabels(signal_monitor_labels,fontsize=13,verticalalignment="baseline")

    # Vertical cursor configuration

    # Execute trace parser and data ploter scripts coherent with user's selection
    if adc_enabled in ['y','Y',True]:
        if dual:
            multi = MultiCursor(fig.canvas, (ax1,ax2,subplot), color='r', lw=1)
            multi.visible = False
        else:
            multi = MultiCursor(fig.canvas, (ax1,subplot), color='r', lw=1)
            multi.visible = False
    else:
        multi = Cursor(subplot, color='r', lw=1)
        multi.visible = False

    class VerticalCursor(ToolBase):
        """List all the tools controlled by the `ToolManager`."""
        # keyboard shortcut
        default_keymap = 'm'
        description = 'Vertical Cursor'
        image = os.path.join(os.getcwd(),"images/pointer_resized.png")

        # When the GUI button is pressed, the cursor visibility toggles
        def trigger(self, *args, **kwargs):
            multi.visible = not multi.visible
            if multi.visible is True:
                print("\tCursor visibility turned on.")
            else:
                print("\tCursor visibility turned off.")
            fig.canvas.draw()

    class AXIBusInfo(ToolBase):
        """List all the tools controlled by the `ToolManager`."""
        # keyboard shortcut
        default_keymap = 'n'
        description = 'Show AXI Bus Communication'
        #image = os.path.join(os.getcwd(),"images/pointer_resized.png")

        # When the GUI button is pressed, the html AXI information file opens
        def trigger(self, *args, **kwargs):
            webbrowser.open_new('file://' + os.path.realpath("tmp/axi_communication.html"))
            print("\tAXI Communications displayed in a browser window.")


    # Add cursor and AXI info gui buttons to the navigation bar
    fig.canvas.manager.toolmanager.add_tool("Cursor", VerticalCursor)
    fig.canvas.manager.toolbar.add_tool('Cursor', 'navigation', 1)
    axi_bus_info_toolbase = fig.canvas.manager.toolmanager.add_tool("AXI", AXIBusInfo)
    fig.canvas.manager.toolbar.add_tool('AXI', 'navigation', 1)

    # Show pyplot canvas and drawings
    print("\nVisualization tool opened...\n")
    pyplot.show()
    print("\nVisualization tool closed...")

    # Remove temporal directory
    shutil.rmtree(os.getcwd() + '/tmp')
