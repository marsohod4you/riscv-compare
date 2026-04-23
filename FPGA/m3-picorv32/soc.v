
module soc(
	input  wire CLK100MHZ,
	input  wire KEY0,
	input  wire KEY1,
	output wire [7:0]LED,
	inout  wire	[19:0] IO,
	input  wire SERIAL_RX,
	output wire SERIAL_TX

);

// 8K 32bit words = 32Kbytes memory
localparam MEM_SIZE = (1024*32);
localparam SERIAL_PORT_ADDR  = 32'h1000_0000;
localparam SEG7_PORT_ADDR  = 32'h1000_0004;
localparam SIMSTOP_PORT_ADDR = 32'h1000_1000;

// -------------------------------
// PLL instance and create reset from PLL Lock or KEY0 button press
wire clk;
wire serial_clk;
wire locked;

`ifdef SIMULATION
pll4sim u_pll2(
	.inclk0( CLK100MHZ),
	.c0( clk ),
	.c1( serial_clk ),
	.locked( locked )
	);
`else
pll2 u_pll2(
	.inclk0( CLK100MHZ),
	.c0( clk ),
	.c1( serial_clk ),
	.locked( locked )
	);
`endif

reg [3:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @( posedge clk )
	if(KEY1==1'b0)
		resetn_counter<=0;
	else
	if ( !resetn )
		resetn_counter <= resetn_counter + 4'd1;
		
// -------------------------------
// Memory and Read/Write address decoder

wire mem_valid;
reg  mem_ready=1'b0;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [31:0] mem_rdata_sram;
wire [31:0] mem_rdata_port;
wire [31:0] mem_rdata;
wire [ 3:0] mem_wstrb;
wire mem_write; 
assign mem_write = (mem_valid & !mem_ready & (|mem_wstrb) & (mem_addr!=SERIAL_PORT_ADDR) & (mem_addr!=SEG7_PORT_ADDR) & (mem_addr!=SIMSTOP_PORT_ADDR) );

always @(posedge clk)
begin
	if (mem_valid & !mem_ready)
		mem_ready <= 1'b1;
	else
		mem_ready <= 1'b0;
end

`ifdef SIMULATION
//initialized with *.hex file RISCV code
sram4sim u_sram(
	.address( mem_addr[17:2]),
	.byteena(mem_wstrb),
	.clock(clk),
	.data(mem_wdata),
	.wren(mem_write),
	.q(mem_rdata_sram)
	);
`else
//initialized with *.MIF file RISCV code
`ifdef MIN_CPU_CONFIG
	sram_ec
`else
	sram_im
`endif	
	u_sram(
			.address(mem_addr[17:2]),
			.byteena(mem_wstrb),
			.clock(clk),
			.data(mem_wdata),
			.wren(mem_write),
			.q(mem_rdata_sram)
			);
`endif

//serial port FIFO (dual clock - CPU and Serial may work on different frequences)
wire serial_port_wr; assign serial_port_wr = (mem_addr==SERIAL_PORT_ADDR) & mem_valid & !mem_ready & mem_wstrb[0];
wire seg7_port_wr; assign seg7_port_wr = (mem_addr==SEG7_PORT_ADDR) & mem_valid & !mem_ready & mem_wstrb[0];
wire simulation_stop_port_wr; assign simulation_stop_port_wr = (mem_addr==SIMSTOP_PORT_ADDR) & mem_valid & !mem_ready & (|mem_wstrb);

wire serial_busy;
wire serial_out;	
assign mem_serial_rdata_port = {31'h0,serial_busy};
assign mem_rdata = (mem_addr==SERIAL_PORT_ADDR) ? mem_serial_rdata_port : mem_rdata_sram;

sserial u_sserial(
	//write clk domain
	.resetn(resetn),
	.wr_clk(clk),
	.wr_data(mem_wdata[7:0]),
	.wr(serial_port_wr),
	.busy(serial_busy),
	
	//send clk domain
	.send_clk(serial_clk),
	.serial_out(serial_out)
	
);

assign SERIAL_TX = serial_out;

`ifdef SIMULATION
always @(posedge clk)
	if(serial_port_wr)
	begin
		$write("%c",mem_wdata[ 7: 0]);
	end
	else
	if(simulation_stop_port_wr)
	begin
		$finish();
	end
`endif

//-----------------------------
reg [31:0]seg7r = 0;
always @(posedge clk)
	if(resetn==0)
		seg7r <= 0;
	else
	if(seg7_port_wr)
		seg7r <= mem_wdata;

wire [3:0]s7_digit_sel;
wire [7:0]s7_out;
seg4x7 u_seg4x7(
	.clk( CLK100MHZ ),
	.in( seg7r[15:0] ),
	.digit_sel( s7_digit_sel ),
	.out( s7_out )
);

assign { IO[15],IO[13],IO[12],IO[14] } = s7_digit_sel;
assign IO[7:0]  = s7_out;

`ifdef MIN_CPU_CONFIG
//minimal CPU configuration
initial
begin
	$display("Simulation Config for Embedded/Compressed CPU with reduced number of REGs=16");
end
localparam _ENABLE_REGS_16_31	= 0;
localparam _COMPRESSED_ISA		= 1;
localparam _TWO_STAGE_SHIFT		= 1;
localparam _BARREL_SHIFTER		= 0;
localparam _TWO_CYCLE_ALU		= 1;
localparam _ENABLE_MUL			= 0;
localparam _ENABLE_FAST_MUL		= 0;
localparam _ENABLE_DIV			= 0;
`else
//maximal CPU configuration
initial
begin
	$display("Simulation Config for CPU with MUL/DIV and number of REGs=32");
end
localparam _ENABLE_REGS_16_31	= 1;
localparam _COMPRESSED_ISA		= 1;
localparam _TWO_STAGE_SHIFT		= 0;
localparam _BARREL_SHIFTER		= 1;
localparam _TWO_CYCLE_ALU		= 0;
localparam _ENABLE_MUL			= 1;
localparam _ENABLE_FAST_MUL		= 1;
localparam _ENABLE_DIV			= 1;
`endif	

// -------------------------------
// PicoRV32 Core
picorv32 #(
	.ENABLE_COUNTERS(1),
	.ENABLE_REGS_16_31( _ENABLE_REGS_16_31 ),
	.COMPRESSED_ISA( _COMPRESSED_ISA ),
	.LATCHED_MEM_RDATA(1),
	.TWO_STAGE_SHIFT( _TWO_STAGE_SHIFT ),
	.BARREL_SHIFTER( _BARREL_SHIFTER ),
	.TWO_CYCLE_ALU( _TWO_CYCLE_ALU ),
	.CATCH_MISALIGN(0),
	.CATCH_ILLINSN(0),
	.ENABLE_MUL( _ENABLE_MUL ),
	.ENABLE_FAST_MUL( _ENABLE_FAST_MUL ),
	.ENABLE_DIV( _ENABLE_DIV ),
	.PROGADDR_RESET(32'h00000000)
) cpu (
	.clk      (clk      ),
	.resetn   (resetn   ),
	.mem_valid(mem_valid),
	.mem_ready(mem_ready),
	.mem_addr (mem_addr ),
	.mem_wdata(mem_wdata),
	.mem_wstrb(mem_wstrb),
	.mem_rdata(mem_rdata)
);

assign LED = 0;

endmodule
