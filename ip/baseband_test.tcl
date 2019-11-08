open_project baseband.xpr

if { [file exists baseband.srcs/sources_1/bd/test_bd/test_bd.bd] != 1 } {
  set_property ip_repo_paths [list ./] [current_fileset]
  update_ip_catalog
  create_bd_design "test_bd"
  update_compile_order -fileset sources_1
  
  # create axi-4 master vip
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_master
  set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.PROTOCOL {AXI4LITE} CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0}] [get_bd_cells axi_vip_master]
  
  # create axi-4 slave vip
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_slave
  set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE}] [get_bd_cells axi_vip_slave]

  # create baseband (DUT)
  create_bd_cell -type ip -vlnv cs.berkeley.edu:user:baseband:1.0 Baseband_0

  # create constant 0
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
  set_property -dict [list CONFIG.CONST_WIDTH {16}] [get_bd_cells xlconstant_0]

  # create constant 1
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
  set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells xlconstant_1]

  # create axi4-stream master vip
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi4stream_vip:1.1 axi4stream_vip_master
  set_property -dict [list CONFIG.INTERFACE_MODE {MASTER} CONFIG.TDATA_NUM_BYTES {4}] [get_bd_cells axi4stream_vip_master]

  create_bd_cell -type ip -vlnv xilinx.com:ip:axi4stream_vip:1.1 axi4stream_vip_slave
  set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.TDATA_NUM_BYTES {4}] [get_bd_cells axi4stream_vip_slave]
  
  # create slice to split axi4-stream master into i and q
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
  set_property -dict [list CONFIG.DIN_TO {16} CONFIG.DIN_FROM {31} CONFIG.DIN_WIDTH {32}] [get_bd_cells xlslice_0]
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
  set_property -dict [list CONFIG.DIN_TO {0} CONFIG.DIN_FROM {15} CONFIG.DIN_WIDTH {32}] [get_bd_cells xlslice_1]

  # connect vip to slices and slices to baseband adc in
  connect_bd_net [get_bd_pins xlslice_0/Din] [get_bd_pins axi4stream_vip_master/m_axis_tdata]
  connect_bd_net [get_bd_pins xlslice_1/Din] [get_bd_pins axi4stream_vip_master/m_axis_tdata]
  connect_bd_net [get_bd_pins xlslice_0/Dout] [get_bd_pins Baseband_0/adc_data_i0]
  connect_bd_net [get_bd_pins xlslice_1/Dout] [get_bd_pins Baseband_0/adc_data_q0]

  # create concat to join i and q for axi4-stream slave
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
  set_property -dict [list CONFIG.IN0_WIDTH {16} CONFIG.IN1_WIDTH {16}] [get_bd_cells xlconcat_0]
  connect_bd_net [get_bd_pins xlconcat_0/In0] [get_bd_pins Baseband_0/dac_data_i0]
  connect_bd_net [get_bd_pins xlconcat_0/In1] [get_bd_pins Baseband_0/dac_data_q0]
  connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi4stream_vip_slave/s_axis_tdata]
  connect_bd_net [get_bd_pins axi4stream_vip_slave/s_axis_tready] [get_bd_pins Baseband_0/dac_valid_i0]
  connect_bd_net [get_bd_pins axi4stream_vip_slave/s_axis_tready] [get_bd_pins Baseband_0/dac_valid_q0]
  connect_bd_net [get_bd_pins axi4stream_vip_slave/s_axis_tvalid] [get_bd_pins Baseband_0/dma_valid_i0]

  # connect valid to vip
  connect_bd_net [get_bd_pins axi4stream_vip_master/m_axis_tvalid] [get_bd_pins Baseband_0/adc_valid_i0]
  connect_bd_net [get_bd_pins axi4stream_vip_master/m_axis_tvalid] [get_bd_pins Baseband_0/adc_valid_q0]
  # connect vip ready to true
  connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins axi4stream_vip_master/m_axis_tready]

  # connect axi master vip to slave
  connect_bd_intf_net [get_bd_intf_pins axi_vip_master/M_AXI] [get_bd_intf_pins Baseband_0/s_axi]

  # connect axi slave vip to master
  connect_bd_intf_net [get_bd_intf_pins axi_vip_slave/S_AXI] [get_bd_intf_pins Baseband_0/m_axi]

  # enable i0 and q0
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_i0] [get_bd_pins xlconstant_1/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_q0] [get_bd_pins xlconstant_1/dout]
  
  # connect everything else to constant 0
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_q1] [get_bd_pins xlconstant_0/dout]
  # connect_bd_net [get_bd_pins Baseband_0/dac_valid_i0] [get_bd_pins xlconstant_0/dout]
  # connect_bd_net [get_bd_pins Baseband_0/dac_valid_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_valid_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_valid_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_data_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_valid_out_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_data_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_valid_out_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_data_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_valid_out_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_data_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_valid_out_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dma_dunf] [get_bd_pins xlconstant_0/dout]
  
  # create clocks/resets
  create_bd_port -dir I -type clk clock
  create_bd_port -dir I -type clk rx_clock
  create_bd_port -dir I -type rst aresetn
  set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports aresetn]
  create_bd_port -dir I -type rst reset
  set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset]
  create_bd_port -dir I -type rst resetn
  set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports resetn]
  
  # connect clocks/resets
  connect_bd_net [get_bd_ports clock]    [get_bd_pins axi_vip_master/aclk]
  connect_bd_net [get_bd_ports clock]    [get_bd_pins axi_vip_slave/aclk]
  connect_bd_net [get_bd_ports clock]    [get_bd_pins Baseband_0/s_axi_aclk]
  connect_bd_net [get_bd_ports rx_clock] [get_bd_pins axi4stream_vip_master/aclk]
  connect_bd_net [get_bd_ports rx_clock] [get_bd_pins axi4stream_vip_slave/aclk]
  connect_bd_net [get_bd_ports rx_clock] [get_bd_pins Baseband_0/clock]
  connect_bd_net [get_bd_ports aresetn]  [get_bd_pins axi_vip_master/aresetn]
  connect_bd_net [get_bd_ports aresetn]  [get_bd_pins axi_vip_slave/aresetn]
  connect_bd_net [get_bd_ports aresetn]  [get_bd_pins Baseband_0/s_axi_aresetn]
  connect_bd_net [get_bd_ports resetn]   [get_bd_pins axi4stream_vip_master/aresetn]
  connect_bd_net [get_bd_ports resetn]   [get_bd_pins axi4stream_vip_slave/aresetn]
  connect_bd_net [get_bd_ports reset]    [get_bd_pins Baseband_0/reset]
  
  assign_bd_address -external -offset 0x79400000 -range 64K [get_bd_addr_segs {Baseband_0/m_axi/reg0 }]
  assign_bd_address -external -offset 0x00000000 -range 1G  [get_bd_addr_segs {axi_vip_master/Master_AXI/Reg}]
  # set_property range 64K [get_bd_addr_segs {Baseband_0/s_axi/reg0 }]
  # set_property offset 0x79400000 [get_bd_addr_segs {Baseband_0/s_axi/reg0 }]

  set_property CONFIG.CLK_DOMAIN s_axi_aclk [get_bd_intf_pins /Baseband_0/s_axi]
  set_property CONFIG.CLK_DOMAIN s_axi_aclk [get_bd_intf_pins /Baseband_0/m_axi]

  
  # clean up bd and save it
  regenerate_bd_layout
  regenerate_bd_layout -routing
  save_bd_design

  generate_target all [get_files  /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd]

  export_ip_user_files -of_objects [get_files /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd] -no_script -sync -force -quiet
  export_simulation -of_objects [get_files /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd] -directory /home/rigge/src/adi-bbp/ip/baseband.ip_user_files/sim_scripts -ip_user_files_dir /home/rigge/src/adi-bbp/ip/baseband.ip_user_files -ipstatic_source_dir /home/rigge/src/adi-bbp/ip/baseband.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/modelsim} {questa=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/questa} {ies=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/ies} {xcelium=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/xcelium} {vcs=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/vcs} {riviera=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
  
  # add test files to sim
  add_files -fileset sim_1 /home/rigge/src/adi-bbp/ip/baseband_test.sv
  add_files -fileset sim_1 /home/rigge/src/adi-bbp/ip/test_wrapper.v
  set_property top baseband_test [get_filesets sim_1]
  set_property top_lib xil_defaultlib [get_filesets sim_1]
  update_compile_order -fileset sim_1
}

set_property -name {xsim.simulate.runtime} -value {2000000000ns} -objects [get_filesets sim_1]
launch_simulation
