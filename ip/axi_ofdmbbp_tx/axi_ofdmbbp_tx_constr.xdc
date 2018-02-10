
#set_property shreg_extract no [get_cells -hier -filter {name =~ *dac_enable*}]
set_property shreg_extract no [get_cells -hier -filter {name =~ *dac_sync*}]
set_property shreg_extract no [get_cells -hier -filter {name =~ *ad_rst_sync*}]
#
set_false_path -from [get_cells -hier -filter {name =~ *s_dac_sync_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *dac_sync_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *s_adc_sync_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *adc_sync_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *s_dac_ack_t_reg  && IS_SEQUENTIAL}]       -to [get_cells -hier -filter {name =~ *up_dac_ack_t_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *s_adc_ack_t_reg  && IS_SEQUENTIAL}]       -to [get_cells -hier -filter {name =~ *up_adc_ack_t_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *up_dac_enable_reg  && IS_SEQUENTIAL}]     -to [get_cells -hier -filter {name =~ *dac_enable_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *up_dac_req_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *s_dac_req_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *up_adc_req_reg  && IS_SEQUENTIAL}]        -to [get_cells -hier -filter {name =~ *s_adc_req_m1_reg  && IS_SEQUENTIAL}]
set_false_path -from [get_cells -hier -filter {name =~ *up_dac_preset_reg  && IS_SEQUENTIAL}]     -to [get_cells -hier -filter {name =~ *ad_rst_sync_m1_reg  && IS_SEQUENTIAL}]
#set_false_path -from [get_cells -hier -filter {name =~ *up_adc_preset_reg  && IS_SEQUENTIAL}]     -to [get_cells -hier -filter {name =~ *ad_rst_sync_m1_reg  && IS_SEQUENTIAL}]
#
#set_property ram_style block [get_cells -hier  -filter {name =~ *i_dac_mem_1}]
set_property ram_style block [get_cells -hier  -filter {name =~ *i_dac_mem_2}]
#set_property ram_style block [get_cells -hier  -filter {name =~ *i_adc_mem_1}]
#set_property ram_style block [get_cells -hier  -filter {name =~ *i_adc_mem_2}]
#
