module ID_EX(
	
	input clk, rst,
	input IDEX_stall,
	
	input  [15:0] InA, InB,
	input  [2:0]  ALU_op,
	input  		  Cin, invA, invB, sign,
	input  [1:0]  second_operand,		// immediate, zero or Rt?
	input  [15:0] imm,					// Immediate value
	input  		  PC_selSrc,			// Select whether PC should be updated with value from execute stage
	input  [1:0]  PC_Add, 				// PC+2 -> 00, +imm -> 01, RS + i -> 10
		
	input [15:0] PC,

	input MEM_En, MEM_writeEn, Mux_MtoReg,

	input err, 
	input halt, createdump,
	
	input [3:0] Rd, Rs, Rt,
	
	input [2:0] writeRegSel,
	//input [15:0] writeData,
	input regWrite_enable,
	
	input [15:0] arbitrary_num, mask,
	input [1:0] writeSrc,

	input [15:0] instruction,
	input flush_DE,
	
	output [15:0] arbitrary_num_ff, mask_ff,
	output [1:0] writeSrc_ff,
	
	output [2:0] writeRegSel_ff,
	//output [15:0] writeData_ff,
	output regWrite_enable_ff,

	output [15:0] InA_ff, InB_ff, PC_ff, imm_ff,//
	output [2:0] ALU_op_ff, //
	
	output [1:0] PC_Add_ff, second_operand_ff,//
	
	output Cin_ff, invA_ff, invB_ff, sign_ff,
	
	output PC_selSrc_ff,
	
	output MEM_En_ff, MEM_writeEn_ff, Mux_MtoReg_ff,
	
	output err_ff, halt_ff, createdump_ff,
	
	output [3:0] Rd_ff, Rs_ff, Rt_ff,

	output [15:0] instruction_ff
	
);
	dff_16bit instruction_ff0(.clk(clk), .rst(rst), .d(instruction), .q(instruction_ff));

	wire rst_def;

	assign rst_def = rst | flush_DE;

	wire [15:0] InA_stall, InB_stall, PC_stall, imm_stall;
	
	wire MEM_En_stall, MEM_writeEn_stall, Mux_MtoReg_stall;
	
	wire PC_selSrc_stall;
	
	wire err_stall, halt_stall, createdump_stall;
	
	wire [3:0] Rd_stall, Rt_stall, Rs_stall;

	assign InB_stall = IDEX_stall ? InB_ff : InB;
	assign InA_stall = IDEX_stall ? InA_ff : InA;

	assign PC_stall =  IDEX_stall ? PC_ff : PC;
	assign imm_stall = IDEX_stall ? imm_ff : imm;

	dff_16bit  INB_IDEX_ff(.clk(clk), .rst(rst_def), .d(InB_stall), .q(InB_ff));
	dff_16bit  INA_IDEX_ff(.clk(clk), .rst(rst_def), .d(InA_stall), .q(InA_ff));

	dff_16bit  PC_IDEX_ff(.clk(clk), .rst(rst_def),  .d(PC_stall ), .q(PC_ff ));
	dff_16bit  imm_IDEX_ff(.clk(clk), .rst(rst_def), .d(imm_stall), .q(imm_ff));

	wire [2:0] ALU_op_stall;

	assign ALU_op_stall = IDEX_stall ? ALU_op_ff : ALU_op;
	dff ALUop_IDEX_ff0(.clk(clk), .rst(rst_def), .d(ALU_op_stall[0]), .q(ALU_op_ff[0]));
	dff ALUop_IDEX_ff1(.clk(clk), .rst(rst_def), .d(ALU_op_stall[1]), .q(ALU_op_ff[1]));
	dff AlUop_IDEX_ff2(.clk(clk), .rst(rst_def), .d(ALU_op_stall[2]), .q(ALU_op_ff[2]));

	wire Cin_stall, invA_stall, invB_stall, sign_stall;

	assign Cin_stall =   IDEX_stall ? Cin_ff : Cin ;
	assign invA_stall =  IDEX_stall ? invA_ff: invA;
	assign invB_stall =  IDEX_stall ? invB_ff: invB;
	assign sign_stall =  IDEX_stall ? sign_ff: sign;

	dff Cin_IDEX_ff2(.clk(clk), .rst(rst_def),  .d(Cin_stall), .q(Cin_ff ));
	dff invA_IDEX_ff2(.clk(clk), .rst(rst_def), .d(invA_stall), .q(invA_ff));
	dff invB_IDEX_ff2(.clk(clk), .rst(rst_def), .d(invB_stall), .q(invB_ff));
	dff sign_IDEX_ff2(.clk(clk), .rst(rst_def), .d(sign_stall), .q(sign_ff));


	wire [1:0] second_operand_stall, PC_Add_stall;

	assign second_operand_stall = IDEX_stall ? second_operand_ff :second_operand;
	assign PC_Add_stall = IDEX_stall ? PC_Add_ff :PC_Add;
	
	dff secondop_IDEX_ff0(.clk(clk), .rst(rst_def), .d(second_operand_stall[0]), .q(second_operand_ff[0]));
	dff secondop_IDEX_ff1(.clk(clk), .rst(rst_def), .d(second_operand_stall[1]), .q(second_operand_ff[1]));

	assign PC_Add_stall = IDEX_stall?	PC_Add_ff	:	PC_Add;

	dff PC_Add_IDEX_ff0(.clk(clk), .rst(rst_def), .d(PC_Add_stall[0]), .q(PC_Add_ff[0]));
	dff PC_Add_IDEX_ff1(.clk(clk), .rst(rst_def), .d(PC_Add_stall[1]), .q(PC_Add_ff[1]));
	
	assign MEM_En_stall = IDEX_stall ? MEM_En_ff	:	MEM_En;
	assign MEM_writeEn_stall = IDEX_stall ? MEM_writeEn_ff	:	MEM_writeEn;
	assign Mux_MtoReg_stall = IDEX_stall ? Mux_MtoReg_ff	:	Mux_MtoReg;
	
	dff MEM_En_IDEX_ff(.clk(clk), .rst(rst_def), .d(MEM_En_stall), .q(MEM_En_ff));
	dff MEM_writeEn_IDEX_ff(.clk(clk), .rst(rst_def), .d(MEM_writeEn_stall), .q(MEM_writeEn_ff));
	dff Mux_MtoReg_IDEX_ff(.clk(clk), .rst(rst_def), .d(Mux_MtoReg_stall), .q(Mux_MtoReg_ff));
	
	assign err_stall = IDEX_stall ?	err_ff	:	err;
	assign halt_stall = IDEX_stall ?	halt_ff	:	halt;
	assign createdump_stall = IDEX_stall ?	createdump_ff	:	createdump;
	
	dff err_IDEX_ff(.clk(clk), .rst(rst_def), .d(err_stall), .q(err_ff));
	dff halt_IDEX_ff(.clk(clk), .rst(rst_def), .d(halt_stall), .q(halt_ff));
	dff createdump_IDEX_ff(.clk(clk), .rst(rst_def), .d(createdump_stall), .q(createdump_ff));
	
	assign PC_selSrc_stall = IDEX_stall	?	PC_selSrc_ff	:	PC_selSrc;
	dff PC_selSrc_IDEX_ff(.clk(clk), .rst(rst_def), .d(PC_selSrc_stall), .q(PC_selSrc_ff));
	
	wire [2:0] writeRegSel_stall;
	
	//wire [15:0] writeData_stall;
	wire regWrite_enable_stall;
	//assign writeData_stall = IDEX_stall	?	writeData_ff	:	writeData;
	assign regWrite_enable_stall = IDEX_stall	?	regWrite_enable_ff	:	regWrite_enable;
	assign writeRegSel_stall = IDEX_stall	?	writeRegSel_ff	:	writeRegSel;
	//dff_16bit writeData_ff0(.clk(clk), .rst(rst_def), .d(writeData_stall), .q(writeData_ff));
	dff regWrite_enable_ff0(.clk(clk), .rst(rst_def), .d(regWrite_enable_stall), .q(regWrite_enable_ff));
	dff writeRegSel_ff0(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[0]), .q(writeRegSel_ff[0]));
	dff writeRegSel_ff1(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[1]), .q(writeRegSel_ff[1]));
	dff writeRegSel_ff2(.clk(clk), .rst(rst_def), .d(writeRegSel_stall[2]), .q(writeRegSel_ff[2]));
	//assign writeRegSel_ff = writeRegSel;
	
	wire [15:0] mask_stall, arbitrary_num_stall;
	wire [1:0] writeSrc_stall;
	
	assign mask_stall = IDEX_stall? mask_ff	:	mask;
	assign arbitrary_num_stall	= IDEX_stall? arbitrary_num_ff	:	arbitrary_num;
	assign writeSrc_stall = IDEX_stall?	writeSrc_ff	:	writeSrc;
	
	dff_16bit mask_ff0(.clk(clk), .rst(rst_def), .d(mask_stall), .q(mask_ff));
	dff_16bit arbitrary_num_ff0(.clk(clk), .rst(rst_def), .d(arbitrary_num_stall), .q(arbitrary_num_ff));
	dff writeSrc_ff0(.clk(clk), .rst(rst_def), .d(writeSrc_stall[0]), .q(writeSrc_ff[0]));
	dff writeSrc_ff1(.clk(clk), .rst(rst_def), .d(writeSrc_stall[1]), .q(writeSrc_ff[1]));

	// Pipeline Rs, Rd, Rt
	dff Rd_IDEX_ff0(.clk(clk), .rst(rst), .d(Rd[0]), .q(Rd_ff[0]));
	dff Rd_IDEX_ff1(.clk(clk), .rst(rst), .d(Rd[1]), .q(Rd_ff[1]));
	dff Rd_IDEX_ff2(.clk(clk), .rst(rst), .d(Rd[2]), .q(Rd_ff[2]));
	dff Rd_IDEX_ff3(.clk(clk), .rst(rst), .d(Rd[3]), .q(Rd_ff[3]));
	
	dff Rs_IDEX_ff0(.clk(clk), .rst(rst), .d(Rs[0]), .q(Rs_ff[0]));
	dff Rs_IDEX_ff1(.clk(clk), .rst(rst), .d(Rs[1]), .q(Rs_ff[1]));
	dff Rs_IDEX_ff2(.clk(clk), .rst(rst), .d(Rs[2]), .q(Rs_ff[2]));
	dff Rs_IDEX_ff3(.clk(clk), .rst(rst), .d(Rs[3]), .q(Rs_ff[3]));
	
	dff Rt_IDEX_ff0(.clk(clk), .rst(rst), .d(Rt[0]), .q(Rt_ff[0]));
	dff Rt_IDEX_ff1(.clk(clk), .rst(rst), .d(Rt[1]), .q(Rt_ff[1]));
	dff Rt_IDEX_ff2(.clk(clk), .rst(rst), .d(Rt[2]), .q(Rt_ff[2]));
	dff Rt_IDEX_ff3(.clk(clk), .rst(rst), .d(Rt[3]), .q(Rt_ff[3]));

endmodule 