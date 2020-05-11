module MEM_WB(

	input clk, rst,

	input [15:0] data_MEM,// read data
	input [15:0] addr_2WB,// write the EX result to the register directly
	input 		Mux_MtoReg,
	input [3:0] Rs, Rt, Rd,
	input MEMWB_stall,
	input ALU_Zero, ALU_Ofl,
	
	input [2:0] writeRegSel,
	//input [15:0] writeData,
	input regWrite_enable,
	
	input [15:0] imm, arbitrary_num, mask,
	input [1:0] writeSrc,
	
	input [15:0] PC,

	input createdump,

	input flush_MW,

	input [15:0] instruction,
	
	input mem_err, ex_mem_err,

	output [15:0] instruction_ff,
	
	output createdump_ff,

	output [15:0] PC_ff,
	
	output [15:0] imm_ff, arbitrary_num_ff, mask_ff,
	output [1:0] writeSrc_ff,
	
	output [2:0] writeRegSel_ff,
	//output [15:0] writeData_ff,
	output regWrite_enable_ff,

	output 	[15:0]	data_MEM_ff, addr_2WB_ff,
	output 			Mux_MtoReg_ff,
	
	output ALU_Ofl_ff, ALU_Zero_ff,
	
	output	[3:0] Rs_ff, Rt_ff, Rd_ff,
	
	output mem_wb_err
	
	);

	wire rst_def;

	assign rst_def = rst | flush_MW;
	
	wire [15:0] PC_stall;
	
	assign PC_stall = MEMWB_stall	?	PC_ff	:	PC;
	dff_16bit PC_ff0(.clk(clk), .rst(rst_def), .d(PC_stall), .q(PC_ff));

	wire [15:0] data_MEM_stall;
	wire [15:0] addr_2WB_stall;
	wire [3:0] Rd_stall, Rs_stall, Rt_stall;

	assign data_MEM_stall = MEMWB_stall ? data_MEM_stall : data_MEM;
	assign addr_2WB_stall = MEMWB_stall ? addr_2WB_stall : addr_2WB;

	dff_16bit  data_out_ff0(.clk(clk), .rst(rst_def), .d(data_MEM_stall ), .q(data_MEM_ff));
	dff_16bit  addr_2WB_ff0(.clk(clk), .rst(rst_def), .d(addr_2WB_stall),  .q(addr_2WB_ff));

	wire Mux_MtoReg_stall;
	assign Mux_MtoReg_stall = MEMWB_stall ? Mux_MtoReg_ff : Mux_MtoReg;
	dff Mux_MtoREg_MEMWB_ff(.clk(clk), .rst(rst_def), .d(Mux_MtoReg_stall), .q(Mux_MtoReg_ff));
	
	assign Rd_stall = MEMWB_stall?	Rd_ff	:	Rd;
	assign Rs_stall = MEMWB_stall?	Rs_ff	:	Rs;
	assign Rt_stall = MEMWB_stall?	Rt_ff	:	Rt;

	dff Rd_MEMWB_ff0(.clk(clk), .rst(rst), .d(Rd_stall[0]), .q(Rd_ff[0]));
	dff Rd_MEMWB_ff1(.clk(clk), .rst(rst), .d(Rd_stall[1]), .q(Rd_ff[1]));
	dff Rd_MEMWB_ff2(.clk(clk), .rst(rst), .d(Rd_stall[2]), .q(Rd_ff[2]));
	dff Rd_MEMWB_ff3(.clk(clk), .rst(rst), .d(Rd_stall[3]), .q(Rd_ff[3]));
	
	dff Rs_MEMWB_ff0(.clk(clk), .rst(rst), .d(Rs_stall[0]), .q(Rs_ff[0]));
	dff Rs_MEMWB_ff1(.clk(clk), .rst(rst), .d(Rs_stall[1]), .q(Rs_ff[1]));
	dff Rs_MEMWB_ff2(.clk(clk), .rst(rst), .d(Rs_stall[2]), .q(Rs_ff[2]));
	dff Rs_MEMWB_ff3(.clk(clk), .rst(rst), .d(Rs_stall[3]), .q(Rs_ff[3]));
	
	dff Rt_MEMWB_ff0(.clk(clk), .rst(rst), .d(Rt_stall[0]), .q(Rt_ff[0]));
	dff Rt_MEMWB_ff1(.clk(clk), .rst(rst), .d(Rt_stall[1]), .q(Rt_ff[1]));
	dff Rt_MEMWB_ff2(.clk(clk), .rst(rst), .d(Rt_stall[2]), .q(Rt_ff[2]));
	dff Rt_MEMWB_ff3(.clk(clk), .rst(rst), .d(Rt_stall[3]), .q(Rt_ff[3]));
	
	wire [2:0] writeRegSel_stall;
	//wire [15:0] writeData_stall;
	wire regWrite_enable_stall;
	
	//assign writeData_stall = MEMWB_stall	?	writeData_ff	:	writeData;
	assign regWrite_enable_stall = MEMWB_stall	?	regWrite_enable_ff	:	regWrite_enable;
	assign writeRegSel_stall = MEMWB_stall	?	writeRegSel_ff	:	writeRegSel;
	
	//dff_16bit writeData_ff0(.clk(clk), .rst(rst_def), .d(writeData_stall), .q(writeData_ff));
	dff regWrite_enable_ff0(.clk(clk), .rst(rst_def), .d(regWrite_enable_stall), .q(regWrite_enable_ff));
	
	dff writeRegSel_ff0(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[0]), .q(writeRegSel_ff[0]));
	dff writeRegSel_ff1(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[1]), .q(writeRegSel_ff[1]));
	dff writeRegSel_ff2(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[2]), .q(writeRegSel_ff[2]));
	
	wire ALU_Zero_stall, ALU_Ofl_stall;
	assign ALU_Zero_stall = MEMWB_stall	?	ALU_Zero_ff	:	ALU_Zero;
	assign ALU_Ofl_stall = MEMWB_stall	?	ALU_Ofl_ff	:	ALU_Ofl;
	dff ALU_Zero_ff0(.clk(clk), .rst(rst_def), .d(ALU_Zero_stall), .q(ALU_Zero_ff));
	dff ALU_Ofl_ff0(.clk(clk), .rst(rst_def), .d(ALU_Ofl_stall), .q(ALU_Ofl_ff));
	
	wire [15:0] imm_stall, mask_stall, arbitrary_num_stall;
	wire [1:0] writeSrc_stall;
	
	assign imm_stall = MEMWB_stall?	imm_ff	:	imm;
	assign mask_stall = MEMWB_stall? mask_ff	:	mask;
	assign arbitrary_num_stall	= MEMWB_stall? arbitrary_num_ff	:	arbitrary_num;
	assign writeSrc_stall = MEMWB_stall?	writeSrc_ff	:	writeSrc;
	
	dff_16bit imm_ff0(.clk(clk), .rst(rst_def), .d(imm_stall), .q(imm_ff));
	dff_16bit mask_ff0(.clk(clk), .rst(rst_def), .d(mask_stall), .q(mask_ff));
	dff_16bit arbitrary_num_ff0(.clk(clk), .rst(rst_def), .d(arbitrary_num_stall), .q(arbitrary_num_ff));
	dff writeSrc_ff0(.clk(clk), .rst(rst_def), .d(writeSrc_stall[0]), .q(writeSrc_ff[0]));
	dff writeSrc_ff1(.clk(clk), .rst(rst_def), .d(writeSrc_stall[1]), .q(writeSrc_ff[1]));
	wire createdump_stall;
	wire createdump_ffinal;
	assign createdump_stall = MEMWB_stall ? createdump_ff : createdump;
	assign createdump_ff = (~MEMWB_stall)&createdump_ffinal;


	dff cd_ff0(.clk(clk), .rst(rst), .d(createdump_stall), .q(createdump_ffinal));

	dff_16bit instruction_ff0(.clk(clk), .rst(rst), .d(instruction), .q(instruction_ff));
	
	wire mem_wb_err_stall;
	assign mem_wb_err_stall = (MEMWB_stall)? mem_wb_err	:	(mem_err | ex_mem_err);
	dff mem_wb_err_ff(.d(mem_wb_err_stall), .q(mem_wb_err), .clk(clk), .rst(rst));

	
endmodule