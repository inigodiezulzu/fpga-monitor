from __future__ import division
import matplotlib.pyplot as pyplot
from matplotlib import gridspec
from matplotlib.widgets import MultiCursor
from matplotlib.backend_tools import ToolBase
pyplot.rcParams["toolbar"] = "toolmanager"
import os
import shutil
import warnings
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

# Plotting traces 
def plot_traces(config_parameters):

    ####################### Consumption Ploter ###############################

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

    # y limit depends on the number of traces
    subplot.set_ylim([-0.5,(signals * 2) - 0.5])

    # x limit depends on the adqusition time
    subplot.set_xlim([0,time_adc])

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
            # line format "iteration (not needed), timestamp, probes"
            _,timestamp,probes = line.split(",")
            
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
                    signal_file[i].writelines("end" + "," + str(time_adc) + "," + str(signal_value_bit) + "\n")

            cont +=1

    # Close all signal files
    for i in range(signals):
        signal_file[i].close()

    # Plot each signal and add labels
    for i in range(signals):
        signal_monitor_labels.append(plot_signal(i, time_adc, signals_label[i]))
        # Each signal takes two rows, so the upper one needs an empty label
        signal_monitor_labels.append("")          


    ####################### Matplot Configuration ############################

    # Remove x tickvalues from power subplot (they are already in the other)
    pyplot.setp(ax1.get_xticklabels(), visible=False)

    # Each trace has two tick values, hence, the overall tickvalues are the
    # range of 2 * number of signals
    subplot.set_yticks(range(2*signals))

    subplot.set_yticklabels(signal_monitor_labels,fontsize=13,verticalalignment="baseline")

    # Vertical cursor configuration
        
    # Execute trace parser and data ploter scripts coherent with user's selection
    if dual:
        multi = MultiCursor(fig.canvas, (ax1,ax2,subplot), color='r', lw=1)
        multi.visible = False
    else:
        multi = MultiCursor(fig.canvas, (ax1,subplot), color='r', lw=1)
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

    # Add cursor gui button to the navigation bar
    fig.canvas.manager.toolmanager.add_tool("Cursor", VerticalCursor)
    fig.canvas.manager.toolbar.add_tool('Cursor', 'navigation', 1)

    # Show pyplot canvas and drawings
    print("\nVisualization tool opened...\n")
    pyplot.show()
    print("\nVisualization tool closed...")

    # Remove temporal directory
    shutil.rmtree(os.getcwd() + '/tmp')
