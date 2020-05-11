/*
    CS/ECE 552 Spring '20
    Homework #2, Problem 2

    A 16-bit ALU module.  It is designed to choose
    the correct operation to perform on 2 16-bit numbers from rotate
    left, shift left, shift right arithmetic, shift right logical, add,
    or, xor, & and.  Upon doing this, it should output the 16-bit result
    of the operation, as well as output a Zero bit and an Overflow
    (OFL) bit.
*/
module alu(InA, InB, Cin, Op, invA, invB, sign, Out, Zero, Ofl);

   // declare constant for size of inputs, outputs (N),
   // and operations (O)
	parameter    N = 16;
	parameter    O = 3;
   
	input [N-1:0] InA;
	input [N-1:0] InB;
	input         Cin;
	input [O-1:0] Op;
	input         invA;
	input         invB;
	input         sign;
	output [N-1:0] Out;
	output 	Ofl;
	output	Zero;
	
	wire [N-1:0]	proc_A, proc_B, shifter_Out, adder_Out;
	wire C_out;

   /* YOUR CODE HERE */

	// Invert A and B if needed
	
	assign proc_A = (invA)? 	~InA	:	InA;
	assign proc_B = (invB)? 	~InB	:	InB;
	
	shifter shift(.In(proc_A), .Cnt(proc_B[3:0]), .Op(Op[1:0]), .Out(shifter_Out));
	cla_16b adder(.A(proc_A), .B(proc_B), .C_in(Cin), .S(adder_Out), .C_out(C_out));	
	
	assign Ofl = 	(Op != 3'b100)? 	1'b0			:
					(sign != 1'b1)?		C_out			:
					(proc_A[15] != proc_B[15])?	1'b0	:
					(proc_A[15] == adder_Out[15])? 1'b0	:
					1'b1;
	
	assign Out = 	(Op[2] == 1'b0)? shifter_Out			:	
					(Op[1:0] == 2'b00)? adder_Out			:
					(Op[1:0] == 2'b01)? (proc_A & proc_B)	:
					(Op[1:0] == 2'b10)?	(proc_A | proc_B)	:
					(proc_A ^ proc_B);
	
	assign Zero = (Out == 16'h0000)? 1'b1:1'b0;
	
endmodule
