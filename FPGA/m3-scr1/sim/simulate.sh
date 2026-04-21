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

SIM_DIR=${PWD}
echo "Patching SCR1 project.."
cd ../
tclsh patch/patch.tcl
echo "Patching SCR1 project done.."
cd ${SIM_DIR}

rm -f obj_dir
verilator -cc -Wno-fatal --no-timing \
	-sv +1800-2017ext+sv \
	--exe ${PWD}/tb.cpp \
	-DSIMULATION=1 \
	-DSCR1_TRGT_SIMULATION=1 \
	-DSCR1_ARCH_CUSTOM=1 \
	-I../../../FPGA/m3-scr1 \
	-I../../../riscv-cores/scr1/src/includes \
	-I${FIFO_DIR} \
	--top-module max10 \
	../../m3-scr1/max10.v \
	${COMMON_DIR}/sserial.v \
	${FIFO_DIR}/generic_dpram.v \
	${FIFO_DIR}/generic_fifo_dc_gray.v \
	../../../riscv-cores/scr1/src/core/primitives/scr1_reset_cells.sv \
	../../../riscv-cores/scr1/src/core/primitives/scr1_cg.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_tracelog.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_top.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_tdu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_mprf.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_lsu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_ifu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_idu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_ialu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_hdu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_exu.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_pipe_csr.sv \
	../../../riscv-cores/scr1/src/core/pipeline/scr1_ipic.sv \
	../../../riscv-cores/scr1/src/core/scr1_tapc_synchronizer.sv \
	../../../riscv-cores/scr1/src/core/scr1_tapc_shift_reg.sv \
	../../../riscv-cores/scr1/src/core/scr1_tapc.sv \
	../../../riscv-cores/scr1/src/core/scr1_scu.sv \
	../../../riscv-cores/scr1/src/core/scr1_dmi.sv \
	../../../riscv-cores/scr1/src/core/scr1_dm.sv \
	../../../riscv-cores/scr1/src/core/scr1_core_top.sv \
	../../../riscv-cores/scr1/src/core/scr1_clk_ctrl.sv \
	../../../riscv-cores/scr1/src/top/scr1_top_ahb.sv \
	../../../riscv-cores/scr1/src/top/scr1_timer.sv \
	../../../riscv-cores/scr1/src/top/scr1_tcm.sv \
	../../../riscv-cores/scr1/src/top/scr1_imem_router.sv \
	../../../riscv-cores/scr1/src/top/scr1_imem_ahb.sv \
	../../../riscv-cores/scr1/src/top/scr1_dp_memory.sv \
	../../../riscv-cores/scr1/src/top/scr1_dmem_router.sv \
	../../../riscv-cores/scr1/src/top/scr1_dmem_ahb.sv

cd obj_dir
make -f Vmax10.mk
