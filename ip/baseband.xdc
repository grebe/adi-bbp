set_property ASYNC_REG true [get_cells -hier -regexp .*/AsyncQueueSink.*/widx_gray/sync_.*/reg.*/q_reg]
set_property ASYNC_REG true [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/sync_.*/reg.*/q_reg]
set_property ASYNC_REG true [get_cells -hier -regexp .*/AsyncQueueSource.*/AsyncValidSync.*/sync_.*/reg.*/q_reg]

# set_false_path -from [get_cells -hier -regexp .*/AsyncQueueSource.*/mem.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/.*/sync.*]
# # set_false_path -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*]
# # set_false_path -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*/q_reg.*/.*]
# set_false_path -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_bin/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
# set_false_path -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
# set_false_path -from [get_cells -hier -regexp .*/AsyncQueueSink.*/reg_0/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/reg_0/.*]
# set_false_path -from [get_cells -hier -regexp .*/AsyncQueueSource.*/widx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/widx_gray/.*]
# 
set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSource.*/mem.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/.*/sync.*]
# set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*]
# set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*/q_reg.*/.*]
set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_bin/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSink.*/reg_0/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/reg_0/.*]
set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSource.*/widx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/widx_gray/.*]
set_max_delay 10 -from [get_nets -hier -regexp .*/baseband/s_axi_reset] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/sync_0]
set_max_delay 10 -from [get_nets -hier -regexp .*/baseband/reset] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/sync_.*/reg_0/q_reg]

# set_max_delay 10 -datapath_only -from [get_cells -hier -regexp .*/AsyncQueueSource] -to [get_cells -hier -regexp .*/AsyncQueueSink]

set_bus_skew -from [get_cells -hier -regexp .*/AsyncQueueSource.*/mem.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/.*/sync.*] 2.0
# set_bus_skew -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*]
# set_bus_skew -from [get_cells -hier -regexp .*/rst_reg] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/.*/sync.*/q_reg.*/.*]
set_bus_skew -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_bin/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
set_bus_skew -from [get_cells -hier -regexp .*/AsyncQueueSink.*/reg_0/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/reg_0/.*]
set_bus_skew -from [get_cells -hier -regexp .*/AsyncQueueSink.*/ridx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSource.*/ridx_gray/.*]
set_bus_skew -from [get_cells -hier -regexp .*/AsyncQueueSource.*/widx_gray/.*] -to [get_cells -hier -regexp .*/AsyncQueueSink.*/widx_gray/.*]

# set_property shreg_extract no [get_cells -hier -filter {name =~ *ad_rst_sync*}]

# set_false_path -from [get_cells -hier -filter {name =~ *s_adc_sync_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *adc_sync_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *up_adc_req_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *s_adc_req_m1_reg  && IS_SEQUENTIAL}]
# set_false_path -from [get_cells -hier -filter {name =~ *up_adc_preset_reg  && IS_SEQUENTIAL}]     -to [get_cells -hier -filter {name =~ *ad_rst_sync_m1_reg  && IS_SEQUENTIAL}]

# set_property ram_style block [get_cells -hier  -filter {name =~ *i_adc_mem_2}]
