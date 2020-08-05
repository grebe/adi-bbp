# project

proc replace_tx {old new} {
  # remove original connections
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_q1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_q1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_q1]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_dunf]]]

  # ADI's valid is really more of a ready signal...
  # Connect it to the AXI4-Stream ready for the dac
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 uvl_dac_0
  set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and}] [get_bd_cells uvl_dac_0]
  ad_connect $old/dac_valid_i0 uvl_dac_0/Op1
  ad_connect $old/dac_valid_q0 uvl_dac_0/Op2
  ad_connect uvl_dac_0/Res $new/dac_0_ready

  # Split a single AXI4-Stream interface with IQ into I and Q
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dac_data_0_top
  set_property -dict [list CONFIG.DIN_WIDTH {32} CONFIG.DIN_FROM {31} CONFIG.DIN_TO {16} CONFIG.DOUT_WIDTH {16}] [get_bd_cells slice_dac_data_0_top]
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dac_data_0_bottom
  set_property -dict [list CONFIG.DIN_WIDTH {32} CONFIG.DIN_FROM {15} CONFIG.DIN_TO {0} CONFIG.DOUT_WIDTH {16}] [get_bd_cells slice_dac_data_0_bottom]
  ad_connect $new/dac_0_data slice_dac_data_0_top/Din
  ad_connect $new/dac_0_data slice_dac_data_0_bottom/Din
  ad_connect slice_dac_data_0_top/Dout $old/dac_data_i0
  ad_connect slice_dac_data_0_bottom/Dout $old/dac_data_q0

  # ADI's valid is really more of a ready signal...
  # Connect it to the AXI4-Stream ready for the dac
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 uvl_dac_1
  set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {and}] [get_bd_cells uvl_dac_1]
  ad_connect $old/dac_valid_i1 uvl_dac_1/Op1
  ad_connect $old/dac_valid_q1 uvl_dac_1/Op2
  ad_connect uvl_dac_1/Res $new/dac_1_ready

  # Split a single AXI4-Stream interface with IQ into I and Q
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dac_data_1_top
  set_property -dict [list CONFIG.DIN_WIDTH {32} CONFIG.DIN_FROM {31} CONFIG.DIN_TO {16} CONFIG.DOUT_WIDTH {16}] [get_bd_cells slice_dac_data_1_top]
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 slice_dac_data_1_bottom
  set_property -dict [list CONFIG.DIN_WIDTH {32} CONFIG.DIN_FROM {15} CONFIG.DIN_TO {0} CONFIG.DOUT_WIDTH {16}] [get_bd_cells slice_dac_data_1_bottom]
  ad_connect $new/dac_1_data slice_dac_data_1_top/Din
  ad_connect $new/dac_1_data slice_dac_data_1_bottom/Din
  ad_connect slice_dac_data_1_top/Dout $old/dac_data_i1
  ad_connect slice_dac_data_1_bottom/Dout $old/dac_data_q1

  # ad_connect ${old}_dac_fifo/dout_dunf $new/dmain_dunf
  # ad_connect  $new/dmaout_dunf      $old/dac_dunf

  # Connect the old DMA interface
  # It operates as passthrough unless a register is set, in which case
  # the custom baseband cuts everything off and emits its own samples
  ad_connect ${old}_dac_fifo/dout_data_0      $new/dmain_data_0
  ad_connect ${old}_dac_fifo/dout_data_1      $new/dmain_data_1
  ad_connect ${old}_dac_fifo/dout_data_2      $new/dmain_data_2
  ad_connect ${old}_dac_fifo/dout_data_3      $new/dmain_data_3
  ad_connect ${old}_dac_fifo/dout_valid_out_0 $new/dmain_valid_out_0
  ad_connect ${old}_dac_fifo/dout_valid_out_1 $new/dmain_valid_out_1
  ad_connect ${old}_dac_fifo/dout_valid_out_2 $new/dmain_valid_out_2
  ad_connect ${old}_dac_fifo/dout_valid_out_3 $new/dmain_valid_out_3

  ad_connect $new/dmain_enable_0 ${old}_dac_fifo/dout_enable_0
  ad_connect $new/dmain_enable_1 ${old}_dac_fifo/dout_enable_1
  ad_connect $new/dmain_enable_2 ${old}_dac_fifo/dout_enable_2
  ad_connect $new/dmain_enable_3 ${old}_dac_fifo/dout_enable_3
  ad_connect $new/dmain_valid_0  ${old}_dac_fifo/dout_valid_0
  ad_connect $new/dmain_valid_1  ${old}_dac_fifo/dout_valid_1
  ad_connect $new/dmain_valid_2  ${old}_dac_fifo/dout_valid_2
  ad_connect $new/dmain_valid_3  ${old}_dac_fifo/dout_valid_3

  ad_connect $old/dac_enable_i0 $new/dmaout_enable_0
  ad_connect $old/dac_enable_q0 $new/dmaout_enable_1
  ad_connect $old/dac_enable_i1 $new/dmaout_enable_2
  ad_connect $old/dac_enable_q1 $new/dmaout_enable_3
  ad_connect $old/dac_valid_i0  $new/dmaout_valid_0
  ad_connect $old/dac_valid_q0  $new/dmaout_valid_1
  ad_connect $old/dac_valid_i1  $new/dmaout_valid_2
  ad_connect $old/dac_valid_q1  $new/dmaout_valid_3

  # ad_connect ${old}_dac_fifo/dout_unf $new/dmain_dunf
  # ad_connect $new/dmaout_dunf $old/dac_dunf
}

proc add_rx {old new} {
  # connect adc output to replacement block
  ad_connect  $old/adc_valid_i0 $new/adc_0_valid
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_adc_data_0
  ad_connect  $old/adc_data_i0  concat_adc_data_0/In0
  ad_connect  $old/adc_data_q0  concat_adc_data_0/In1
  ad_connect  concat_adc_data_0/dout $new/adc_0_data

  ad_connect  $old/adc_valid_i1 $new/adc_1_valid
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_adc_data_1
  ad_connect  $old/adc_data_i1  concat_adc_data_1/In0
  ad_connect  $old/adc_data_q1  concat_adc_data_1/In1
  ad_connect  concat_adc_data_1/dout $new/adc_1_data

  # ad_connect  $old/adc_valid_q0 $new/adc_valid_q0
  # ad_connect  $old/adc_valid_q1 $new/adc_valid_q1
}


proc add_clock_and_reset {old new} {
  ad_connect  $old/clk $new/clock
  ad_connect  $old/rst $new/reset
}

proc update_rxtx {old new} {
    add_clock_and_reset $old $new
    add_rx $old $new
    # replace_tx $old $new
}

proc make_baseband {base_address} {
  set baseband [create_bd_cell -type ip -vlnv cs.berkeley.edu:user:baseband:1.0 baseband]
  ad_cpu_interconnect $base_address Baseband
  ad_mem_hp3_interconnect sys_cpu_clk sys_ps7/S_AXI_HP3
  ad_mem_hp3_interconnect sys_cpu_clk Baseband/m_axi
}

proc add_ila {} {

  set_property mark_debug true [get_nets -hier -regexp .*/baseband/s_axi_aw.*]
  set_property mark_debug true [get_nets -hier -regexp .*/baseband/s_axi_ar.*]
  set_property mark_debug true [get_nets -hier -regexp .*/baseband/s_axi_r.*]
  set_property mark_debug true [get_nets -hier -regexp .*/baseband/s_axi_w.*]
  set_property mark_debug true [get_nets -hier -regexp .*/baseband/s_axi_b.*]

  # set_property mark_debug true [get_nets -hier -regexp .*/baseband/m_axi_aw.*]
  # set_property mark_debug true [get_nets -hier -regexp .*/baseband/m_axi_ar.*]
  # set_property mark_debug true [get_nets -hier -regexp .*/baseband/m_axi_r.*]
  # set_property mark_debug true [get_nets -hier -regexp .*/baseband/m_axi_w.*]
  # set_property mark_debug true [get_nets -hier -regexp .*/baseband/m_axi_b.*]

  create_debug_core ila1 ila
  set_property C_DATA_DEPTH 2048 [get_debug_cores ila1]
  set_property C_EN_STRG_QUAL true [get_debug_cores ila1]
  set_property C_ADV_TRIGGER true [get_debug_cores ila1]
  set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores ila1]
  set_property C_INPUT_PIPE_STAGES 5 [get_debug_cores ila1]

  set ila_nets [get_nets -hier -filter {MARK_DEBUG==1}]
  set num_ila_nets [llength [get_nets [list $ila_nets]]]

  set_property port_width 1 [get_debug_ports ila1/clk]
  connect_debug_port ila1/clk [get_nets -hier -regexp .*/baseband/s_axi_aclk]

  set_property port_width $num_ila_nets [get_debug_ports ila1/probe0]
  connect_debug_port ila1/probe0 $ila_nets

  save_constraints
  implement_debug_core

  # write_debug_probes -force ./results/ila1.ltx
}

proc place_ila {} {
  create_pblock pblock_ilamem
  add_cells_to_pblock pblock_ilamem [get_cells -regexp ila1/.* -hier -filter {PRIMITIVE_SUBGROUP == bram}] -clear_locs
  place_pblocks -effort HIGH -utilization 75 [get_pblocks [list pblock_ilamem]]
}

proc update_bd {} {
  regenerate_bd_layout
  save_bd_design
  validate_bd_design
}

proc make_targets {sources} {
  set_property synth_checkpoint_mode Hierarchical [get_files $sources/bd/system/system.bd]
  generate_target {synthesis implementation} [get_files $sources/bd/system/system.bd]
  export_ip_user_files -of_objects [get_files $sources/bd/system/system.bd]
  create_ip_run [get_files $sources/bd/system/system.bd]
  make_wrapper -files [get_files $sources/bd/system/system.bd] -top
  import_files -force -norecurse -fileset sources_1 $sources/bd/system/hdl/system_wrapper.v
  if {[file exists ./reference.dcp]} {
    set_property incremental_checkpoint ./reference.dcp [get_runs impl_1]
  }
}

proc project_run_synth {project_name} {
  launch_runs -jobs 8 system_*_synth_1 synth_1
  wait_on_run synth_1
  open_run synth_1
  report_timing_summary -file timing_synth.log
  report_bus_skew -file skew_synth.log

  set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
}

proc project_run_impl {project_name} {
  launch_runs impl_1 -to_step write_bitstream
  wait_on_run impl_1
  open_run impl_1
  report_timing_summary -file timing_impl.log
  report_bus_skew -file skew_impl.log

  file mkdir $project_name.sdk

  if [expr [get_property SLACK [get_timing_paths]] < 0] {
    file copy -force $project_name.runs/impl_1/system_top.hwdef $project_name.sdk/system_top_bad_timing.hdf
  } else {
    file copy -force $project_name.runs/impl_1/system_top.hwdef $project_name.sdk/system_top.hdf
  }

  if [expr [get_property SLACK [get_timing_paths]] < 0] {
    return -code error [format "ERROR: Timing Constraints NOT met!"]
  }
}

