set ad_hdl_dir $::env(ADI_HDL_DIR)
set ad_phdl_dir $::env(ADI_HDL_DIR)

source $ad_hdl_dir/projects/scripts/adi_board.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl

set sys_zynq 1

create_project zc706 . -part xc7z045ffg900-2 -force

set_param general.maxThreads 8

add_files -norecurse -fileset sources_1 [list \
  "system_top.v" \
  "system_constr.xdc" \
  "$ad_hdl_dir/library/xilinx/common/ad_iobuf.v" \
  "$ad_hdl_dir/projects/common/zc706/zc706_system_constr.xdc" \
]
set_property top system_top [current_fileset]

set_property board_part xilinx.com:zc706:part0:1.2 [current_project]

if {[file exists $ad_hdl_dir/ipcache] == 0} {
  file mkdir $ad_hdl_dir/ipcache
}
config_ip_cache -import_from_project -use_cache_location $ad_hdl_dir/ipcache

set_property ip_repo_paths [list $ad_hdl_dir/library ../../ip]  [current_fileset]
update_ip_catalog

create_bd_design "system"

# write_hwdef -file "zc706.sdk/system_top.hdf"

source ../common/common.tcl

# begin projects/fmcomms2/zc706/system_bd.tcl, which uses bad imports
source $ad_hdl_dir/projects/common/zc706/zc706_system_bd.tcl
source $ad_hdl_dir/projects/fmcomms2/common/fmcomms2_bd.tcl

ad_ip_parameter axi_sysid_0 CONFIG.ROM_ADDR_BITS 9
ad_ip_parameter rom_sys_0 CONFIG.PATH_TO_FILE "[pwd]/mem_init_sys.txt"
ad_ip_parameter rom_sys_0 CONFIG.ROM_ADDR_BITS 9
set sys_cstring "sys rom custom string placeholder"
sysid_gen_sys_init_file $sys_cstring

ad_ip_parameter axi_ad9361 CONFIG.ADC_INIT_DELAY 20
# end projects/fmcomms2/zc706/system_bd.tcl

make_baseband 0x79040000
get_bd_designs -verbose
update_rxtx axi_ad9361 Baseband

update_bd
make_targets zc706.srcs/sources_1


project_run_synth zc706

# create_pblock pblock_rx
# add_cells_to_pblock pblock_rx [get_cells -hier -regexp .*/baseband/inst/sAxiIsland/.*] -clear_locs
# place_pblocks -effort HIGH -utilization 45 [get_pblocks [list pblock_rx]]

create_pblock pblock_freqRx
add_cells_to_pblock pblock_freqRx [get_cells -hier -regexp .*/baseband/inst/sAxiIsland/freqRx/freqRx] -clear_locs

create_pblock pblock_timeRx
add_cells_to_pblock pblock_timeRx [get_cells -hier -regexp .*/baseband/inst/sAxiIsland/timeRx/rx] -clear_locs

# create_pblock pblock_baseband_crossings
# add_cells_to_pblock pblock_baseband_crossings [get_cells -hier -regexp .*/baseband/inst/.*/AsyncQueueS.*] -clear_locs
# add_cells_to_pblock pblock_baseband_crossings [get_cells -hier -regexp .*/baseband/inst/sAxiIsland/.*/AsyncQueueS.*] -clear_locs
#
# place_pblocks -effort HIGH -utilization 40 [get_pblocks [list pblock_timeRx]]
# place_pblocks -effort HIGH -utilization 55 [get_pblocks [list pblock_freqRx]]
resize_pblock pblock_timeRx -add SLICE_X0Y210:SLICE_X163Y50
resize_pblock pblock_freqRx -add SLICE_X0Y170:SLICE_X163Y0


# set_property DONT_TOUCH true [get_nets -hier -regexp .*/axi_hp3_interconnect/S00_AXI_.*]
# set_property mark_debug true [get_nets -hier -regexp .*/axi_hp3_interconnect/S00_AXI_.*]
# set_property DONT_TOUCH true [get_nets -hier -regexp .*/axi_hp3_interconnect/M00_AXI_.*]
# set_property mark_debug true [get_nets -hier -regexp .*/axi_hp3_interconnect/M00_AXI_.*]

add_ila
place_ila

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
