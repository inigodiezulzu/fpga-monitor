#
# ARTICo3 IP library script for Vivado
#
# Author      : Alfonso Rodriguez <alfonso.rodriguezm@upm.es>
# Date        : August 2017
#
# Description : This script generates a full system in Vivado using the
#               IP library created by create_ip_library.tcl by instantiating
#               the required modules and making the necessary connections.
#

<a3<artico3_preproc>a3>

variable script_file
set script_file "export.tcl"

# Help information for this script
proc help {} {

    variable script_file
    puts "\nDescription:"
    puts "This TCL script sets up all modules and connections in an IP integrator"
    puts "block design needed to create a fully functional ARTICo3 design.\n"
    puts "Syntax when called in batch mode:"
    puts "vivado -mode tcl -source $script_file -tclargs \[-proj_name <Name> -proj_path <Path>\]"
    puts "$script_file -tclargs \[--help\]\n"
    puts "Usage:"
    puts "Name                   Description"
    puts "-------------------------------------------------------------------------"
    puts "-proj_name <Name>        Optional: When given, a new project will be"
    puts "                         created with the given name"
    puts "-proj_path <path>        Path to the newly created project"
    puts "\[--help\]               Print help information for this script"
    puts "-------------------------------------------------------------------------\n"
    exit 0

}

set artico3_ip_dir [pwd]/pcores
set proj_name ""
set proj_path ""

# Parse command line arguments
if { $::argc > 0 } {
    for {set i 0} {$i < [llength $::argc]} {incr i} {
        set option [string trim [lindex $::argv $i]]
        switch -regexp -- $option {
            "-proj_name" { incr i; set proj_name  [lindex $::argv $i] }
            "-proj_path" { incr i; set proj_path  [lindex $::argv $i] }
            "-help"      { help }
            default {
                if { [regexp {^-} $option] } {
                    puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
                    return 1
                }
            }
        }
    }
}

proc artico3_hw_setup {new_project_path new_project_name artico3_ip_dir} {

    # Create new project if "new_project_name" is given.
    # Otherwise current project will be reused.
    if { [llength $new_project_name] > 0} {
        create_project -force $new_project_name $new_project_path -part xcu250-figd2104-2L-e
    }

    # Save directory and project names to variables for easy reuse
    set proj_name [current_project]
    set proj_dir [get_property directory [current_project]]

    # Set project properties
    #set_property "board_part_repo_paths" -value "[file normalize "$/tools/Xilinx/Vivado/2024.2/data/xhub/boards/XilinxBoardStore/boards/Xilinx"]" $proj_name
    set_property "default_lib" "xil_defaultlib" $proj_name
    set_property "sim.ip.auto_export_scripts" "1" $proj_name
    set_property "simulator_language" "Mixed" $proj_name
    set_property "target_language" "VHDL" $proj_name
    

    # Create 'sources_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sources_1] ""]} {
        create_fileset -srcset sources_1
    }

    # Create 'constrs_1' fileset (if not found)
    if {[string equal [get_filesets -quiet constrs_1] ""]} {
        create_fileset -constrset constrs_1
    }

    # Create 'sim_1' fileset (if not found)
    if {[string equal [get_filesets -quiet sim_1] ""]} {
        create_fileset -simset sim_1
    }

    # Set 'sim_1' fileset properties
    set obj [get_filesets sim_1]
    set_property "transport_int_delay" "0" $obj
    set_property "transport_path_delay" "0" $obj
    set_property "xelab.nosort" "1" $obj
    set_property "xelab.unifast" "" $obj
# VIVADO CONFIGURATION
    # Create 'synth_1' run (if not found)
	if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xcu250-figd2104-2L-e -flow {Vivado Synthesis 2024} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
	} else {
	  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
	  set_property flow "Vivado Synthesis 2024" [get_runs synth_1]
	}
# END

    # Apply custom configuration for Synthesis
    set obj [get_runs synth_1]
    set_property "steps.synth_design.args.flatten_hierarchy" "rebuilt" $obj

    # set the current synth run
    current_run -synthesis [get_runs synth_1]

	
# VIVADO CONFIGURATION
    # Create 'impl_1' run (if not found)
    if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xcu250-figd2104-2L-e -flow {Vivado Implementation 2024} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
	} else {
	  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
	  set_property flow "Vivado Implementation 2024" [get_runs impl_1]
	}

# END

    # Apply custom configuration for Implementation
    set obj [get_runs impl_1]
    set_property "steps.write_bitstream.args.mask_file" false $obj
    set_property "steps.write_bitstream.args.bin_file" false $obj
    set_property "steps.write_bitstream.args.readback_file" false $obj
    set_property "steps.write_bitstream.args.verbose" false $obj

    # set the current impl run
    current_run -implementation [get_runs impl_1]

	# Adding sources referenced in BDs, if not already added
	if { [get_files a3_slot.vhd] == "" } {
	import_files -quiet -fileset sources_1 pcores/artico3_slot/a3_slot.vhd
	}

    #
    # Start block design
    #

    create_bd_design "system"
    update_compile_order -fileset sources_1
	
    # Add artico3 repository
    set_property  ip_repo_paths $artico3_ip_dir [current_project]
    update_ip_catalog
    
	# Set board template
    set_property board_part xilinx.com:au250:part0:1.3 [current_project]

	# Create interface ports
	set S00_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI_0 ]
	set_property -dict [ list \
	CONFIG.ADDR_WIDTH {32} \
	CONFIG.ARUSER_WIDTH {0} \
	CONFIG.AWUSER_WIDTH {0} \
	CONFIG.BUSER_WIDTH {0} \
	CONFIG.DATA_WIDTH {32} \
	CONFIG.HAS_BRESP {1} \
	CONFIG.HAS_BURST {0} \
	CONFIG.HAS_CACHE {0} \
	CONFIG.HAS_LOCK {0} \
	CONFIG.HAS_PROT {1} \
	CONFIG.HAS_QOS {0} \
	CONFIG.HAS_REGION {0} \
	CONFIG.HAS_RRESP {1} \
	CONFIG.HAS_WSTRB {1} \
	CONFIG.ID_WIDTH {0} \
	CONFIG.NUM_READ_OUTSTANDING {1} \
	CONFIG.NUM_READ_THREADS {1} \
	CONFIG.NUM_WRITE_OUTSTANDING {1} \
	CONFIG.NUM_WRITE_THREADS {1} \
	CONFIG.PROTOCOL {AXI4LITE} \
	CONFIG.READ_WRITE_MODE {READ_WRITE} \
	CONFIG.RUSER_BITS_PER_BYTE {0} \
	CONFIG.RUSER_WIDTH {0} \
	CONFIG.WUSER_BITS_PER_BYTE {0} \
	CONFIG.WUSER_WIDTH {0} \
	] $S00_AXI_0

	set S00_AXI_1 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI_1 ]
	set_property -dict [ list \
	CONFIG.ADDR_WIDTH {32} \
	CONFIG.ARUSER_WIDTH {1} \
	CONFIG.AWUSER_WIDTH {1} \
	CONFIG.BUSER_WIDTH {1} \
	CONFIG.DATA_WIDTH {32} \
	CONFIG.HAS_BRESP {1} \
	CONFIG.HAS_BURST {1} \
	CONFIG.HAS_CACHE {1} \
	CONFIG.HAS_LOCK {1} \
	CONFIG.HAS_PROT {1} \
	CONFIG.HAS_QOS {1} \
	CONFIG.HAS_REGION {0} \
	CONFIG.HAS_RRESP {1} \
	CONFIG.HAS_WSTRB {1} \
	CONFIG.ID_WIDTH {12} \
	CONFIG.MAX_BURST_LENGTH {256} \
	CONFIG.NUM_READ_OUTSTANDING {2} \
	CONFIG.NUM_READ_THREADS {1} \
	CONFIG.NUM_WRITE_OUTSTANDING {2} \
	CONFIG.NUM_WRITE_THREADS {1} \
	CONFIG.PROTOCOL {AXI4} \
	CONFIG.READ_WRITE_MODE {READ_WRITE} \
	CONFIG.RUSER_BITS_PER_BYTE {0} \
	CONFIG.RUSER_WIDTH {0} \
	CONFIG.SUPPORTS_NARROW_BURST {1} \
	CONFIG.WUSER_BITS_PER_BYTE {0} \
	CONFIG.WUSER_WIDTH {0} \
	] $S00_AXI_1

	set M00_AXI_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI_0 ]
	set_property -dict [ list \
	CONFIG.ADDR_WIDTH {32} \
	CONFIG.DATA_WIDTH {32} \
	CONFIG.PROTOCOL {AXI4} \
	] $M00_AXI_0

	# Create ports
	set s_axi_aclk [ create_bd_port -dir I -type clk s_axi_aclk -freq_hz 100000000]
	set_property -dict [ list \
	CONFIG.ASSOCIATED_BUSIF {S00_AXI_0:S00_AXI_1:M00_AXI_0} \
	CONFIG.ASSOCIATED_RESET {s_axi_aresetn} \
	] $s_axi_aclk
	set s_axi_aresetn [ create_bd_port -dir I -type rst s_axi_aresetn ]
	set interrupt [ create_bd_port -dir O -from 3 -to 0 -type intr interrupt ]


	# Create instance: axi_traffic_gen_0, and set properties
	set axi_traffic_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_traffic_gen:3.0 axi_traffic_gen_0 ]

	
# APPLICATION CONFIGURATION

    # Create instance of ARTICo3 infrastructure
    set artico3_shuffler_0 [ create_bd_cell -type ip -vlnv cei.upm.es:artico3:artico3_shuffler:1.0 artico3_shuffler_0 ]

    # Create instances of hardware kernels
<a3<generate for SLOTS>a3>
	set block_name a3_slot
	set block_cell_name a3_slot_<a3<id>a3>
	if { [catch {set a3_slot_<a3<id>a3> [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
		catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
		return 1
	} elseif { $a3_slot_<a3<id>a3> eq "" } {
		catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
		return 1
	}
<a3<end generate>a3>

	# Create instance: monitor_0, and set properties
	set monitor_0 [ create_bd_cell -type ip -vlnv cei.upm.es:artico3:monitor:1.0 monitor_0 ]
		set_property -dict [list \
		CONFIG.ADC_DUAL {false} \
		CONFIG.ADC_ENABLE {false} \
		CONFIG.ADC_VREF_IS_DOUBLE {false} \
		CONFIG.AXI_SNIFFER_DATA_WIDTH {0} \
		CONFIG.AXI_SNIFFER_ENABLE {false} \
		CONFIG.CLK_FREQ {100} \
		CONFIG.COUNTER_BITS {32} \
		CONFIG.C_S00_AXI_ADDR_WIDTH {4} \
		CONFIG.C_S00_AXI_DATA_WIDTH {32} \
		CONFIG.C_S01_AXI_ADDR_WIDTH {8} \
		CONFIG.C_S01_AXI_DATA_WIDTH {32} \
		CONFIG.C_S02_AXI_ADDR_WIDTH {17} \
		CONFIG.C_S02_AXI_DATA_WIDTH {64} \
		CONFIG.NUMBER_PROBES {32} \
		CONFIG.SCLK_FREQ {20} \
		CONFIG.TRACES_DEPTH {16384} \
	] $monitor_0

	# Create instance: xlconcat_1, and set properties
	set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
	set_property CONFIG.NUM_PORTS {32} $xlconcat_1

    # Required to avoid problems with AXI Interconnect
    set_property CONFIG.C_S_AXI_ID_WIDTH {12} $artico3_shuffler_0

    # Create and configure new AXI SmartConnect instances
	set axi_a3ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_a3ctrl ]
	set_property -dict [list \
		CONFIG.NUM_MI {3} \
		CONFIG.NUM_SI {1} \
	] $axi_a3ctrl

	set axi_a3data [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_a3data ]
	set_property -dict [list \
		CONFIG.NUM_CLKS {1} \
		CONFIG.NUM_MI {2} \
		CONFIG.NUM_SI {1} \
	] $axi_a3data

	set axi_mdata [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_mdata ]
	set_property -dict [list \
		CONFIG.NUM_MI {1} \
		CONFIG.NUM_SI {1} \
	] $axi_mdata

	# Connect AXI interfaces
	connect_bd_intf_net -intf_net S00_AXI_0_1 [get_bd_intf_ports S00_AXI_0] [get_bd_intf_pins axi_a3ctrl/S00_AXI]
	connect_bd_intf_net -intf_net axi_a3ctrl_M00_AXI [get_bd_intf_pins axi_a3ctrl/M00_AXI] [get_bd_intf_pins artico3_shuffler_0/s00_axi]
	connect_bd_intf_net -intf_net axi_a3ctrl_M01_AXI [get_bd_intf_pins axi_a3ctrl/M01_AXI] [get_bd_intf_pins axi_traffic_gen_0/S_AXI]
  	connect_bd_intf_net -intf_net axi_a3ctrl_M02_AXI [get_bd_intf_pins axi_a3ctrl/M02_AXI] [get_bd_intf_pins monitor_0/S00_AXI]
  	
	connect_bd_intf_net -intf_net S00_AXI_1_1 [get_bd_intf_ports S00_AXI_1] [get_bd_intf_pins axi_a3data/S00_AXI]
	connect_bd_intf_net -intf_net axi_a3data_M00_AXI [get_bd_intf_pins artico3_shuffler_0/s01_axi] [get_bd_intf_pins axi_a3data/M00_AXI]
	connect_bd_intf_net -intf_net axi_a3data_M01_AXI [get_bd_intf_pins axi_a3data/M01_AXI] [get_bd_intf_pins monitor_0/S02_AXI]
	
	connect_bd_intf_net -intf_net axi_traffic_gen_0_M_AXI [get_bd_intf_pins axi_traffic_gen_0/M_AXI] [get_bd_intf_pins axi_mdata/S00_AXI]
	connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_ports M00_AXI_0] [get_bd_intf_pins axi_mdata/M00_AXI]

    # Connect clocks
	connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_ports s_axi_aclk] \
						[get_bd_pins artico3_shuffler_0/s_axi_aclk] \
						[get_bd_pins axi_a3ctrl/aclk] \
						[get_bd_pins axi_a3data/aclk] \
						[get_bd_pins axi_mdata/aclk] \
						[get_bd_pins axi_traffic_gen_0/s_axi_aclk] \
						[get_bd_pins monitor_0/s00_axi_aclk] \
						[get_bd_pins monitor_0/s02_axi_aclk] \
						[get_bd_pins monitor_0/s01_axi_aclk] \
						[get_bd_pins monitor_0/s_sniffer_in_axi_aclk] \
						[get_bd_pins monitor_0/m_sniffer_out_axi_aclk]
		
    # Connect resets
	connect_bd_net -net s_axi_aresetn_2  [get_bd_ports s_axi_aresetn] \
						[get_bd_pins artico3_shuffler_0/s_axi_aresetn] \
						[get_bd_pins axi_a3ctrl/aresetn] \
						[get_bd_pins axi_a3data/aresetn] \
						[get_bd_pins axi_mdata/aresetn] \
						[get_bd_pins axi_traffic_gen_0/s_axi_aresetn] \
						[get_bd_pins monitor_0/s00_axi_aresetn] \
						[get_bd_pins monitor_0/s02_axi_aresetn] \
						[get_bd_pins monitor_0/s01_axi_aresetn] \
						[get_bd_pins monitor_0/s_sniffer_in_axi_aresetn] \
						[get_bd_pins monitor_0/m_sniffer_out_axi_aresetn]

	# Connect interrupts
	set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
	set_property CONFIG.NUM_PORTS {4} $xlconcat_0

	connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  						[get_bd_ports interrupt]
	connect_bd_net -net artico3_shuffler_0_interrupt  [get_bd_pins artico3_shuffler_0/interrupt] \
  						[get_bd_pins xlconcat_0/In0]
	connect_bd_net -net monitor_0_interrupt  [get_bd_pins monitor_0/interrupt] \
  						[get_bd_pins xlconcat_0/In1]
	
    # Connect ARTICo3 slots
<a3<generate for SLOTS>a3>
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_aclk [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_aclk] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_aclk]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_aresetn [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_aresetn] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_aresetn]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_start [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_start] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_start]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_ready [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_ready] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_ready]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_en [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_en] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_en]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_we [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_we] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_we]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_mode [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_mode] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_mode]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_addr [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_addr] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_addr]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_wdata [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_wdata] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_wdata]
    connect_bd_net -net artico3_shuffler_0_m<a3<id>a3>_artico3_rdata [get_bd_pins artico3_shuffler_0/m<a3<id>a3>_artico3_rdata] [get_bd_pins a3_slot_<a3<id>a3>/s_artico3_rdata]
<a3<end generate>a3>

	# Connect monitor
    connect_bd_net [get_bd_pins artico3_shuffler_0/m0_artico3_start] [get_bd_pins xlconcat_1/In0]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m0_artico3_ready] [get_bd_pins xlconcat_1/In1]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m1_artico3_start] [get_bd_pins xlconcat_1/In2]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m1_artico3_ready] [get_bd_pins xlconcat_1/In3]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m2_artico3_start] [get_bd_pins xlconcat_1/In4]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m2_artico3_ready] [get_bd_pins xlconcat_1/In5]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m3_artico3_start] [get_bd_pins xlconcat_1/In6]
    connect_bd_net [get_bd_pins artico3_shuffler_0/m3_artico3_ready] [get_bd_pins xlconcat_1/In7]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m4_artico3_start] [get_bd_pins xlconcat_1/In8]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m4_artico3_ready] [get_bd_pins xlconcat_1/In9]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m5_artico3_start] [get_bd_pins xlconcat_1/In10]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m5_artico3_ready] [get_bd_pins xlconcat_1/In11]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m6_artico3_start] [get_bd_pins xlconcat_1/In12]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m6_artico3_ready] [get_bd_pins xlconcat_1/In13]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m7_artico3_start] [get_bd_pins xlconcat_1/In14]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m7_artico3_ready] [get_bd_pins xlconcat_1/In15]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m8_artico3_start] [get_bd_pins xlconcat_1/In16]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m8_artico3_ready] [get_bd_pins xlconcat_1/In17]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m9_artico3_start] [get_bd_pins xlconcat_1/In18]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m9_artico3_ready] [get_bd_pins xlconcat_1/In19]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m10_artico3_start] [get_bd_pins xlconcat_1/In20]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m10_artico3_ready] [get_bd_pins xlconcat_1/In21]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m11_artico3_start] [get_bd_pins xlconcat_1/In22]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m11_artico3_ready] [get_bd_pins xlconcat_1/In23]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m12_artico3_start] [get_bd_pins xlconcat_1/In24]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m12_artico3_ready] [get_bd_pins xlconcat_1/In25]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m13_artico3_start] [get_bd_pins xlconcat_1/In26]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m13_artico3_ready] [get_bd_pins xlconcat_1/In27]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m14_artico3_start] [get_bd_pins xlconcat_1/In28]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m14_artico3_ready] [get_bd_pins xlconcat_1/In29]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m15_artico3_start] [get_bd_pins xlconcat_1/In30]
	connect_bd_net [get_bd_pins artico3_shuffler_0/m15_artico3_ready] [get_bd_pins xlconcat_1/In31]
    connect_bd_net -net xlconcat_1_dout [get_bd_pins xlconcat_1/dout] [get_bd_pins monitor_0/probes]


    # Generate memory-mapped segments for custom peripherals
    assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces axi_traffic_gen_0/Data] [get_bd_addr_segs M00_AXI_0/Reg] -force
	assign_bd_address -offset 0x42000000 -range 0x00400000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs artico3_shuffler_0/s00_axi/reg0] -force
	assign_bd_address -offset 0x42400000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs axi_traffic_gen_0/S_AXI/Reg0] -force
	assign_bd_address -offset 0x42410000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI_0] [get_bd_addr_segs monitor_0/s00_axi/reg0] -force
	assign_bd_address -offset 0x80000000 -range 0x00400000 -target_address_space [get_bd_addr_spaces S00_AXI_1] [get_bd_addr_segs artico3_shuffler_0/s01_axi/reg0] -force
	assign_bd_address -offset 0x80400000 -range 0x00040000 -target_address_space [get_bd_addr_spaces S00_AXI_1] [get_bd_addr_segs monitor_0/s02_axi/reg0] -force

# END

    # Update layout of block design
    regenerate_bd_layout

    #make wrapper file; vivado needs it to implement design
    make_wrapper -files [get_files $proj_dir/$proj_name.srcs/sources_1/bd/system/system.bd] -top
    add_files -norecurse $proj_dir/$proj_name.gen/sources_1/bd/system/hdl/system_wrapper.vhd
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    set_property top system_wrapper [current_fileset]
    save_bd_design

# KERNEL LIBRARY (Xilinx Partial Reconfiguration Flow)

<a3<generate for KERNELS>a3>
    #
    # Kernel : <a3<KernCoreName>a3>
    #

    # Create submodule block design
    create_bd_design "<a3<KernCoreName>a3>"

    # Create dummy port
    create_bd_intf_port -mode Slave -vlnv cei.upm.es:artico3:artico3_rtl:1.0 s_artico3

    # Create module instance
    create_bd_cell -type ip -vlnv cei.upm.es:artico3:<a3<KernCoreName>a3>:[string range <a3<KernCoreVersion>a3> 0 2] "slot"

    # Connect ARTICo3 slot
    connect_bd_intf_net -intf_net artico3_slot [get_bd_intf_ports s_artico3] [get_bd_intf_pins slot/s_artico3]

    # Update layout of block design
    regenerate_bd_layout

    #make wrapper file; vivado needs it to implement design
    make_wrapper -files [get_files $proj_dir/$proj_name.srcs/sources_1/bd/<a3<KernCoreName>a3>/<a3<KernCoreName>a3>.bd] -top
    add_files -norecurse $proj_dir/$proj_name.gen/sources_1/bd/<a3<KernCoreName>a3>/hdl/<a3<KernCoreName>a3>_wrapper.vhd
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
    save_bd_design
<a3<end generate>a3>
# END

# Close Vivado project
close_project

}

#
# Main script starts here
#

artico3_hw_setup $proj_path $proj_name $artico3_ip_dir
puts "\[A3DK\] project creation finished"
