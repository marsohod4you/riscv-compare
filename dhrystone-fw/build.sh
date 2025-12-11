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
else
	if [ "$1" = "IM" ]; then
		echo "BUILD FOR code with mul/dev and 32 regs"
		ABI="-Wa,-march=rv32im_zicsr_zifencei -march=rv32im_zicsr_zifencei -mabi=ilp32 "
	else
		echo "Please give param EC or IM"
		exit 1
	fi
fi

CFLAGS="-O3 "
CFLAGS+="-funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -fno-common -fno-builtin-printf "
CFLAGS+="-static -std=gnu99 "
CFLAGS+=$ABI
CFLAGS+="-c -I./ "
CFLAGS+="-DSELF_TIMED=1 -DTIME=1 -DTCM=1 "

export CFLAGS

riscv64-unknown-elf-gcc $CFLAGS start.S -o done/start.o
riscv64-unknown-elf-gcc $CFLAGS syscalls.c -o done/syscalls.o
riscv64-unknown-elf-gcc $CFLAGS sc_print.c -o done/sc_print.o
riscv64-unknown-elf-gcc $CFLAGS dhry_1.c -o done/dhry_1.o
riscv64-unknown-elf-gcc $CFLAGS dhry_2.c -o done/dhry_2.o
riscv64-unknown-elf-gcc -o done/dhry.elf -T riscv.ld done/start.o done/sc_print.o done/dhry_1.o done/dhry_2.o -nostartfiles -nostdlib -lc -lgcc --specs=nano.specs $ABI
riscv64-unknown-elf-objdump -D -D -w -x -S done/dhry.elf > done/dhry.dump
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 1 done/dhry.elf done/dhry.hex
python.exe mk-mif.py > done/dhry.mif
python.exe mk-tcm-mem.py > done/dhry32.hex

echo "Update Memory Init files of FPGA projects"
cp done/dhry.mif ../FPGA/m3-picorv32/
