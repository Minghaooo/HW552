/*
   CS/ECE 552 Spring '20
  
   Filename        : execute.v
   Description     : This is the overall module for the execute stage of the processor.
*/
module execute (

	input clk, rst,

	input [15:0] InA, InB, PC, imm,
	input [2:0] ALU_op,
	
	input [1:0] PC_Add, second_operand,
	
	input Cin, invA, invB, sign,
	input jump_at_ex,

	input [15:0] instr_ex,
	input [15:0] arbitrary_num,

	output [15:0] arbitrary_num_ex,
	output ALU_Zero, ALU_Ofl,
	output [15:0] ALU_Out,
	output [15:0] PC_Out,
	output [15:0] addr
	
	);

	wire [15:0] alu_InA, alu_InB, PC_A, PC_B;
	wire C_out;
	wire [15:0] PC_operand;
	wire [15:0] PC_EX_Out, PC_stored_in, PC_stored;

	wire [1:0] PC_Add_f;

	wire jump_ex, jump_at_ex_1, jump_at_ex_2, jump_assert;

	dff jump_at_ex_ff1(.clk(clk), .rst(rst), .d(jump_at_ex), .q(jump_at_ex_1));
	dff jump_at_ex_ff2(.clk(clk), .rst(rst), .d(jump_at_ex_1), .q(jump_at_ex_2));

	assign jump_ex = jump_at_ex | jump_at_ex_1 | jump_at_ex_2;					// Will keep high for 2 cycles
	assign jump_assert = jump_at_ex_1 | jump_at_ex_2;								// Will keep high for 1 cycles

	dff_16bit PC_stored_ff1(.clk(clk), .rst(rst), .d(PC_stored_in), .q(PC_stored));

	assign PC_stored_in = (jump_ex)	?	((jump_assert)?	PC_stored	:	PC_Out)	:	PC;

	// Second operand
	localparam IM = 2'b00;
	localparam ZE = 2'b01;
	localparam RT = 2'b10;
	
	alu unit(.InA(alu_InA), .InB(alu_InB), .Cin(Cin), .Op(ALU_op), .invA(invA), .invB(invB), 
		.sign(sign), .Out(ALU_Out), .Zero(ALU_Zero), .Ofl(ALU_Ofl));
   
	cla_16b PC_adder(.A(PC_A), .B(PC_B), .S(PC_EX_Out), .C_in(1'b0), .C_out(C_out));
	
	assign alu_InA = InA;
	assign alu_InB = (second_operand == IM)? imm		:
					(second_operand == RT)? InB			:
					16'h0000;
	
	assign PC_A = (jump_assert)? 	PC_stored	:	PC;
	assign PC_B = (jump_ex)?	(jump_assert?	16'h0000	:	PC_operand)	:	PC_operand;

	assign PC_operand = (PC_Add_f[0] == 1'b0) ? 16'h0000	: imm;
	assign PC_Out = (PC_Add_f[1] == 0)? PC_EX_Out	:	ALU_Out;
	
	assign addr = InB;	

	assign PC_Add_f =	(instr_ex[15:11] == 5'b01100)	?	((ALU_Zero == 1'b1)?	2'b01	:	2'b00)	:	
						(instr_ex[15:11] == 5'b01101)	?	((ALU_Zero == 1'b0)?	2'b01	:	2'b00)	:	
						(instr_ex[15:11] == 5'b01110)	?	((ALU_Out[15] == 1'b1)?	2'b01	:	2'b00)	:	
						(instr_ex[15:11] == 5'b01111)	?	((ALU_Out[15] == 1'b0)?	2'b01 	: 	2'b00)	:	
						PC_Add;

	wire LT;
	assign LT	=			(instr_ex[15:11] == 5'b11101)?	((InA[15] == InB[15])?	ALU_Out[15]	:	((InA[15] == 1'b1)? 1'b1:	1'b0))	:
							(instr_ex[15:11] == 5'b11110)?	((InA[15] == InB[15])?	ALU_Out[15]	:	((InA[15] == 1'b1)? 1'b1:	1'b0))	:
							1'b0;

	assign arbitrary_num_ex = 	(instr_ex[15:11] == 5'b11100)	?	{15'h0000, ALU_Zero}	:	// SEQ
								(instr_ex[15:11] == 5'b11101)	?	{15'h0000, LT}			:	// SLT
								(instr_ex[15:11] == 5'b11110)	?	{15'h0000,(LT|ALU_Zero)}:	// SLE
								(instr_ex[15:11] == 5'b11111)	?	{15'h0000, ALU_Ofl}		:	// SCO
								arbitrary_num;
					
   
endmodule
