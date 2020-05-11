/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 2
    
    a 1-bit full adder
*/
module fullAdder_1b(A, B, C_in, S, C_out);
    input  A, B;
    input  C_in;
    output S;
    output C_out;

    // YOUR CODE HERE
	wire NOT_A, NOT_B, NOT_CIN;
	wire n2_1_out, n2_2_out, n2_3_out, n2_4_out, n2_5_out;
	wire n3_1_out, n3_2_out;

	not1 n1_1(.in1(A), .out(NOT_A));
	not1 n1_2(.in1(B), .out(NOT_B));
	not1 n1_3(.in1(C_in), .out(NOT_Cin));

	nand2 n2_1(.in1(A), .in2(B), .out(n2_1_out));
	nand2 n2_2(.in1(NOT_A), .in2(B), .out(n2_2_out));
	nand2 n2_3(.in1(A), .in2(NOT_B), .out(n2_3_out));
	nand3 n3_1(.in1(n2_1_out), .in2(n2_2_out), .in3(n2_3_out), .out(n3_1_out));
	nand2 n2_4(.in1(C_in), .in2(n3_1_out), .out(n2_4_out));
	nand3 n3_2(.in1(NOT_Cin), .in2(A), .in3(B), .out(n3_2_out));
	nand2 n2_5(.in1(n2_4_out), .in2(n3_2_out), .out(C_out));
	
	xor3 x1_1(.in1(A), .in2(B), .in3(C_in), .out(S));

endmodule
