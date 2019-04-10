set ad_hdl_dir $::env(ADI_HDL_DIR)
set ad_phdl_dir $::env(ADI_HDL_DIR)

source ../common/common.tcl
source $ad_hdl_dir/projects/common/zc706/zc706_system_bd.tcl
source $ad_hdl_dir/projects/fmcomms2/common/fmcomms2_bd.tcl

make_baseband 0x79040000
get_bd_designs -verbose
update_rxtx axi_ad9361 Baseband

update_bd
make_targets zc706.srcs/sources_1
