 module pipeline_ctrl(

	// Inputs
	input clk, rst,
	// From fetch
	input [15:0] pc_Fetch,
	input [15:0] instr_2ID,
	
	// From decode
	input createdump, halt, err,
	input Cin, invA, invB, sign,
	input MEM_En, MEM_writeEn, Mux_MtoReg,
	input [15:0] InA, InB, imm,
	input [15:0] pc_Dec,
	input PC_selSrc,
	input [1:0] PC_Add, second_operand,
	input [2:0] ALU_op,

	// From execute
	input ALU_Zero, ALU_Ofl,
	input [15:0] ALU_Out,
	input [15:0] pc_Ex,
	
	// From memory
	input [15:0] MEM_ex_result, MEM_data_out,
	
	// Outputs
	output reg [15:0] pc_to_Dec, pc_to_Ex, pc_to_Fetch,			// PC signals
	output reg [15:0] instr_to_Dec,								// Instruction signal
	output reg cd_to_Mem,										// Createdump
	output reg halt_to_Fetch,									// Halt
	output reg PC_selSrc_to_Fetch,								// PC source selection signal
	
	output reg Cin_to_Ex, invA_to_Ex, invB_to_Ex, sign_to_Ex,	// ALU select signals
	output reg [1:0] PC_Add_to_Ex, second_operand_to_Ex,		// PC_Add and second_operand sent to Ex stage
	output reg [2:0] ALU_op_to_Ex,								// ALU operation signal
	output reg ALU_Zero_to_WB, ALU_Ofl_to_WB,					// ALU Sign/Ofl flags
	output reg [15:0] ALU_Out_to_Mem, ALU_Out_to_WB,			// Output from Ex stage to Mem stage
	output reg [15:0] InA_to_Ex, InB_to_Ex, 					// Inputs to Ex stage
	output reg [15:0] imm_to_Ex,
	
	output reg MEM_En_to_Mem,									// Memory enable signal
	output reg MEM_writeEn_to_Mem,								// Memory write enable signal
	
	output reg [15:0] MEM_ex_result_to_WB,						// Execute stage result, but from memory
	output reg [15:0] MEM_data_out_to_WB,						// Data memory read result
	
	output reg Mux_MtoReg_to_WB,								// Write-back MUX signal 
		
	// Signals that are not pipelined
	output cd_to_Fetch											// Createdump to Fetch stage

	);
	
	reg pause_IF_ID, pause_ID_Ex, pause_Ex_Mem, pause_Mem_WB;	// Used to pause different pipeline modules
	
	reg PC_selSrc_to_Ex;
	reg cd_to_Ex;
	
	reg MEM_En_to_Ex, MEM_writeEn_to_Ex;
	
	reg ALU_Zero_to_Mem;										// ALU_Zero signals 
	reg ALU_Ofl_to_Mem;											// ALU_Ofl signals
	
	reg halt_to_Ex, halt_to_Mem, halt_to_WB;
	
	reg Mux_MtoREg_to_Ex, Mux_MtoREg_to_Mem;
	
	// Registers to hold register addresses (one bit more to distinguish whether they exist or not)
	reg [3:0] IF_ID_Rd, ID_EX_Rd, EX_MEM_Rd;
	reg [3:0] IF_ID_Rs, ID_EX_Rs, EX_MEM_Rs;
	reg [3:0] IF_ID_Rt, ID_EX_Rt, EX_MEM_Rt;
	
	// Signal pipelines
	always @(posedge clk, posedge rst) begin
		
		case (rst)

			1'b1:	begin
			
				pc_to_Dec 				<= 16'h0000	;
				pc_to_Ex 				<= 16'h0000	;
				pc_to_Fetch 			<= 16'h0000	;
				instr_to_Dec 			<= 16'h0000	;				
				cd_to_Mem				<= 1'b0		;							
				halt_to_Fetch			<= 1'b0		;		
				halt_to_Ex				<= 1'b0		;
				halt_to_Mem				<= 1'b0		;
				halt_to_WB				<= 1'b0		;
				PC_selSrc_to_Fetch		<= 1'b0		;					
		
				Cin_to_Ex				<= 1'b0		;
				invA_to_Ex				<= 1'b0		;
				invB_to_Ex				<= 1'b0		;
				sign_to_Ex				<= 1'b0		;	
				PC_Add_to_Ex			<= 2'b00	;
				second_operand_to_Ex	<= 2'b00	;		
				ALU_op_to_Ex			<= 3'b000	;										
				ALU_Out_to_Mem			<= 16'h0000	;	
				ALU_Out_to_WB			<= 16'h0000	;				
		
				MEM_En_to_Mem			<= 1'b0		;								
				MEM_writeEn_to_Mem		<= 1'b0		;								
		
				MEM_ex_result_to_WB		<= 16'h0000	;						
				MEM_data_out_to_WB		<= 16'h0000	;					
		
				Mux_MtoREg_to_Ex		<= 1'b0		;
				Mux_MtoREg_to_Mem		<= 1'b0		;			
				Mux_MtoReg_to_WB		<= 1'b0		;
				
				PC_selSrc_to_Ex			<= 1'b0		;
				cd_to_Ex				<= 1'b0		;
				MEM_En_to_Ex			<= 1'b0		;
				MEM_writeEn_to_Ex		<= 1'b0		;
				ALU_Zero_to_Mem			<= 1'b0		;
				ALU_Zero_to_WB			<= 1'b0		;
				ALU_Ofl_to_Mem			<= 1'b0		;
				ALU_Ofl_to_WB			<= 1'b0		;
				
				InA_to_Ex				<= 16'h0000	;
				InB_to_Ex				<= 16'h0000	;
			
			end
			
			1'b0:	begin
			
				// IF/ID
				pc_to_Dec 				<= pc_Fetch				;
				instr_to_Dec 			<= instr_2ID			;
				
				// ID/EX
				pc_to_Ex				<= pc_to_Dec			;
				halt_to_Ex 				<= halt					;
				PC_selSrc_to_Ex			<= PC_selSrc			;
				cd_to_Ex				<= createdump			;
				Cin_to_Ex				<= Cin					;
				invA_to_Ex				<= invA					;
				invB_to_Ex				<= invB					;
				sign_to_Ex				<= sign					;
				PC_Add_to_Ex			<= PC_Add				;
				second_operand_to_Ex	<= second_operand		;
				ALU_op_to_Ex			<= ALU_op				;
				MEM_En_to_Ex			<= MEM_En				;
				MEM_writeEn_to_Ex		<= MEM_writeEn			;
				Mux_MtoREg_to_Ex		<= Mux_MtoReg			;
				InA_to_Ex				<= InA					;
				InB_to_Ex				<= InB					;
				imm_to_Ex				<= imm					;
				
				// EX/MEM
				cd_to_Mem				<= cd_to_Ex				;
				halt_to_Mem				<= halt_to_Ex			;
				ALU_Out_to_Mem			<= ALU_Out				;
				ALU_Zero_to_Mem			<= ALU_Zero				;
				ALU_Ofl_to_Mem			<= ALU_Ofl				;
				MEM_En_to_Mem			<= MEM_En_to_Ex			;
				MEM_writeEn_to_Mem		<= MEM_writeEn_to_Ex	;
				Mux_MtoREg_to_Mem		<= Mux_MtoREg_to_Ex		;
				
				// MEM/WB
				MEM_ex_result_to_WB		<= MEM_ex_result		;
				MEM_data_out_to_WB		<= MEM_data_out			;
				Mux_MtoReg_to_WB		<= Mux_MtoREg_to_Mem	;
				ALU_Out_to_WB			<= ALU_Out_to_Mem		;
				ALU_Zero_to_WB			<= ALU_Zero_to_Mem		;
				ALU_Ofl_to_WB			<= ALU_Ofl_to_Mem		;
				halt_to_WB				<= halt_to_Mem			;
				
			
			end
		
			default:	begin
			
				pc_to_Dec 				<= 16'h0000	;
				pc_to_Ex 				<= 16'h0000	;
				pc_to_Fetch 			<= 16'h0000	;
				instr_to_Dec 			<= 16'h0000	;				
				cd_to_Mem				<= 1'b0		;							
				halt_to_Fetch			<= 1'b0		;		
				halt_to_Ex				<= 1'b0		;
				halt_to_Mem				<= 1'b0		;
				halt_to_WB				<= 1'b0		;
				PC_selSrc_to_Fetch		<= 1'b0		;					
		
				Cin_to_Ex				<= 1'b0		;
				invA_to_Ex				<= 1'b0		;
				invB_to_Ex				<= 1'b0		;
				sign_to_Ex				<= 1'b0		;	
				PC_Add_to_Ex			<= 2'b00	;
				second_operand_to_Ex	<= 2'b00	;		
				ALU_op_to_Ex			<= 3'b000	;									
				ALU_Out_to_Mem			<= 16'h0000	;							
		
				MEM_En_to_Mem			<= 1'b0		;								
				MEM_writeEn_to_Mem		<= 1'b0		;								
		
				MEM_ex_result_to_WB		<= 16'h0000	;						
				MEM_data_out_to_WB		<= 16'h0000	;					
		
				Mux_MtoREg_to_Ex		<= 1'b0		;
				Mux_MtoREg_to_Mem		<= 1'b0		;			
				Mux_MtoReg_to_WB		<= 1'b0		;
				
				PC_selSrc_to_Ex			<= 1'b0		;
				cd_to_Ex				<= 1'b0		;
				MEM_En_to_Ex			<= 1'b0		;
				MEM_writeEn_to_Ex		<= 1'b0		;
				ALU_Zero_to_Mem			<= 1'b0		;
				ALU_Zero_to_WB			<= 1'b0		;
				ALU_Ofl_to_Mem			<= 1'b0		;
				ALU_Ofl_to_WB			<= 1'b0		;
				
				InA_to_Ex				<= 16'h0000	;
				InB_to_Ex				<= 16'h0000	;
				imm_to_Ex				<= 16'h0000	;
			
			end
		
		endcase
	
	end
	
	// Register address extraction
	always@(*) begin
	
		case(instr_2ID[15: 11])
		
			// J-Type
			00000, 00001, 00100, 00110, 00010, 00011	:	begin
			
				IF_ID_Rd = 4'hF;
				IF_ID_Rs = 4'hF;
				IF_ID_Rt = 4'hF;
			
			end
			
			// I-Type 1
			01000, 01001, 01010, 01011, 10100, 10101, 10110, 10111, 10000, 10001, 10011	:	begin
			
				IF_ID_Rd = instr_2ID[7:5];
				IF_ID_Rs = instr_2ID[10:8];
				IF_ID_Rt = 4'hF;
			
			end
			
			// I-Type 2
			01100, 01101, 01110, 01111, 11000, 10010, 00101, 00111	:	begin
			
				IF_ID_Rd = 4'hF;
				IF_ID_Rs = instr_2ID[10:8];
				IF_ID_Rt = 4'hF;
			
			end
			
			// R-Type
			11011, 11010, 11100, 11101, 11110, 11111	:	begin
			
				IF_ID_Rd = instr_2ID[4:2];
				IF_ID_Rs = instr_2ID[10:8];
				IF_ID_Rt = instr_2ID[7:5];
			
			end
			
			// Special
			11001	:	begin
				
				IF_ID_Rd = instr_2ID[4:2];
				IF_ID_Rs = instr_2ID[10:8];
				IF_ID_Rt = 4'hF;
				
			end
			
			default	:	begin
			
				IF_ID_Rd = 4'hF;
				IF_ID_Rs = 4'hF;
				IF_ID_Rt = 4'hF;
			
			end
		
		endcase
	
	end
	
	// Register address pipeline_ctrl
	always@(posedge clk, posedge rst) begin

		case (rst)

			1'b1:	begin
			
				ID_EX_Rd <= 4'hF;
				ID_EX_Rs <= 4'hF;
				ID_EX_Rt <= 4'hF;
				
				EX_MEM_Rd <= 4'hF;
				EX_MEM_Rs <= 4'hF;
				EX_MEM_Rt <= 4'hF;
			
			end
			
			1'b0:	begin
			
				ID_EX_Rd <= IF_ID_Rd;
				EX_MEM_Rd <= ID_EX_Rd;
				
				ID_EX_Rs <= IF_ID_Rs;
				EX_MEM_Rs <= ID_EX_Rs;
				
				ID_EX_Rt <= IF_ID_Rt;
				EX_MEM_Rt <= ID_EX_Rt;
			
			end
		
			default:	begin
			
				ID_EX_Rd <= 4'hF;
				ID_EX_Rs <= 4'hF;
				ID_EX_Rt <= 4'hF;
				
				EX_MEM_Rd <= 4'hF;
				EX_MEM_Rs <= 4'hF;
				EX_MEM_Rt <= 4'hF;
			
			end
		
		endcase
	
	end
	
	// Pause signal (used to pause the entire pipeline)
	always@(posedge clk, posedge rst) begin
	
		case (rst)

			1'b1:	begin
			
				pause_IF_ID 	<= 1'b0;
				pause_ID_Ex 	<= 1'b0;
				pause_Ex_Mem 	<= 1'b0;
				pause_Mem_WB 	<= 1'b0;
			
			end
			
			1'b0:	begin
			
				
			
			end
		
			default:	begin
			
			end
		
		endcase
	
	end
	
	assign cd_to_Fetch = createdump;
	
endmodule