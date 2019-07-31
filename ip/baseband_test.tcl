open_project baseband.xpr

if { [file exists baseband.srcs/sources_1/bd/test_bd/test_bd.bd] != 1 } {
  create_bd_design "test_bd"
  update_compile_order -fileset sources_1
  
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip:1.1 axi_vip_0
  set_property -dict [list CONFIG.INTERFACE_MODE {MASTER}] [get_bd_cells axi_vip_0]
  create_bd_cell -type module -reference Baseband Baseband_0
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
  set_property -dict [list CONFIG.CONST_WIDTH {16}] [get_bd_cells xlconstant_0]
  
  set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.DATA_WIDTH {64} CONFIG.SUPPORTS_NARROW {0} CONFIG.HAS_BURST {0} CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0}] [get_bd_cells axi_vip_0]
  
  connect_bd_intf_net [get_bd_intf_pins axi_vip_0/M_AXI] [get_bd_intf_pins Baseband_0/s_axi]
  
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_valid_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/adc_data_q1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_valid_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_i0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_valid_q0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_valid_i1] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/dac_enable_q0] [get_bd_pins xlconstant_0/dout]
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
  connect_bd_net [get_bd_pins Baseband_0/m_axi_awready] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/m_axi_wready] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/m_axi_bresp] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/m_axi_bvalid] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/m_axi_arready] [get_bd_pins xlconstant_0/dout]
  connect_bd_net [get_bd_pins Baseband_0/m_axi_rvalid] [get_bd_pins xlconstant_0/dout]
  
  create_bd_port -dir I -type clk clock
  create_bd_port -dir I -type rst aresetn
  set_property CONFIG.POLARITY ACTIVE_LOW [get_bd_ports aresetn]
  create_bd_port -dir I -type rst reset
  set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset]
  
  connect_bd_net [get_bd_ports clock] [get_bd_pins axi_vip_0/aclk]
  connect_bd_net [get_bd_ports clock] [get_bd_pins Baseband_0/clock]
  connect_bd_net [get_bd_ports clock] [get_bd_pins Baseband_0/s_axi_aclk]
  connect_bd_net [get_bd_ports clock] [get_bd_pins Baseband_0/m_axi_aclk]
  connect_bd_net [get_bd_ports aresetn] [get_bd_pins axi_vip_0/aresetn]
  connect_bd_net [get_bd_ports aresetn] [get_bd_pins Baseband_0/s_axi_aresetn]
  connect_bd_net [get_bd_ports reset] [get_bd_pins Baseband_0/reset]
  
  assign_bd_address [get_bd_addr_segs {Baseband_0/s_axi/reg0 }]
  set_property range 64K [get_bd_addr_segs {Baseband_0/s_axi/reg0 }]
  set_property offset 0x79400000 [get_bd_addr_segs {Baseband_0/s_axi/reg0 }]
  # set_property range 64K [get_bd_addr_segs {axi_vip_0/Master_AXI/SEG_Baseband_0_reg0}]
  # set_property offset 0x79400000 [get_bd_addr_segs {axi_vip_0/Master_AXI/SEG_Baseband_0_reg0}]
  
  regenerate_bd_layout
  regenerate_bd_layout -routing
  save_bd_design

  generate_target all [get_files  /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd]

  export_ip_user_files -of_objects [get_files /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd] -no_script -sync -force -quiet
  export_simulation -of_objects [get_files /home/rigge/src/adi-bbp/ip/baseband.srcs/sources_1/bd/test_bd/test_bd.bd] -directory /home/rigge/src/adi-bbp/ip/baseband.ip_user_files/sim_scripts -ip_user_files_dir /home/rigge/src/adi-bbp/ip/baseband.ip_user_files -ipstatic_source_dir /home/rigge/src/adi-bbp/ip/baseband.ip_user_files/ipstatic -lib_map_path [list {modelsim=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/modelsim} {questa=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/questa} {ies=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/ies} {xcelium=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/xcelium} {vcs=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/vcs} {riviera=/home/rigge/src/adi-bbp/ip/baseband.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
  
  add_files -fileset sim_1 /home/rigge/src/adi-bbp/ip/baseband_test.sv
  add_files -fileset sim_1 /home/rigge/src/adi-bbp/ip/test_wrapper.v
  set_property top baseband_test [get_filesets sim_1]
  set_property top_lib xil_defaultlib [get_filesets sim_1]
  update_compile_order -fileset sim_1
}

set_property -name {xsim.simulate.runtime} -value {9000ns} -objects [get_filesets sim_1]
launch_simulation
