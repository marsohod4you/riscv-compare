
`include "scr1_arch_description.svh"

module max10(
	input wire	CLK100MHZ,
	input wire	KEY0,
	input wire	KEY1,
	input wire	SERIAL_RX,
	output wire	SERIAL_TX,
	inout  wire	[19:0] IO,
	output wire	[7:0] LED
);

localparam SERIAL_PORT_ADDR  = 32'h1000_0000;
localparam SIMSTOP_PORT_ADDR = 32'h1000_1000;

wire sysclk;
wire serial_clk;
mypll	mypll_inst(
	.inclk0(CLK100MHZ),
	.locked(),
	.c0(sysclk),
	.c1(serial_clk)
	);

reg [3:0]rstcnt=0;
reg rst=1'b0;
always @(posedge sysclk)
begin
	if(~KEY1)
		rstcnt <= 0;
	else
	if( rstcnt!=4'hF )
		rstcnt <= rstcnt+1;
	rst <= ~(rstcnt==4'hF);
end

// JTAG
`ifdef SCR1_DBG_EN
wire trst_n; assign trst_n = 1'b1;
wire tck; assign tck = 1'b0;
wire tms; assign tms = 1'b0;
wire tdi; assign tdi = 1'b0;
`endif

logic [15:0]irq_lines = 16'd0;
logic soft_irq = 1'b0;
logic ext_irq = 1'b0;
logic [31:0]fuse_mhartid = 32'h0;

wire dmem_hwrite_;
wire dmem_hready_; assign dmem_hready_ = dmem_hwrite_;
wire [`SCR1_DMEM_AWIDTH-1:0]dmem_haddr_;
wire [`SCR1_DMEM_DWIDTH-1:0]dmem_hwdata_;
reg  [`SCR1_DMEM_DWIDTH-1:0]dmem_hrdata_;

//-------------------------------------------------------------------------------
// Core instance
//-------------------------------------------------------------------------------
scr1_top_ahb i_top (
    // Reset
    .pwrup_rst_n            (~rst                   ),
    .rst_n                  (~rst                   ),
    .cpu_rst_n              (~rst                   ),
`ifdef SCR1_DBG_EN
    .sys_rst_n_o            (                       ),
    .sys_rdc_qlfy_o         (                       ),
`endif // SCR1_DBG_EN

    // Clock
    .clk                    (sysclk                 ),
    .rtc_clk                (1'b0                   ),

    // Fuses
    .fuse_mhartid           (fuse_mhartid           ),
`ifdef SCR1_DBG_EN
    .fuse_idcode            (`SCR1_TAP_IDCODE       ),
`endif // SCR1_DBG_EN

    // IRQ
`ifdef SCR1_IPIC_EN
    .irq_lines              (irq_lines              ),
`else // SCR1_IPIC_EN
    .ext_irq                (ext_irq                ),
`endif // SCR1_IPIC_EN
    .soft_irq               (soft_irq               ),

    // DFT
    .test_mode              (1'b0                   ),
    .test_rst_n             (1'b1                   ),

`ifdef SCR1_DBG_EN
    // JTAG
    .trst_n                 (trst_n                 ),
    .tck                    (tck                    ),
    .tms                    (tms                    ),
    .tdi                    (tdi                    ),
    .tdo                    (tdo                    ),
    .tdo_en                 (tdo_en                 ),
`endif // SCR1_DBG_EN

    // Instruction Memory Interface
    .imem_hprot         (),
    .imem_hburst        (),
    .imem_hsize         (),
    .imem_htrans        (),
    .imem_hmastlock     (),
    .imem_haddr         (),
    .imem_hready        (1'b1),
    .imem_hrdata        (32'h0),
    .imem_hresp         (1'b0),

    // Data Memory Interface
    .dmem_hprot         (),
    .dmem_hburst        (),
    .dmem_hsize         (),
    .dmem_htrans        (),
    .dmem_hmastlock     (),
    .dmem_haddr         (dmem_haddr_),
    .dmem_hwrite        (dmem_hwrite_),
    .dmem_hwdata        (dmem_hwdata_),
    .dmem_hready        (1'b1),
    .dmem_hrdata        (dmem_hrdata_),
    .dmem_hresp         (1'b0)
);

wire bus_serial_wr;  assign bus_serial_wr  = dmem_hwrite_         & (dmem_haddr_==SERIAL_PORT_ADDR);
wire bus_serial_rd;  assign bus_serial_rd  = (dmem_hwrite_==1'b0) & (dmem_haddr_==SERIAL_PORT_ADDR);
wire bus_simstop_wr; assign bus_simstop_wr = dmem_hwrite_ & (dmem_haddr_==SIMSTOP_PORT_ADDR);

wire serial_busy;
always @(posedge sysclk)
begin
	bus_serial_wr_ <= bus_serial_wr;
	//read port
	if(bus_serial_rd)
		dmem_hrdata_<={31'd0,serial_busy};
end

wire serial_out;	

sserial u_sserial(
	//write clk domain
	.resetn(~rst),
	.wr_clk(sysclk),
	.wr_data(dmem_hwdata_[7:0]),
	.wr(bus_serial_wr_),
	.busy(serial_busy),
	
	//send clk domain
	.send_clk(serial_clk),
	.serial_out(serial_out)
	
);

//serial output
assign SERIAL_TX = serial_out;

`ifdef SIMULATION
always @(posedge sysclk)
	if(bus_serial_wr_)
	begin
		$write("%c",dmem_hwdata_[ 7: 0]);
	end
	else
	if(bus_simstop_wr)
	begin
		$finish();
	end
`endif

//////////////////////////////////////////////////

assign LED = 0;

endmodule
