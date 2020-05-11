/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 2
    
    a 4-bit CLA module
*/
module cla_4b(A, B, C_in, S, C_out, P, G);

    // declare constant for size of inputs, outputs (N)
    parameter   N = 4;

    input [N-1: 0] A, B;
    input          C_in;
    output [N-1:0] S;
    output         C_out, P, G;

	// YOUR CODE HERE

	wire [N-1: 0] Cout;
	wire [N-2: 0] C;    
	wire [N-1: 0] g, p, not_g, pc;
	wire [N-1: 0] nor2_out, nand2_out;
	wire nand_2_13_out, nand_2_14_out, nand_2_15_out, nand_2_16_out;
	wire nand_2_17_out, nand_2_18_out, nand_2_19_out;
	wire nand_3_1_out;
	wire nor_2_5_out, nor_2_6_out;
	wire not_1_13_out, not_1_14_out;

	// Generate and Propogate Calculation
	
	nor2 nor_2_1(.in1(A[0]), .in2(B[0]), .out(nor2_out[0])); 
	nand2 nand_2_1(.in1(A[0]), .in2(B[0]), .out(nand2_out[0])); 
	not1 not_1_1(.in1(nor2_out[0]), .out(p[0]));
	not1 not_1_2(.in1(nand2_out[0]), .out(g[0]));

	nor2 nor_2_2(.in1(A[1]), .in2(B[1]), .out(nor2_out[1])); 
	nand2 nand_2_2(.in1(A[1]), .in2(B[1]), .out(nand2_out[1])); 
	not1 not_1_3(.in1(nor2_out[1]), .out(p[1]));
	not1 not_1_4(.in1(nand2_out[1]), .out(g[1]));

	nor2 nor_2_3(.in1(A[2]), .in2(B[2]), .out(nor2_out[2])); 
	nand2 nand_2_3(.in1(A[2]), .in2(B[2]), .out(nand2_out[2])); 
	not1 not_1_5(.in1(nor2_out[2]), .out(p[2]));
	not1 not_1_6(.in1(nand2_out[2]), .out(g[2]));

	nor2 nor_2_4(.in1(A[3]), .in2(B[3]), .out(nor2_out[3])); 
	nand2 nand_2_4(.in1(A[3]), .in2(B[3]), .out(nand2_out[3])); 
	not1 not_1_7(.in1(nor2_out[3]), .out(p[3]));
	not1 not_1_8(.in1(nand2_out[3]), .out(g[3]));

	// Inverse g Calculation

	not1 not_1_9(.in1(g[0]), .out(not_g[0]));
	not1 not_1_10(.in1(g[1]), .out(not_g[1]));
	not1 not_1_11(.in1(g[2]), .out(not_g[2]));
	not1 not_1_12(.in1(g[3]), .out(not_g[3]));

	// Carry in Calculation

	nand2 nand_2_5(.in1(p[0]), .in2(C_in), .out(pc[0]));
	nand2 nand_2_9(.in1(not_g[0]), .in2(pc[0]), .out(C[0]));

	nand2 nand_2_6(.in1(p[1]), .in2(C[0]), .out(pc[1]));
	nand2 nand_2_10(.in1(not_g[1]), .in2(pc[1]), .out(C[1]));

	nand2 nand_2_7(.in1(p[2]), .in2(C[1]), .out(pc[2]));
	nand2 nand_2_11(.in1(not_g[2]), .in2(pc[2]), .out(C[2]));

	nand2 nand_2_8(.in1(p[3]), .in2(C[2]), .out(pc[3]));
	nand2 nand_2_12(.in1(not_g[3]), .in2(pc[3]), .out(C_out));
	
	// Adder Block

	fullAdder_1b FA1(.A(A[0]), .B(B[0]), .S(S[0]), .C_in(C_in), .C_out(Cout[0]));
	fullAdder_1b FA2(.A(A[1]), .B(B[1]), .S(S[1]), .C_in(C[0]), .C_out(Cout[1]));
	fullAdder_1b FA3(.A(A[2]), .B(B[2]), .S(S[2]), .C_in(C[1]), .C_out(Cout[2]));
	fullAdder_1b FA4(.A(A[3]), .B(B[3]), .S(S[3]), .C_in(C[2]), .C_out(Cout[3]));

	// G and P Calculation (used for 16bit CLA)

	nand2 nand_2_13(.in1(p[3]), .in2(g[2]), .out(nand_2_13_out));
	nand2 nand_2_14(.in1(not_g[3]), .in2(nand_2_13_out), .out(nand_2_14_out));
	nand3 nand_3_1(.in1(p[3]), .in2(p[2]), .in3(g[1]), .out(nand_3_1_out));
	nand2 nand_2_15(.in1(p[3]), .in2(p[2]), .out(nand_2_15_out));
	nand2 nand_2_16(.in1(p[1]), .in2(g[0]), .out(nand_2_16_out));
	nor2 nor_2_5(.in1(nand_2_15_out), .in2(nand_2_16_out), .out(nor_2_5_out));
	not1 not_1_13(.in1(nor_2_5_out), .out(not_1_13_out));
	nand2 nand_2_17(.in1(nand_3_1_out), .in2(not_1_13_out), .out(nand_2_17_out));
	nor2 nor_2_6(.in1(nand_2_14_out), .in2(nand_2_17_out), .out(nor_2_6_out));
	not1 not_1_14(.in1(nor_2_6_out), .out(G));

	nand2 nand_2_18(.in1(p[3]), .in2(p[2]), .out(nand_2_18_out));
	nand2 nand_2_19(.in1(p[1]), .in2(p[0]), .out(nand_2_19_out));
	nor2 nor_2_7(.in1(nand_2_18_out), .in2(nand_2_19_out), .out(P));

endmodule
