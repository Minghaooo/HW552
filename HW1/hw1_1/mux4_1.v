/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 1

    4-1 mux template
*/
module mux4_1(InA, InB, InC, InD, S, Out);
    input        InA, InB, InC, InD;
    input [1:0]  S;
    output       Out;

    wire Out_a, Out_b;
    wire out_not;


    mux2_1 mux2_1a(
        .InA(InA), 
        .InB(InB), 
        .S(S[0]), 
        .Out(Out_a)
    );

    mux2_1 mux2_1b(
        .InA(InC), 
        .InB(InD), 
        .S(S[0]), 
        .Out(Out_b)
    );

  mux2_1 mux2_out(
        .InA(Out_a), 
        .InB(Out_b), 
        .S(S[1]), 
        .Out(Out)
    );

   


    // YOUR CODE HERE

endmodule
