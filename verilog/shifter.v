/*
    CS/ECE 552 Spring '20
    Project Phase 1
 */
module shifter (In, Cnt, Op, Out);

	// declare constant for size of inputs, outputs (N) and # bits to shift (C)
	parameter   N = 16;
	parameter   C = 4;
	parameter   O = 2;

	input [N-1:0]   In;
	input [C-1:0]   Cnt;
	input [O-1:0]   Op;
	output [N-1:0]  Out;

	wire [N-1:0]	rol_Out, ror_Out;
	reg	[N-1:0]shifter_left, shifter_right;

	/* YOUR CODE HERE */
	
	left_rotator lrot(.In(In), .Cnt(Cnt), .Out(rol_Out));
	right_rotator rrot(.In(In), .Cnt(Cnt), .Out(ror_Out));

	assign Out = 	(Op == 2'b00) ? rol_Out		:
					(Op == 2'b10) ? ror_Out		:
					(Op == 2'b01) ? shifter_left:
					shifter_right;
					
	always@(*) begin
	
		case(Cnt)
		
			4'h0	:	shifter_left = In;
			4'h1	:	shifter_left = In << 1;
			4'h2	:	shifter_left = In << 2;
			4'h3	:	shifter_left = In << 3;
			4'h4	:	shifter_left = In << 4;
			4'h5	:	shifter_left = In << 5;
			4'h6	:	shifter_left = In << 6;
			4'h7	:	shifter_left = In << 7;
			4'h8	:	shifter_left = In << 8;
			4'h9	:	shifter_left = In << 9;
			4'ha	:	shifter_left = In << 10;
			4'hb	:	shifter_left = In << 11;
			4'hc	:	shifter_left = In << 12;
			4'hd	:	shifter_left = In << 13;
			4'he	:	shifter_left = In << 14;
			4'hf	:	shifter_left = In << 15;
			default	:	shifter_left = In;
		
		endcase
	
	end
	
	always@(*) begin
	
		case(Cnt)
		
			4'h0	:	shifter_right = In;
			4'h1	:	shifter_right = In >> 4'h1;
			4'h2	:	shifter_right = In >> 4'h2;
			4'h3	:	shifter_right = In >> 4'h3;
			4'h4	:	shifter_right = In >> 4'h4;
			4'h5	:	shifter_right = In >> 4'h5;
			4'h6	:	shifter_right = In >> 4'h6;
			4'h7	:	shifter_right = In >> 4'h7;
			4'h8	:	shifter_right = In >> 4'h8;
			4'h9	:	shifter_right = In >> 4'h9;
			4'ha	:	shifter_right = In >> 4'ha;
			4'hb	:	shifter_right = In >> 4'hb;
			4'hc	:	shifter_right = In >> 4'hc;
			4'hd	:	shifter_right = In >> 4'hd;
			4'he	:	shifter_right = In >> 4'he;
			4'hf	:	shifter_right = In >> 4'hf;
			default	:	shifter_right = In;
		
		endcase
	
	end
   
endmodule