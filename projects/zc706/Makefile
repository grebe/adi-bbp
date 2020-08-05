####################################################################################
####################################################################################

PROJECT_NAME := fmcomms2_baseband_zc706

M_DIR := $(shell pwd)

export ADI_HDL_DIR := $(M_DIR)/../../hdl
export ADI_PHDL_DIR := $(M_DIR)/../../hdl
export ADI_IGNORE_VERSION_CHECK := 1

M_DEPS += $(ADI_HDL_DIR)/projects/fmcomms2/common/fmcomms2_bd.tcl
M_DEPS += $(ADI_HDL_DIR)/projects/common/zc706/zc706_system_constr.xdc
M_DEPS += $(ADI_HDL_DIR)/projects/common/zc706/zc706_system_bd.tcl
M_DEPS += $(ADI_HDL_DIR)/library/xilinx/common/ad_iobuf.v
M_DEPS += $(ADI_HDL_DIR)/library/axi_ad9361/axi_ad9361_delay.tcl
M_DEPS += ../../ip/baseband.xpr

LIB_DEPS += axi_ad9361
LIB_DEPS += axi_clkgen
LIB_DEPS += axi_dmac
LIB_DEPS += axi_hdmi_tx
LIB_DEPS += axi_spdif_tx
LIB_DEPS += axi_sysid
LIB_DEPS += sysid_rom
LIB_DEPS += util_pack/util_cpack2
LIB_DEPS += util_pack/util_upack2
LIB_DEPS += util_rfifo
LIB_DEPS += util_tdd_sync
LIB_DEPS += util_wfifo
LIB_DEPS += xilinx/util_clkdiv

include $(ADI_HDL_DIR)/projects/scripts/project-xilinx.mk

#M_VIVADO := vivado -mode batch -source
M_VIVADO := vivado -mode tcl -source

M_FLIST := *.cache
M_FLIST += *.hw
M_FLIST += *.ip_user_files
M_FLIST += *.data
M_FLIST += *.xpr
M_FLIST += *.log
M_FLIST += *.jou
M_FLIST +=  xgui
M_FLIST += *.runs
M_FLIST += *.srcs
M_FLIST += *.sdk
M_FLIST += *.sim
M_FLIST += *.str
M_FLIST += *.ioplanning
M_FLIST += *.ltx
M_FLIST += .Xil

.PHONY: all clean clean-all
all: ../../ip/baseband.xpr zc706.sdk/system_top.hdf

../../ip/baseband.xpr:
	make -C ../../ip/
# clean: 
# 	rm -rf $(M_FLIST)
# 
# clean-all:clean
# 	make -C $(ADI_HDL_DIR)/library/axi_clkgen clean
# 	make -C $(ADI_HDL_DIR)/library/axi_hdmi_tx clean
# 	make -C $(ADI_HDL_DIR)/library/axi_spdif_tx clean
# 	make -C $(ADI_HDL_DIR)/library/axi_dmac clean
# 	make -C $(ADI_HDL_DIR)/library/util_clkdiv clean
# 	make -C $(ADI_HDL_DIR)/library/util_cpack clean
# 	make -C $(ADI_HDL_DIR)/library/util_upack clean
# 	make -C $(ADI_HDL_DIR)/library/util_rfifo clean
# 	make -C $(ADI_HDL_DIR)/library/util_wfifo clean
# 	make -C $(ADI_HDL_DIR)/library/util_tdd_sync clean
# 	make -C $(ADI_HDL_DIR)/library/axi_ad9361 clean
# 	make -C ../../ip clean


#zc706.sdk/system_top.hdf: $(M_DEPS)
#	rm -rf $(M_FLIST)
#	$(M_VIVADO) system_project.tcl |& tee zc706.log

#	$(M_VIVADO) zc706.tcl >> zc706_vivado.log 2>&1


# lib:
# 	make -C $(ADI_HDL_DIR)/library/axi_clkgen
# 	make -C $(ADI_HDL_DIR)/library/axi_hdmi_tx
# 	make -C $(ADI_HDL_DIR)/library/axi_spdif_tx
# 	make -C $(ADI_HDL_DIR)/library/axi_dmac
# 	make -C $(ADI_HDL_DIR)/library/util_clkdiv
# 	make -C $(ADI_HDL_DIR)/library/util_cpack
# 	make -C $(ADI_HDL_DIR)/library/util_upack
# 	make -C $(ADI_HDL_DIR)/library/util_wfifo
# 	make -C $(ADI_HDL_DIR)/library/util_rfifo
# 	make -C $(ADI_HDL_DIR)/library/util_tdd_sync
# 	make -C $(ADI_HDL_DIR)/library/axi_ad9361
# 	make -C ../../ip/

####################################################################################
####################################################################################
