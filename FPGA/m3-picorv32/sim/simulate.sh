#!/bin/bash

export PATH=$PATH:/d/altera/syntacore/sc-dt-2025.09-Win/sc-dt/riscv-gcc/bin
export PATH=$PATH:/d/Programs/Python311/

export FIFO_DIR=../generic_fifos/rtl/verilog/
iverilog -o qqq -DSIMULATION=1 -I${FIFO_DIR} testbench.v ../soc.v ../sserial.v ../picorv32/picorv32.v pll4sim.v sram4sim.v ${FIFO_DIR}/generic_dpram.v ${FIFO_DIR}/generic_fifo_dc_gray.v
vvp qqq
