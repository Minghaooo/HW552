module stall_detect(

	input clk,
	input rst,
	
	input Rd_val, Rs_val, Rt_val,

	input [15:0] instr_Fetch, instr_Decode, instr_Ex, instr_Mem, instr_Wb,

	input [3:0] Rs_Fetch, Rt_Fetch, Rd_Fetch,
	/*input [3:0] Rd_Dec, Rs_Dec, Rt_Dec,*/

	input [3:0] IFID_Rd_ff, IFID_Rs_ff, IFID_Rt_ff,
	input [3:0] IDEX_Rd_ff, IDEX_Rs_ff, IDEX_Rt_ff,
	input [3:0] EXMEM_Rd_ff, EXMEM_Rs_ff, EXMEM_Rt_ff,
	input [3:0] MEMWB_Rd_ff, MEMWB_Rs_ff, MEMWB_Rt_ff,

	input [1:0] IDEX_PC_Add, //PC_Add[1]
	input [15:0] instr_2ID_ff,

	input regWrite_enable_IDEX,
	input regWrite_enable_EXMEM,

	output IFID_stall,
	output IDEX_stall,
	output EXMEM_stall,
	output MEMWB_stall,

	output flush_DE, flush_XM, flush_MW,
	
	output PC_force_stop,
	output jump_at_dec,
	output jump_at_ex,
	output jump_at_mem,
	output jump_at_wb			// Indicate whether the Jump command has arrived at whiever stage
);

wire j_instr, j_Ex, j_Mem, j_Dec, j_Wb;
wire J_stall;
wire j_conde;

assign J_stall=	(IDEX_PC_Add != 2'b00);	// 

/*wire BR_J_Stall_in, BR_J_Stall;
wire BR_J_Stall_Out;

dff BR_J_Stall_ff0(.clk(clk), .rst(rst), .d(BR_J_Stall_in), .q(BR_J_Stall_Out));

// Start stalling for branches and jumps
always@(*) begin

	case(instr_Fetch[15:11])

		5'b01100, 5'b01101, 5'b01110, 5'b01111, 5'b00100, 5'b00101, 5'b00110, 5'b00111	: begin
			BR_J_Stall_in = 1'b1;
		end

		default begin
			case(BR_J_Stall_Out)

				1'b1	:	begin
					BR_J_Stall_in = (MEM_imm == DEC_imm)? 1'b0	:	1'b1;
					BR_J_Stall = BR_J_Stall_in & BR_J_Stall_Out;
				end

				1'b0	:	begin
					BR_J_Stall = 1'b0;
					BR_J_Stall_in = 1'b0;
				end

				default	:	begin
					BR_J_Stall = 1'b0;
					BR_J_Stall_in = 1'b0;
				end

			endcase
		end

	endcase

end
*/

	// Disable flush right now
	assign flush_DE = 1'b0;
	assign flush_MW = 1'b0;
	assign flush_XM = 1'b0;

	wire j_instr_ff;

	assign j_instr =  j_Dec |j_Ex|j_Mem | j_Wb;

	assign j_Dec =	(instr_Decode[15:11] == 5'b00100)|
					(instr_Decode[15:11] == 5'b00101)|
					(instr_Decode[15:11] == 5'b00110)|
					(instr_Decode[15:11] == 5'b00111)|
					(instr_Decode[15:11] == 5'b01100)|
					(instr_Decode[15:11] == 5'b01101)|
					(instr_Decode[15:11] == 5'b01110)|
					(instr_Decode[15:11] == 5'b01111)	?	1'b1	:	1'b0;

	assign j_Ex =	(instr_Ex[15:11] == 5'b00100)|
					(instr_Ex[15:11] == 5'b00101)|
					(instr_Ex[15:11] == 5'b00110)|
					(instr_Ex[15:11] == 5'b00111)|
					(instr_Ex[15:11] == 5'b01100)|
					(instr_Ex[15:11] == 5'b01101)|
					(instr_Ex[15:11] == 5'b01110)|
					(instr_Ex[15:11] == 5'b01111)	?	1'b1	:	1'b0;

	assign j_Mem =	(instr_Mem[15:11] == 5'b00100)|
					(instr_Mem[15:11] == 5'b00101)|
					(instr_Mem[15:11] == 5'b00110)|
					(instr_Mem[15:11] == 5'b00111)|
					(instr_Mem[15:11] == 5'b01100)|
					(instr_Mem[15:11] == 5'b01101)|
					(instr_Mem[15:11] == 5'b01110)|
					(instr_Mem[15:11] == 5'b01111)	?	1'b1	:	1'b0;

	assign j_Wb =	(instr_Wb[15:11] == 5'b00100)|
					(instr_Wb[15:11] == 5'b00101)|
					(instr_Wb[15:11] == 5'b00110)|
					(instr_Wb[15:11] == 5'b00111)|
					(instr_Wb[15:11] == 5'b01100)|
					(instr_Wb[15:11] == 5'b01101)|
					(instr_Wb[15:11] == 5'b01110)|
					(instr_Wb[15:11] == 5'b01111)	?	1'b1	:	1'b0;
	//assign j_Wb = 1'b0;

	assign jump_at_wb = j_Wb;
	assign jump_at_dec = j_Dec;
	assign jump_at_ex = j_Ex;
	assign jump_at_mem = j_Mem;

	//assign IFID_stall = 1'b0;
	assign IDEX_stall 	= 1'b0;
	assign EXMEM_stall 	= 1'b0;
	assign MEMWB_stall 	= 1'b0;

	dff j_instr_ff0(.clk(clk), .rst(rst), .d(j_instr), .q(j_instr_ff));
	//assign IDEX_stall = j_instr_ff;

	//wire IFID_stall_Out;

	//dff IFID_stall_ff0(.clk(clk), .rst(rst), .d(IFID_stall), .q(IFID_stall_Out));

	// check the ex stage Rs Rt against decode and fetch stage Rd
	assign IFID_stall = 	(((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
							((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
							((IDEX_Rd_ff[3] == 1'b1)	&	((IDEX_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
							((IDEX_Rd_ff[3] == 1'b1) 	&	((IDEX_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
							1'b0)	|	j_instr;

	/*assign IDEX_stall = 	((IDEX_Rs_ff[3] == 1'b1)	&	((IDEX_Rs_ff[2:0] == IFID_Rd_ff[2:0]) 	& IFID_Rd_ff[3]))	? 1'b1 :
							((IDEX_Rt_ff[3] == 1'b1)	&	((IDEX_Rt_ff[2:0] == IFID_Rd_ff[2:0]) 	& IFID_Rd_ff[3]))	? 1'b1 :
							1'b0;*/

						
	assign PC_force_stop = (rst)? 1'b1 : ((IFID_stall & j_instr)?	1'b0	:	IFID_stall);

	//assign flush_DE = (IFID_stall_Out == 1'b1)	?	((IFID_stall == 1'b0)	?	1'b1	:	1'b0)	:	1'b0;
	//assign flush_XM = (IFID_stall_Out == 1'b1)	?	((IFID_stall == 1'b0)	?	1'b1	:	1'b0)	:	1'b0;

	/*assign IDEX_stall = (IDEX_Rs_ff == EXMEM_Rd_ff) |(IDEX_Rs_ff == EXMEM_Rd_ff)|
						(IDEX_Rt_ff == EXMEM_Rd_ff) |(IDEX_Rt_ff == EXMEM_Rd_ff)|
						EXMEM_stall|J_stall; 	

	assign EXMEM_stall = (EXMEM_Rs_ff ==MEMWB_Rd_ff) |(EXMEM_Rs_ff == MEMWB_Rd_ff)|
						(EXMEM_Rt_ff == MEMWB_Rd_ff) |(EXMEM_Rt_ff == MEMWB_Rd_ff)|
						MEMWB_stall|J_stall; 	*/



	//assign PC_Out = (PC_Add[1] == 0)? PC_EX_Out	:	ALU_Out;			

 

endmodule