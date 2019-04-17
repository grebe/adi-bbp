set ad_hdl_dir $::env(ADI_HDL_DIR)
set ad_phdl_dir $::env(ADI_HDL_DIR)

source $ad_hdl_dir/projects/scripts/adi_board.tcl
source $ad_hdl_dir/projects/scripts/adi_project.tcl

set sys_zynq 1

create_project zc706 . -part xc7z045ffg900-2 -force

set_param general.maxThreads 6

add_files -norecurse -fileset sources_1 [list \
  "system_top.v" \
  "system_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/zc706/zc706_system_constr.xdc" \
]
set_property top system_top [current_fileset]

set_property board_part xilinx.com:zc706:part0:1.2 [current_project]
set_property ip_repo_paths [list $ad_hdl_dir/library ../../ip]  [current_fileset]
update_ip_catalog

create_bd_design "system"

# write_hwdef -file "zc706.sdk/system_top.hdf"

source ../common/common.tcl
source $ad_hdl_dir/projects/common/zc706/zc706_system_bd.tcl
source $ad_hdl_dir/projects/fmcomms2/common/fmcomms2_bd.tcl

make_baseband 0x79040000
get_bd_designs -verbose
update_rxtx axi_ad9361 Baseband

update_bd
make_targets zc706.srcs/sources_1

project_run_synth zc706

add_ila

project_run_impl zc706

source $ad_hdl_dir/library/axi_ad9361/axi_ad9361_delay.tcl


#start_gui

#adi_project_run zc706

#launch_runs impl_1 -to_step write_bitstream -jobs 8
#wait_on_run impl_1


## the following snipped builds the design and
# instantiates and connects ILAs that connect to any nets
# that have the "mark_debug" property set

#launch_runs synth_1 -jobs 12 #wait_on_run synth_1
#open_run synth_1 -name synth_1
#source ../scripts/new_batch_insert_ila.tcl
#batch_insert_ila 1024
#close_design
#set_property constrset debug_constraints.xdc [get_runs synth_1]
#set_property constrset debug_constraints.xdc [get_runs impl_1]
#
#reset_run synth_1
#launch_runs impl_1 -to_step write_bitstream -jobs 12
#wait_on_run impl_1

#start_gui

# standard build

# launch_runs impl_1 -to_step write_bitstream -jobs 12
# wait_on_run impl_1
# start_gui
# synth_design -rtl
