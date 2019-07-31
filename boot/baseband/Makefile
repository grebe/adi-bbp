ifneq (${KERNELRELEASE},)
obj-m += baseband.o

else
KERNEL_SOURCE ?= ../linux/
PWD=$(shell pwd)
endif

default:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} modules

clean:
	${MAKE} -C ${KERNEL_SOURCE} SUBDIRS=${PWD} clean
