/*
   CS/ECE 552 Spring '20
  
   Filename        : decode.v
   Description     : This is the module for the overall decode stage of the processor.
*/
module decode (

	// Inputs
	input [15:0] instruction,
	input [15:0] PC,				// Note: byte-addressable, 8 bits in 1 Byte
	
	input [15:0] ALU_Out,
	input ALU_Zero, ALU_Ofl,
	
	input clk, rst,
	input [15:0] WB_data,
	
	// Outputs to Execution
	output [15:0] InA, InB,
	output reg [2:0] ALU_op,
	output reg Cin, invA, invB, sign,
	output reg [1:0] second_operand,		// immediate, zero or Rt?
	output reg [15:0] imm,					// Immediate value
	output reg [1:0] PC_Add, 				// PC+2 -> 00, +imm -> 01, RS + i -> 10
	
	// Outputs to Memory
	output reg MEM_En, MEM_writeEn, createdump,
	
	// Outputs to Write-Back
	output reg Mux_MtoREg,
	
	// Outputs to PROC
	output reg err
	);
	
	// Second operand
	localparam IM = 2'b00;
	localparam ZE = 2'b01;
	localparam RT = 2'b10;
	
	wire [4:0] opcode;
	wire [2:0] Rd_R, Rd_I, Rs, Rt;
	wire [10:0] disp;
	wire [4:0] imm_5;
	wire [7:0] imm_8;

	reg writeEn;
	wire reg_err;
	reg [2:0] read1RegSel, read2RegSel; 
	wire [2:0] writeRegSel;
	reg [1:0] REG_writeSel;				// 00 -> Rs, 01 -> decimal 7, 10 -> Rd_R, 11 -> Rd_I
	reg [1:0] writeSrc;					// 01 -> WriteBack result, 00 -> Local result, 10 -> Arbitrary number, 11 -> imm 
	reg [15:0] arbitrary_num;			// Choose the arbitrary number to be written into register
	reg [15:0] mask;					// Used for SLBI and LBI
	wire [15:0] writeData;
	wire [15:0] read1Data, read2Data;
	reg halt;
	
	regFile regFile0(.read1Data(read1Data), .read2Data(read2Data), .err(reg_err), .clk(clk), .rst(rst), 
		.read1RegSel(read1RegSel), .read2RegSel(read2RegSel), 
		.writeRegSel(writeRegSel), .writeData(writeData), .writeEn(writeEn));
	
	assign opcode = instruction[15:11];
	assign opcode_ex = instruction[1:0];
	
	assign Rs = instruction[10:8];
	assign Rt = instruction[7:5];
	assign Rd_R = instruction[4:2];
	assign Rd_I = instruction[7:5];
	
	assign disp = instruction[10:0];
	assign imm_5 = instruction[4:0];
	assign imm_8 = instruction[7:0];
	
	dff halt_ff(.q(halt_flag), .d(halt), .clk(clk), .rst(rst));
	
	always@(posedge clk) begin
	
		// Default behavior of signals in case they don't get updated in any operations.
		assign REG_writeSel = 2'b10;	// Default write register: Rd_R
		assign read1RegSel = Rs;		// Default 1st read register: Rs
		assign read2RegSel = Rt;		// Default 2nd read register: Rt
		assign writeSrc = 2'b01;		// Default data to write: from Write-Back
		assign writeEn = 1'b0;			// Don't write to register
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
		assign Mux_MtoREg = 1'b0;		// Only ALU's output written back at default
		
		assign createdump = 1'b0;		// No dump created unless HALTed
		
		assign halt = 1'b0;
		
		if(halt_flag == 1'b1) begin		// HALT program -> no further update on PC
	
			assign PC_Add = 2'b01;
			assign imm = 16'hFFFD;
			assign createdump = 1'b1;
			assign halt = 1'b1;
	
		end
		
		else begin
			// ISA instructions break down
			casex(opcode)
		
				// Special Operation -> write into Rs with immediate (LBI)
				5'b11000	:	begin
				
					assign REG_writeSel = 2'b00;
					assign mask = 16'h0000;
					assign writeSrc = 2'b10;
					assign arbitrary_num = {{8{imm_8[7]}}, imm_8};
					
					assign writeEn = 1'b1;
				
				end
				
				// Special Operation -> BTR
				5'b11001	:	begin
					
					assign arbitrary_num = {read1Data[0], read1Data[1], read1Data[2], read1Data[3], read1Data[4], read1Data[5]
											, read1Data[6], read1Data[7], read1Data[8], read1Data[9], read1Data[10], read1Data[11]
											, read1Data[12], read1Data[13], read1Data[14], read1Data[15]};
					
					assign read1RegSel = Rs;
					assign REG_writeSel = 2'b10;
					assign writeSrc = 2'b10;
					assign writeEn = 1'b1;
				
				end
		
				// Exception-related commands	(Not for Phase 1)
				5'b0001x	:	begin
				
					assign MEM_writeEn = 1'b0;
					assign writeEn = 1'b0;
					assign PC_Add = 2'b00;
				
				end
				
				// Program pause-related commands
				5'b0000x	:	begin
					
					// HALT command
					if(opcode[0] == 1'b1) begin

						// No data shall be written anywhere
						assign MEM_writeEn = 1'b0;
						assign writeEn = 1'b0;
						assign PC_Add = 2'b00;

						assign halt = 1'b1;
					
					end
					// NOP command
					else begin
					
						// No data shall be written anywhere
						assign MEM_writeEn = 1'b0;
						assign writeEn = 1'b0;
						assign PC_Add = 2'b00;	// PC = PC + 2
						
					end
				
				end
				
				// ALU operations with only registers
				5'b1101x	:	begin
					
					assign second_operand = RT;			// Specify second operand as Rt
					assign writeEn = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b10;		// Write to Rd (R-format)
					assign read1RegSel = Rs;
					assign read2RegSel = Rt;
					
					if(opcode[0] == 1'b1) begin
					
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
					
					else begin
					
						
						assign ALU_op = {1'b0, opcode_ex};
					
					end
				
				end
		   
				// ALU operations with immediate as second operand 
				5'b101xx	:	begin

					assign second_operand = IM;			// Specify second operand as immediate
					assign writeEn = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					// To EX
					assign ALU_op = {1'b0, opcode[1:0]};// Pass in operations to ALU, MSB specifies rotate/shift commands
					assign imm = {12'h000, imm_5[3:0]};	// Lowest 4 bits immediate
					
					// To Memory
					assign MEM_En = 1'b0;
					assign MEM_writeEn = 1'b0;
					assign Mux_MtoREg = 1'b0;			// Writeback passes ALU output
					
				end
				5'b010xx	:	begin

					assign second_operand = IM;			// Specify second operand as immediate
					assign writeEn = 1'b1;				// Register allowed to write
					assign writeSrc = 2'b01;			// Register data write <- from WriteBack
					assign REG_writeSel = 2'b11;		// Write to Rd (I-format)
					assign read1RegSel = Rs;			// First operand is Rs

					assign Mux_MtoREg = 1'b0;			// Writeback passes ALU output
					
					case(opcode[1:0])
					
						2'b00:	begin		// ADD
						
							assign ALU_op = 3'b100;
							assign imm = {{11{imm_5[4]}}, imm_5};
							
						end
						
						2'b01:	begin		// SUB
						
							assign ALU_op = 3'b100;
							assign invA = 1'b1;
							assign Cin = 1'b1;
							assign imm = {{11{imm_5[4]}}, imm_5};
							
						end
						
						2'b10:	begin		// XOR
						
							assign ALU_op = 3'b111;
							assign imm = {11'h000, imm_5};
							
						end
						
						2'b11:	begin		// ANDN
						
							assign ALU_op = 3'b101;
							assign invB = 1'b1;
							assign imm = {11'h000, imm_5};
							
						end
						
						default:	begin
						
							$display("Error!!!");
							assign err = 1'b1;
							
						end
					
					endcase
				
				end

				// MEM operations
				5'b100xx	:	begin
				
					case(opcode[1:0])
					
						2'b10	:	begin			// 10010 -> Special case, instruction SLBI
						
							assign imm = {read1Data[7:0], imm_8};
							assign mask = 16'h0000;
							assign writeEn = 1'b1;
							assign REG_writeSel = 2'b00;
							assign writeSrc = 2'b11;
						
						end
						
						2'b00	:	begin			// ST

							assign MEM_En = 1'b1;
							assign MEM_writeEn = 1'b1;
							assign read2RegSel = Rd_I;
							
							assign Mux_MtoREg = 1'b1;
							
							assign ALU_op = 3'b100;
							assign second_operand = IM;
							assign Cin = 1'b0;
							assign imm = {{11{imm_5[4]}}, imm_5};
							
							assign PC_Add = 2'b00;
							
							assign writeEn = 1'b1;
							assign writeSrc = 2'b01;
							assign REG_writeSel = 2'b11;
							
						end
						
						2'b01	:	begin			// LD
						
							assign writeSrc = 2'b01;		// Write data from WriteBack
							assign MEM_En = 1'b1;
							assign MEM_writeEn = 1'b0;
							assign Mux_MtoREg = 1'b1;
							
							assign writeEn = 1'b1;			// Register write enabled
							assign REG_writeSel = 2'b11;	// Rd as target register
							
							assign ALU_op = 3'b100;
							assign second_operand = IM;
							assign imm = {{11{imm_5[4]}}, imm_5};
						
						end

						2'b11	:	begin			// STU
							
							assign MEM_En = 1'b1;			// Memory enabled
							assign MEM_writeEn = 1'b1;		// Memory write operation enabled
							assign read2RegSel = Rd_I;		// Mem writedata from Rd_I
							assign Mux_MtoREg = 1'b0;		// From ALU		
							
							assign ALU_op = 3'b100;			// Addition
							assign second_operand = IM;		// Immediate as 2nd operand to ALU
							assign Cin = 1'b0;				// No Carry-in
							assign imm = {{11{imm_5[4]}}, imm_5};	// Immediate sign extended
							
							assign writeEn = 1'b1;
							assign REG_writeSel = 2'b00;	// Write to Rs
							assign writeSrc = 2'b01;		// Data from WriteBack
							
						end
						
						default	:	begin
						
							$display("Error!!!");
							assign err = 1'b1;
						
						end
					
					endcase
				
				end
				
				// Comparison-aimed R-formatted commands
				5'b111xx	:	begin

					assign writeSrc = 2'b10;	// Arbitrary number to write into register
					assign read1RegSel = Rs;
					assign read2RegSel = Rt;
					assign REG_writeSel = 2'b10;
					assign ALU_op = 3'b100;
					assign second_operand = RT;
					assign writeEn = 1'b1;
				
					case(opcode[1:0])
					
						2'b00	:	begin    	// SEQ
						
							assign invB = 1'b1;
							assign Cin = 1'b1;
							
							assign arbitrary_num = {15'h0000, ALU_Zero};
							
						end
						
						2'b01	:	begin 		// SLT
						
							assign invB = 1'b1;
							assign Cin = 1'b1;
							
							assign arbitrary_num = {15'h0000, ALU_Out[15]};
						
						end
						
						2'b10	:	begin 		// SLE

							assign invB = 1'b1;
							assign Cin = 1'b1;
							
							assign arbitrary_num = {15'h0000, (ALU_Out[15]	|	ALU_Zero)};
						
						end
						
						2'b11	:	begin 		// SCO

							assign sign = 1'b0;		// Logical addition
							
							assign arbitrary_num = {15'h0000, ALU_Ofl};
						
						end
						
						default	:	begin
							
							$display("Error!!!");
							assign err = 1'b1;
							
						end
						
					endcase
				
				end
				
				// PC-Update commands, immediates may be used
				5'b011xx	:	begin
				
					assign second_operand = ZE;  //zero
					assign read1RegSel = Rs;
					assign imm = {{8{imm_8[7]}}, imm_8};
					assign ALU_op = 3'b100;
					assign Cin = 1'b0;
				
					case(opcode[1:0]) 
					
						2'b00	:	begin		// BEQZ ==

							assign PC_Add = (ALU_Zero == 1'b1) ? 2'b01 : 2'b00;
							
						end
						
						2'b01	:	begin		// BNEQ !=

							assign PC_Add = (ALU_Zero == 1'b0) ? 2'b01 : 2'b00;
						
						end
						
						2'b10	:	begin		// BLTZ <

							assign PC_Add = (ALU_Out[15] == 1'b1) ? 2'b01 : 2'b00;
						
						end
						
						2'b11	:	begin		// BGEZ >

							assign PC_Add = (ALU_Out[15] == 1'b0) ? 2'b01 : 2'b00;
						
						end
					
						default	:	begin
							
							$display("Error!!!");
							assign err = 1'b1;
							
						end
					
					endcase
				
				end
				5'b001xx	:	begin
					
					case(opcode[1:0])
					
						2'b00	:	begin  // J displacement PC+2+D
						
							assign PC_Add = 2'b01;
							assign imm = {{5{disp[10]}}, disp};
							assign writeEn = 1'b0;
						
						end
						
						2'b01 	: 	begin // JR pc = RS+I 
						
							assign PC_Add = 2'b10;
							assign ALU_op = 3'b100;
							
							assign writeSrc = 2'b00;	// Write PC to Reg file
							assign REG_writeSel = 2'b01;	// Choose R7 as target
							
							assign second_operand = IM;
							assign imm = {{8{imm_8[7]}}, imm_8};
							assign read1RegSel = Rs;
						
						end
						
						2'b10	:	begin //JAL
						
							assign PC_Add = 2'b01;
							assign imm = {{5{disp[10]}}, disp};
							
							assign writeEn = 1'b1;
							
							assign writeSrc = 2'b00;	// Write PC to Reg file
							assign REG_writeSel = 2'b01;	// Choose R7 as target
						
						end
						
						2'b11	:	begin //JALR
						
							assign PC_Add = 2'b10;
							assign second_operand = IM;
							assign imm = {{8{imm_8[7]}}, imm_8};
							
							assign writeSrc = 2'b00;	// Write PC to Reg file
							assign REG_writeSel = 2'b01;	// Choose R7 as target

							assign writeEn = 1'b1;
						
						end
						
						/*default	:	begin
						
							$display("Error!!!");
							assign err = 1'b1;
						
						end*/
					
					endcase
					
				end	
				
				default	:	begin
				
					//$stop();
					$display("Error!!!");
					
					assign err = 1'b0;

					assign MEM_writeEn = 1'b0;
					assign writeEn = 1'b0;
					assign PC_Add = 2'b00;
				
				end
				
				
			endcase
			
			if(reg_err)
				assign err = 1'b1;
		
		end
		
	end
	
	assign writeData = 	(writeSrc == 2'b00)?	PC	:	
						(writeSrc == 2'b01)?	WB_data	:	
						(writeSrc == 2'b10)?	arbitrary_num:
						(imm | mask);
	
	assign writeRegSel = 	(REG_writeSel == 2'b00)?	Rs	:	
							(REG_writeSel == 2'b01)?	3'd7:	
							(REG_writeSel == 2'b10)?	Rd_R:
							Rd_I;
	
	assign InA = read1Data;
	assign InB = read2Data;
   
endmodule
