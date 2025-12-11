
module soc(
	input  wire CLK100MHZ,
	input  wire KEY0,
	input  wire KEY1,
	output wire [7:0]LED,
	input  wire SERIAL_RX,
	output wire SERIAL_TX

);

// 32K 32bit words = 128Kbytes memory
localparam MEM_SIZE = (1024*128);
localparam SERIAL_PORT_ADDR  = 32'h1000_0000;
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
assign mem_write = (mem_valid & !mem_ready & (|mem_wstrb) & (mem_addr!=SERIAL_PORT_ADDR) & (mem_addr!=SIMSTOP_PORT_ADDR) );

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
	.address( mem_addr[31:2]),
	.byteena(mem_wstrb),
	.clock(clk),
	.data(mem_wdata),
	.wren(mem_write),
	.q(mem_rdata_sram)
	);
`else
//initialized with *.MIF file RISCV code
sram u_sram(
	.address(mem_addr[31:2]),
	.byteena(mem_wstrb),
	.clock(clk),
	.data(mem_wdata),
	.wren(mem_write),
	.q(mem_rdata_sram)
	);
`endif

//serial port FIFO (dual clock - CPU and Serial may work on different frequences)
wire serial_port_wr; assign serial_port_wr = (mem_addr==SERIAL_PORT_ADDR) & mem_valid & !mem_ready & mem_wstrb[0];
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

`define MIN_CONF 1

`ifdef MIN_CONF
localparam _ENABLE_REGS_16_31	= 0;
localparam _COMPRESSED_ISA		= 1;
localparam _TWO_STAGE_SHIFT	= 0;
localparam _BARREL_SHIFTER		= 0;
localparam _TWO_CYCLE_ALU		= 1;
localparam _ENABLE_MUL			= 0;
localparam _ENABLE_FAST_MUL	= 0;
localparam _ENABLE_DIV			= 0;
`else
localparam _ENABLE_REGS_16_31	= 1;
localparam _COMPRESSED_ISA		= 1;
localparam _TWO_STAGE_SHIFT	= 0;
localparam _BARREL_SHIFTER		= 1;
localparam _TWO_CYCLE_ALU		= 0;
localparam _ENABLE_MUL			= 1;
localparam _ENABLE_FAST_MUL	= 1;
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

/*
reg [31:0]cnt = 0;
reg [7:0]port=8'h00;
always @(posedge clk)
begin
	cnt <= cnt+1;
	if(serial_port_wr)
		port <= mem_wdata[7: 0];
end
*/

assign LED = {7'd0,serial_busy}; //port; //cnt[23:16];

endmodule
