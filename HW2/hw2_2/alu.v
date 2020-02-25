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
module alu (InA, InB, Cin, Op, invA, invB, sign, Out, Zero, Ofl);

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
   input         sign;  // to determine whether it is signed or unsigned. 
   output [N-1:0] Out; //
   output         Ofl; //
   output         Zero; //

   wire [N-1:0] InA_inv;
   wire [N-1:0] InB_inv;
   /* YOUR CODE HERE */

   wire [N-1:0] Out_adder;
   wire [N-1:0] Out_shift;
   wire Co_ov;

  reg [N-1:0] Out; 



   // invert signal;  use InA_inv later 
  assign InA_inv = invA ? ~InA : InA;
  assign InB_inv = invB ? ~InB : InB;

// cla adder and shiter here: 

  shifter_hier  shifter ( 
                          .In(InA_inv), 
                          .Cnt(InB_inv[3:0]), 
                          .Op(Op), 
                          .Out(Out_shift)
                        );

  
   cla_16b cla(
              .A(InA_inv), 
              .B(InB_inv), 
              .C_in(Cin), 
              .S(Out_adder), 
              .C_out(Co_ov)
              );




  always @(*) begin 
    casex (Op)
      3'b0??: Out = Out_shift;
      3'b100: Out = Out_adder; 
      3'b101: Out = InA_inv &InB_inv; 
      3'b110: Out = InA_inv |InB_inv; 
      3'b111: Out = InA_inv ^InB_inv; 
      default : Out = 0;
    endcase
  
  end

   assign Ofl = (Op == 3'b100)&&(sign == 1'b1)? (Out_adder[15]^InA_inv[15]^InB_inv[15]^Co_ov): 
                (Op == 3'b100)&&(sign == 1'b0)?  Co_ov: 1'b0;


   assign Zero = (Out_adder == 0) ? 1'b1 : 1'b0; 
/*
    if (sign == 1'b1)
                 ExOfl = Out_adder[15]^InA[15]^InB[15]^Co_ov;
               else
                 ExOfl = ExOut[16];

   */ 
endmodule
