/* $Author: sinclair $ */
/* $LastChangedDate: 2020-02-09 17:03:45 -0600 (Sun, 09 Feb 2020) $ */
/* $Rev: 46 $ */
module proc (/*AUTOARG*/
	// Outputs
	err, 
	// Inputs
	clk, rst
	);

	input clk;
	input rst;

	output err;

	// None of the above lines can be modified

	// OR all the err ouputs for every sub-module and assign it as this
	// err output

	// As desribed in the homeworks, use the err signal to trap corner
	// cases that you think are illegal in your statemachines


	/* your code here -- should include instantiations of fetch, decode, execute, mem and wb modules */
	
	wire clk, rst;
	
	// stall signals
	wire IFID_stall, IDEX_stall, EXMEM_stall, MEMWB_stall;
	
	// To fetch
	wire [15:0]	pc_to_Fetch, instr_2ID;
	wire cd_to_Fetch, halt_to_Fetch, PC_selSrc_to_Fetch;
	
	// From fetch
	wire [15:0] pc_Fetch;
	
	// To decode
	wire [3:0] Rd_to_Dec, Rs_to_Dec, Rt_to_Dec;
	wire [15:0] instr_to_Dec, pc_to_Dec;
	
	// From decode
	wire cd_Dec, halt_Dec, err_Dec;
	wire Cin_Dec, invA_Dec, invB_Dec, sign_Dec;
	wire MEM_En_Dec, MEM_writeEn_Dec, Mux_MtoReg_Dec;
	wire [15:0] InA_Dec, InB_Dec, imm_Dec, ALU_Out_Dec, pc_Dec;
	wire PC_selSrc_Dec;
	wire [1:0] PC_Add_Dec, second_operand_Dec;
	wire [2:0] ALU_op_Dec;
	
	// To execute
	wire err_to_Ex, halt_to_Ex, createdump_to_Ex;
	wire [3:0] Rd_to_Ex, Rs_to_Ex, Rt_to_Ex;
	wire [15:0] InA_to_Ex, InB_to_Ex, pc_to_Ex, imm_to_Ex;
	wire Cin_to_Ex, invA_to_Ex, invB_to_Ex, sign_to_Ex;		// ALU select signals
	wire [1:0] PC_Add_to_Ex, second_operand_to_Ex;			// PC_Add and second_operand sent to Ex stage
	wire [2:0] ALU_op_to_Ex;								// ALU operation signal
	wire Mux_MtoReg_to_EX;

	// From execute
	wire ALU_Zero_Ex, ALU_Ofl_Ex, ALU_Zero_to_Mem;
	wire [15:0] ALU_Out_Ex, addr_Ex;
	wire [15:0] pc_Ex;
	
	// To memory
	wire [3:0] Rd_to_Mem, Rs_to_Mem, Rt_to_Mem;
	wire [15:0] ALU_Out_to_Mem, data_in_to_Mem;
	wire MEM_writeEn_to_Mem, MEM_En_to_Mem, cd_to_Mem;
	wire Mux_MtoReg_to_Mem;
	
	// From memory
	wire [15:0] MEM_ex_result, MEM_data_out;
	wire ALU_Ofl_to_WB;
	
	// To writeback
	wire [15:0] MEM_data_out_to_WB, WB_data, MEM_ex_result_to_WB;
	wire [3:0] Rd_to_WB, Rs_to_WB, Rt_to_WB;
	
	// register operation signals
	wire [15:0] writeData_to_Dec, writeData_to_Ex, writeData_to_Mem, writeData_Dec;
	wire [2:0] writeRegSel_to_Dec, writeRegSel_to_Ex, writeRegSel_to_Mem, writeRegSel_Dec;
	wire regWrite_enable_to_Dec, regWrite_enable_to_Ex, regWrite_enable_to_Mem, regWrite_enable_Dec;
	
	// imm, arbitrary_num, mask, writeSrc
	wire [15:0] imm_to_Mem, imm_to_WB;
	wire [15:0]	PC_to_WB;
	wire [15:0] arbitrary_num_to_WB, arbitrary_num_to_Mem, arbitrary_num_to_Ex, arbitrary_num_Dec, arbitrary_num_from_Ex;
	wire [15:0] mask_Dec, mask_to_Ex, mask_to_Mem, mask_to_WB;
	wire [1:0] writeSrc_Dec, writeSrc_to_Ex, writeSrc_to_Mem, writeSrc_to_WB;

	wire [3:0] Rs_Fetch, Rt_Fetch, Rd_Fetch;
	
	// variables used for stall control
	wire	Rd_val, Rs_val, Rt_val;
	wire	PC_force_stop;

	wire flush_MW, flush_XM, flush_DE;

	wire jump_at_wb, jump_at_dec, jump_at_ex, jump_at_mem;
	
	/*
	assign IFID_stall = 1'b0;
	assign IDEX_stall = 1'b0;
	assign EXMEM_stall = 1'b0;
	assign MEMWB_stall = 1'b0;
	*/
	
	assign halt_to_Fetch = halt_Dec;

	wire [15:0] instr_to_ex, instr_Mem, instr_WB;
	
	fetch fetch0(.pc_nxt(pc_to_Fetch), .pc_2ID(pc_Fetch), .instr_2ID(instr_2ID), .jump_at_mem(jump_at_mem), .jump_at_wb(jump_at_wb),
		.rst(rst), .clk(clk), .createdump(cd_to_Fetch), .halt(halt_to_Fetch), .PC_selSrc(PC_selSrc_to_Fetch), 
		.PC_force_stop(PC_force_stop));
		
	IF_ID fd_ctrl(.clk(clk), .rst(rst), .pc_2ID(pc_Fetch), .instr_2ID(instr_2ID), .IFID_stall(IFID_stall), 
		.pc_2ID_ff(pc_to_Dec), .instr_2ID_ff(instr_to_Dec), .Rd_ff(Rd_to_Dec), .Rs_ff(Rs_to_Dec), .Rt_ff(Rt_to_Dec),
		. Rd_valff(Rd_val), .Rs_valff(Rs_val), .Rt_valff(Rt_val),
		.Rs(Rs_Fetch), .Rt(Rt_Fetch), .Rd(Rd_Fetch));
   
	decode_new decode0(.clk(clk), .rst(rst), .instruction(instr_to_Dec), .PC(pc_to_Dec), .PC_selSrc(PC_selSrc_Dec),
		.ALU_Out(ALU_Out_Dec), .ALU_Zero(ALU_Zero_to_Dec), 
		.ALU_Ofl(ALU_Ofl_to_Dec), .WB_data(WB_data), .InA(InA_Dec), .InB(InB_Dec), .ALU_op(ALU_op_Dec), .Cin(Cin_Dec),
		.invA(invA_Dec), .invB(invB_Dec), 
		.sign(sign_Dec), .second_operand(second_operand_Dec), .imm(imm_Dec), .PC_Add(PC_Add_Dec), 
		.MEM_En(MEM_En_Dec), .MEM_writeEn(MEM_writeEn_Dec), .Mux_MtoReg(Mux_MtoReg_Dec), 
		.createdump(cd_Dec), .err(err_Dec), .halt(halt_Dec), 
		.writeRegSel(writeRegSel_to_Dec), /*.writeData(writeData_to_Dec),*/ .regWrite_ext_enable(regWrite_enable_to_Dec),
		.writeRegSel_Out(writeRegSel_Dec), /*.writeData(writeData_Dec),*/ .regWrite_enable(regWrite_enable_Dec),
		.imm_from_WB(imm_to_WB), .PC_from_WB(PC_to_WB), .arbitrary_num_from_WB(arbitrary_num_to_WB),
		.mask_from_WB(mask_to_WB), .writeSrc_from_WB(writeSrc_to_WB),
		.mask(mask_Dec), .arbitrary_num(arbitrary_num_Dec), .writeSrc(writeSrc_Dec));
		
	ID_EX de_ctrl(.clk(clk), .rst(rst), .PC(pc_to_Dec) , .flush_DE(flush_DE), .IDEX_stall(IDEX_stall), .instruction(instr_to_Dec),
		.InA(InA_Dec), .InB(InB_Dec), .ALU_op(ALU_op_Dec), 
		.Cin(Cin_Dec), .invA(invA_Dec), .invB(invB_Dec), .sign(sign_Dec), .second_operand(second_operand_Dec), 
		.imm(imm_Dec), .PC_selSrc(PC_selSrc_Dec), .PC_Add(PC_Add_Dec), .MEM_En(MEM_En_Dec), .MEM_writeEn(MEM_writeEn_Dec),
		.Mux_MtoReg(Mux_MtoReg_Dec), .err(err_Dec), .halt(halt_Dec), .createdump(cd_Dec), 
		.Rs(Rs_to_Dec), .Rt(Rt_to_Dec), .Rd(Rd_to_Dec),
		.InA_ff(InA_to_Ex), .InB_ff(InB_to_Ex), .PC_ff(pc_to_Ex), .imm_ff(imm_to_Ex), .ALU_op_ff(ALU_op_to_Ex),
		.PC_Add_ff(PC_Add_to_Ex), .second_operand_ff(second_operand_to_Ex),
		.Cin_ff(Cin_to_Ex), .invA_ff(invA_to_Ex), .invB_ff(invB_to_Ex), .sign_ff(sign_to_Ex), .PC_selSrc_ff(PC_selSrc_to_Ex),
		.MEM_En_ff(MEM_En_to_Ex), .MEM_writeEn_ff(MEM_writeEn_to_Ex), .Mux_MtoReg_ff(Mux_MtoReg_to_EX), 
		.err_ff(err_to_Ex), .halt_ff(halt_to_Ex), .createdump_ff(createdump_to_Ex), 
		.Rd_ff(Rd_to_Ex), .Rs_ff(Rs_to_Ex), .Rt_ff(Rt_to_Ex),
		.instruction_ff(instr_to_ex),
		.writeRegSel(writeRegSel_Dec), /*.writeData(writeData_Dec),*/ .regWrite_enable(regWrite_enable_Dec),
		.writeRegSel_ff(writeRegSel_to_Ex), /*.writeData_ff(writeData_to_Ex),*/ .regWrite_enable_ff(regWrite_enable_to_Ex),
		.mask(mask_Dec), .arbitrary_num(arbitrary_num_Dec), .writeSrc(writeSrc_Dec),
		.mask_ff(mask_to_Ex), .arbitrary_num_ff(arbitrary_num_to_Ex), .writeSrc_ff(writeSrc_to_Ex));
		
	execute execute0(.clk(clk), .rst(rst), .instr_ex(instr_to_ex), .arbitrary_num(arbitrary_num_to_Ex), .arbitrary_num_ex(arbitrary_num_from_Ex),
		.InA(InA_to_Ex), .InB(InB_to_Ex), .PC(pc_to_Ex), .imm(imm_to_Ex), .ALU_op(ALU_op_to_Ex), .PC_Add(PC_Add_to_Ex), 
		.second_operand(second_operand_to_Ex), .Cin(Cin_to_Ex), .invA(invA_to_Ex), .invB(invB_to_Ex), .sign(sign_to_Ex), 
		.ALU_Zero(ALU_Zero_Ex), .ALU_Ofl(ALU_Ofl_Ex), .ALU_Out(ALU_Out_Ex), .PC_Out(pc_Ex), .addr(addr_Ex), .jump_at_ex(jump_at_ex));
		
	EX_MEM em_ctrl(.clk(clk), .rst(rst), .createdump(createdump_to_Ex), .flush_XM(flush_XM), .PC_selSrc(PC_selSrc_to_Ex),
		.instruction(instr_to_ex), .instruction_ff(instr_Mem),
		.ALU_Zero(ALU_Zero_Ex), .ALU_Ofl(ALU_Ofl_Ex), .ALU_Out(ALU_Out_Ex), .PC_Out(pc_Ex),
		.Rs(Rs_to_Ex), .Rt(Rt_to_Ex), .Rd(Rd_to_Ex), .MEM_data_in(InB_to_Ex), 
		.EXMEM_stall(EXMEM_stall), .Mux_MtoReg(Mux_MtoReg_to_EX), .wr(MEM_writeEn_to_Ex), .enable(MEM_En_to_Ex),
		.PC_Out_ff(pc_to_Fetch), .ALU_Zero_ff(ALU_Zero_to_Mem), .ALU_Ofl_ff(ALU_Ofl_to_WB), .ALU_Out_ff(ALU_Out_to_Mem),
		.wr_ff(MEM_writeEn_to_Mem), .enable_ff(MEM_En_to_Mem), .createdump_ff(cd_to_Mem), 
		.Rs_ff(Rs_to_Mem), .Rd_ff(Rd_to_Mem), .Rt_ff(Rt_to_Mem), .Mux_MtoReg_ff(Mux_MtoReg_to_Mem), .MEM_data_in_ff(data_in_to_Mem),
		.PC_selSrc_ff(PC_selSrc_to_Fetch),
		.writeRegSel(writeRegSel_to_Ex), /*.writeData(writeData_to_Ex),*/ .regWrite_enable(regWrite_enable_to_Ex),
		.writeRegSel_ff(writeRegSel_to_Mem), /*.writeData_ff(writeData_to_Mem),*/ .regWrite_enable_ff(regWrite_enable_to_Mem),
		.imm(imm_to_Ex), .mask(mask_to_Ex), .arbitrary_num(arbitrary_num_from_Ex), .writeSrc(writeSrc_to_Ex),
		.imm_ff(imm_to_Mem), .mask_ff(mask_to_Mem), .arbitrary_num_ff(arbitrary_num_to_Mem), .writeSrc_ff(writeSrc_to_Mem));
	
	memory memory0(.clk(clk), .rst(rst), .addr(ALU_Out_to_Mem), .data_in(data_in_to_Mem), .wr(MEM_writeEn_to_Mem), .enable(MEM_En_to_Mem), 
		.createdump(cd_to_Mem), 
		.data_out(MEM_data_out), .addr_2WB(MEM_ex_result));
		
	MEM_WB mw_ctrl(.clk(clk), .rst(rst), .flush_MW(flush_MW), .createdump(cd_to_Mem),
		.instruction(instr_Mem), .instruction_ff(instr_WB),
		.addr_2WB(MEM_ex_result), .data_MEM(MEM_data_out),
		.Mux_MtoReg(Mux_MtoReg_to_Mem), .ALU_Zero(ALU_Zero_to_Mem), .ALU_Ofl(ALU_Ofl_to_WB),
		.Rs(Rs_to_Mem), .Rt(Rt_to_Mem), .Rd(Rd_to_Mem), 
		.MEMWB_stall(MEMWB_stall),
		.data_MEM_ff(MEM_data_out_to_WB), .addr_2WB_ff(MEM_ex_result_to_WB), 
		.Mux_MtoReg_ff(Mux_MtoReg_to_WB),
		.Rs_ff(Rs_to_WB), .Rt_ff(Rt_to_WB), .Rd_ff(Rd_to_WB),
		.ALU_Zero_ff(ALU_Zero_to_Dec), .ALU_Ofl_ff(ALU_Ofl_to_Dec),
		.writeRegSel(writeRegSel_to_Mem), /*.writeData(writeData_to_Mem), */.regWrite_enable(regWrite_enable_to_Mem),
		.writeRegSel_ff(writeRegSel_to_Dec), /*.writeData_ff(writeData_to_Dec),*/ .regWrite_enable_ff(regWrite_enable_to_Dec),
		.imm(imm_to_Mem), .mask(mask_to_Mem), .arbitrary_num(arbitrary_num_to_Mem), .writeSrc(writeSrc_to_Mem),
		.imm_ff(imm_to_WB), .mask_ff(mask_to_WB), .arbitrary_num_ff(arbitrary_num_to_WB), .writeSrc_ff(writeSrc_to_WB), 
		.PC(pc_to_Fetch), .PC_ff(PC_to_WB), .createdump_ff(cd_WB));
	
	wb write_back(.data_MEM(MEM_data_out_to_WB), .Mux_MtoReg(Mux_MtoReg_to_WB), .data_toReg(WB_data), .data_ALU(MEM_ex_result_to_WB));

	assign ALU_Out_Dec = MEM_ex_result_to_WB;

	stall_detect stall(.clk(clk), .rst(rst), .instr_Fetch(instr_2ID),

		.Rs_Fetch(Rs_Fetch), .Rt_Fetch(Rt_Fetch), .Rd_Fetch(Rd_Fetch),
		.IFID_Rd_ff(Rd_to_Dec),   .IFID_Rs_ff(Rs_to_Dec),  .IFID_Rt_ff(Rt_to_Dec),
		.IDEX_Rd_ff(Rd_to_Ex),   .IDEX_Rs_ff(Rs_to_Ex),  .IDEX_Rt_ff(Rt_to_Ex),
		.EXMEM_Rd_ff(Rd_to_Mem),  .EXMEM_Rs_ff(Rs_to_Mem), .EXMEM_Rt_ff(Rt_to_Mem),
		.MEMWB_Rd_ff(Rd_to_WB),  .MEMWB_Rs_ff(Rs_to_WB), .MEMWB_Rt_ff(Rt_to_WB),

		//input 
		.IDEX_PC_Add(PC_Add_to_Ex), 
		.instr_2ID_ff(instr_to_Dec),
		.Rd_val(Rd_val), .Rs_val(Rs_val), .Rt_val(Rt_val),
		.instr_Decode(instr_to_Dec), .instr_Ex(instr_to_ex), .instr_Mem(instr_Mem), .instr_Wb(instr_WB),

		//output
		.IFID_stall(IFID_stall),
		.IDEX_stall(IDEX_stall),
		.EXMEM_stall(EXMEM_stall),
		.MEMWB_stall(MEMWB_stall),
		.regWrite_enable_IDEX(regWrite_enable_to_Ex),
		.regWrite_enable_EXMEM(regWrite_enable_to_Mem),
		.PC_force_stop(PC_force_stop),
		.flush_DE(flush_DE), .flush_XM(flush_XM), .flush_MW(flush_MW),
		.jump_at_wb(jump_at_wb), .jump_at_ex(jump_at_ex), .jump_at_mem(jump_at_mem), .jump_at_dec(jump_at_dec)
	);

endmodule // proc
// DUMMY LINE FOR REV CONTROL :0:
