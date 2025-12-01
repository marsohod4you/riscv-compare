
//Simple Serial Sender
module sserial(
	//write clk domain
	input wire resetn,
	input wire wr_clk,
	input wire [7:0]wr_data,
	input wire wr,
	output wire busy,
	
	//send clk domain
	input wire send_clk,
	output wire serial_out
);

//serial fifo write level
wire [1:0]sfifo_wr_level;
wire [7:0]sfifo_data;
wire sfifo_empty;
reg sfifo_read=1'b0;
generic_fifo_dc_gray #( .dw(8), .aw(4) ) u_serial_fifo(
	.rd_clk(send_clk),
	.wr_clk(wr_clk),
	.rst(1'b1),		//no async reset
	.clr(~resetn), //syncronous clear
	.din(wr_data),
	.we(wr),
	.dout(sfifo_data),
	.rd(sfifo_read),
	.full(),
	.empty(sfifo_empty),
	.wr_level(sfifo_wr_level),
	.rd_level()
	);

assign busy = sfifo_wr_level==2'b11; //busy when Full

//10 bits: 1start, 8data, 1stop
reg [9:0]serial_shift_reg = 10'h3FF;
reg [3:0]serial_cnt = 0;
wire serial_busy; assign serial_busy = |serial_cnt;

always @(posedge send_clk)
begin
	if(!serial_busy & !sfifo_empty)
	begin
		sfifo_read <=1'b1;
		serial_cnt <= 10;
	end
	else
	begin
		if(sfifo_read)
			serial_shift_reg <= {1'b1,sfifo_data,1'b0};	//load shift reg
		else
		begin
			serial_shift_reg <= {1'b1,serial_shift_reg[9:1]}; //shift out
			if(serial_cnt)
				serial_cnt<=serial_cnt-1;
		end
		sfifo_read<=1'b0;
	end
end

assign serial_out = serial_shift_reg[0];

endmodule
