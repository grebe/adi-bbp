# project

proc replace_tx {replacement} {
  # remove original connections
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_valid_i0]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_data_i0]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_valid_q0]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_data_q0]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_valid_i1]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_data_i1]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_valid_q1]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_data_q1]]]
  # delete_bd_objs [get_bd_nets -of_objects [find_bd_objs -relation connected_to [get_bd_pins axi_ad9361/dac_dunf]]]

  # connect output of replacement block
  # ad_connect  $replacement/dac_valid_i0 axi_ad9361/dac_valid_i0
  # ad_connect  $replacement/dac_data_i0  axi_ad9361/dac_data_i0
  # ad_connect  $replacement/dac_valid_q0 axi_ad9361/dac_valid_q0
  # ad_connect  $replacement/dac_data_q0  axi_ad9361/dac_data_q0
  # ad_connect  $replacement/dac_valid_i1 axi_ad9361/dac_valid_i1
  # ad_connect  $replacement/dac_data_i1  axi_ad9361/dac_data_i1
  # ad_connect  $replacement/dac_valid_q1 axi_ad9361/dac_valid_q1
  # ad_connect  $replacement/dac_data_q1  axi_ad9361/dac_data_q1
  # ad_connect  $replacement/dac_dovf     axi_ad9361/dac_dovf
  # ad_connect  $replacement/dac_dunf     axi_ad9361/dac_dunf

  ad_connect  util_ad9361_dac_upack/dac_data_0 $replacement/dma_data_i0
  ad_connect  util_ad9361_dac_upack/dac_data_1 $replacement/dma_data_q0
  ad_connect  util_ad9361_dac_upack/dac_data_2 $replacement/dma_data_i1
  ad_connect  util_ad9361_dac_upack/dac_data_3 $replacement/dma_data_q1
  # ad_connect  axi_ad9361_dac_dma/fifo_rd_underflow $replacement/dma_dunf
  # ad_connect  $replacement/dma_dovf GND
}

proc add_rx {replacement} {
  # connect adc output to replacement block
  ad_connect  axi_ad9361/adc_valid_i0 $replacement/adc_valid_i0
  ad_connect  axi_ad9361/adc_data_i0  $replacement/adc_data_i0
  ad_connect  axi_ad9361/adc_valid_q0 $replacement/adc_valid_q0
  ad_connect  axi_ad9361/adc_data_q0  $replacement/adc_data_q0
  ad_connect  axi_ad9361/adc_valid_i1 $replacement/adc_valid_i1
  ad_connect  axi_ad9361/adc_data_i1  $replacement/adc_data_i1
  ad_connect  axi_ad9361/adc_valid_q1 $replacement/adc_valid_q1
  ad_connect  axi_ad9361/adc_data_q1  $replacement/adc_data_q1
}


proc add_clock_and_reset {replacement} {
  ad_connect  axi_ad9361/clk $replacement/clock
  ad_connect  axi_ad9361/rst $replacement/reset
}

proc update_rxtx {replacement} {
    add_clock_and_reset $replacement
    add_rx $replacement
    replace_tx $replacement
}

proc make_baseband {base_address} {
  set baseband [create_bd_cell -type ip -vlnv analog.com:user:baseband:1.0 baseband]
  ad_cpu_interconnect $base_address baseband
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
