/*
   CS/ECE 552, Spring '20
   Homework #3, Problem #1
  
   This module creates a 16-bit register.  It has 1 write port, 2 read
   ports, 3 register select inputs, a write enable, a reset, and a clock
   input.  All register state changes occur on the rising edge of the
   clock. 
*/
module regFile (read1Data, read2Data, err, clk, rst, read1RegSel, read2RegSel, writeRegSel, writeData, writeEn);
				
	parameter SIZE = 16;

	input        clk, rst;
	input [2:0]  read1RegSel;
	input [2:0]  read2RegSel;
	input [2:0]  writeRegSel;
	input [(SIZE - 1):0] writeData;
	input        writeEn;

	output reg [(SIZE - 1):0] read1Data;
	output reg [(SIZE - 1):0] read2Data;
	output	err;

	/* YOUR CODE HERE */
	
	reg		[7:0] read1Sel, read2Sel;
	wire 	[7:0] readSel;
	wire 	[7:0] writeSel;
	wire	[7:0] reg_err;
	wire 	[(SIZE - 1):0] q[7:0];
	reg 	[(SIZE - 1):0] d;
	
	// Instantiate 16 bit registers
	reg_16bit R0(.readData(q[0]), .clk(clk), .rst(rst), .readSel(readSel[0]), .writeSel(writeSel[0]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[0]));
	reg_16bit R1(.readData(q[1]), .clk(clk), .rst(rst), .readSel(readSel[1]), .writeSel(writeSel[1]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[1]));
	reg_16bit R2(.readData(q[2]), .clk(clk), .rst(rst), .readSel(readSel[2]), .writeSel(writeSel[2]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[2]));
	reg_16bit R3(.readData(q[3]), .clk(clk), .rst(rst), .readSel(readSel[3]), .writeSel(writeSel[3]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[3]));
	reg_16bit R4(.readData(q[4]), .clk(clk), .rst(rst), .readSel(readSel[4]), .writeSel(writeSel[4]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[4]));
	reg_16bit R5(.readData(q[5]), .clk(clk), .rst(rst), .readSel(readSel[5]), .writeSel(writeSel[5]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[5]));
	reg_16bit R6(.readData(q[6]), .clk(clk), .rst(rst), .readSel(readSel[6]), .writeSel(writeSel[6]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[6]));
	reg_16bit R7(.readData(q[7]), .clk(clk), .rst(rst), .readSel(readSel[7]), .writeSel(writeSel[7]), .writeData(writeData), .writeEn(writeEn), .err(reg_err[7]));

	always @(*) begin
	
		// readSel1 logic
		case(read1RegSel)
			3'b000	:	assign read1Sel = 8'b00000001;
			3'b001	:	assign read1Sel = 8'b00000010;
			3'b010	:	assign read1Sel = 8'b00000100;
			3'b011	:	assign read1Sel = 8'b00001000;
			3'b100	:	assign read1Sel = 8'b00010000;
			3'b101	:	assign read1Sel = 8'b00100000;
			3'b110	:	assign read1Sel = 8'b01000000;
			3'b111	:	assign read1Sel = 8'b10000000;
			default	:	assign read1Sel = 8'b00000000;
		endcase
		
	end
	
	always @(*) begin
	
		// readSel2 logic
		case(read2RegSel)
			3'b000	:	assign read2Sel = 8'b00000001;
			3'b001	:	assign read2Sel = 8'b00000010;
			3'b010	:	assign read2Sel = 8'b00000100;
			3'b011	:	assign read2Sel = 8'b00001000;
			3'b100	:	assign read2Sel = 8'b00010000;
			3'b101	:	assign read2Sel = 8'b00100000;
			3'b110	:	assign read2Sel = 8'b01000000;
			3'b111	:	assign read2Sel = 8'b10000000;
			default	:	assign read2Sel = 8'b00000000;
		endcase
	
	end
	
	always @(*) begin
	
		// readData logic
		case(read1RegSel)
			3'o0:	assign read1Data = q[0];
			3'o1:	assign read1Data = q[1];
			3'o2:	assign read1Data = q[2];
			3'o3:	assign read1Data = q[3];
			3'o4:	assign read1Data = q[4];
			3'o5:	assign read1Data = q[5];
			3'o6:	assign read1Data = q[6];
			3'o7:	assign read1Data = q[7];
			default:	assign read1Data = q[0];
		endcase
	
	end
	
	always @(*) begin
	
		case(read2RegSel)
			3'o0:	assign read2Data = q[0];
			3'o1:	assign read2Data = q[1];
			3'o2:	assign read2Data = q[2];
			3'o3:	assign read2Data = q[3];
			3'o4:	assign read2Data = q[4];
			3'o5:	assign read2Data = q[5];
			3'o6:	assign read2Data = q[6];
			3'o7:	assign read2Data = q[7];
			default:	assign read2Data = q[0];
		endcase
	
	end
	
	assign readSel = read1Sel | read2Sel;	
	
	// Determine writeSel logic
	assign writeSel[0] = (writeRegSel == 3'o0)? 1'b1	:	1'b0;
	assign writeSel[1] = (writeRegSel == 3'o1)? 1'b1	:	1'b0;
	assign writeSel[2] = (writeRegSel == 3'o2)? 1'b1	:	1'b0;
	assign writeSel[3] = (writeRegSel == 3'o3)? 1'b1	:	1'b0;
	assign writeSel[4] = (writeRegSel == 3'o4)? 1'b1	:	1'b0;
	assign writeSel[5] = (writeRegSel == 3'o5)? 1'b1	:	1'b0;
	assign writeSel[6] = (writeRegSel == 3'o6)? 1'b1	:	1'b0;
	assign writeSel[7] = (writeRegSel == 3'o7)? 1'b1	:	1'b0;
	
	assign err = (|reg_err);
	


endmodule
