/*
   CS/ECE 552, Spring '20
   Homework #3, Problem #2
  
   This module creates a wrapper around the 8x16b register file, to do
   do the bypassing logic for RF bypassing.
*/
module regFile_bypass (
                       // Outputs
                       read1Data, read2Data, err,
                       // Inputs
                       clk, rst, read1RegSel, read2RegSel, writeRegSel, writeData, writeEn
                       );
	
	parameter SIZE = 16;
					   
   input        clk, rst;
   input [2:0]  read1RegSel;
   input [2:0]  read2RegSel;
   input [2:0]  writeRegSel;
   input [(SIZE - 1):0] writeData;
   input        writeEn;

   output [(SIZE - 1):0] read1Data;
   output [(SIZE - 1):0] read2Data;
   output        err;

   /* YOUR CODE HERE */

   wire [(SIZE - 1):0] read1Data_temp;
   wire [(SIZE - 1):0] read2Data_temp;

   // instance here - 16bit 
  regFile my_register_file(
                // Outputs
                .read1Data(read1Data_temp), 
                .read2Data(read2Data_temp), 
                .err(err),
                // Inputs
                .clk(clk), 
                .rst(rst), 
                .read1RegSel(read1RegSel), 
                .read2RegSel(read2RegSel), 
                .writeRegSel(writeRegSel), 
                .writeData(writeData), 
                .writeEn(writeEn)
                );

	assign read1Data = ((read1RegSel == writeRegSel) & writeEn) ? writeData : read1Data_temp;
	assign read2Data = ((read2RegSel == writeRegSel) & writeEn) ? writeData : read2Data_temp;

endmodule
