module EX_MEM(

	input clk,
	input rst,
	
	input wr, enable,

	input ALU_Zero, ALU_Ofl,
	input [15:0] ALU_Out, MEM_data_in,
	input [15:0] PC_Out,
	input [3:0] Rs, Rt, Rd,
	input createdump,
	
	input PC_selSrc,
	
	input Mux_MtoReg,
	
	input EXMEM_stall,
	
	input [2:0] writeRegSel,
	//input [15:0] writeData,
	input regWrite_enable,
	
	input [15:0] imm, arbitrary_num, mask,
	input [1:0] writeSrc,

	input flush_XM,

	input [15:0] instruction,

	output [15:0] instruction_ff,
	
	output [15:0] imm_ff, arbitrary_num_ff, mask_ff,
	output [1:0] writeSrc_ff,
	
	output [2:0] writeRegSel_ff,
	//output [15:0] writeData_ff,
	output regWrite_enable_ff,
  
	output [15:0] PC_Out_ff,
	output ALU_Zero_ff,
	output ALU_Ofl_ff,

	output [15:0] ALU_Out_ff,
	output [15:0] MEM_data_in_ff, //write data

	output wr_ff, 
	output enable_ff, //MEMORY ENABLE
	output createdump_ff,
	
	output [3:0] Rs_ff, Rt_ff, Rd_ff, 
	
	output Mux_MtoReg_ff,
	
	output PC_selSrc_ff

	);

	dff_16bit instruction_ff0(.clk(clk), .rst(rst), .d(instruction), .q(instruction_ff));

	wire rst_def;

	assign rst_def = rst | flush_XM;
	
	wire PC_selSrc_stall;
	assign PC_selSrc_stall = EXMEM_stall	?	PC_selSrc_ff	:	PC_selSrc;
	dff PC_selSrc_ff0(.clk(clk), .rst(rst_def), .d(PC_selSrc_stall), .q(PC_selSrc_ff));

	wire [15:0] PC_Out_stall,ALU_Out_stall, MEM_data_in_stall;
	wire [3:0] Rd_stall, Rs_stall, Rt_stall;

	assign PC_Out_stall =  EXMEM_stall ? PC_Out_ff : PC_Out;
	assign ALU_Out_stall = EXMEM_stall ? ALU_Out_ff :ALU_Out;
	assign MEM_data_in_stall = EXMEM_stall	?	MEM_data_in_ff	:	MEM_data_in;

	dff_16bit  	PC_Out_EXMEM_ff(.clk(clk), .rst(rst_def), .d(PC_Out_stall ), .q(PC_Out_ff ));
	dff_16bit  	ALU_Out_EXMEM_ff(.clk(clk), .rst(rst_def), .d(ALU_Out_stall), .q(ALU_Out_ff));
	dff_16bit	MEM_data_in_EXMEM_ff(.clk(clk), .rst(rst_def), .d(MEM_data_in_stall), .q(MEM_data_in_ff));

	wire  ALU_Zero_stall, ALU_Ofl_stall;

	assign ALU_Zero_stall =	EXMEM_stall ?ALU_Zero_ff	:	ALU_Zero;
	assign ALU_Ofl_stall  =	EXMEM_stall ? ALU_Ofl_ff	:	ALU_Ofl ;

	dff ALUOFL_EXMEM_ff(.clk(clk), .rst(rst_def),  .d(ALU_Ofl_stall), .q(ALU_Ofl_ff));
	dff ALUZERO_EXMEM_ff(.clk(clk), .rst(rst_def),  .d(ALU_Zero_stall ), .q(ALU_Zero_ff));
	//output wr_ff, 
	//output enable_ff, //MEMORY ENABLE
	//output createdump_ff
	
	wire Mux_MtoReg_stall;
	
	assign Mux_MtoReg_stall = EXMEM_stall?	Mux_MtoReg_ff	:	Mux_MtoReg;
	
	dff Mux_MtoReg_ff0(.clk(clk), .rst(rst_def), .d(Mux_MtoReg_stall), .q(Mux_MtoReg_ff));
	
	wire wr_stall, enable_stall;
	assign wr_stall = EXMEM_stall? wr_ff	:	wr;
	assign enable_stall = EXMEM_stall? enable_ff	:	enable;
	dff wr_ff0(.clk(clk), .rst(rst_def), .d(wr_stall), .q(wr_ff));
	dff enable_ff0(.clk(clk), .rst(rst_def), .d(enable_stall), .q(enable_ff));
	
	assign Rd_stall = (EXMEM_stall?	Rd_ff	:	Rd);
	assign Rs_stall = (EXMEM_stall?	Rs_ff	:	Rs);
	assign Rt_stall = (EXMEM_stall?	Rt_ff	:	Rt);

	dff Rd_EXMEM_ff0(.clk(clk), .rst(rst), .d(Rd_stall[0]), .q(Rd_ff[0]));
	dff Rd_EXMEM_ff1(.clk(clk), .rst(rst), .d(Rd_stall[1]), .q(Rd_ff[1]));
	dff Rd_EXMEM_ff2(.clk(clk), .rst(rst), .d(Rd_stall[2]), .q(Rd_ff[2]));
	dff Rd_EXMEM_ff3(.clk(clk), .rst(rst), .d(Rd_stall[3]), .q(Rd_ff[3]));
	
	dff Rs_EXMEM_ff0(.clk(clk), .rst(rst), .d(Rs_stall[0]), .q(Rs_ff[0]));
	dff Rs_EXMEM_ff1(.clk(clk), .rst(rst), .d(Rs_stall[1]), .q(Rs_ff[1]));
	dff Rs_EXMEM_ff2(.clk(clk), .rst(rst), .d(Rs_stall[2]), .q(Rs_ff[2]));
	dff Rs_EXMEM_ff3(.clk(clk), .rst(rst), .d(Rs_stall[3]), .q(Rs_ff[3]));
	
	dff Rt_EXMEM_ff0(.clk(clk), .rst(rst), .d(Rt_stall[0]), .q(Rt_ff[0]));
	dff Rt_EXMEM_ff1(.clk(clk), .rst(rst), .d(Rt_stall[1]), .q(Rt_ff[1]));
	dff Rt_EXMEM_ff2(.clk(clk), .rst(rst), .d(Rt_stall[2]), .q(Rt_ff[2]));
	dff Rt_EXMEM_ff3(.clk(clk), .rst(rst), .d(Rt_stall[3]), .q(Rt_ff[3]));
	
	wire [2:0] writeRegSel_stall;
	wire [15:0] writeData_stall;
	wire regWrite_enable_stall;
	
	//assign writeData_stall = EXMEM_stall	?			writeData_ff	:	writeData;
	assign regWrite_enable_stall = EXMEM_stall	?	regWrite_enable_ff	:	regWrite_enable;
	assign writeRegSel_stall = EXMEM_stall	?			writeRegSel_ff	:	writeRegSel;
	
	//dff_16bit writeData_ff0(.clk(clk), .rst(rst_def), .d(writeData_stall), .q(writeData_ff));
	dff regWrite_enable_ff0(.clk(clk), .rst(rst_def), .d(regWrite_enable_stall), .q(regWrite_enable_ff));

	dff writeRegSel_ff0(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[0]), .q(writeRegSel_ff[0]));
	dff writeRegSel_ff1(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[1]), .q(writeRegSel_ff[1]));
	dff writeRegSel_ff2(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[2]), .q(writeRegSel_ff[2]));
	
	wire [15:0] imm_stall, mask_stall, arbitrary_num_stall;
	wire [1:0] writeSrc_stall;
	
	assign imm_stall = EXMEM_stall?	imm_ff	:	imm;
	assign mask_stall = EXMEM_stall? mask_ff	:	mask;
	assign arbitrary_num_stall	= EXMEM_stall? arbitrary_num_ff	:	arbitrary_num;
	assign writeSrc_stall = EXMEM_stall?	writeSrc_ff	:	writeSrc;
	
	dff_16bit imm_ff0(.clk(clk), .rst(rst_def), .d(imm_stall), .q(imm_ff));
	dff_16bit mask_ff0(.clk(clk), .rst(rst_def), .d(mask_stall), .q(mask_ff));
	dff_16bit arbitrary_num_ff0(.clk(clk), .rst(rst_def), .d(arbitrary_num_stall), .q(arbitrary_num_ff));
	dff writeSrc_ff0(.clk(clk), .rst(rst_def), .d(writeSrc_stall[0]), .q(writeSrc_ff[0]));
	dff writeSrc_ff1(.clk(clk), .rst(rst_def), .d(writeSrc_stall[1]), .q(writeSrc_ff[1]));

	dff cd_ff0(.clk(clk), .rst(rst), .d(createdump), .q(createdump_ff));
	
endmodule 