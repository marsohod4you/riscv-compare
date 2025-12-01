`ifndef SCR1_ARCH_CUSTOM_SVH
`define SCR1_ARCH_CUSTOM_SVH

// Possible targets:
`define SCR1_TRGT_FPGA_INTEL         // target platform is Intel FPGAs
`define SCR1_TRGT_FPGA_INTEL_MAX10   // target platform is Intel MAX 10 FPGAs (used in the SCR1-SDK project)
// `define SCR1_TRGT_FPGA_INTEL_ARRIAV  // target platform is Intel Arria V FPGAs (used in the SCR1-SDK project)
// `define SCR1_TRGT_FPGA_XILINX        // target platform is Xilinx FPGAs (used in the SCR1-SDK project)
// `define SCR1_TRGT_ASIC               // target platform is ASIC
// `define SCR1_TRGT_SIMULATION         // target is simulation (enable simulation code)

//------------------------------------------------------------------------------
// RECOMMENDED CORE ARCHITECTURE CONFIGURATIONS
//------------------------------------------------------------------------------
// Uncomment one of these defines to set the recommended configuration:

`define SCR1_CFG_RV32IMC_MAX
//`define SCR1_CFG_RV32IC_BASE
//`define SCR1_CFG_RV32EC_MIN

parameter bit [`SCR1_XLEN-1:0]          SCR1_ARCH_RST_VECTOR        = 'h0;            // Reset vector value (start address after reset)
parameter bit [`SCR1_XLEN-1:0]          SCR1_ARCH_MTVEC_BASE        = 'h10;           // MTVEC.base field reset value, or constant value for MTVEC.base bits that are hardwired

parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TCM_ADDR_MASK          = 'hFFFF0000;   // TCM mask and size
parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TCM_ADDR_PATTERN       = 'h00000000;   // TCM address match pattern

parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TIMER_ADDR_MASK        = 'hFFFFFFE0;   // Timer mask (should be 0xFFFFFFE0)
parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TIMER_ADDR_PATTERN     = 'h00490000;   // Timer address match pattern
  
`define SCR1_TCM_INITIAL_DATA "tcm_data.hex"

`endif // SCR1_ARCH_CUSTOM_SVH
