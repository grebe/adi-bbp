
# constraints
# ad9361

set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_p]
set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_clk_in_n]
set_property -dict {PACKAGE_PIN AF15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_p]
set_property -dict {PACKAGE_PIN AG15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports rx_frame_in_n]
set_property -dict {PACKAGE_PIN AE12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[0]}]
set_property -dict {PACKAGE_PIN AF12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[0]}]
set_property -dict {PACKAGE_PIN AG12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[1]}]
set_property -dict {PACKAGE_PIN AH12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[1]}]
set_property -dict {PACKAGE_PIN AJ15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[2]}]
set_property -dict {PACKAGE_PIN AK15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[2]}]
set_property -dict {PACKAGE_PIN AE16 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[3]}]
set_property -dict {PACKAGE_PIN AE15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[3]}]
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[4]}]
set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[4]}]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_p[5]}]
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVDS_25 DIFF_TERM 1} [get_ports {rx_data_in_n[5]}]
set_property -dict {PACKAGE_PIN AD14 IOSTANDARD LVDS_25} [get_ports tx_clk_out_p]
set_property -dict {PACKAGE_PIN AD13 IOSTANDARD LVDS_25} [get_ports tx_clk_out_n]
set_property -dict {PACKAGE_PIN AH14 IOSTANDARD LVDS_25} [get_ports tx_frame_out_p]
set_property -dict {PACKAGE_PIN AH13 IOSTANDARD LVDS_25} [get_ports tx_frame_out_n]
set_property -dict {PACKAGE_PIN AJ16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[0]}]
set_property -dict {PACKAGE_PIN AK16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[0]}]
set_property -dict {PACKAGE_PIN AD16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[1]}]
set_property -dict {PACKAGE_PIN AD15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[1]}]
set_property -dict {PACKAGE_PIN AH17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[2]}]
set_property -dict {PACKAGE_PIN AH16 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[2]}]
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[3]}]
set_property -dict {PACKAGE_PIN AC13 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[3]}]
set_property -dict {PACKAGE_PIN AF18 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[4]}]
set_property -dict {PACKAGE_PIN AF17 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[4]}]
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVDS_25} [get_ports {tx_data_out_p[5]}]
set_property -dict {PACKAGE_PIN AB14 IOSTANDARD LVDS_25} [get_ports {tx_data_out_n[5]}]
set_property -dict {PACKAGE_PIN AE18 IOSTANDARD LVCMOS25} [get_ports enable]
set_property -dict {PACKAGE_PIN AE17 IOSTANDARD LVCMOS25} [get_ports txnrx]
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS25} [get_ports tdd_sync]

set_property -dict {PACKAGE_PIN AG26 IOSTANDARD LVCMOS25} [get_ports {gpio_status[0]}]
set_property -dict {PACKAGE_PIN AG27 IOSTANDARD LVCMOS25} [get_ports {gpio_status[1]}]
set_property -dict {PACKAGE_PIN AH28 IOSTANDARD LVCMOS25} [get_ports {gpio_status[2]}]
set_property -dict {PACKAGE_PIN AH29 IOSTANDARD LVCMOS25} [get_ports {gpio_status[3]}]
set_property -dict {PACKAGE_PIN AK27 IOSTANDARD LVCMOS25} [get_ports {gpio_status[4]}]
set_property -dict {PACKAGE_PIN AK28 IOSTANDARD LVCMOS25} [get_ports {gpio_status[5]}]
set_property -dict {PACKAGE_PIN AJ26 IOSTANDARD LVCMOS25} [get_ports {gpio_status[6]}]
set_property -dict {PACKAGE_PIN AK26 IOSTANDARD LVCMOS25} [get_ports {gpio_status[7]}]
set_property -dict {PACKAGE_PIN AF30 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[0]}]
set_property -dict {PACKAGE_PIN AG30 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[1]}]
set_property -dict {PACKAGE_PIN AF29 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[2]}]
set_property -dict {PACKAGE_PIN AG29 IOSTANDARD LVCMOS25} [get_ports {gpio_ctl[3]}]
set_property -dict {PACKAGE_PIN AH26 IOSTANDARD LVCMOS25} [get_ports gpio_en_agc]
set_property -dict {PACKAGE_PIN AH27 IOSTANDARD LVCMOS25} [get_ports gpio_sync]
set_property -dict {PACKAGE_PIN AD25 IOSTANDARD LVCMOS25} [get_ports gpio_resetb]

set_property PACKAGE_PIN AJ30 [get_ports spi_csn]
set_property IOSTANDARD LVCMOS25 [get_ports spi_csn]
set_property PULLUP true [get_ports spi_csn]
set_property -dict {PACKAGE_PIN AK30 IOSTANDARD LVCMOS25} [get_ports spi_clk]
set_property -dict {PACKAGE_PIN AJ28 IOSTANDARD LVCMOS25} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN AJ29 IOSTANDARD LVCMOS25} [get_ports spi_miso]

# spi pmod J58

set_property PACKAGE_PIN AJ21 [get_ports spi_udc_csn_tx]
set_property IOSTANDARD LVCMOS25 [get_ports spi_udc_csn_tx]
set_property PULLUP true [get_ports spi_udc_csn_tx]
set_property PACKAGE_PIN Y20 [get_ports spi_udc_csn_rx]
set_property IOSTANDARD LVCMOS25 [get_ports spi_udc_csn_rx]
set_property PULLUP true [get_ports spi_udc_csn_rx]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS25} [get_ports spi_udc_sclk]
set_property -dict {PACKAGE_PIN AK21 IOSTANDARD LVCMOS25} [get_ports spi_udc_data]

set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS25} [get_ports gpio_muxout_tx]
set_property -dict {PACKAGE_PIN AC18 IOSTANDARD LVCMOS25} [get_ports gpio_muxout_rx]


# clocks
create_clock -period 4.000 -name rx_clk [get_ports rx_clk_in_p]

# Input Delays
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.25 [get_ports {rx_data_in_n[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.25 [get_ports {rx_data_in_n[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.25 [get_ports {rx_data_in_n[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.25 [get_ports {rx_data_in_n[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.25 [get_ports {rx_data_in_p[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.25 [get_ports {rx_data_in_p[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.25 [get_ports {rx_data_in_p[*]}]
# set_input_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.25 [get_ports {rx_data_in_p[*]}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -min -add_delay [get_ports {iic_scl}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -max -add_delay [get_ports {iic_scl}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -min -add_delay [get_ports {iic_sda}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -max -add_delay [get_ports {iic_sda}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.25 [get_ports {rx_frame_in_n}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.25 [get_ports {rx_frame_in_n}]
# set_input_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.25 [get_ports {rx_frame_in_n}]
# set_input_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.25 [get_ports {rx_frame_in_n}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.25 [get_ports {rx_frame_in_p}]
# set_input_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.25 [get_ports {rx_frame_in_p}]
# set_input_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.25 [get_ports {rx_frame_in_p}]
# set_input_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.25 [get_ports {rx_frame_in_p}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -min -add_delay [get_ports {tdd_sync}]
# set_input_delay -clock [get_clocks {clk_fpga_0}] -max -add_delay [get_ports {tdd_sync}]

# Output Delays
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.0 [get_ports {tx_data_out_n[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.0 [get_ports {tx_data_out_n[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.0 [get_ports {tx_data_out_n[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.0 [get_ports {tx_data_out_n[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.0 [get_ports {tx_data_out_p[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.0 [get_ports {tx_data_out_p[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.0 [get_ports {tx_data_out_p[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.0 [get_ports {tx_data_out_p[*]}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.0 [get_ports {tx_frame_out_n}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.0 [get_ports {tx_frame_out_n}]
# set_output_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.0 [get_ports {tx_frame_out_n}]
# set_output_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.0 [get_ports {tx_frame_out_n}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -min -add_delay 0.0 [get_ports {tx_frame_out_p}]
# set_output_delay -clock [get_clocks {rx_clk}] -clock_fall -max -add_delay 1.0 [get_ports {tx_frame_out_p}]
# set_output_delay -clock [get_clocks {rx_clk}] -min -add_delay 0.0 [get_ports {tx_frame_out_p}]
# set_output_delay -clock [get_clocks {rx_clk}] -max -add_delay 1.0 [get_ports {tx_frame_out_p}]

# False paths in baseband CDC
set_false_path \
      -from i_system_wrapper/system_i/baseband/inst/axi4asink/AsyncQueueSource_1/mem_1_id_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4asource/AsyncQueueSink_1/deq_bits_reg/sync_0_reg[2]/D
set_false_path \
      -from i_system_wrapper/system_i/axi_ad9361/inst/i_rx/i_up_adc_common/i_core_rst_reg/rst_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4asource/AsyncQueueSource_1/AsyncValidSync_1/source_extend/sync_0/reg_0/q_reg/CLR
set_false_path \
      -from i_system_wrapper/system_i/axi_ad9361/inst/i_rx/i_up_adc_common/i_core_rst_reg/rst_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4streamasource/AsyncQueueSource/AsyncValidSync/sink_valid/sync_0/reg_0/q_reg/CLR
set_false_path \
      -from i_system_wrapper/system_i/axi_ad9361/inst/i_rx/i_up_adc_common/i_core_rst_reg/rst_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4streamasource/AsyncQueueSource/AsyncValidSync/sink_valid/sync_1/reg_0/q_reg/CLR
set_false_path \
      -from i_system_wrapper/system_i/axi_ad9361/inst/i_rx/i_up_adc_common/i_core_rst_reg/rst_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4streamasource/AsyncQueueSource/AsyncValidSync/sink_valid/sync_2/reg_0/q_reg/CLR
set_false_path \
      -from i_system_wrapper/system_i/axi_ad9361/inst/i_rx/i_up_adc_common/i_core_rst_reg/rst_reg/C \
      -to i_system_wrapper/system_i/baseband/inst/sAxiIsland/axi4streamasource/AsyncQueueSource/AsyncValidSync/sink_valid/sync_3/reg_0/q_reg/CLR
set_false_path \
      -from i_system_wrapper/system_i/sys_rstgen/U0/ACTIVE_LOW_PR_OUT_DFF[0].FDRE_PER_N/C \
      -to i_system_wrapper/system_i/baseband/inst/axi4asink/AsyncQueueSink_1/AsyncValidSync/sink_valid/sync_3/reg_0/q_reg/CLR

