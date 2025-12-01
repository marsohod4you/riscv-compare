`timescale 1 ns / 1 ps

module testbench;

wire [7:0]led;
wire sdata;

reg key1=1'b1;

soc u_soc(
	.CLK100MHZ(1'b0),
	.KEY0(1'b1),
	.KEY1( key1 ),
	.LED(led),
	.SERIAL_RX(1'b1),
	.SERIAL_TX(sdata)
);

initial begin
	$dumpfile("testbench.vcd");
	$dumpvars(0, testbench);
end

endmodule
