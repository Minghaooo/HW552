/*
    CS/ECE 552 Spring '20
    Homework #1, Problem 1

    2-1 mux template
*/
module mux2_1(InA, InB, S, Out);
    input   InA, InB;
    input   S;
    output  Out;

    wire S_not;
    wire A1,B1,out_nor;

    not1 not_s(
        .in1(S),
        .out(S_not)
        );

    nand2 Nand_A (
        .in1(S_not),
        .in2(InA),
        .out(A1)
        );
     nand2 Nand_B (
        .in1(S),
        .in2(InB),
        .out(B1)
        );

    nand2 and_AB (
         .in1(A1),
        .in2(B1),
        .out(out_nor)
        );
     not1 not_out(
        .in1(out_nor),
        .out(Out)
        );

endmodule
