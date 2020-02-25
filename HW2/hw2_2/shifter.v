/*
    CS/ECE 552 Spring '20
    Homework #2, Problem 1
    
    A barrel shifter module.  It is designed to shift a number via rotate
    left, shift left, shift right arithmetic, or shift right logical based
    on the Op() value that is passed in (2 bit number).  It uses these
    shifts to shift fthe value any number o bits between 0 and 15 bits.
 */
module shifter (In, Cnt, Op, Out);

   // declare constant for size of inputs, outputs (N) and # bits to shift (C)
   parameter   N = 16;
   parameter   C = 4;
   parameter   O = 3;

   input [N-1:0]   In;
   input [C-1:0]   Cnt;
   input [O-1:0]   Op;
   output [N-1:0]  Out;
   
  



   /*
always @(*) begin 
  case (Op)
    0: Out <= {In[Cnt-1:0],In[N-1:Cnt]};
    default: Out <= {In[Cnt-1:0],In[N-1:Cnt]};
    endcase // Op

end

*/
   /* YOUR CODE HERE */
   assign Out =(Op == 3'b000) ?  (In << Cnt)| (In>>(N-Cnt)):
                (Op == 3'b001) ? In << Cnt: // sheif left
                (Op == 3'b010) ? (In >>Cnt) | ({16{In[15]}} <<(N-Cnt)):  // shift right arithematic 
                (Op == 3'b011)?  In >>Cnt:
                                In;
                               

   
endmodule
