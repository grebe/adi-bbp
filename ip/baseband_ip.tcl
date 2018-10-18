# ip

set ad_hdl_dir $::env(ADI_HDL_DIR)
set ad_phdl_dir $::env(ADI_HDL_DIR)

source $ad_hdl_dir/library/scripts/adi_ip.tcl

adi_ip_create baseband
adi_ip_files baseband [list \
  "baseband.xdc" \
  "Baseband.v" ]

adi_ip_properties baseband

ipx::remove_bus_interface reset [ipx::current_core]
ipx::remove_bus_interface clock [ipx::current_core]

# ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces s_axi_aclk \
#   -of_objects [ipx::current_core]]

# set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF \
#   -of_objects [ipx::get_bus_interfaces s_axi_aclk \
#   -of_objects [ipx::current_core]]]

ipx::save_core [ipx::current_core]

