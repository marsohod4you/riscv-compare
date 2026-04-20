#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <OPT>"
  echo "Where OPT is either EC (16 regs, embedded/compressed) or IM (32 regs with mul/div)"
  exit 1
fi

export PATH=$PATH:/d/altera/syntacore/sc-dt-2025.09-Win/sc-dt/riscv-gcc/bin
export PATH=$PATH:/d/Programs/Python311/

if [ "$1" = "EC" ]; then
	echo "BUILD FOR Embedded/Compressed code with 16 regs"
	ABI="-Wa,-march=rv32ec_zicsr_zifencei -march=rv32ec_zicsr_zifencei -mabi=ilp32e -D__RVE_EXT -D__RVC_EXT "
	DONE_DIR="./done_ec"
	SUFFIX="_ec"
else
	if [ "$1" = "IM" ]; then
		echo "BUILD FOR code with mul/dev and 32 regs"
		ABI="-Wa,-march=rv32im_zicsr_zifencei -march=rv32im_zicsr_zifencei -mabi=ilp32 "
		DONE_DIR="./done_im"
		SUFFIX="_im"
	else
		echo "Please give param EC or IM"
		exit 1
	fi
fi

mkdir -p ${DONE_DIR}

CFLAGS="-O3 "
CFLAGS+="-funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -fno-common -fno-builtin-printf "
CFLAGS+="-static -std=gnu99 "
CFLAGS+=$ABI
CFLAGS+="-c -I./ "
CFLAGS+="-DSELF_TIMED=1 -DTIME=1 -DTCM=1 "

export CFLAGS

riscv64-unknown-elf-gcc $CFLAGS start.S -o ${DONE_DIR}/start.o
riscv64-unknown-elf-gcc $CFLAGS syscalls.c -o ${DONE_DIR}/syscalls.o
riscv64-unknown-elf-gcc $CFLAGS sc_print.c -o ${DONE_DIR}/sc_print.o
riscv64-unknown-elf-gcc $CFLAGS dhry_1.c -o ${DONE_DIR}/dhry_1.o
riscv64-unknown-elf-gcc $CFLAGS dhry_2.c -o ${DONE_DIR}/dhry_2.o
riscv64-unknown-elf-gcc -o ${DONE_DIR}/dhry.elf -T riscv.ld ${DONE_DIR}/start.o ${DONE_DIR}/sc_print.o ${DONE_DIR}/dhry_1.o ${DONE_DIR}/dhry_2.o -nostartfiles -nostdlib -lc -lgcc --specs=nano.specs $ABI
riscv64-unknown-elf-objdump -D -D -w -x -S ${DONE_DIR}/dhry.elf > ${DONE_DIR}/dhry.dump
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 1 ${DONE_DIR}/dhry.elf ${DONE_DIR}/dhry.hex
python mk-mif.py ${DONE_DIR}/dhry.hex > ${DONE_DIR}/dhry.mif
python mk-tcm-mem.py ${DONE_DIR}/dhry.hex > ${DONE_DIR}/dhry32.hex

echo "Update Memory Init files of FPGA projects"
cp ${DONE_DIR}/dhry.mif ../FPGA/m3-picorv32/ip_sram${SUFFIX}/dhry${SUFFIX}.mif

echo "Update Memory Init files for picorv32 simulations"
cp ${DONE_DIR}/dhry.hex ../FPGA/m3-picorv32/sim/dhry${SUFFIX}.hex
