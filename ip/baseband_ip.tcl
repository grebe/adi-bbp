# ip

create_project baseband . -force

## add files
set ip_constr_files ""
set proj_fileset [get_filesets sources_1]
add_files -norecurse -scan_for_includes -fileset $proj_fileset "circularTable16.v" "Baseband.v" "NCOTableLUT.v" "NCOTableLUT_1.v" "baseband.xdc"
set_property "top" "Baseband" $proj_fileset
set_property USED_IN {synthesis out_of_context} [get_files "baseband.xdc"]

# make ip
ipx::package_project -root_dir . -vendor cs.berkeley.edu -library user -taxonomy /Berkeley
set_property name baseband [ipx::current_core]
set_property vendor_display_name {UC Berkeley} [ipx::current_core]
set_property company_url {http://bwrc.eecs.berkeley.edu} [ipx::current_core]

set i_families ""
foreach i_part [get_parts] {
  lappend i_families [get_property FAMILY $i_part]
}
set i_families [lsort -unique $i_families]
set s_families [get_property supported_families [ipx::current_core]]

foreach i_family $i_families {
  set s_families "$s_families $i_family Production"
  set s_families "$s_families $i_family Beta"
}
set_property supported_families $s_families [ipx::current_core]
ipx::save_core

ipx::remove_all_bus_interface [ipx::current_core]

set memory_maps [ipx::get_memory_maps * -of_objects [ipx::current_core]]
foreach map $memory_maps {
ipx::remove_memory_map [lindex $map 2] [ipx::current_core ]
}
ipx::save_core

set i_filegroup [ipx::get_file_groups -of_objects [ipx::current_core] -filter {NAME =~ *synthesis*}]
foreach i_file $ip_constr_files {
set i_module [file tail $i_file]
regsub {_constr\.xdc} $i_module {} i_module
ipx::add_file $i_file $i_filegroup
ipx::reorder_files -front $i_file $i_filegroup
set_property SCOPED_TO_REF $i_module [ipx::get_files $i_file -of_objects $i_filegroup]
}
ipx::save_core

ipx::infer_bus_interface {\
  s_axi_aclk,
  s_axi_aresetn,
  m_axi_awvalid \
  m_axi_awid \
  m_axi_awaddr \
  m_axi_awlen \
  m_axi_awsize \
  m_axi_awburst \
  m_axi_awlock \
  m_axi_awcache \
  m_axi_awprot \
  m_axi_awready \
  m_axi_wvalid \
  m_axi_wdata \
  m_axi_wstrb \
  m_axi_wlast \
  m_axi_wready \
  m_axi_bvalid \
  m_axi_bid \
  m_axi_bresp \
  m_axi_bready \
  m_axi_arvalid \
  m_axi_arid \
  m_axi_araddr \
  m_axi_arlen \
  m_axi_arsize \
  m_axi_arburst \
  m_axi_arlock \
  m_axi_arcache \
  m_axi_arprot \
  m_axi_arready \
  m_axi_rvalid \
  m_axi_rid \
  m_axi_rdata \
  m_axi_rresp \
  m_axi_rready \
  m_axi_rlast }\
xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

set_property master_address_space_ref m_axi \
  [ipx::get_bus_interfaces m_axi \
  -of_objects [ipx::current_core]]

# ipx::infer_bus_interface m_axi_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
# ipx::infer_bus_interface m_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
#
# ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces m_axi_aclk \
#   -of_objects [ipx::current_core]]

ipx::save_core [ipx::current_core]

ipx::infer_bus_interface s_axi_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface s_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface {\
  s_axi_aclk \
  s_axi_resetn \
  s_axi_awvalid \
  s_axi_awaddr \
  s_axi_awprot \
  s_axi_awready \
  s_axi_wvalid \
  s_axi_wdata \
  s_axi_wstrb \
  s_axi_wready \
  s_axi_bvalid \
  s_axi_bresp \
  s_axi_bready \
  s_axi_arvalid \
  s_axi_araddr \
  s_axi_arprot \
  s_axi_arready \
  s_axi_rvalid \
  s_axi_rdata \
  s_axi_rresp \
  s_axi_rready} \
xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]


set raddr_width [expr [get_property SIZE_LEFT [ipx::get_ports -nocase true s_axi_araddr -of_objects [ipx::current_core]]] + 1]
set waddr_width [expr [get_property SIZE_LEFT [ipx::get_ports -nocase true s_axi_awaddr -of_objects [ipx::current_core]]] + 1]

if {$raddr_width != $waddr_width} {
  puts [format "WARNING: AXI address width mismatch for %s (r=%d, w=%d)" $ip_name $raddr_width, $waddr_width]
  set range 65536
} else {
  if {$raddr_width >= 16} {
    set range 65536
  } else {
    set range [expr 1 << $raddr_width]
  }
}

ipx::add_memory_map {m_axi} [ipx::current_core]
ipx::add_address_block {axi} [ipx::get_memory_maps m_axi -of_objects [ipx::current_core]]
set_property range $range [ipx::get_address_blocks axi \
  -of_objects [ipx::get_memory_maps m_axi -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif m_axi -clock s_axi_aclk -reset s_axi_aresetn [ipx::current_core]
# m_axi_aresetn

ipx::add_memory_map {s_axi} [ipx::current_core]
set_property slave_memory_map_ref {s_axi} [ipx::get_bus_interfaces s_axi -of_objects [ipx::current_core]]
ipx::add_address_block {axi_lite} [ipx::get_memory_maps s_axi -of_objects [ipx::current_core]]
set_property range $range [ipx::get_address_blocks axi_lite \
  -of_objects [ipx::get_memory_maps s_axi -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif s_axi -clock s_axi_aclk -reset s_axi_aresetn [ipx::current_core]
ipx::save_core

# ipx::remove_bus_interface adc_valid_i0 [ipx::current_core]
# ipx::remove_bus_interface adc_valid_i1 [ipx::current_core]
# ipx::remove_bus_interface adc_valid_q0 [ipx::current_core]
# ipx::remove_bus_interface adc_valid_q1 [ipx::current_core]
# ipx::remove_bus_interface adc_data_i0 [ipx::current_core]
# ipx::remove_bus_interface adc_data_i1 [ipx::current_core]
# ipx::remove_bus_interface adc_data_q0 [ipx::current_core]
# ipx::remove_bus_interface adc_data_q1 [ipx::current_core]
#
# ipx::remove_bus_interface dac_valid_i0 [ipx::current_core]
# ipx::remove_bus_interface dac_valid_i1 [ipx::current_core]
# ipx::remove_bus_interface dac_valid_q0 [ipx::current_core]
# ipx::remove_bus_interface dac_valid_q1 [ipx::current_core]
# ipx::remove_bus_interface dac_data_i0 [ipx::current_core]
# ipx::remove_bus_interface dac_data_i1 [ipx::current_core]
# ipx::remove_bus_interface dac_data_q0 [ipx::current_core]
# ipx::remove_bus_interface dac_data_q1 [ipx::current_core]


#ipx::remove_bus_interface reset [ipx::current_core]
#ipx::remove_bus_interface clock [ipx::current_core]


ipx::infer_bus_interface reset xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface clock xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces s_axi_aresetn \
  -of_objects [ipx::current_core]]

set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
  -of_objects [ipx::get_bus_interfaces s_axi_aresetn \
  -of_objects [ipx::current_core]]]

ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces s_axi_aclk \
  -of_objects [ipx::current_core]]

set_property value m_axi:s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
  -of_objects [ipx::get_bus_interfaces s_axi_aclk \
  -of_objects [ipx::current_core]]]

# set_property value s_axi_aclk [ipx::get_bus_parameters CLK_DOMAIN \
#   -of_objects [ipx::get_bus_interfaces s_axi \
#   -of_objects [ipx::current_core]]]
# set_property value s_axi_aclk [ipx::get_bus_parameters CLK_DOMAIN \
#   -of_objects [ipx::get_bus_interfaces m_axi \
#   -of_objects [ipx::current_core]]]


ipx::save_core [ipx::current_core]

