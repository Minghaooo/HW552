module IF_ID(
	input clk,
	input rst,
	
	input [15:0] 	pc_2ID,		// output the PC(+2) to ID, EX stage
	input [15:0]	instr_2ID, // output the fetched instruction 
	input IFID_stall, IFID_special_stall,
	input fetch_err,
	
	output if_id_err,

	output 	[15:0] pc_2ID_ff,
	output 	[15:0] instr_2ID_ff,
	
	//output [3:0] Rd_Dec, Rs_Dec, Rt_Dec,
	output reg [3:0] Rd_ff, Rs_ff, Rt_ff,
	output reg [3:0] Rd, Rs, Rt,
	output  Rd_valff, Rs_valff, Rt_valff
	
	);

	wire [15:0] pc_stall, instr_stall;
	
	wire [15:0] instr_2ID_fe;
	 
	wire rst_ff;
	
	dff rst_ff0(.clk(clk), .rst(1'b0), .d(rst), .q(rst_ff));
	
	wire [15:0] instr_input;

	// Instruction to decode stage can have bubbles inserted
	assign instr_2ID_ff = 	(rst_ff)	?	16'h0800	:
							instr_2ID_fe;

	reg Rd_val,Rs_val,Rt_val;

	assign pc_stall = (IFID_stall)?	pc_2ID_ff	:	pc_2ID;
	assign instr_stall = (IFID_special_stall)? instr_2ID_fe	:	(IFID_stall)?	16'h0800	:	instr_2ID;
	//assign instr_stall = (IFID_stall)? 16'h0800	:	(IFID_special_stall ? instr_2ID_fe	:	instr_2ID);
	
	wire fetch_stall;
	assign fetch_stall = (IFID_stall)? if_id_err	:	fetch_stall;
	dff if_id_err_ff(.clk(clk), .rst(rst), .d(fetch_stall), .q(if_id_err));

	// Pipeline PC and instruction that will be passed into decode stage
	dff_16bit  PC_IFID_ff0(.clk(clk), .rst(rst), .d(pc_stall), .q(pc_2ID_ff));
	dff_16bit  instr_IFID_ff0(.clk(clk), .rst(rst), .d(instr_stall), .q(instr_2ID_fe));

	dff Rd_val_ff(.clk(clk), .rst(rst), .d(Rd_val), .q(Rd_valff));
	dff Rs_val_ff(.clk(clk), .rst(rst), .d(Rs_val), .q(Rs_valff));
	dff Rt_val_ff(.clk(clk), .rst(rst), .d(Rt_val), .q(Rt_valff));
	
	// Register address extraction happens at fetch stage
	always@(*) begin
		case(instr_2ID[15: 11])
			// J-Type
			5'b00000, 5'b00001, 5'b00100, 5'b00110, 5'b00010, 5'b00011	:	begin
				Rd = 4'h0;
				Rs = 4'h0;
				Rt = 4'h0;
				Rd_val = 0;
				Rs_val = 0;
				Rt_val = 0;
			end
			
			// I-Type 1
			5'b01000, 5'b01001, 5'b01010, 5'b01011, 5'b10100, 5'b10101, 5'b10110, 5'b10111, 5'b10001	:	begin
				Rd = {1'b1, instr_2ID[7:5]};
				Rs = {1'b1, instr_2ID[10:8]};
				Rt = 4'h0;
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 0;
			end
			
			// I-Type 2
			5'b01100, 5'b01101, 5'b01110, 5'b01111, 5'b00101, 5'b00111	:	begin
				Rd = 4'h0;
				Rs = {1'b1, instr_2ID[10:8]};
				Rt = 4'h0;
				Rd_val = 0;
				Rs_val = 1;
				Rt_val = 0;
			end
			
			// R-Type
			5'b11011, 5'b11010, 5'b11100, 5'b11101, 5'b11110, 5'b11111	:	begin
				Rd = {1'b1, instr_2ID[4:2]};
				Rs = {1'b1, instr_2ID[10:8]};
				Rt = {1'b1, instr_2ID[7:5]};
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 1;
			end
			
			// Special Cases LBI
			5'b11000:	begin
				Rd = {1'b1, instr_2ID[10:8]};
				Rs = 4'h0;
				Rt = 4'h0;
				Rd_val = 1'b1;
				Rs_val = 1'b0;
				Rt_val = 1'b0;
			end

			// Special Case SLBI
			5'b10010	:	begin
				Rd = {1'b1, instr_2ID[10:8]};
				Rs = {1'b1, instr_2ID[10:8]};
				Rt = 4'h0;
				Rd_val = 1'b1;
				Rs_val = 1'b1;
				Rt_val = 1'b0;
			end
			
			// Special Case BTR
			5'b11001	:	begin
				Rd = {1'b1, instr_2ID[4:2]};
				Rs = {1'b1, instr_2ID[10:8]};
				Rt = 4'h0;
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 0;
			end

			// Special Case ST
			5'b10000	:	begin
				Rd = 4'h0;
				Rs = {1'b1, instr_2ID[7:5]};
				Rt = {1'b1, instr_2ID[10:8]};
				Rd_val = 0;
				Rs_val = 1;
				Rt_val = 1;
			end

			// Special Case STU
			5'b10011	:	begin
				Rd = {1'b1, instr_2ID[10:8]};
				Rs = {1'b1, instr_2ID[7:5]};
				Rt = {1'b1, instr_2ID[10:8]};
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 1;
			end
			
			default	:	begin
				Rd = 4'h0;
				Rs = 4'h0;
				Rt = 4'h0;
				Rd_val = 0;
				Rs_val = 0;
				Rt_val = 0;
			end
		endcase
	end

	// Register address checked again at decode stage, it is independent of initial instructions and is prone to bubbles
	always@(*) begin
		case(instr_2ID_ff[15: 11])
			// J-Type
			5'b00000, 5'b00001, 5'b00100, 5'b00110, 5'b00010, 5'b00011	:	begin
				Rd_ff = 4'h0;
				Rs_ff = 4'h0;
				Rt_ff = 4'h0;
				Rd_val = 0;
				Rs_val = 0;
				Rt_val = 0;
			end
			
			// I-Type 1
			5'b01000, 5'b01001, 5'b01010, 5'b01011, 5'b10100, 5'b10101, 5'b10110, 5'b10111, 5'b10001	:	begin
				Rd_ff = {1'b1, instr_2ID_ff[7:5]};
				Rs_ff = {1'b1, instr_2ID_ff[10:8]};
				Rt_ff = 4'h0;
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 0;
			end
			
			// I-Type 2
			5'b01100, 5'b01101, 5'b01110, 5'b01111, 5'b00101, 5'b00111	:	begin
				Rd_ff = 4'h0;
				Rs_ff = {1'b1, instr_2ID_ff[10:8]};
				Rt_ff = 4'h0;
				Rd_val = 0;
				Rs_val = 1;
				Rt_val = 0;
			end
			
			// R-Type
			5'b11011, 5'b11010, 5'b11100, 5'b11101, 5'b11110, 5'b11111	:	begin
				Rd_ff = {1'b1, instr_2ID_ff[4:2]};
				Rs_ff = {1'b1, instr_2ID_ff[10:8]};
				Rt_ff = {1'b1, instr_2ID_ff[7:5]};
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 1;
			end
			
			// Special Cases LBI
			5'b11000:	begin
				Rd_ff = {1'b1, instr_2ID_ff[10:8]};
				Rs_ff = 4'h0;
				Rt_ff = 4'h0;
				Rd_val = 1'b1;
				Rs_val = 1'b0;
				Rt_val = 1'b0;
			end

			// Special Case SLBI
			5'b10010	:	begin
				Rd_ff = {1'b1, instr_2ID_ff[10:8]};
				Rs_ff = {1'b1, instr_2ID_ff[10:8]};
				Rt_ff = 4'h0;
				Rd_val = 1'b1;
				Rs_val = 1'b1;
				Rt_val = 1'b0;
			end

			// Special Case ST
			5'b10000	:	begin
				Rd_ff = 4'h0;
				Rs_ff = {1'b1, instr_2ID_ff[7:5]};
				Rt_ff = {1'b1, instr_2ID_ff[10:8]};
				Rd_val = 0;
				Rs_val = 1;
				Rt_val = 1;
			end

			// Special Case STU 
			5'b10011	:	begin
				Rd_ff = {1'b1, instr_2ID_ff[10:8]};
				Rs_ff = {1'b1, instr_2ID_ff[7:5]};
				Rt_ff = {1'b1, instr_2ID_ff[10:8]};
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 1;
			end
			
			// Special BTR
			5'b11001	:	begin
				Rd_ff = {1'b1, instr_2ID_ff[4:2]};
				Rs_ff = {1'b1, instr_2ID_ff[10:8]};
				Rt_ff = 4'h0;
				Rd_val = 1;
				Rs_val = 1;
				Rt_val = 0;
			end
			
			default	:	begin
				Rd_ff = 4'h0;
				Rs_ff = 4'h0;
				Rt_ff = 4'h0;
				Rd_val = 0;
				Rs_val = 0;
				Rt_val = 0;
			end
		endcase
	end

endmodule