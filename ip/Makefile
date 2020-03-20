M_DIR := $(shell pwd)
CHISEL_DIR := $(shell pwd)/../
IVYS := $(shell find ~/.ivy2/local/ -name *.jar)
CHISEL_SRCS := \
	$(shell find ../src -name *.scala) $(IVYS)

export ADI_HDL_DIR := $(M_DIR)/../hdl
export ADI_PHDL_DIR := $(M_DIR)/../hdl
# export ADI_IGNORE_VERSION_CHECK := 1

M_DEPS := baseband_ip.tcl
M_DEPS += baseband.xdc
M_DEPS += Baseband.v

M_VIVADO := vivado -mode batch -source

M_FLIST := *.cache
M_FLIST += *.hw
M_FLIST += *.ip_user_files
M_FLIST += *.data
M_FLIST += *.xpr
M_FLIST += *.log
M_FLIST += component.xml
M_FLIST += *.jou
M_FLIST +=  xgui
M_FLIST += .Xil
M_FLIST += *.json
M_FLIST += *.fir

.PHONY: all clean clean-all
all: baseband.xpr

clean:clean-all

clean-all:
	rm -rf $(M_FLIST)

baseband.xpr: $(M_DEPS)
	rm -rf $(M_FLIST)
	$(M_VIVADO) baseband_ip.tcl  |& tee baseband.log

sim: baseband.xpr
	$(M_VIVADO) baseband_test.tcl |& tee baseband_test.log
.PHONY: sim

xilinx: baseband.xpr
.PHONY: xilinx

-include Makefrag.mill

Baseband.v: $(CHISEL_SRCS)
	cd $(CHISEL_DIR) && sbt "run -td $(M_DIR) -foaf Baseband.anno.json -X low"
	cd $(CHISEL_DIR) && sbt "run -td $(M_DIR) -foaf Baseband.anno.json -X verilog"

Baseband.fir: $(CHISEL_SRCS)
	cd $(CHISEL_DIR) && sbt "run -td $(M_DIR) -X low -ll trace --full-stacktrace" 
