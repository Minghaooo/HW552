/*
   CS/ECE 552, Spring '20
   Homework #3, Problem #1
   
*/
module reg_16bit (readData, clk, rst, readSel, writeSel, writeData, writeEn, err);

	parameter SIZE = 16;

	input	clk, rst;
	input	readSel;
	input	writeSel;
	input	[(SIZE - 1):0]	writeData;
	input	writeEn;

	output [(SIZE - 1):0] readData;
	output err;

   /* YOUR CODE HERE */
   	
	wire [(SIZE - 1):0] d;
	wire [(SIZE - 1):0] q;
   
	dff_16bit FF(.rst(rst), .clk(clk), .d(d), .q(q));
	
	//assign err = (writeData == SIZE'hxxxx)? (1'b1 | err)	:	(1'b0 | err);	// Error flag.
	//assign readData = (readSel == 1'b1)? q[(SIZE - 1):0]	:	16'hzzzz;		// If selected, output data; otherwise high impedance
	
	assign err = (^writeData == 1'bx)?	1	:	0;	// Because XOR output depends on number of 1s or 0s, can use it to determine the existence of x
	
	assign readData = q;		// Output data
	
	assign err = (writeEn == 1'bx)?	(1'b1 | err)	:	(1'b0 | err);

	assign d = ({writeEn, writeSel} == 2'b11)?	writeData	:	q;			// Keep storing own value if not selected or not enabled
   
endmodule
