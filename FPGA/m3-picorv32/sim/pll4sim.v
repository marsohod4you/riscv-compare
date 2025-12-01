`timescale 1 ns / 1 ps

module pll4sim(
	input wire inclk0,
	output wire c0,
	output wire c1,
	output wire locked
	);

reg clk0 = 1; assign c0 = clk0;
always #500 clk0 = ~clk0;

reg clk1 = 1; assign c1 = clk1;
always #42 clk1 = ~clk1;

reg lock=1'b0; assign locked = lock;
initial
	#200 lock = 1'b1;

endmodule
