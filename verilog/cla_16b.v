/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 2
    
    a 16-bit CLA module
*/
module cla_16b(A, B, C_in, S, C_out);

    // declare constant for size of inputs, outputs (N)
    parameter   N = 16;

    input [N-1: 0] A, B;
    input          C_in;
    output [N-1:0] S;
    output         C_out;

    // YOUR CODE HERE

	wire [N-1: 0] C;
	wire [3:0] P, G, pc, NOT_G, Cout;
	wire P16, G16, NOT_G16;

	wire nand_2_13_out, nand_2_14_out, nand_2_15_out, nand_2_16_out;
	wire nand_2_17_out, nand_2_18_out, nand_2_19_out;
	wire nand_3_1_out;
	wire nor_2_5_out, nor_2_6_out;
	wire not_1_13_out, not_1_14_out;

	// Inverse G Calculation

	not1 not_1_9(.in1(G[0]), .out(NOT_G[0]));
	not1 not_1_10(.in1(G[1]), .out(NOT_G[1]));
	not1 not_1_11(.in1(G[2]), .out(NOT_G[2]));
	not1 not_1_12(.in1(G[3]), .out(NOT_G[3]));

	// Carry in Calculation

	nand2 nand_2_5(.in1(P[0]), .in2(C_in), .out(pc[0]));
	nand2 nand_2_9(.in1(NOT_G[0]), .in2(pc[0]), .out(C[0]));

	nand2 nand_2_6(.in1(P[1]), .in2(C[0]), .out(pc[1]));
	nand2 nand_2_10(.in1(NOT_G[1]), .in2(pc[1]), .out(C[1]));

	nand2 nand_2_7(.in1(P[2]), .in2(C[1]), .out(pc[2]));
	nand2 nand_2_11(.in1(NOT_G[2]), .in2(pc[2]), .out(C[2]));

	nand2 nand_2_8(.in1(P[3]), .in2(C[2]), .out(pc[3]));
	nand2 nand_2_12(.in1(NOT_G[3]), .in2(pc[3]), .out(C[3]));

	// G and P Calculation (Adapted from cla_4b.v)

	nand2 nand_2_13(.in1(P[3]), .in2(G[2]), .out(nand_2_13_out));
	nand2 nand_2_14(.in1(NOT_G[3]), .in2(nand_2_13_out), .out(nand_2_14_out));
	nand3 nand_3_1(.in1(P[3]), .in2(P[2]), .in3(G[1]), .out(nand_3_1_out));
	nand2 nand_2_15(.in1(P[3]), .in2(P[2]), .out(nand_2_15_out));
	nand2 nand_2_16(.in1(P[1]), .in2(G[0]), .out(nand_2_16_out));
	nor2 nor_2_5(.in1(nand_2_15_out), .in2(nand_2_16_out), .out(nor_2_5_out));
	not1 not_1_13(.in1(nor_2_5_out), .out(not_1_13_out));
	nand2 nand_2_17(.in1(nand_3_1_out), .in2(not_1_13_out), .out(nand_2_17_out));
	nor2 nor_2_6(.in1(nand_2_14_out), .in2(nand_2_17_out), .out(nor_2_6_out));
	not1 not_1_14(.in1(nor_2_6_out), .out(G16));

	nand2 nand_2_18(.in1(P[3]), .in2(P[2]), .out(nand_2_18_out));
	nand2 nand_2_19(.in1(P[1]), .in2(P[0]), .out(nand_2_19_out));
	nor2 nor_2_7(.in1(nand_2_18_out), .in2(nand_2_19_out), .out(P16));

	// Carry Out Look Ahead Logic

	not1 not_1_15(.in1(G16), .out(NOT_G16));
	nand2 nand_2_20(.in1(P16), .in2(C_in), .out(nand_2_20_out));
	nand2 nand_2_21(.in1(NOT_G16), .in2(nand_2_20_out), .out(C_out));

	// CLA Blocks

	cla_4b	cla4_1(.A(A[3:0]), .B(B[3:0]), .S(S[3:0]), .C_in(C_in), .C_out(Cout[0]), .P(P[0]), .G(G[0]));
	cla_4b	cla4_2(.A(A[7:4]), .B(B[7:4]), .S(S[7:4]), .C_in(C[0]), .C_out(Cout[1]), .P(P[1]), .G(G[1]));
	cla_4b	cla4_3(.A(A[11:8]), .B(B[11:8]), .S(S[11:8]), .C_in(C[1]), .C_out(Cout[2]), .P(P[2]), .G(G[2]));
	cla_4b	cla4_4(.A(A[15:12]), .B(B[15:12]), .S(S[15:12]), .C_in(C[2]), .C_out(Cout[3]), .P(P[3]), .G(G[3]));

endmodule
