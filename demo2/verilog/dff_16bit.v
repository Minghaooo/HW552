module dff_16bit(clk, rst, d, q);

	parameter SIZE = 16;

	input clk, rst;
	input [(SIZE - 1):0] d;
	output [(SIZE - 1):0] q;
	
	dff flop[(SIZE - 1): 0](.d(d), .q(q), .rst(rst), .clk(clk));
	
	/*dff f0(.d(d[0]), .q(q[0]), .clk(clk), .rst(rst));
	dff f1(.d(d[1]), .q(q[1]), .clk(clk), .rst(rst));
	dff f2(.d(d[2]), .q(q[2]), .clk(clk), .rst(rst));
	dff f3(.d(d[3]), .q(q[3]), .clk(clk), .rst(rst));
	dff f4(.d(d[4]), .q(q[4]), .clk(clk), .rst(rst));
	dff f5(.d(d[5]), .q(q[5]), .clk(clk), .rst(rst));
	dff f6(.d(d[6]), .q(q[6]), .clk(clk), .rst(rst));
	dff f7(.d(d[7]), .q(q[7]), .clk(clk), .rst(rst));
	dff f8(.d(d[8]), .q(q[8]), .clk(clk), .rst(rst));
	dff f9(.d(d[9]), .q(q[9]), .clk(clk), .rst(rst));
	dff f10(.d(d[10]), .q(q[10]), .clk(clk), .rst(rst));
	dff f11(.d(d[11]), .q(q[11]), .clk(clk), .rst(rst));
	dff f12(.d(d[12]), .q(q[12]), .clk(clk), .rst(rst));
	dff f13(.d(d[13]), .q(q[13]), .clk(clk), .rst(rst));
	dff f14(.d(d[14]), .q(q[14]), .clk(clk), .rst(rst));
	dff f15(.d(d[15]), .q(q[15]), .clk(clk), .rst(rst));*/
	
endmodule