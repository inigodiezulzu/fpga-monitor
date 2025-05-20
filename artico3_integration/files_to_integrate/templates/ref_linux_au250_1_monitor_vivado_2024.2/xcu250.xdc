# Configure pipeline logic
# create_pblock a3_pipe
# add_cells_to_pblock [get_pblocks a3_pipe] [get_cells -quiet -hierarchical pipe_logic*]
# resize_pblock [get_pblocks a3_pipe] -add {SLICE_X47Y180:SLICE_X49Y419}

# Configure slot #0
create_pblock a3_slot_0
add_cells_to_pblock [get_pblocks a3_slot_0] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_0]
resize_pblock [get_pblocks a3_slot_0] -add {CLOCKREGION_X5Y15:CLOCKREGION_X7Y15}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_0]
set_property IS_SOFT FALSE [get_pblocks a3_slot_0]

# Configure slot #1
create_pblock a3_slot_1
add_cells_to_pblock [get_pblocks a3_slot_1] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_1]
resize_pblock [get_pblocks a3_slot_1] -add {CLOCKREGION_X5Y14:CLOCKREGION_X7Y14}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_1]
set_property IS_SOFT FALSE [get_pblocks a3_slot_1]

# Configure slot #2
create_pblock a3_slot_2
add_cells_to_pblock [get_pblocks a3_slot_2] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_2]
resize_pblock [get_pblocks a3_slot_2] -add {CLOCKREGION_X5Y13:CLOCKREGION_X7Y13}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_2]
set_property IS_SOFT FALSE [get_pblocks a3_slot_2]

# Configure slot #3
create_pblock a3_slot_3
add_cells_to_pblock [get_pblocks a3_slot_3] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_3]
resize_pblock [get_pblocks a3_slot_3] -add {CLOCKREGION_X5Y12:CLOCKREGION_X7Y12}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_3]
set_property IS_SOFT FALSE [get_pblocks a3_slot_3]

# Configure slot #4
create_pblock a3_slot_4
add_cells_to_pblock [get_pblocks a3_slot_4] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_4]
resize_pblock [get_pblocks a3_slot_4] -add {CLOCKREGION_X5Y11:CLOCKREGION_X7Y11}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_4]
set_property IS_SOFT FALSE [get_pblocks a3_slot_4]


# Configure slot #5
create_pblock a3_slot_5
add_cells_to_pblock [get_pblocks a3_slot_5] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_5]
resize_pblock [get_pblocks a3_slot_5] -add {CLOCKREGION_X5Y10:CLOCKREGION_X7Y10}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_5]
set_property IS_SOFT FALSE [get_pblocks a3_slot_5]

# Configure slot #6
create_pblock a3_slot_6
add_cells_to_pblock [get_pblocks a3_slot_6] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_6]
resize_pblock [get_pblocks a3_slot_6] -add {CLOCKREGION_X5Y9:CLOCKREGION_X7Y9}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_6]
set_property IS_SOFT FALSE [get_pblocks a3_slot_6]

# Configure slot #7
create_pblock a3_slot_7
add_cells_to_pblock [get_pblocks a3_slot_7] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_7]
resize_pblock [get_pblocks a3_slot_7] -add {CLOCKREGION_X5Y8:CLOCKREGION_X7Y8}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_7]
set_property IS_SOFT FALSE [get_pblocks a3_slot_7]

# Configure slot #8
create_pblock a3_slot_8
add_cells_to_pblock [get_pblocks a3_slot_8] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_8]
resize_pblock [get_pblocks a3_slot_8] -add {CLOCKREGION_X0Y15:CLOCKREGION_X2Y15}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_8]
set_property IS_SOFT FALSE [get_pblocks a3_slot_8]

# Configure slot #9
create_pblock a3_slot_9
add_cells_to_pblock [get_pblocks a3_slot_9] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_9]
resize_pblock [get_pblocks a3_slot_9] -add {CLOCKREGION_X0Y14:CLOCKREGION_X2Y14}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_9]
set_property IS_SOFT FALSE [get_pblocks a3_slot_9]

# Configure slot #10
create_pblock a3_slot_10
add_cells_to_pblock [get_pblocks a3_slot_10] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_10]
resize_pblock [get_pblocks a3_slot_10] -add {CLOCKREGION_X0Y13:CLOCKREGION_X2Y13}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_10]
set_property IS_SOFT FALSE [get_pblocks a3_slot_10]

# Configure slot #11
create_pblock a3_slot_11
add_cells_to_pblock [get_pblocks a3_slot_11] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_11]
resize_pblock [get_pblocks a3_slot_11] -add {CLOCKREGION_X0Y12:CLOCKREGION_X2Y12}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_11]
set_property IS_SOFT FALSE [get_pblocks a3_slot_11]

# Configure slot #12
create_pblock a3_slot_12
add_cells_to_pblock [get_pblocks a3_slot_12] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_12]
resize_pblock [get_pblocks a3_slot_12] -add {CLOCKREGION_X0Y11:CLOCKREGION_X2Y11}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_12]
set_property IS_SOFT FALSE [get_pblocks a3_slot_12]

# Configure slot #13
create_pblock a3_slot_13
add_cells_to_pblock [get_pblocks a3_slot_13] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_13]
resize_pblock [get_pblocks a3_slot_13] -add {CLOCKREGION_X0Y10:CLOCKREGION_X2Y10}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_13]
set_property IS_SOFT FALSE [get_pblocks a3_slot_13]

# Configure slot #14
create_pblock a3_slot_14
add_cells_to_pblock [get_pblocks a3_slot_14] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_14]
resize_pblock [get_pblocks a3_slot_14] -add {CLOCKREGION_X0Y9:CLOCKREGION_X2Y9}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_14]
set_property IS_SOFT FALSE [get_pblocks a3_slot_14]

# Configure slot #15
create_pblock a3_slot_15
add_cells_to_pblock [get_pblocks a3_slot_15] [get_cells floorplan_static_i/reconfig_base_inst_0/U0/a3_slot_15]
resize_pblock [get_pblocks a3_slot_15] -add {CLOCKREGION_X0Y8:CLOCKREGION_X2Y8}
set_property SNAPPING_MODE ON [get_pblocks a3_slot_15]
set_property IS_SOFT FALSE [get_pblocks a3_slot_15]
