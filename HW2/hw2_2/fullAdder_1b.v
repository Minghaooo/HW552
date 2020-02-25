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

    wire ab_nand;
    wire ab_xor;
    wire cab_nand;

    wire g_n;
    wire p_n;

    wire gnpn_not;
    wire gncn_not;

    wire cnot;
    wire cin_not;


    // YOUR CODE HERE
// s = a xor b xor cin
xor3 xor_S (
	.in1(A),
	.in2(B),
	.in3(C_in),
	.out(S)
	);
//cout = ab+cin(a xor b)
//cout =((ab)'(C (a xor b))' )'


//cla_cout 
//	nand2 nand_ab(
//		.in1(A),
//		.in2(B),
//		.out(ab_nand)
//		);
//	xor2 xor_ab (
//		.in1(A),
//		.in2(B),
//		.out(ab_xor)
//		);
//	nand2 nand2_cab (
//		.in1(C_in),
//		.in2(ab_xor),
//		.out(cab_nand)
//		);
//	nand2 nand_out(
//		.in1(cab_nand),
//		.in2(ab_nand),
//		.out(C_out)
//		);


//cout_cla

	not1 notCin(
    	.in1(C_in),
    	.out(cin_not)
    	);

	nand2 gi_not (
        .in1(A),
        .in2(B),
        .out(g_n)
        );

    nor2 pi_not (
        .in1(A),
        .in2(B),
        .out(p_n)
        );

    nand2 gp_not (
        .in1(g_n),
        .in2(p_n),
        .out(gnpn_not)
        );

    nand2 gc_not (
        .in1(g_n),
        .in2(cin_not),
        .out(gncn_not)
        );

    nand2 c_outn (
        .in1(gncn_not),
        .in2(gnpn_not),
        .out(cnot)
        );
    
    not1 Cout_not(
    	.in1(cnot),
    	.out(C_out)
    	);






endmodule










