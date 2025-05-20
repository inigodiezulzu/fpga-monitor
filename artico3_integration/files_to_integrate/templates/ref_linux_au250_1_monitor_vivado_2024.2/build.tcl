#
# ARTICo3 IP library script for Vivado
#
# Author      : Alfonso Rodriguez <alfonso.rodriguezm@upm.es>
# Date        : August 2017
#
# Description : Generates FPGA bitstream from Vivado project.
#

<a3<artico3_preproc>a3>

proc get_cpu_core_count {} {
    global tcl_platform env
    switch ${tcl_platform(platform)} {
        "windows" {
            return $env(NUMBER_OF_PROCESSORS)
        }

        "unix" {
            if {![catch {open "/proc/cpuinfo"} f]} {
            set cores [regexp -all -line {^processor\s} [read $f]]
            close $f
            if {$cores > 0} {
                return $cores
            }
            }
        }

        "Darwin" {
            if {![catch {exec $sysctl -n "hw.ncpu"} cores]} {
            return $cores
            }
        }

        default {
            puts "Unknown System"
            return 1
        }
    }
}

proc artico3_syntesize {} {


    # Open Vivado project
    open_project myARTICo3.xpr
    set dcp_file_name reconfig_artico3
    set top system

    #
    # Main system synthesis
    #

    puts "\[A3DK\] generating static system"

    # Generate output products
    generate_target all [get_files *system.bd]
    # Export IP user files
    export_ip_user_files -of_objects [get_files *system.bd] -no_script -sync -force -quiet
    # Create specific IP run
    create_ip_run [get_files -of_objects [get_fileset sources_1] *system.bd]
    # Launch module run
    launch_runs system_axi_traffic_gen_0_0_synth_1 \
                system_axi_mdata_0_synth_1 \
                system_axi_a3ctrl_0_synth_1 \
                system_axi_a3data_0_synth_1 \
                system_artico3_shuffler_0_0_synth_1 \
                system_monitor_0_0_synth_1 -jobs [ expr [get_cpu_core_count] / 2 + 1]
    # Wait for module run to finish
    wait_on_run system_artico3_shuffler_0_0_synth_1
    # Synthesize reconfig system
    synth_design -top $top -part xcu250-figd2104-2L-e -mode out_of_context
    # Save checkpoint 
    write_checkpoint -force checkpoints/${dcp_file_name}.dcp

<a3<generate for KERNELS>a3>
    #
    # Kernel synthesis : <a3<KernCoreName>a3>
    #

    puts "\[A3DK\] generating kernel <a3<KernCoreName>a3>"
    # Export IP user files
    export_ip_user_files -of_objects [get_files *<a3<KernCoreName>a3>.bd] -no_script -sync -force -quiet
    
    # Generate output products
    generate_target all [get_files *<a3<KernCoreName>a3>.bd]

    # Create specific IP run
    create_ip_run [get_files -of_objects [get_fileset sources_1] *<a3<KernCoreName>a3>.bd]
    # Launch module run
    launch_runs -jobs [ expr [get_cpu_core_count] / 2 + 1] <a3<KernCoreName>a3>_slot_0_synth_1
    # Wait for module run to finish
    wait_on_run <a3<KernCoreName>a3>_slot_0_synth_1
<a3<end generate>a3>

}

proc artico3_implementation {} {

    set loc "./A1"
    set part xcu250-figd2104-2L-e

    file delete -force $loc
    file mkdir $loc
    file mkdir $loc/reports
    open_checkpoint checkpoints/top_A0_locked.dcp
    puts "#HD: Subdividing reconfig_base_inst into second-order a3_slot RPs"
    pr_subdivide -cell floorplan_static_i/reconfig_base_inst_0/U0 -subcells {floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14
                                                                            floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15} ./checkpoints/reconfig_artico3.dcp
    write_checkpoint -force $loc/top_A1_divided.dcp
    puts "	#HD: Completed"
    close_project

<a3<generate for KERNELS(KernCoreName=="a3_dummy")>a3>
    #
    # Kernel implementation : <a3<KernCoreName>a3>
    #

    puts "\[A3DK\] implementing kernel <a3<KernCoreName>a3>"
    create_project -in_memory -part $part > $loc/create_project.log
    add_file $loc/top_A1_divided.dcp
    add_file myARTICo3.runs/<a3<KernCoreName>a3>_slot_0_synth_1/<a3<KernCoreName>a3>_slot_0.dcp
    set_property SCOPED_TO_CELLS {  floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15
                                } [get_files myARTICo3.runs/<a3<KernCoreName>a3>_slot_0_synth_1/<a3<KernCoreName>a3>_slot_0.dcp]
    add_files xcu250.xdc
    set_property USED_IN {implementation} [get_files xcu250.xdc]
    set_property PROCESSING_ORDER LATE [get_files xcu250.xdc]
    link_design -mode default -reconfig_partitions {floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0 
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1 
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15} -part $part -top floorplan_static_wrapper
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_link.dcp > $loc/write_checkpoint.log
    opt_design > $loc/top_A1_<a3<KernCoreName>a3>_opt.log
    puts "	#HD: Completed: opt_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_opt.dcp > $loc/write_checkpoint.log
    place_design > $loc/top_A1_<a3<KernCoreName>a3>_place.log
    puts "	#HD: Completed: place_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_place.dcp > $loc/write_checkpoint.log
    phys_opt_design > $loc/top_A1_<a3<KernCoreName>a3>_phys_opt.log
    puts "	#HD: Completed: phys_opt_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_phys_opt.dcp > $loc/write_checkpoint.log
    route_design > $loc/top_A1_<a3<KernCoreName>a3>_routed.log
    puts "	#HD: Completed: route_design" 
    write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_route.dcp > $loc/write_checkpoint.log
    
    # Replace slot contents by black boxes
<a3<=generate for SLOTS=>a3>
    update_design -cells [get_cells -hierarchical a3_slot_<a3<id>a3>] -black_box
<a3<=end generate=>a3>

    # Lock static routing
    lock_design -level routing
    # Save checkpoint
    write_checkpoint -force $loc/top_A1_locked.dcp
    # Close Vivado project
    close_project

    puts "#HD: Recombining reconfig_base_inst/<a3<KernCoreName>a3>"
    open_checkpoint $loc/top_A1_<a3<KernCoreName>a3>_route.dcp
    pr_recombine -cell floorplan_static_i/reconfig_base_inst_0/U0
    write_checkpoint -force $loc/top_A1_recombined.dcp
    puts "	#HD: Completed"
    close_project

<a3<end generate>a3>

<a3<generate for KERNELS(KernCoreName!="a3_dummy")>a3>
    #
    # Kernel implementation : <a3<KernCoreName>a3>
    #

    puts "\[A3DK\] implementing kernel <a3<KernCoreName>a3>"
    create_project -in_memory -part $part > $loc/create_project.log
    add_file $loc/top_A1_locked.dcp
    add_file myARTICo3.runs/<a3<KernCoreName>a3>_slot_0_synth_1/<a3<KernCoreName>a3>_slot_0.dcp
    set_property SCOPED_TO_CELLS {  floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14
                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15
                                } [get_files myARTICo3.runs/<a3<KernCoreName>a3>_slot_0_synth_1/<a3<KernCoreName>a3>_slot_0.dcp]
    add_files xcu250.xdc
    set_property USED_IN {implementation} [get_files xcu250.xdc]
    set_property PROCESSING_ORDER LATE [get_files xcu250.xdc]
    link_design -mode default -reconfig_partitions {floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0 
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1 
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14
                                                    floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15} -part $part -top floorplan_static_wrapper
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_link.dcp > $loc/write_checkpoint.log
    opt_design > $loc/top_A1_<a3<KernCoreName>a3>_opt.log
    puts "	#HD: Completed: opt_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_opt.dcp > $loc/write_checkpoint.log
    place_design > $loc/top_A1_<a3<KernCoreName>a3>_place.log
    puts "	#HD: Completed: place_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_place.dcp > $loc/write_checkpoint.log
    phys_opt_design > $loc/top_A1_<a3<KernCoreName>a3>_phys_opt.log
    puts "	#HD: Completed: phys_opt_design"
    # write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_phys_opt.dcp > $loc/write_checkpoint.log
    route_design > $loc/top_A1_<a3<KernCoreName>a3>_routed.log
    puts "	#HD: Completed: route_design" 
    write_checkpoint -force $loc/top_A1_<a3<KernCoreName>a3>_route.dcp > $loc/write_checkpoint.log
    
    # Close Vivado project
    close_project

<a3<end generate>a3>
}

proc artico3_build_bitstream {} {

    #Define second order Reconfigurable Partitions
    set firstRP1 "bin"
    set firstRP1bit "bitstreams"
    set secondRP1 "bin/pbs"
    
    #Create folders for storing full, first-order and second-order bitstreams
    file mkdir [pwd]/$secondRP1
    file mkdir [pwd]/$firstRP1bit

    #Generate first-order partial bitstreams 
    puts "#HD: Generating first-order partial bitstreams "
    open_checkpoint A1/top_A1_recombined.dcp
    write_bitstream -force -bin_file -cell floorplan_static_i/reconfig_base_inst_0/U0 ./$firstRP1/top_A1_artico3_recombined_partial.bit
    file rename -force "./$firstRP1/top_A1_artico3_recombined_partial.bit" "./$firstRP1bit/top_A1_artico3_recombined_partial.bit"
    puts "	#HD: Completed"
    close_project

<a3<generate for KERNELS(KernCoreName!="a3_dummy")>a3>
    #
    # Kernel implementation : <a3<KernCoreName>a3>
    #

    puts "\[A3DK\] Generate bitstreams kernel <a3<KernCoreName>a3>"

    puts "#HD: Generating full and partial bitstreams for shift_right functions"
    open_checkpoint A1/top_A1_<a3<KernCoreName>a3>_route.dcp
    write_bitstream -force -bin_file -no_partial_bitfile ./$secondRP1/top_A1_<a3<KernCoreName>a3>.bit
    file rename "./$secondRP1/top_A1_<a3<KernCoreName>a3>.bit" "./$firstRP1bit/top_A1_<a3<KernCoreName>a3>.bit"

<a3<=generate for SLOTS=>a3>
    write_bitstream -force -bin_file -cell floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_<a3<id>a3> ./$secondRP1/<a3<KernCoreName>a3>_a3_slot_<a3<id>a3>_partial.bit
    file rename "./$secondRP1/<a3<KernCoreName>a3>_a3_slot_<a3<id>a3>_partial.bit" "./$firstRP1bit/<a3<KernCoreName>a3>_a3_slot_<a3<id>a3>_partial.bit"
<a3<=end generate=>a3>

    puts "	#HD: Completed"
    close_project

<a3<end generate>a3>

}

#
# Main script starts here
#

# Run synthesis
artico3_syntesize
# Run implementation
artico3_implementation
# Generate bitstreams
artico3_build_bitstream
exit

