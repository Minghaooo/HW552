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

	/* YOUR CODE HERE */
	
	left_rotator lrot(.In(In), .Cnt(Cnt), .Out(rol_Out));
	right_rotator rrot(.In(In), .Cnt(Cnt), .Out(ror_Out));

	assign Out = 	(Op == 2'b00) ? rol_Out		:
					(Op == 2'b10) ? ror_Out		:
					(Op == 2'b01) ? (In << Cnt)	:
					(In >> Cnt);
   
endmodule