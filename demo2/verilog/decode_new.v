module decode_new(

	// Inputs
	input clk, rst,
	
	input [15:0] instruction,
	input [15:0] PC,				// Note: byte-addressable, 8 bits in 1 Byte
	
	input [15:0] ALU_Out,
	input ALU_Zero, ALU_Ofl,
	
	input [15:0] WB_data,
	
	input [2:0] writeRegSel,
	//input [15:0] writeData,
	input regWrite_ext_enable,
	
	input [15:0] imm_from_WB, PC_from_WB, arbitrary_num_from_WB, mask_from_WB,
	input [1:0] writeSrc_from_WB,
	
	output [2:0] writeRegSel_Out,
	//output [15:0] writeData_Out,
	output regWrite_enable,
	
	output [1:0] writeSrc,				// 01 -> WriteBack result, 00 -> Local result, 10 -> Arbitrary number, 11 -> imm 
	output [15:0] imm, mask, 			// Used for SLBI and LBI
	output [15:0] arbitrary_num,			
	
	// Outputs to Execution
	output [15:0] InA, InB,
	output [2:0] ALU_op,
	output Cin, invA, invB, sign,
	output [1:0] second_operand,		// immediate, zero or Rt?
	output PC_selSrc,					// Select whether PC should be updated with value from execute stage
	output [1:0] PC_Add, 				// PC+2 -> 00, +imm -> 01, RS + i -> 10
	
	// Outputs to Memory & Write-Back
	output MEM_En, MEM_writeEn, Mux_MtoReg,

	// Outputs to PROC
	output err, 
	output halt, createdump
	
	);
	
	// Second operand
	localparam IM = 2'b00;
	localparam ZE = 2'b01;
	localparam RT = 2'b10;
	
	wire [4:0] opcode;
	wire [1:0] opcode_ex;
	wire [2:0] Rd_R, Rd_I, Rs, Rt;
	wire [10:0] disp;
	wire [4:0] imm_5;
	wire [7:0] imm_8;
	
	wire [15:0] writeData;
	
	wire [2:0] t_ops;	// Translated opcode to fit the adder's operations

	wire reg_err;
	wire [2:0] read1RegSel, read2RegSel; 
	wire [1:0] REG_writeSel;				// 00 -> Rs, 01 -> decimal 7, 10 -> Rd_R, 11 -> Rd_I					
	wire [15:0] read1Data, read2Data;
	wire halt_flag;
	wire LT;
	
	regFile_bypass regFile0(.read1Data(read1Data), .read2Data(read2Data), .err(reg_err), .clk(clk), .rst(rst), 
		.read1RegSel(read1RegSel), .read2RegSel(read2RegSel), 
		.writeRegSel(writeRegSel), .writeData(writeData), .writeEn(regWrite_ext_enable));
	
	// Peripheral Signals
	assign opcode = instruction[15:11];
	assign opcode_ex = instruction[1:0];
	
	assign Rs = instruction[10:8];
	assign Rt = instruction[7:5];
	assign Rd_R = instruction[4:2];
	assign Rd_I = instruction[7:5];
	
	assign disp = instruction[10:0];
	assign imm_5 = instruction[4:0];
	assign imm_8 = instruction[7:0];
	
	assign t_ops = 	(opcode_ex == 2'b00)?	3'b100	:	(opcode_ex == 2'b01)?	3'b100	:
					(opcode_ex == 2'b10)?	3'b111	:	(opcode_ex == 2'b11)?	3'b101	:
					3'b100;
	
	dff halt_ff(.d(halt | halt_flag), .q(halt_flag), .clk(clk), .rst(rst));
	
	assign writeData = 	(writeSrc_from_WB == 2'b00)?	PC_from_WB	:	
						(writeSrc_from_WB == 2'b01)?	WB_data	:	
						(writeSrc_from_WB == 2'b10)?	arbitrary_num_from_WB:
						(imm_from_WB | mask_from_WB);
	
	assign writeRegSel_Out = 	(rst == 1'b1)	?			3'h0	:
								(REG_writeSel == 2'b00)?	Rs	:	
								(REG_writeSel == 2'b01)?	3'h7:	
								(REG_writeSel == 2'b10)?	Rd_R:
								Rd_I;
								
	wire[15:0]	writeData_tst;
	assign writeData_tst = 	(writeSrc == 2'b00)	?	PC:	
							(writeSrc == 2'b01)	?	WB_data	:	
							(writeSrc == 2'b10)	?	arbitrary_num	:	
							(imm	|	mask);
	
	assign InA = read1Data;
	assign InB = read2Data;
	assign PC_selSrc = (PC_Add == 2'b00)? 1'b0	:	1'b1;

	// Halt and createdump signals
	assign halt = (instruction[15:11] == 5'b00000)? 1'b1	:	1'b0;
	assign createdump = halt;
	
	//assign writeData_Out = 16'hEEEE;	// This signal is not longer used.
	
	assign writeRegSel_Out = 	(rst == 1'b1)	?			3'h0	:
								((REG_writeSel == 2'b00)?	Rs	:	
								(REG_writeSel == 2'b01)?	3'h7:	
								(REG_writeSel == 2'b10)?	Rd_R:
								Rd_I);
	
	// Signals related to Memory operations
	assign MEM_En = 		(opcode == 5'b10000)?	1'b1	/*ST*/		:
							(opcode == 5'b10001)?	1'b1 	/*LD*/		:	
							(opcode == 5'b10011)?	1'b1	/*STU*/		:
							1'b0;
						
	assign MEM_writeEn = 	(opcode == 5'b10000)?	1'b1	/*ST*/		:
							(opcode == 5'b10011)?	1'b1	/*STU*/		:
							1'b0;
	
	// Signal to write back
	assign Mux_MtoReg = 	(opcode == 5'b10100)?	1'b0	/*ROLI*/	:	(opcode == 5'b10101)?	1'b0	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b0	/*RORI*/	:	(opcode == 5'b10111)?	1'b0	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b0	/*ADDI*/	:	(opcode == 5'b01001)?	1'b0	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b0	/*XORI*/	:	(opcode == 5'b01011)?	1'b0	/*ANDNI*/	:
							(opcode == 5'b11011)?	1'b0	/*OPSR*/	:	(opcode == 5'b11010)?	1'b0	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b0	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b1 	/*LD*/		:	(opcode == 5'b10011)?	1'b0	/*STU*/		:
							(opcode == 5'b11100)?	1'b0	/*SEQ*/		:	(opcode == 5'b11101)?	1'b0	/*SLT*/		:
							(opcode == 5'b11110)?	1'b0	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b0	/*JAL*/		:	(opcode == 5'b00111)?	1'b0	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b0	/*LBI*/		:
							(opcode == 5'b11001)?	1'b0	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b0;
	
	// Err signal
	assign err = 			((opcode == 5'b10100)?	1'b0	/*ROLI*/	:	(opcode == 5'b10101)?	1'b0	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b0	/*RORI*/	:	(opcode == 5'b10111)?	1'b0	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b0	/*ADDI*/	:	(opcode == 5'b01001)?	1'b0	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b0	/*XORI*/	:	(opcode == 5'b01011)?	1'b0	/*ANDNI*/	:
							(opcode == 5'b11011)?	1'b0	/*OPSR*/	:	(opcode == 5'b11010)?	1'b0	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b0	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b0 	/*LD*/		:	(opcode == 5'b10011)?	1'b0	/*STU*/		:
							(opcode == 5'b11100)?	1'b0	/*SEQ*/		:	(opcode == 5'b11101)?	1'b0	/*SLT*/		:
							(opcode == 5'b11110)?	1'b0	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b0	/*JAL*/		:	(opcode == 5'b00111)?	1'b0	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b0	/*LBI*/		:
							(opcode == 5'b11001)?	1'b0	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b1) | reg_err;
	
	// regWrite_enable, used to enable/disable register input
	assign regWrite_enable =(opcode == 5'b10100)?	1'b1	/*ROLI*/	:	(opcode == 5'b10101)?	1'b1	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b1	/*RORI*/	:	(opcode == 5'b10111)?	1'b1	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b1	/*ADDI*/	:	(opcode == 5'b01001)?	1'b1	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b1	/*XORI*/	:	(opcode == 5'b01011)?	1'b1	/*ANDNI*/	:
							(opcode == 5'b11011)?	1'b1	/*OPSR*/	:	(opcode == 5'b11010)?	1'b1	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b1	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b1 	/*LD*/		:	(opcode == 5'b10011)?	1'b1	/*STU*/		:
							(opcode == 5'b11100)?	1'b1	/*SEQ*/		:	(opcode == 5'b11101)?	1'b1	/*SLT*/		:
							(opcode == 5'b11110)?	1'b1	/*SLE*/		:	(opcode == 5'b11111)?	1'b1	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b1	/*JAL*/		:	(opcode == 5'b00111)?	1'b1	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b1	/*LBI*/		:
							(opcode == 5'b11001)?	1'b1	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b0;
	
	// writeSrc signal, used to choose source written into register
	assign writeSrc =		(opcode == 5'b10100)?	2'b01	/*ROLI*/	:	(opcode == 5'b10101)?	2'b01	/*SLLI*/	:
							(opcode == 5'b10110)?	2'b01	/*RORI*/	:	(opcode == 5'b10111)?	2'b01	/*SRLI*/	:
							(opcode == 5'b01000)?	2'b01	/*ADDI*/	:	(opcode == 5'b01001)?	2'b01	/*SUBI*/	:
							(opcode == 5'b01010)?	2'b01	/*XORI*/	:	(opcode == 5'b01011)?	2'b01	/*ANDNI*/	:
							(opcode == 5'b11011)?	2'b01	/*OPSR*/	:	(opcode == 5'b11010)?	2'b01	/*SFTR*/	:
							(opcode == 5'b10010)?	2'b11	/*SLBI*/	:	(opcode == 5'b10000)?	2'b01	/*ST*/		:
							(opcode == 5'b10001)?	2'b01 	/*LD*/		:	(opcode == 5'b10011)?	2'b01	/*STU*/		:
							(opcode == 5'b11100)?	2'b10	/*SEQ*/		:	(opcode == 5'b11101)?	2'b10	/*SLT*/		:
							(opcode == 5'b11110)?	2'b10	/*SLE*/		:	(opcode == 5'b11111)?	2'b10	/*SCO*/		:
							(opcode == 5'b01100)?	2'b01	/*BEQZ*/	:	(opcode == 5'b01101)?	2'b01	/*BNEZ*/	:
							(opcode == 5'b01110)?	2'b01	/*BLTZ*/	:	(opcode == 5'b01111)?	2'b01	/*BGEZ*/	:
							(opcode == 5'b00100)?	2'b01	/*J*/		:	(opcode == 5'b00101)?	2'b01	/*JR*/		:
							(opcode == 5'b00110)?	2'b10	/*JAL*/		:	(opcode == 5'b00111)?	2'b10	/*JALR*/	:
							(opcode == 5'b00001)?	2'b01	/*NOP*/		:	(opcode == 5'b00000)?	2'b01	/*HALT*/	:
							(opcode == 5'b00010)?	2'b01	/*SIIC*/	:	(opcode == 5'b11000)?	2'b10	/*LBI*/		:
							(opcode == 5'b11001)?	2'b10	/*BTR*/		:	(opcode == 5'b00011)?	2'b01	/*RTI*/		:
							2'b01;
	
	// imm signal, extended immediate value
	assign imm		 =		(opcode == 5'b10100)?	{12'h000, imm_5[3:0]}	/*ROLI*/	:	(opcode == 5'b10101)?	{12'h000, imm_5[3:0]}	/*SLLI*/	:
							(opcode == 5'b10110)?	{12'h000, imm_5[3:0]}	/*RORI*/	:	(opcode == 5'b10111)?	{12'h000, imm_5[3:0]}	/*SRLI*/	:
							(opcode == 5'b01000)?	{{11{imm_5[4]}}, imm_5}	/*ADDI*/	:	(opcode == 5'b01001)?	{{11{imm_5[4]}}, imm_5}	/*SUBI*/	:
							(opcode == 5'b01010)?	{11'h000, imm_5}		/*XORI*/	:	(opcode == 5'b01011)?	{11'h000, imm_5}		/*ANDNI*/	:
							(opcode == 5'b11011)?	16'h0000				/*OPSR*/	:	(opcode == 5'b11010)?	16'h0000				/*SFTR*/	:
							(opcode == 5'b10010)?	{read1Data[7:0], imm_8}	/*SLBI*/	:	(opcode == 5'b10000)?	{{11{imm_5[4]}}, imm_5}	/*ST*/		:
							(opcode == 5'b10001)?	{{11{imm_5[4]}}, imm_5} /*LD*/		:	(opcode == 5'b10011)?	{{11{imm_5[4]}}, imm_5}	/*STU*/		:
							(opcode == 5'b11100)?	16'h0000				/*SEQ*/		:	(opcode == 5'b11101)?	16'h0000				/*SLT*/		:
							(opcode == 5'b11110)?	16'h0000				/*SLE*/		:	(opcode == 5'b11111)?	16'h0000				/*SCO*/		:
							(opcode == 5'b01100)?	{{8{imm_8[7]}}, imm_8}	/*BEQZ*/	:	(opcode == 5'b01101)?	{{8{imm_8[7]}}, imm_8}	/*BNEZ*/	:
							(opcode == 5'b01110)?	{{8{imm_8[7]}}, imm_8}	/*BLTZ*/	:	(opcode == 5'b01111)?	{{8{imm_8[7]}}, imm_8}	/*BGEZ*/	:
							(opcode == 5'b00100)?	{{5{disp[10]}}, disp}	/*J*/		:	(opcode == 5'b00101)?	{{8{imm_8[7]}}, imm_8}	/*JR*/		:
							(opcode == 5'b00110)?	{{5{disp[10]}}, disp}	/*JAL*/		:	(opcode == 5'b00111)?	{{8{imm_8[7]}}, imm_8}	/*JALR*/	:
							(opcode == 5'b00001)?	16'h0000				/*NOP*/		:	(opcode == 5'b00000)?	16'hFFFD				/*HALT*/	:
							(opcode == 5'b00010)?	16'h0000				/*SIIC*/	:	(opcode == 5'b11000)?	16'h0000				/*LBI*/		:
							(opcode == 5'b11001)?	16'h0000				/*BTR*/		:	(opcode == 5'b00011)?	16'h0000				/*RTI*/		:
							16'h0000;
							
	// mask signal, used to mask off certain bits
	assign mask = 16'h0000;	// This signal is no longer used.
	
	// arbitrary number that is directly assigned in decode stage
	assign arbitrary_num =	(opcode == 5'b10100)?	16'h0000				/*ROLI*/	:	(opcode == 5'b10101)?	16'h0000				/*SLLI*/	:
							(opcode == 5'b10110)?	16'h0000				/*RORI*/	:	(opcode == 5'b10111)?	16'h0000				/*SRLI*/	:
							(opcode == 5'b01000)?	16'h0000				/*ADDI*/	:	(opcode == 5'b01001)?	16'h0000				/*SUBI*/	:
							(opcode == 5'b01010)?	16'h0000				/*XORI*/	:	(opcode == 5'b01011)?	16'h0000				/*ANDNI*/	:
							(opcode == 5'b11011)?	16'h0000				/*OPSR*/	:	(opcode == 5'b11010)?	16'h0000				/*SFTR*/	:
							(opcode == 5'b10010)?	16'h0000				/*SLBI*/	:	(opcode == 5'b10000)?	16'h0000				/*ST*/		:
							(opcode == 5'b10001)?	16'h0000 				/*LD*/		:	(opcode == 5'b10011)?	16'h0000				/*STU*/		:
							(opcode == 5'b11100)?	{15'h0000, ALU_Zero}	/*SEQ*/		:	(opcode == 5'b11101)?	{15'h0000, LT}			/*SLT*/		:
							(opcode == 5'b11110)?	{15'h0000,(LT|ALU_Zero)}/*SLE*/		:	(opcode == 5'b11111)?	{15'h0000, ALU_Ofl}		/*SCO*/		:
							(opcode == 5'b01100)?	16'h0000				/*BEQZ*/	:	(opcode == 5'b01101)?	16'h0000				/*BNEZ*/	:
							(opcode == 5'b01110)?	16'h0000				/*BLTZ*/	:	(opcode == 5'b01111)?	16'h0000				/*BGEZ*/	:
							(opcode == 5'b00100)?	16'h0000				/*J*/		:	(opcode == 5'b00101)?	16'h0000				/*JR*/		:
							(opcode == 5'b00110)?	PC						/*JAL*/		:	(opcode == 5'b00111)?	PC						/*JALR*/	:
							(opcode == 5'b00001)?	16'h0000				/*NOP*/		:	(opcode == 5'b00000)?	16'h0000				/*HALT*/	:
							(opcode == 5'b00010)?	16'h0000				/*SIIC*/	:	(opcode == 5'b11000)?	{{8{imm_8[7]}}, imm_8}	/*LBI*/		:
							(opcode == 5'b11001)?	{read1Data[0], read1Data[1], read1Data[2], read1Data[3], read1Data[4], read1Data[5]
													, read1Data[6], read1Data[7], read1Data[8], read1Data[9], read1Data[10], read1Data[11]
													, read1Data[12], read1Data[13], read1Data[14], read1Data[15]}							/*BTR*/		:	
							(opcode == 5'b00011)?	16'h0000				/*RTI*/		:	16'h0000;

	// Inputs to execute stage
	assign InA = read1Data;
	assign InB = read2Data;
	
	// ALU_op, defines the operation that the ALU will carry out
	assign ALU_op	 =		(opcode == 5'b10100)?	3'b000	/*ROLI*/	:	(opcode == 5'b10101)?	3'b001	/*SLLI*/	:
							(opcode == 5'b10110)?	3'b010	/*RORI*/	:	(opcode == 5'b10111)?	3'b011	/*SRLI*/	:
							(opcode == 5'b01000)?	3'b100	/*ADDI*/	:	(opcode == 5'b01001)?	3'b100	/*SUBI*/	:
							(opcode == 5'b01010)?	3'b111	/*XORI*/	:	(opcode == 5'b01011)?	3'b101	/*ANDNI*/	:
							(opcode == 5'b11011)?	t_ops	/*OPSR*/	:	(opcode == 5'b11010)?	{1'b0, opcode_ex}	/*SFTR*/	:
							(opcode == 5'b10010)?	3'b100	/*SLBI*/	:	(opcode == 5'b10000)?	3'b100	/*ST*/		:
							(opcode == 5'b10001)?	3'b100 	/*LD*/		:	(opcode == 5'b10011)?	3'b100	/*STU*/		:
							(opcode == 5'b11100)?	3'b100	/*SEQ*/		:	(opcode == 5'b11101)?	3'b100	/*SLT*/		:
							(opcode == 5'b11110)?	3'b100	/*SLE*/		:	(opcode == 5'b11111)?	3'b100	/*SCO*/		:
							(opcode == 5'b01100)?	3'b100	/*BEQZ*/	:	(opcode == 5'b01101)?	3'b100	/*BNEZ*/	:
							(opcode == 5'b01110)?	3'b100	/*BLTZ*/	:	(opcode == 5'b01111)?	3'b100	/*BGEZ*/	:
							(opcode == 5'b00100)?	3'b100	/*J*/		:	(opcode == 5'b00101)?	3'b100	/*JR*/		:
							(opcode == 5'b00110)?	3'b100	/*JAL*/		:	(opcode == 5'b00111)?	3'b100	/*JALR*/	:
							(opcode == 5'b00001)?	3'b100	/*NOP*/		:	(opcode == 5'b00000)?	3'b100	/*HALT*/	:
							(opcode == 5'b00010)?	3'b100	/*SIIC*/	:	(opcode == 5'b11000)?	3'b100	/*LBI*/		:
							(opcode == 5'b11001)?	3'b100	/*BTR*/		:	(opcode == 5'b00011)?	3'b100	/*RTI*/		:
							3'b100;
	
	// Cin, used in execute stage
	assign Cin 		= 		(opcode == 5'b10100)?	1'b0	/*ROLI*/	:	(opcode == 5'b10101)?	1'b0	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b0	/*RORI*/	:	(opcode == 5'b10111)?	1'b0	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b0	/*ADDI*/	:	(opcode == 5'b01001)?	1'b1	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b0	/*XORI*/	:	(opcode == 5'b01011)?	1'b0	/*ANDNI*/	:
							(opcode == 5'b11011)?	((opcode_ex == 2'b01)? 	1'b1	:	1'b0)/*OPSR*/	:	
							(opcode == 5'b11010)?	1'b0	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b0	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b0 	/*LD*/		:	(opcode == 5'b10011)?	1'b0	/*STU*/		:
							(opcode == 5'b11100)?	1'b1	/*SEQ*/		:	(opcode == 5'b11101)?	1'b1	/*SLT*/		:
							(opcode == 5'b11110)?	1'b1	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b0	/*JAL*/		:	(opcode == 5'b00111)?	1'b0	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b0	/*LBI*/		:
							(opcode == 5'b11001)?	1'b0	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b0; 
	
	// invA, choose to invert A before it enters ALU
	assign invA 		= 	(opcode == 5'b10100)?	1'b0	/*ROLI*/	:	(opcode == 5'b10101)?	1'b0	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b0	/*RORI*/	:	(opcode == 5'b10111)?	1'b0	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b0	/*ADDI*/	:	(opcode == 5'b01001)?	1'b1	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b0	/*XORI*/	:	(opcode == 5'b01011)?	1'b0	/*ANDNI*/	:
							(opcode == 5'b11011)?	((opcode_ex == 2'b01)? 	1'b1	:	1'b0)/*OPSR*/	:	
							(opcode == 5'b11010)?	1'b0	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b0	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b0 	/*LD*/		:	(opcode == 5'b10011)?	1'b0	/*STU*/		:
							(opcode == 5'b11100)?	1'b0	/*SEQ*/		:	(opcode == 5'b11101)?	1'b0	/*SLT*/		:
							(opcode == 5'b11110)?	1'b0	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b0	/*JAL*/		:	(opcode == 5'b00111)?	1'b0	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b0	/*LBI*/		:
							(opcode == 5'b11001)?	1'b0	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b0; 
							
	// invB, choose to invert A before it enters ALU
	assign invB 		= 	(opcode == 5'b10100)?	1'b0	/*ROLI*/	:	(opcode == 5'b10101)?	1'b0	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b0	/*RORI*/	:	(opcode == 5'b10111)?	1'b0	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b0	/*ADDI*/	:	(opcode == 5'b01001)?	1'b0	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b0	/*XORI*/	:	(opcode == 5'b01011)?	1'b1	/*ANDNI*/	:
							(opcode == 5'b11011)?	((opcode_ex == 2'b11)? 	1'b1	:	1'b0)/*OPSR*/	:	
							(opcode == 5'b11010)?	1'b0	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b0	/*SLBI*/	:	(opcode == 5'b10000)?	1'b0	/*ST*/		:
							(opcode == 5'b10001)?	1'b0 	/*LD*/		:	(opcode == 5'b10011)?	1'b0	/*STU*/		:
							(opcode == 5'b11100)?	1'b1	/*SEQ*/		:	(opcode == 5'b11101)?	1'b1	/*SLT*/		:
							(opcode == 5'b11110)?	1'b1	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b0	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b0	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b0	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b0	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b0	/*J*/		:	(opcode == 5'b00101)?	1'b0	/*JR*/		:
							(opcode == 5'b00110)?	1'b0	/*JAL*/		:	(opcode == 5'b00111)?	1'b0	/*JALR*/	:
							(opcode == 5'b00001)?	1'b0	/*NOP*/		:	(opcode == 5'b00000)?	1'b0	/*HALT*/	:
							(opcode == 5'b00010)?	1'b0	/*SIIC*/	:	(opcode == 5'b11000)?	1'b0	/*LBI*/		:
							(opcode == 5'b11001)?	1'b0	/*BTR*/		:	(opcode == 5'b00011)?	1'b0	/*RTI*/		:
							1'b0; 
							
	// sign, indicates if the sign matters
	assign sign 		= 	(opcode == 5'b10100)?	1'b1	/*ROLI*/	:	(opcode == 5'b10101)?	1'b1	/*SLLI*/	:
							(opcode == 5'b10110)?	1'b1	/*RORI*/	:	(opcode == 5'b10111)?	1'b1	/*SRLI*/	:
							(opcode == 5'b01000)?	1'b1	/*ADDI*/	:	(opcode == 5'b01001)?	1'b1	/*SUBI*/	:
							(opcode == 5'b01010)?	1'b1	/*XORI*/	:	(opcode == 5'b01011)?	1'b1	/*ANDNI*/	:
							(opcode == 5'b11011)?	1'b1	/*OPSR*/	:	(opcode == 5'b11010)?	1'b1	/*SFTR*/	:
							(opcode == 5'b10010)?	1'b1	/*SLBI*/	:	(opcode == 5'b10000)?	1'b1	/*ST*/		:
							(opcode == 5'b10001)?	1'b1 	/*LD*/		:	(opcode == 5'b10011)?	1'b1	/*STU*/		:
							(opcode == 5'b11100)?	1'b1	/*SEQ*/		:	(opcode == 5'b11101)?	1'b1	/*SLT*/		:
							(opcode == 5'b11110)?	1'b1	/*SLE*/		:	(opcode == 5'b11111)?	1'b0	/*SCO*/		:
							(opcode == 5'b01100)?	1'b1	/*BEQZ*/	:	(opcode == 5'b01101)?	1'b1	/*BNEZ*/	:
							(opcode == 5'b01110)?	1'b1	/*BLTZ*/	:	(opcode == 5'b01111)?	1'b1	/*BGEZ*/	:
							(opcode == 5'b00100)?	1'b1	/*J*/		:	(opcode == 5'b00101)?	1'b1	/*JR*/		:
							(opcode == 5'b00110)?	1'b1	/*JAL*/		:	(opcode == 5'b00111)?	1'b1	/*JALR*/	:
							(opcode == 5'b00001)?	1'b1	/*NOP*/		:	(opcode == 5'b00000)?	1'b1	/*HALT*/	:
							(opcode == 5'b00010)?	1'b1	/*SIIC*/	:	(opcode == 5'b11000)?	1'b1	/*LBI*/		:
							(opcode == 5'b11001)?	1'b1	/*BTR*/		:	(opcode == 5'b00011)?	1'b1	/*RTI*/		:
							1'b1; 
							
	// second_operand, RT, IM or ZE
	assign second_operand = (opcode == 5'b10100)?	IM	/*ROLI*/	:	(opcode == 5'b10101)?	IM	/*SLLI*/	:
							(opcode == 5'b10110)?	IM	/*RORI*/	:	(opcode == 5'b10111)?	IM	/*SRLI*/	:
							(opcode == 5'b01000)?	IM	/*ADDI*/	:	(opcode == 5'b01001)?	IM	/*SUBI*/	:
							(opcode == 5'b01010)?	IM	/*XORI*/	:	(opcode == 5'b01011)?	IM	/*ANDNI*/	:
							(opcode == 5'b11011)?	RT	/*OPSR*/	:	(opcode == 5'b11010)?	RT	/*SFTR*/	:
							(opcode == 5'b10010)?	RT	/*SLBI*/	:	(opcode == 5'b10000)?	IM	/*ST*/		:
							(opcode == 5'b10001)?	IM 	/*LD*/		:	(opcode == 5'b10011)?	IM	/*STU*/		:
							(opcode == 5'b11100)?	RT	/*SEQ*/		:	(opcode == 5'b11101)?	RT	/*SLT*/		:
							(opcode == 5'b11110)?	RT	/*SLE*/		:	(opcode == 5'b11111)?	RT	/*SCO*/		:
							(opcode == 5'b01100)?	ZE	/*BEQZ*/	:	(opcode == 5'b01101)?	ZE	/*BNEZ*/	:
							(opcode == 5'b01110)?	ZE	/*BLTZ*/	:	(opcode == 5'b01111)?	ZE	/*BGEZ*/	:
							(opcode == 5'b00100)?	RT	/*J*/		:	(opcode == 5'b00101)?	IM	/*JR*/		:
							(opcode == 5'b00110)?	RT	/*JAL*/		:	(opcode == 5'b00111)?	IM	/*JALR*/	:
							(opcode == 5'b00001)?	RT	/*NOP*/		:	(opcode == 5'b00000)?	RT	/*HALT*/	:
							(opcode == 5'b00010)?	RT	/*SIIC*/	:	(opcode == 5'b11000)?	RT	/*LBI*/		:
							(opcode == 5'b11001)?	RT	/*BTR*/		:	(opcode == 5'b00011)?	RT	/*RTI*/		:
							RT; 
	
	// PC_selSrc, select whether PC would be updated with value from execute stage
	assign PC_selSrc = (PC_Add == 2'b00)? 1'b0	:	1'b1;
	
	// PC_Add choose input to PC Adder 00: PC = PC+2 	01: PC = PC + 2 + imm	10: PC = Rs + imm	
	assign PC_Add =			(halt_flag == 1'b1)?  	2'b01	:	
							(opcode == 5'b10100)?	2'b00	/*ROLI*/	:	(opcode == 5'b10101)?	2'b00	/*SLLI*/	:
							(opcode == 5'b10110)?	2'b00	/*RORI*/	:	(opcode == 5'b10111)?	2'b00	/*SRLI*/	:
							(opcode == 5'b01000)?	2'b00	/*ADDI*/	:	(opcode == 5'b01001)?	2'b00	/*SUBI*/	:
							(opcode == 5'b01010)?	2'b00	/*XORI*/	:	(opcode == 5'b01011)?	2'b00	/*ANDNI*/	:
							(opcode == 5'b11011)?	2'b00	/*OPSR*/	:	(opcode == 5'b11010)?	2'b00	/*SFTR*/	:
							(opcode == 5'b10010)?	2'b00	/*SLBI*/	:	(opcode == 5'b10000)?	2'b00	/*ST*/		:
							(opcode == 5'b10001)?	2'b00 	/*LD*/		:	(opcode == 5'b10011)?	2'b00	/*STU*/		:
							(opcode == 5'b11100)?	2'b00	/*SEQ*/		:	(opcode == 5'b11101)?	2'b00	/*SLT*/		:
							(opcode == 5'b11110)?	2'b00	/*SLE*/		:	(opcode == 5'b11111)?	2'b00	/*SCO*/		:
							(opcode == 5'b01100)?	2'b01	/*BEQZ*/	:	(opcode == 5'b01101)?	2'b01	/*BNEZ*/	:
							(opcode == 5'b01110)?	2'b01	/*BLTZ*/	:	(opcode == 5'b01111)?	2'b01	/*BGEZ*/	:
							(opcode == 5'b00100)?	2'b01	/*J*/		:	(opcode == 5'b00101)?	2'b10	/*JR*/		:
							(opcode == 5'b00110)?	2'b01	/*JAL*/		:	(opcode == 5'b00111)?	2'b10	/*JALR*/	:
							(opcode == 5'b00001)?	2'b00	/*NOP*/		:	(opcode == 5'b00000)?	2'b01	/*HALT*/	:
							(opcode == 5'b00010)?	2'b00	/*SIIC*/	:	(opcode == 5'b11000)?	2'b00	/*LBI*/		:
							(opcode == 5'b11001)?	2'b00	/*BTR*/		:	(opcode == 5'b00011)?	2'b00	/*RTI*/		:
							2'b00;
	
	// read1RegSel, selects the register to read from
	assign read1RegSel = Rs;
							
	// read2RegSel, selects the register to read from
	assign read2RegSel	 =	(opcode == 5'b10100)?	Rt	/*ROLI*/	:	(opcode == 5'b10101)?	Rt	/*SLLI*/	:
							(opcode == 5'b10110)?	Rt	/*RORI*/	:	(opcode == 5'b10111)?	Rt	/*SRLI*/	:
							(opcode == 5'b01000)?	Rt	/*ADDI*/	:	(opcode == 5'b01001)?	Rt	/*SUBI*/	:
							(opcode == 5'b01010)?	Rt	/*XORI*/	:	(opcode == 5'b01011)?	Rt	/*ANDNI*/	:
							(opcode == 5'b11011)?	Rt	/*OPSR*/	:	(opcode == 5'b11010)?	Rt	/*SFTR*/	:
							(opcode == 5'b10010)?	Rt	/*SLBI*/	:	(opcode == 5'b10000)?	Rd_I/*ST*/		:
							(opcode == 5'b10001)?	Rt 	/*LD*/		:	(opcode == 5'b10011)?	Rd_I/*STU*/		:
							(opcode == 5'b11100)?	Rt	/*SEQ*/		:	(opcode == 5'b11101)?	Rt	/*SLT*/		:
							(opcode == 5'b11110)?	Rt	/*SLE*/		:	(opcode == 5'b11111)?	Rt	/*SCO*/		:
							(opcode == 5'b01100)?	Rt	/*BEQZ*/	:	(opcode == 5'b01101)?	Rt	/*BNEZ*/	:
							(opcode == 5'b01110)?	Rt	/*BLTZ*/	:	(opcode == 5'b01111)?	Rt	/*BGEZ*/	:
							(opcode == 5'b00100)?	Rt	/*J*/		:	(opcode == 5'b00101)?	Rt	/*JR*/		:
							(opcode == 5'b00110)?	Rt	/*JAL*/		:	(opcode == 5'b00111)?	Rt	/*JALR*/	:
							(opcode == 5'b00001)?	Rt	/*NOP*/		:	(opcode == 5'b00000)?	Rt	/*HALT*/	:
							(opcode == 5'b00010)?	Rt	/*SIIC*/	:	(opcode == 5'b11000)?	Rt	/*LBI*/		:
							(opcode == 5'b11001)?	Rt	/*BTR*/		:	(opcode == 5'b00011)?	Rt	/*RTI*/		:
							Rt;
							
	// REG_writeSel, selects which register to write into, 	00: Rs		01:	#7		10:	Rd_R		11:	Rd_I
	assign REG_writeSel =	(opcode == 5'b10100)?	2'b11	/*ROLI*/	:	(opcode == 5'b10101)?	2'b11	/*SLLI*/	:
							(opcode == 5'b10110)?	2'b11	/*RORI*/	:	(opcode == 5'b10111)?	2'b11	/*SRLI*/	:
							(opcode == 5'b01000)?	2'b11	/*ADDI*/	:	(opcode == 5'b01001)?	2'b11	/*SUBI*/	:
							(opcode == 5'b01010)?	2'b11	/*XORI*/	:	(opcode == 5'b01011)?	2'b11	/*ANDNI*/	:
							(opcode == 5'b11011)?	2'b10	/*OPSR*/	:	(opcode == 5'b11010)?	2'b10	/*SFTR*/	:
							(opcode == 5'b10010)?	2'b00	/*SLBI*/	:	(opcode == 5'b10000)?	2'b00	/*ST*/		:
							(opcode == 5'b10001)?	2'b11 	/*LD*/		:	(opcode == 5'b10011)?	2'b00	/*STU*/		:
							(opcode == 5'b11100)?	2'b10	/*SEQ*/		:	(opcode == 5'b11101)?	2'b10	/*SLT*/		:
							(opcode == 5'b11110)?	2'b10	/*SLE*/		:	(opcode == 5'b11111)?	2'b10	/*SCO*/		:
							(opcode == 5'b01100)?	2'b10	/*BEQZ*/	:	(opcode == 5'b01101)?	2'b10	/*BNEZ*/	:
							(opcode == 5'b01110)?	2'b10	/*BLTZ*/	:	(opcode == 5'b01111)?	2'b10	/*BGEZ*/	:
							(opcode == 5'b00100)?	2'b10	/*J*/		:	(opcode == 5'b00101)?	2'b10	/*JR*/		:
							(opcode == 5'b00110)?	2'b01	/*JAL*/		:	(opcode == 5'b00111)?	2'b01	/*JALR*/	:
							(opcode == 5'b00001)?	2'b10	/*NOP*/		:	(opcode == 5'b00000)?	2'b10	/*HALT*/	:
							(opcode == 5'b00010)?	2'b10	/*SIIC*/	:	(opcode == 5'b11000)?	2'b00	/*LBI*/		:
							(opcode == 5'b11001)?	2'b10	/*BTR*/		:	(opcode == 5'b00011)?	2'b10	/*RTI*/		:
							2'b10;
	
	assign LT = 1'b0;	// LT no more used at this stage after implementation of pipeline
	/*assign LT	=			(opcode == 5'b11101)?	((read1Data[15] == read2Data[15])?	ALU_Out[15]	:	((read1Data[15] == 1'b1)? 1'b1:	1'b0))	:
							(opcode == 5'b11110)?	((read1Data[15] == read2Data[15])?	ALU_Out[15]	:	((read1Data[15] == 1'b1)? 1'b1:	1'b0))	:
							1'b0;*/
	
endmodule
	
	
	