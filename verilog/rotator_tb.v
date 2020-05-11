module rotator_tb();

	reg [15:0] In;
	reg [3:0] Cnt;
	reg Left;
	
	wire [15:0] Out;

	rotator rot(In, Cnt, Left, Out);
	
	initial begin

		$monitor("In: %h, Cnt: %d, Left: %b, Out: %h", In, Cnt, Left, Out);

		In = 16'h0000;
		Cnt = 4'd0;
		Left = 1'b0;
		
		#10;
		
		In = 16'h1110;
		Cnt = 4'd1;
		Left = 1'b1;
		
		#10;
		
		In = 16'h0F00;
		Cnt = 4'd4;
		Left = 1'b0;
		
		#10;
		
		In = 16'h0030;
		Cnt = 4'd4;
		Left = 1'b0;
		
		#10;
		
		In = 16'h0001;
		Cnt = 4'd15;
		Left = 1'b0;
		
		#10;
		
		In = 16'h0011;
		Cnt = 4'd1;
		Left = 1'b0;
		
		#10;
		
		In = 16'h0011;
		Cnt = 4'd1;
		Left = 1'b1;
		
		#10;
		
		$stop();

	end

endmodule