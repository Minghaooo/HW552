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
	
	input i_mem_stall, i_mem_done,
	input d_mem_stall, d_mem_done,

	output IFID_stall, IFID_special_stall,
	output IDEX_stall,
	output EXMEM_stall,
	output MEMWB_stall,

	output flush_DE, flush_XM, flush_MW,
	
	output PC_force_stop,
	output jump_at_dec,
	output jump_at_ex,
	output jump_at_mem,
	output jump_at_wb,			// Indicate whether the Jump command has arrived at whiever stage
 	output EXEX_FWD_Rt, 
	output EXEX_FWD_Rs,
 	output MEMEX_FWD_Rt,
 	output MEMEX_FWD_Rs
);

	wire j_instr, j_Ex, j_Mem, j_Dec, j_Wb;
	wire J_stall;
	wire j_conde;
	wire  UNSTALL;
	wire IFID_stall_t, hazard;
	assign J_stall=	(IDEX_PC_Add != 2'b00);

	// Disable flush right now
	assign flush_DE = 1'b0;
	assign flush_MW = 1'b0;
	assign flush_XM = 1'b0;

	wire j_instr_ff;

	assign j_instr =  j_Dec |j_Ex|j_Mem | j_Wb;				// Jump instruction detected

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

	assign jump_at_wb = j_Wb;
	assign jump_at_dec = j_Dec;
	assign jump_at_ex = j_Ex;
	assign jump_at_mem = j_Mem;

	reg nxt_state;
	wire curr_state;
	
	dff state_mach0(.d(nxt_state), .q(curr_state), .clk(clk), .rst(rst));
	/*
	always@(*) begin
	
		case(curr_state)
		
			1'b0	:	begin
				nxt_state <= (d_mem_stall)?	((d_mem_done)? 1'b0	:	1'b1)	:	1'b0;
			end
			
			1'b1	:	begin
				nxt_state <= (d_mem_done)?	1'b0	:	1'b1;
			end
			
			default	:	begin
				nxt_state <= 1'b0;
			end
		
		endcase
	
	end*/
	
	// Proper stall logic(as Marvin assumed) for memory-induced stalls
	/*wire d_mem_stall_delay1;
	dff d_mem_stall_delay_ff0(.d(curr_state), .q(IDEX_stall), .clk(clk), .rst(rst));
	dff d_mem_stall_delay_ff1(.d(IDEX_stall), .q(EXMEM_stall), .clk(clk), .rst(rst));
	dff d_mem_stall_delay_ff2(.d(EXMEM_stall), .q(MEMWB_stall), .clk(clk), .rst(rst));*/
	
	assign IFID_special_stall = (d_mem_stall & ~d_mem_done);
	assign IDEX_stall = (d_mem_stall & ~d_mem_done);
	assign EXMEM_stall = IDEX_stall;
	assign MEMWB_stall = IDEX_stall;
	//assign MEMWB_stall = 1'b0;
	
	/*
	assign IDEX_stall 	= d_mem_stall & (~d_mem_done);
	assign EXMEM_stall 	= d_mem_stall & (~d_mem_done);
	assign MEMWB_stall 	= d_mem_stall & (~d_mem_done);
	*/
	dff j_instr_ff0(.clk(clk), .rst(rst), .d(j_instr), .q(j_instr_ff));
	//assign IDEX_stall = j_instr_ff;

	//wire IFID_stall_Out;

	assign stall_code =	
					(instr_Decode[15:11] == 5'b11000)|//lbi
					(instr_Decode[15:11] == 5'b10010)|//slbi
					//(instr_Decode[15:11] == 5'b10001)&hazard|
					(instr_Decode[15:11] == 5'b10011)|	//stu	
					(instr_Ex[15:11] == 5'b11000)|
					(instr_Ex[15:11] == 5'b10010)|
					//(instr_Ex[15:11] == 5'b10010)&hazard|
					(instr_Ex[15:11] == 5'b10011)			
					?1'b1:1'b0;

	//dff IFID_stall_ff0(.clk(clk), .rst(rst), .d(IFID_stall), .q(IFID_stall_Out));
	assign hazard =     ((IFID_Rs_ff[3] == 1'b1)	&	((IFID_Rs_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
						((IFID_Rs_ff[3] == 1'b1)	&	((IFID_Rs_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
						((IDEX_Rs_ff[3] == 1'b1)	&	((IDEX_Rs_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
						((IDEX_Rs_ff[3] == 1'b1) 	&	((IDEX_Rs_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 : 1'b0;
							
	//assign j_Wb = 1'b0;

	//assign st_stall = (instr_Fetch[15:13]==3'b100)&((instr_Decode[15:13] != 3'b100)|(instr_Decode[15:13] != 3'b000));

	// check the ex stage Rs Rt against decode and fetch stage Rd
	assign IFID_stall = (IFID_stall_t & (stall_code))|j_instr|(i_mem_stall & (~i_mem_done))|(d_mem_stall & (~d_mem_done));
	assign IFID_stall_t = ((((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
							((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
							((IDEX_Rd_ff[3] == 1'b1)	&	((IDEX_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
							((IDEX_Rd_ff[3] == 1'b1) 	&	((IDEX_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
							1'b0)	|	j_instr) 			// These are for jump / branch / dependency stalls
							|(i_mem_stall & (~i_mem_done))|(d_mem_stall & (~d_mem_done));	// For memory-induced stalls

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

	//forwording:
		
		assign EXEX_FWD_Rs  = (EXMEM_Rd_ff == IDEX_Rs_ff)&EXMEM_Rd_ff[3]&IDEX_Rd_ff[3]&(~stall_code); //|((instr_WB[15:11]==5'b10010)&(EXMEM_Rs_ff == IDEX_Rs_ff));
		assign EXEX_FWD_Rt  = (EXMEM_Rd_ff == IDEX_Rt_ff)&EXMEM_Rd_ff[3]&IDEX_Rd_ff[3]&(~stall_code);//|((instr_WB[15:11]==5'b10010)&(EXMEM_Rs_ff == IDEX_Rt_ff);
		assign MEMEX_FWD_Rt = (MEMWB_Rd_ff == IDEX_Rt_ff)&MEMWB_Rd_ff[3]&IDEX_Rd_ff[3]&(~stall_code);//|((instr_Wb [15:11]==5'b10010)&(EXMEM_Rs_ff == IDEX_Rt_ff));
		assign MEMEX_FWD_Rs = (MEMWB_Rd_ff == IDEX_Rs_ff)&MEMWB_Rd_ff[3]&IDEX_Rd_ff[3]&(~stall_code);//|((instr_Wb[15:11]==5'b10010)&(EXMEM_Rs_ff == IDEX_Rs_ff));

		//assign ins_allowed = ()

	//	assign FWD_IFID = (instr_Decode[15:11]!=5'b10001)&(((IFID_Rd_ff[3] == 1'b1)&((IFID_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))||((IFID_Rd_ff[3] == 1'b1)&((IFID_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3])));
	//	assign FWD_IDEX = (instr_Ex[15:11]!=1'b10001)&(((IDEX_Rd_ff[3] == 1'b1)&((IDEX_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))||((IDEX_Rd_ff[3] == 1'b1)&((IDEX_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3])));
	//	assign IFID_stall_t = (~(FWD_IDEX||FWD_IFID))&IFID_stall_t;
		//assign UNSTALL = IFID_stall_t;
		assign UNSTALL = hazard;//|(instr_Ex[15:13] == 3'b110);
	/*	
		
		( (((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
						((IFID_Rd_ff[3] == 1'b1)	&	((IFID_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
						((IDEX_Rd_ff[3] == 1'b1)	&	((IDEX_Rd_ff[2:0] == Rs_Fetch[2:0]) & Rs_Fetch[3]))	? 1'b1 :
						((IDEX_Rd_ff[3] == 1'b1) 	&	((IDEX_Rd_ff[2:0] == Rt_Fetch[2:0]) & Rt_Fetch[3]))	? 1'b1 :
						1'b0)	|	j_instr) 			// These are for jump / branch / dependency stalls
						|(i_mem_stall & (~i_mem_done))|(d_mem_stall & (~d_mem_done));	// For memory-induced stalls
		*/
		//LD must have one stall, then, 
	//	assign isLD = instr_2ID_ff[15:11] == 


	//assign PC_Out = (PC_Add[1] == 0)? PC_EX_Out	:	ALU_Out;



 

endmodule