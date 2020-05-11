/*
   CS/ECE 552 Spring '20
  
   Filename        : fetch.v
   Description     : This is the module for the overall fetch stage of the processor.
*/
module fetch (pc_nxt, pc_2ID, instr_2ID, clk, rst, createdump, halt, PC_selSrc, PC_force_stop, jump_at_mem, jump_at_wb);


	localparam PC_w = 16;

	input [PC_w-1:0]	pc_nxt;
	input clk, rst;
	input createdump;
	input halt;
	input PC_selSrc;
	input PC_force_stop;

	input jump_at_mem, jump_at_wb;

	//input [PC_w-1:0]	pc_jump;	// the calculated PC from EX
	//input [PC_w-1:0]	pc_cal;		
	//output [15:0] 		addr;		
	output [PC_w-1:0] 	pc_2ID;		// output the PC(+2) to ID, EX stage
	output [15:0]		instr_2ID; // output the fetched instruction 

	wire [PC_w - 1 : 0] pc_current; 
	wire [PC_w - 1 : 0] pc_operand;
	wire [15:0] pc_in;
	wire [15:0] instr_2ID_t;		// Insturction before mux
	
	wire [15:0] pc_in_ext;

	// pc register
	dff_16bit pc_ff(
		.clk(clk), 
		.rst(rst), 
		.d(pc_in_ext), 
		.q(pc_current)
		);

	memory2c I_MEM(
	.data_in(16'h0000),			// not need in this 
	.addr(pc_current),			// this is PC
	.enable(1'b1), 				//enable read & write, default to 1;
	.clk(clk), 
	.rst(rst), 					// rst_h
	.createdump(createdump),  	// dump out the memory to file
	.data_out(instr_2ID_t),
	.wr(1'b0)
	);

cla_16b pc_adder(
	.A(pc_current), 
	.B(pc_operand), 
	.C_in(1'b0), 
	.S(pc_2ID), 		
	.C_out()  // cout not used
	);

	/*
		If jump has arrived at WB,
		load PC register with PC from WB.
		Lock PC register for 3 cycles,
		*Read PC address for CMD
		Continue operation
	*/
	wire jump_at_wb_1, jump_at_wb_2, jump_at_wb_3;
	dff jump_at_wb_ff1(.clk(clk), .rst(rst), .d(jump_at_wb), .q(jump_at_wb_1));
	dff jump_at_wb_ff2(.clk(clk), .rst(rst), .d(jump_at_wb_1), .q(jump_at_wb_2));
	dff jump_at_wb_ff3(.clk(clk), .rst(rst), .d(jump_at_wb_2), .q(jump_at_wb_3));

	wire jump_wb = jump_at_mem | jump_at_wb | jump_at_wb_1 | jump_at_wb_2 | jump_at_wb_3;	// This signal will last for 4 cycles after jump_at_wb is asserted
	wire jump_assert = jump_at_wb | jump_at_wb_1 | jump_at_wb_2 | jump_at_wb_3;	// This signal will last for 3 cycles after jump_at_wb is asserted and fell down
	
	assign pc_operand = (halt == 1'b1)? 16'd0		:	16'd2;
	assign pc_in = (PC_selSrc == 1'b1)? pc_nxt		:	pc_2ID;

	assign pc_in_ext = (jump_wb) ? ((jump_assert)?	pc_current	:	pc_in)	:	((PC_force_stop)?	pc_current	:	pc_in);

	assign instr_2ID = (jump_assert)? 16'h0800	:	instr_2ID_t;

   
endmodule
