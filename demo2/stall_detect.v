module stall_detect(

	input clk,
	input rst,

	input [3:0] IFID_Rd_ff, IFID_Rs_ff, IFID_Rt_ff,
	input [3:0] IDEX_Rd_ff, IDEX_Rs_ff, IDEX_Rt_ff,
	input [3:0] EXMEM_Rd_ff, EXMEM_Rs_ff, EXMEM_Rt_ff,
	input [3:0] MEMWB_Rd_ff, MEMWB_Rs_ff, MEMWB_Rt_ff,

	input [1:0] IDEX_PC_Add, //PC_Add[1]
	input [15:0] instr_2ID_ff,

	output IFID_stall,
	output IDEX_stall,
	output EXMEM_stall,
	output MEMWB_stall
);
assign IFID_stall = 0;
assign IDEX_stall = 0;
assign EXMEM_stall = 0;
assign MEMWB_stall = 0;


/*
wire J_stall;
wire j_conde;

assign j_conde =(instr_2ID_ff[15:11] == 5'b00100)|(instr_2ID_ff[15:11] == 5'b00101)|(instr_2ID_ff[15:11] == 5'b00110)|(instr_2ID_ff[15:11] == 5'b00111);

// data hazard
//assign IFID_stall = (IFID_Rs_ff == IDEX_Rd_ff) |(IFID_Rs_ff == EXMEM_Rd_ff)|
// 					(IFID_Rt_ff == IDEX_Rd_ff) |(IFID_Rt_ff == EXMEM_Rd_ff);


// may need valid bit here 

assign IFID_stall = EXMEM_stall | IDEX_stall  |MEMWB_stall;
 					
assign IDEX_stall = (IDEX_Rs_ff == EXMEM_Rd_ff) |(IDEX_Rs_ff == EXMEM_Rd_ff)|
 					(IDEX_Rt_ff == EXMEM_Rd_ff) |(IDEX_Rt_ff == EXMEM_Rd_ff)|
 					EXMEM_stall|J_stall; 	

assign EXMEM_stall = (EXMEM_Rs_ff ==MEMWB_Rd_ff) |(EXMEM_Rs_ff == MEMWB_Rd_ff)|
 					(EXMEM_Rt_ff == MEMWB_Rd_ff) |(EXMEM_Rt_ff == MEMWB_Rd_ff)|
 					MEMWB_stall|J_stall; 	

 assign J_stall=	j_conde;
 
 //|(IDEX_PC_Add != 2'b00);

assign MEMWB_stall = 0;

//assign PC_Out = (PC_Add[1] == 0)? PC_EX_Out	:	ALU_Out;			


*/
endmodule