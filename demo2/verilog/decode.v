/*
   CS/ECE 552 Spring '20
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
module decode(

	// Inputs
	input clk, rst,
	
	input [15:0] instruction,
	input [15:0] PC,				// Note: byte-addressable, 8 bits in 1 Byte
	
	input [15:0] ALU_Out,
	input ALU_Zero, ALU_Ofl,
	
	input [15:0] WB_data,
	
	input [2:0] writeRegSel,
	input [15:0] writeData,
	input regWrite_ext_enable,
	
	input[15:0] imm_from_WB, PC_from_WB, arbitrary_num_from_WB, mask_from_WB,
	input [1:0] writeSrc_from_WB,
	
	output [2:0] writeRegSel_Out,
	output [15:0] writeData_Out,
	output reg regWrite_enable,
	
	output reg [1:0] writeSrc,				// 01 -> WriteBack result, 00 -> Local result, 10 -> Arbitrary number, 11 -> imm 
	output reg [15:0] imm, mask, 			// Used for SLBI and LBI
	output reg [15:0]arbitrary_num,			
	
	// Outputs to Execution
	output [15:0] InA, InB,
	output reg [2:0] ALU_op,
	output reg Cin, invA, invB, sign,
	output reg [1:0] second_operand,		// immediate, zero or Rt?
	output PC_selSrc,						// Select whether PC should be updated with value from execute stage
	output reg [1:0] PC_Add, 				// PC+2 -> 00, +imm -> 01, RS + i -> 10
	
	// Outputs to Memory & Write-Back
	output reg MEM_En, MEM_writeEn, Mux_MtoReg,

	// Outputs to PROC
	output reg err, 
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

	wire reg_err;
	reg [2:0] read1RegSel, read2RegSel; 
	reg [1:0] REG_writeSel;				// 00 -> Rs, 01 -> decimal 7, 10 -> Rd_R, 11 -> Rd_I					
	wire [15:0] read1Data, read2Data;
	wire halt_flag;
	reg LT;
	
	regFile_bypass regFile0(.read1Data(read1Data), .read2Data(read2Data), .err(reg_err), .clk(clk), .rst(rst), 
		.read1RegSel(read1RegSel), .read2RegSel(read2RegSel), 
		.writeRegSel(writeRegSel), .writeData(writeData), .writeEn(regWrite_ext_enable));
	
	assign opcode = instruction[15:11];
	assign opcode_ex = instruction[1:0];
	
	assign Rs = instruction[10:8];
	assign Rt = instruction[7:5];
	assign Rd_R = instruction[4:2];
	assign Rd_I = instruction[7:5];
	
	assign disp = instruction[10:0];
	assign imm_5 = instruction[4:0];
	assign imm_8 = instruction[7:0];
	
	dff halt_ff(.d(halt | halt_flag), .q(halt_flag), .clk(clk), .rst(rst));
	
	assign halt = (instruction[15:11] == 5'b00000)? 1'b1	:	1'b0;
	assign createdump = halt;
	
	always@(*) begin
	
		// Default behavior of signals in case they don't get updated in any operations.
		assign REG_writeSel = 2'b10;	// Default write register: Rd_R
		assign read1RegSel = Rs;		// Default 1st read register: Rs
		assign read2RegSel = Rt;		// Default 2nd read register: Rt
		assign writeSrc = 2'b01;		// Default data to write: from Write-Back
		assign regWrite_enable = 1'b0;	// Don't write to register
		assign arbitrary_num = 16'h0000;// Used for direct data write into Register, cleared at default
		assign mask = 16'h0000;			// Mask passing all bits
		
		assign err = 1'b0;				// No error
		
		assign invA = 1'b0;				// Don't inv 1st operand
		assign invB = 1'b0;				// Don't inv 2nd operand
		assign ALU_op = 3'b100;			// ADD operation
		assign Cin = 1'b0;				// No Carry-in
		assign second_operand = RT;		// ALU's second operand is Rt
		assign PC_Add = 2'b00;			// PC = PC + 2
		assign sign = 1'b1;				// Arithmetic operation
		
		assign MEM_En = 1'b0;			// Don't access memory at default
		assign MEM_writeEn = 1'b0;		// Don't write to memory at default
		assign Mux_MtoReg = 1'b0;		// Only ALU's output written back at default
		assign imm = 16'h0000;
		
		if(halt_flag == 1'b1) begin
		
			assign PC_Add = 2'b01;
			assign imm = 16'hFFFE;
		
		end
		
		else begin
		
			// ISA instructions break down
			casex(opcode)
			
				// ROLI
				5'b10100	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					// To EX
					assign ALU_op = 3'b000;// Pass in operations to ALU, MSB specifies rotate/shift commands
					assign imm = {12'h000, imm_5[3:0]};	// Lowest 4 bits immediate
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
				
				end
				
				// SLLI
				5'b10101	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					// To EX
					assign ALU_op = 3'b001;// Pass in operations to ALU, MSB specifies rotate/shift commands
					assign imm = {12'h000, imm_5[3:0]};	// Lowest 4 bits immediate
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
				
				end
				
				// RORI
				5'b10110	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					// To EX
					assign ALU_op = 3'b010;// Pass in operations to ALU, MSB specifies rotate/shift commands
					assign imm = {12'h000, imm_5[3:0]};	// Lowest 4 bits immediate
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
				
				end
				
				// SRLI
				5'b10111	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					// To EX
					assign ALU_op = 3'b011;// Pass in operations to ALU, MSB specifies rotate/shift commands
					assign imm = {12'h000, imm_5[3:0]};	// Lowest 4 bits immediate
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
				
				end
				
				// ADDI
				5'b01000	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs
					
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;

					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
					
					assign ALU_op = 3'b100;
					assign imm = {{11{imm_5[4]}}, imm_5};
				
				end
				
				// SUBI
				5'b01001	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU outp
					
					assign ALU_op = 3'b100;
					assign invA = 1'b1;
					assign Cin = 1'b1;
					assign imm = {{11{imm_5[4]}}, imm_5};
				
				end
				
				// XORI
				5'b01010	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU outp
					
					assign ALU_op = 3'b111;
					assign imm = {11'h000, imm_5};
				
				end
				
				// ANDNI
				5'b01011	:	begin
				
					assign second_operand = IM;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU outp
					
					assign ALU_op = 3'b101;
					assign invB = 1'b1;
					assign imm = {11'h000, imm_5};
				
				end
				
				// ADD
				5'b11011	:	begin
				
					assign second_operand = RT;			// Specify second operand as Rt
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b10;		// Write to Rd (R-format)
					assign read1RegSel = Rs;
					assign read2RegSel = Rt;
					
					case(opcode_ex)
						
						2'b00:	begin		// ADD
						
							assign ALU_op = 3'b100;
							
						end
						
						2'b01:	begin		// SUB
						
							assign ALU_op = 3'b100;
							assign invA = 1'b1;
							assign Cin = 1'b1;
							
						end
						
						2'b10:	begin		// XOR
						
							assign ALU_op = 3'b111;
							
						end
						
						2'b11:	begin		// ANDN
						
							assign ALU_op = 3'b101;
							assign invB = 1'b1;
							
						end
						
						default	:	begin
							
							$display("Error!!!");
							assign err = 1'b1;
							
						end
						
					endcase
				
				end
				
				// R-format Shifter Operations
				5'b11010	:	begin

					assign second_operand = RT;			// Specify second operand as immediate
					assign regWrite_enable = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b10;		// Write to Rd (R-format)
					assign read1RegSel = Rs;			// First operand is Rs
					assign read2RegSel = Rt;			// Second operand is Rt
					
					// To EX
					assign ALU_op = {1'b0, opcode_ex};// Pass in operations to ALU, MSB specifies rotate/shift commands
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b0;			// Writeback passes ALU output
				
				end
				
				// SLBI
				5'b10010	:	begin
				
					assign imm = {read1Data[7:0], imm_8};
					assign mask = 16'h0000;
					assign regWrite_enable = 1'b1;
					assign REG_writeSel = 2'b00;
					assign writeSrc = 2'b11;
				
				end
				
				// ST
				5'b10000	:	begin
				
					assign MEM_En = 1'b1;
					assign MEM_writeEn = 1'b1;
					assign read2RegSel = Rd_I;
					assign Mux_MtoReg = 1'b0;
					
					assign ALU_op = 3'b100;
					assign second_operand = IM;
					assign Cin = 1'b0;
					assign imm = {{11{imm_5[4]}}, imm_5};
					
					assign regWrite_enable = 1'b0;
					assign REG_writeSel = 2'b00;
					assign writeSrc = 2'b01;
				
				end
				
				// LD
				5'b10001	:	begin
				
					assign writeSrc = 2'b01;		// Write data from WriteBack
					assign MEM_En = 1'b1;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoReg = 1'b1;
					
					assign regWrite_enable = 1'b1;			// Register write enabled
					assign REG_writeSel = 2'b11;	// Rd as target register
					
					assign ALU_op = 3'b100;
					assign second_operand = IM;
					assign imm = {{11{imm_5[4]}}, imm_5};
				
				end
				
				// STU
				5'b10011	:	begin
				
					assign MEM_En = 1'b1;
					assign MEM_writeEn = 1'b1;
					assign read2RegSel = Rd_I;
					assign Mux_MtoReg = 1'b0;
					
					assign ALU_op = 3'b100;
					assign second_operand = IM;
					assign Cin = 1'b0;
					assign imm = {{11{imm_5[4]}}, imm_5};
					
					assign regWrite_enable = 1'b1;
					assign REG_writeSel = 2'b00;
					assign writeSrc = 2'b01;
				
				end
				
				// SEQ
				5'b11100	:	begin
				
					assign writeSrc = 2'b10;	// Arbitrary number to write into register
					assign ALU_op = 3'b100;
					assign second_operand = RT;
					assign regWrite_enable = 1'b1;
					
					assign invB = 1'b1;
					assign Cin = 1'b1;
							
					assign arbitrary_num = {15'h0000, ALU_Zero};
				
				end
				
				// SLT
				5'b11101	:	begin
				
					assign writeSrc = 2'b10;	// Arbitrary number to write into register
					assign ALU_op = 3'b100;
					assign second_operand = RT;
					assign regWrite_enable = 1'b1;
					
					assign read1RegSel = Rs;
					assign read2RegSel = Rt;
					
					assign REG_writeSel = 2'b10;	// Update Rd (R format) after execution
					assign Mux_MtoReg = 1'b0;		// Value from WriteBack
					
					assign sign = 1'b1;				// Arithmetic Operation
					
					assign invB = 1'b1;
					assign Cin = 1'b1;
					
					if(read1Data[15] == read2Data[15])
						assign LT = ALU_Out[15];
					else 
						assign LT = (read1Data[15] == 1'b1)? 1'b1:	1'b0;
					
					assign arbitrary_num = {15'h0000, LT};
				
				end
				
				// SLE
				5'b11110	:	begin
				
					assign writeSrc = 2'b10;	// Arbitrary number to write into register
					assign ALU_op = 3'b100;
					assign second_operand = RT;
					assign regWrite_enable = 1'b1;
					
					assign invB = 1'b1;
					assign Cin = 1'b1;
					
					if(read1Data[15] == read2Data[15])
						assign LT = ALU_Out[15];
					else 
						assign LT = (read1Data[15] == 1'b1)? 1'b1:	1'b0;
							
					assign arbitrary_num = {15'h0000, (LT	|	ALU_Zero)};
				
				end
				
				// SCO
				5'b11111	:	begin
				
					assign writeSrc = 2'b10;	// Arbitrary number to write into register
					assign ALU_op = 3'b100;		// Addition
					assign second_operand = RT;	// Rt as second operand
					assign read1RegSel = Rs;
					assign read2RegSel = Rt;
					assign regWrite_enable = 1'b1;			// Register write enabled
					assign REG_writeSel = 2'b10;	// Write into Rd (R-format)
					
					assign Cin = 1'b0;
					assign sign = 1'b0;
							
					assign arbitrary_num = {15'h0000, ALU_Ofl};
				
				end
				
				// BEQZ
				5'b01100	:	begin
				
					assign second_operand = ZE;  //zero
					assign read1RegSel = Rs;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign ALU_op = 3'b100;
					assign Cin = 1'b0;

					assign PC_Add = (ALU_Zero == 1'b1) ? 2'b01 : 2'b00;
				
				end
				
				// BNEZ
				5'b01101	:	begin
				
					assign second_operand = ZE;  //zero
					assign read1RegSel = Rs;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign ALU_op = 3'b100;
					assign Cin = 1'b0;

					assign PC_Add = (ALU_Zero == 1'b0) ? 2'b01 : 2'b00;
				
				end
				
				// BLTZ
				5'b01110	:	begin
				
					assign second_operand = ZE;  //zero
					assign read1RegSel = Rs;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign ALU_op = 3'b100;
					assign Cin = 1'b0;

					assign PC_Add = (ALU_Out[15] == 1'b1) ? 2'b01 : 2'b00;
				
				end
				
				// BGEZ
				5'b01111	:	begin
				
					assign second_operand = ZE;  //zero
					assign read1RegSel = Rs;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign ALU_op = 3'b100;
					assign Cin = 1'b0;

					assign PC_Add = (ALU_Out[15] == 1'b0) ? 2'b01 : 2'b00;
				
				end
				
				// J
				5'b00100	:	begin

					assign PC_Add = 2'b01;
					assign imm = {{5{disp[10]}}, disp};
					assign regWrite_enable = 1'b0;
				
				end
				
				// JR
				5'b00101	:	begin

					assign PC_Add = 2'b10;
					assign ALU_op = 3'b100;
					assign second_operand = IM;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign read1RegSel = Rs;
				
				end
				
				// JAL
				5'b00110	:	begin
				
					assign PC_Add = 2'b01;
					assign imm = {{5{disp[10]}}, disp};
							
					assign REG_writeSel = 2'b01;	// Set to R7
					assign regWrite_enable = 1'b1;
					assign writeSrc = 2'b10;
					assign arbitrary_num = PC;
				
				end
				
				// JALR
				5'b00111	:	begin
				
					assign PC_Add = 2'b10;
					assign second_operand = IM;
					assign imm = {{8{imm_8[7]}}, imm_8};
							
					assign REG_writeSel = 2'b01;	// Set to R7
					assign regWrite_enable = 1'b1;
					assign writeSrc = 2'b10;
					assign arbitrary_num = PC;
				
				end
				
				// NOP
				5'b00001	:	begin
				
					// No data shall be written anywhere
					assign MEM_writeEn = 1'b0;
					assign regWrite_enable = 1'b0;
					assign PC_Add = 2'b00;
				
				end
				
				// Halt
				5'b00000	:	begin
				
					// Let PC = PC + 2
					assign PC_Add = 2'b01;
					assign imm = 16'hFFFD;
					// No data shall be written anywhere
					assign MEM_writeEn = 1'b0;
					assign regWrite_enable = 1'b0;
				
				end
				
				// Exception
				5'b00010	:	begin
				
					assign MEM_writeEn = 1'b0;
					assign regWrite_enable = 1'b0;
					assign PC_Add = 2'b00;
				
				end
				
				// Exception
				5'b00011	:	begin
				
					assign MEM_writeEn = 1'b0;
					assign regWrite_enable = 1'b0;
					assign PC_Add = 2'b00;
				
				end
				
				// LBI
				5'b11000	:	begin
				
					assign REG_writeSel = 2'b00;
					assign mask = 16'h0000;
					assign writeSrc = 2'b10;
					assign arbitrary_num = {{8{imm_8[7]}}, imm_8};
					
					assign regWrite_enable = 1'b1;
				
				end
				
				// BTR
				5'b11001	:	begin
				
					assign arbitrary_num = {read1Data[0], read1Data[1], read1Data[2], read1Data[3], read1Data[4], read1Data[5]
											, read1Data[6], read1Data[7], read1Data[8], read1Data[9], read1Data[10], read1Data[11]
											, read1Data[12], read1Data[13], read1Data[14], read1Data[15]};
					
					assign read1RegSel = Rs;
					assign REG_writeSel = 2'b10;
					assign writeSrc = 2'b10;
					assign regWrite_enable = 1'b1;
				
				end
				
				default 	:	begin
				
					//$stop();
					$display("Error!!!");
					
					assign err = 1'b1;

					assign MEM_writeEn = 1'b0;
					assign regWrite_enable = 1'b0;
					assign PC_Add = 2'b00;
				
				end
			
			endcase
			
		end
		
	end

	assign writeData = 	(writeSrc_from_WB == 2'b00)?	PC_from_WB	:	
						(writeSrc_from_WB == 2'b01)?	WB_data	:	
						(writeSrc_from_WB == 2'b10)?	arbitrary_num_from_WB:
						(imm_from_WB | mask_from_WB);
				
	wire[15:0]	writeData_tst;
	assign writeData_tst = 	(writeSrc == 2'b00)	?	PC:	
							(writeSrc == 2'b01)	?	WB_data	:	
							(writeSrc == 2'b10)	?	arbitrary_num	:	
							(imm	|	mask);
	
	assign writeRegSel_Out = 	(rst == 1'b1)	?			3'h0	:
								(REG_writeSel == 2'b00)?	Rs	:	
								(REG_writeSel == 2'b01)?	3'h7:	
								(REG_writeSel == 2'b10)?	Rd_R:
								Rd_I;
	
	assign InA = read1Data;
	assign InB = read2Data;
	assign PC_selSrc = (PC_Add == 2'b00)? 1'b0	:	1'b1;
   
endmodule
