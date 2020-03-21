WPWD=$(shell sh -c 'pwd -W')
PWD=$(shell pwd)

CC=gcc
CFLAGS=-O2

ifeq ($(OS),Msys)
WPWD=$(shell sh -c 'pwd -W')
PYTHONPATH := $(PWD)/../cosim;$(PYTHONPATH)
else
WPWD=$(shell pwd)
PYTHONPATH := $(PWD)/../cosim:$(PYTHONPATH)
endif

VERILOG_DIR = ../
VERILOG_SOURCES = $(VERILOG_DIR)/Baseband.v \
				  $(VERILOG_DIR)/AsyncResetReg.v \
				  $(VERILOG_DIR)/circularTable16.v \
				  $(VERILOG_DIR)/NCOTableLUT.v \
				  $(VERILOG_DIR)/NCOTableLUT_1.v \
				  $(VERILOG_DIR)/AXI4SingleTapChannel.v

TOPLEVEL = Baseband

MODULE=BasebandTB

LD_LIBRARY_PATH := $(PWD)/../cosim:$(LD_LIBRARY_PATH)

include $(shell cocotb-config --makefiles)/Makefile.inc
include $(shell cocotb-config --makefiles)/Makefile.sim

$(VERILOG_SOURCES):
	cd .. && $(MAKE) Baseband.v

.icarus_touchup.stamp: ../Baseband.v
	./touchup_for_icarus.sh ../Baseband.v
	touch .icarus_touchup.stamp


# Stuff below is useful for profiling
# Need gprof2dot from https://github.com/jrfonseca/gprof2dot
test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	gprof2dot -f pstats $< | dot -Tsvg -o $@

TX_PATH := ../../sw/

tx_wrap.c tx.py: $(TX_PATH)/tx.c $(TX_PATH)/tx.h $(TX_PATH)/tx.i
	swig -outcurrentdir -python $(TX_PATH)/tx.i

_tx.so: $(TX_PATH)/tx.c $(TX_PATH)/tx.h $(TX_PATH)/third_party/fft4g.c tx_wrap.c
	$(CC) $(CFLAGS) -shared -fpic `python-config --cflags` $(TX_PATH)/tx.c $(TX_PATH)/third_party/fft4g.c tx_wrap.c -I$(TX_PATH) -o _tx.so

sim_build: _tx.so tx.py .icarus_touchup.stamp

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg


clean::
	-rm -rf test_profile.pstat
	-rm -rf callgraph.svg
	-rm -rf build sim_build __pycache__
	-rm tx_wrap.c tx.py _tx.so
