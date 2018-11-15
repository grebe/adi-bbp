# project

proc replace_tx {old new} {
  # remove original connections
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_i0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_q0]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_i1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_valid_q1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_enable_q1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_data_q1]]]
  delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins $old/dac_dunf]]]

  # connect output of replacement block
  ad_connect  $old/dac_valid_i0  $new/dac_valid_i0
  ad_connect  $old/dac_enable_i0 $new/dac_enable_i0
  ad_connect  $old/dac_data_i0   $new/dac_data_i0
  ad_connect  $old/dac_valid_q0  $new/dac_valid_q0
  ad_connect  $old/dac_enable_i1 $new/dac_enable_i1
  ad_connect  $old/dac_data_q0   $new/dac_data_q0
  ad_connect  $old/dac_valid_i1  $new/dac_valid_i1
  ad_connect  $old/dac_enable_q0 $new/dac_enable_q0
  ad_connect  $old/dac_data_i1   $new/dac_data_i1
  ad_connect  $old/dac_valid_q1  $new/dac_valid_q1
  ad_connect  $old/dac_enable_q1 $new/dac_enable_q1
  ad_connect  $old/dac_data_q1   $new/dac_data_q1
  ad_connect  $new/dac_dunf      $old/dac_dunf

  ad_connect  ${old}_dac_fifo/dout_data_0      $new/dma_data_i0
  ad_connect  ${old}_dac_fifo/dout_valid_out_0 $new/dma_valid_out_i0
  ad_connect  ${old}_dac_fifo/dout_data_1      $new/dma_data_q0
  ad_connect  ${old}_dac_fifo/dout_valid_out_1 $new/dma_valid_out_i1
  ad_connect  ${old}_dac_fifo/dout_data_2      $new/dma_data_i1
  ad_connect  ${old}_dac_fifo/dout_valid_out_2 $new/dma_valid_out_q0
  ad_connect  ${old}_dac_fifo/dout_data_3      $new/dma_data_q1
  ad_connect  ${old}_dac_fifo/dout_valid_out_3 $new/dma_valid_out_q1
  ad_connect  ${old}_dac_fifo/dout_unf         $new/dma_dunf

  ad_connect $new/dma_enable_i0 ${old}_dac_fifo/dout_enable_0
  ad_connect $new/dma_enable_i1 ${old}_dac_fifo/dout_enable_1
  ad_connect $new/dma_enable_q0 ${old}_dac_fifo/dout_enable_2
  ad_connect $new/dma_enable_q1 ${old}_dac_fifo/dout_enable_3

  ad_connect $new/dma_valid_i0  ${old}_dac_fifo/dout_valid_0
  ad_connect $new/dma_valid_i1  ${old}_dac_fifo/dout_valid_1
  ad_connect $new/dma_valid_q0  ${old}_dac_fifo/dout_valid_2
  ad_connect $new/dma_valid_q1  ${old}_dac_fifo/dout_valid_3
}

proc add_rx {old new} {
  # connect adc output to replacement block
  ad_connect  $old/adc_valid_i0 $new/adc_valid_i0
  ad_connect  $old/adc_data_i0  $new/adc_data_i0
  ad_connect  $old/adc_valid_q0 $new/adc_valid_q0
  ad_connect  $old/adc_data_q0  $new/adc_data_q0
  ad_connect  $old/adc_valid_i1 $new/adc_valid_i1
  ad_connect  $old/adc_data_i1  $new/adc_data_i1
  ad_connect  $old/adc_valid_q1 $new/adc_valid_q1
  ad_connect  $old/adc_data_q1  $new/adc_data_q1
}


proc add_clock_and_reset {old new} {
  ad_connect  $old/clk $new/clock
  ad_connect  $old/rst $new/reset
}

proc update_rxtx {old new} {
    add_clock_and_reset $old $new
    add_rx $old $new
    replace_tx $old $new
}

proc make_baseband {base_address} {
  set baseband [create_bd_cell -type ip -vlnv cs.berkeley.edu:user:baseband:1.0 baseband]
  ad_cpu_interconnect $base_address Baseband
}

proc update_bd {} {
  regenerate_bd_layout
  save_bd_design
  validate_bd_design
}

proc make_targets {sources} {
  generate_target {synthesis implementation} [get_files $sources/bd/system/system.bd]
  make_wrapper -files [get_files $sources/bd/system/system.bd] -top
  import_files -force -norecurse -fileset sources_1 $sources/bd/system/hdl/system_wrapper.v
}
