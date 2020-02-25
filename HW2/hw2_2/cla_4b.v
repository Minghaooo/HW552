/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 2
    
    a 4-bit CLA module
*/
module cla_4b(A, B, C_in, S, C_out);

    // declare constant for size of inputs, outputs (N)
    parameter   N = 4;

    input [N-1: 0] A, B;
    input          C_in;
    output [N-1:0] S;
    output         C_out;

wire c1,c2,c3;

    // YOUR CODE HERE
// Cout = (AiBi)+(Ai+Bi)*Cin = gi' *(pi')
    fullAdder_1b adder01(
        .A(A[0]), 
        .B(B[0]), 
        .C_in(C_in), 
        .S(S[0]), 
        .C_out(c1)
        );
     fullAdder_1b adder02(
        .A(A[1]), 
        .B(B[1]), 
        .C_in(c1), 
        .S(S[1]), 
        .C_out(c2)
        );
      fullAdder_1b adder03(
        .A(A[2]), 
        .B(B[2]), 
        .C_in(c2), 
        .S(S[2]), 
        .C_out(c3)
        );

       fullAdder_1b adder04(
        .A(A[3]), 
        .B(B[3]), 
        .C_in(c3), 
        .S(S[3]), 
        .C_out(C_out)
        );

   // gi' = (Ab)'
   // pi' = (a+b)'

   //c = nand(nand(g'p'),nand(g'c'))' 
    

endmodule
