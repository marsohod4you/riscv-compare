#!/bin/bash

#set PATH=%PATH%;d:\altera\svarka\sc-dt-2025.09-Win\sc-dt\riscv-gcc\bin
#set PATH=%PATH%;d:\Programs\Python311\

export PATH=$PATH:/d/altera/syntacore/sc-dt-2025.09-Win/sc-dt/riscv-gcc/bin
export PATH=$PATH:/d/Programs/Python311/

ABI="-Wa,-march=rv32im_zicsr_zifencei -march=rv32im_zicsr_zifencei -mabi=ilp32 "
CFLAGS="-O3 "
CFLAGS+="-funroll-loops -fpeel-loops -fgcse-sm -fgcse-las -fno-common -fno-builtin-printf "
#CFLAGS+="-D__RVE_EXT -D__RVC_EXT -DTCM=1 "
CFLAGS+="-D__RVC_EXT "
#CFLAGS+="-DFLAGS_STR=\"-O3 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las \" "
CFLAGS+="-static -std=gnu99 "
CFLAGS+=$ABI
CFLAGS+="-c -I./ "
CFLAGS+="-DSELF_TIMED=1 -DTIME=1 "

export CFLAGS

riscv64-unknown-elf-gcc $CFLAGS start.S -o done/start.o
#riscv64-unknown-elf-gcc $CFLAGS stdlib.c -o done/stdlib.o
riscv64-unknown-elf-gcc $CFLAGS syscalls.c -o done/syscalls.o
riscv64-unknown-elf-gcc $CFLAGS sc_print.c -o done/sc_print.o
riscv64-unknown-elf-gcc $CFLAGS dhry_1.c -o done/dhry_1.o
riscv64-unknown-elf-gcc $CFLAGS dhry_2.c -o done/dhry_2.o
riscv64-unknown-elf-gcc -o done/dhry.elf -T riscv.ld done/start.o done/sc_print.o done/dhry_1.o done/dhry_2.o -nostartfiles -nostdlib -lc -lgcc --specs=nano.specs $ABI
riscv64-unknown-elf-objdump -D -D -w -x -S done/dhry.elf > done/dhry.dump
riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 1 done/dhry.elf done/dhry.hex
python.exe mk-mif.py > done/dhry.mif
python.exe mk-tcm-mem.py > done/dhry32.hex
#copy done\tcm_mem.hex ..\scr1\src\top
