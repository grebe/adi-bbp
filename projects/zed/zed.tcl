# project

set ad_hdl_dir $::env(ADI_HDL_DIR)
set ad_phdl_dir $::env(ADI_HDL_DIR)

source $ad_hdl_dir/projects/scripts/adi_board.tcl
source $ad_hdl_dir/projects/scripts/adi_project.tcl

set sys_zynq 1

create_project zed . -part xc7z020clg484-1 -force

set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property ip_repo_paths [list $ad_hdl_dir/library ../../ip]  [current_fileset]

update_ip_catalog

create_bd_design "system"

source ../common/common.tcl
source $ad_hdl_dir/projects/common/zed/zed_system_bd.tcl
source $ad_hdl_dir/projects/fmcomms2/common/fmcomms2_bd.tcl

make_baseband 0x79040000
update_rxtx baseband

update_bd
make_targets zed.srcs/sources_1

adi_project_files zed [list \
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/fmcomms2/zed/system_top.v" \
  "$ad_hdl_dir/projects/fmcomms2/zed/system_constr.xdc"\
  "$ad_hdl_dir/projects/common/zed/zed_system_constr.xdc" ]

#start_gui

#adi_project_run zc706

#launch_runs impl_1 -to_step write_bitstream -jobs 8
#wait_on_run impl_1


## the following snipped builds the design and
# instantiates and connects ILAs that connect to any nets
# that have the "mark_debug" property set

#launch_runs synth_1 -jobs 8
#wait_on_run synth_1
#open_run synth_1 -name synth_1
#source ../scripts/new_batch_insert_ila.tcl
#batch_insert_ila 1024
#close_design
#set_property constrset debug_constraints.xdc [get_runs synth_1]
#set_property constrset debug_constraints.xdc [get_runs impl_1]
#
#reset_run synth_1
#launch_runs impl_1 -to_step write_bitstream -jobs 8
#wait_on_run impl_1

# standard build

#start_gui
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

