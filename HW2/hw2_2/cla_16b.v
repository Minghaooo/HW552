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

    wire c1,c2,c3;


    // YOUR CODE HERE
    cla_4b cla4_01(
        .A(A[3:0]), 
        .B(B[3:0]), 
        .C_in(C_in), 
        .S(S[3:0]), 
        .C_out(c1)
        );
    cla_4b cla4_02(
        .A(A[7:4]), 
        .B(B[7:4]), 
        .C_in(c1), 
        .S(S[7:4]), 
        .C_out(c2)
        );
    
       cla_4b cla4_03(
        .A(A[11:8]), 
        .B(B[11:8]), 
        .C_in(c2), 
        .S(S[11:8]), 
        .C_out(c3)
        );
    
       cla_4b cla4_04(
        .A(A[15:12]), 
        .B(B[15:12]), 
        .C_in(c3), 
        .S(S[15:12]), 
        .C_out(C_out)
        );
    


endmodule
