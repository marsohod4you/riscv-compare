`timescale 1 ns / 1 ps

module sram4sim(
	input wire clock,
	input wire [15:0]address,
	input wire [3:0]byteena,
	input wire [31:0]data,
	input wire wren,
	output wire [31:0]q
	);

reg [7:0] memory[0:128*1024-1];
initial $readmemh("done/dhry.hex", memory);

reg [17:0]address_;
reg [3:0]byteena_;
reg [31:0]data_;
reg wren_;

reg hook = 1'b0;

always @(posedge clock)
begin
	address_ <= {address,2'b00};
	data_ <= data;
	byteena_ <= byteena;
	wren_ <= wren;

	if(wren_)
	begin
		if(byteena_[0]) memory[address_+0] <= data_[ 7: 0];
		if(byteena_[1]) memory[address_+1] <= data_[15: 8];
		if(byteena_[2]) memory[address_+2] <= data_[23:16];
		if(byteena_[3]) memory[address_+3] <= data_[31:24];
	end
end

assign q = { memory[address_+3],memory[address_+2],memory[address_+1],memory[address_+0] };

endmodule
