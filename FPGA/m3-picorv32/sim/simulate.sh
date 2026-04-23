#!/bin/bash

if [ "$1" = "EC" ]; then
	echo "Simulate for reduced CPU (Embedded/Compressed) with 16 regs"
	FW_BOOT_FILE="dhry_ec.hex"
	SIM_FLAGS=-DMIN_CPU_CONFIG=1
else
	if [ "$1" = "IM" ]; then
		echo "Simulate for CPU with mul/dev and 32 regs"
		FW_BOOT_FILE="dhry_im.hex"
		SIM_FLAGS=-DMAX_CPU_CONFIG=1
	else
		echo "Please give param EC or IM"
		exit 1
	fi
fi

if [ -f "$FW_BOOT_FILE" ]; then
    echo "Firmware Boot File exists: ${FW_BOOT_FILE}"
else
    echo "Firmware Boot File DOES NOT exist: ${FW_BOOT_FILE}, first build FW!"
	exit 1
fi

export PRV32_DIR=../../../riscv-cores/picorv32
export COMMON_DIR=../../common
export FIFO_DIR=${COMMON_DIR}/generic_fifos/rtl/verilog/
rm -f qqq
iverilog -o qqq -DSIMULATION=1 ${SIM_FLAGS} -I${FIFO_DIR} testbench.v ../soc.v ../seg4x7.v ${COMMON_DIR}/sserial.v ${PRV32_DIR}/picorv32.v pll4sim.v sram4sim.v ${FIFO_DIR}/generic_dpram.v ${FIFO_DIR}/generic_fifo_dc_gray.v
vvp qqq
