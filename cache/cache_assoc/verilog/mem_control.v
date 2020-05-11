module mem_control(
 input clk,    
 input rst,    
 //input from outsi
 input Wr,    
 input Rd,    

 input [2:0] offset_in,
// state of Cache 
 input C_hit,    
 input C_dirty,    
 input C_valid,    
// sate of Mem
 input [3:0] M_busy,     
 input M_stall,
 input [1:0] Mbank,    
//Cache Control
 output reg C_comp,     
 output reg C_write,     
 output  C_valid_in,     
//mem control 
 output reg M_wr,     
 output reg M_rd,     
 output reg sel_M_datain,     
 output reg sel_addr,     
 output reg true_hit,     
 output reg done,
 output reg C_stall ,
 output reg sel_C_Data_in ,
 //output reg sel_M_addr,
 output reg [2:0] M_offset, 
 output reg [2:0] C_offset, 
 output reg MR_addr,
 output reg FSM_state


	);

	wire[4:0] state_nxt_in;
	wire [4:0]state;
	reg [4:0] nxt_state;
	reg Miss;


	localparam IDLE = 0, WDATA =1, WBANK0 =2,WBANK1 = 3, WBANK2 = 4, WBANK3 = 5, WCACHE=6, WVALID=7;
	localparam RDATA = 11, RBANK0 = 12,RBANK1 = 13,RBANK2 = 14, RBANK3= 15,RFINISH=16, RFINAL=17,RCACHE = 18;

	//assign true_hit= (C_hit & C_valid)&Miss;//only when it is hit and valid;
	assign C_valid_in = 1'b1; // when compare =0?


	assign state_nxt_in = M_stall? state :  nxt_state;

	dff state_f0(.q(state[0]), .d(state_nxt_in[0]), .clk(clk), .rst(rst));
	dff state_f1(.q(state[1]), .d(state_nxt_in[1]), .clk(clk), .rst(rst));
	dff state_f2(.q(state[2]), .d(state_nxt_in[2]), .clk(clk), .rst(rst));
	dff state_f3(.q(state[3]), .d(state_nxt_in[3]), .clk(clk), .rst(rst));
	dff state_f4(.q(state[4]), .d(state_nxt_in[4]), .clk(clk), .rst(rst));




	always @(*) begin 
		C_comp = 1'b0;  // compare default on 
		C_write =1'b0;
		C_stall = 1'b0;
		M_wr= 1'b0;    // memory read
		M_rd= 1'b0;		// memory write 
		sel_M_datain= 1'b0;
		sel_addr= 1'b0;    // the address default from input(otherwise from cache tagout)
		sel_C_Data_in = 1'b0;
		FSM_state = 1'b0;
	//	true_hit = 1'b0;
		M_offset = offset_in;
		C_offset = offset_in;
		true_hit = 1'b0;
		
	    done = 1'b0;
		nxt_state = IDLE; 
		MR_addr = 0;   


		case(state)
		IDLE:begin   //0
		//nxt_state = Wr? WDATA : Rd? RDATA : IDLE;
		FSM_state =1'b1;
		C_comp = 1'b1;
		C_stall = Wr|Rd;
		C_write = Wr;
		true_hit= (C_hit & C_valid)&(Wr|Rd);
		done = (C_hit & C_valid)&(Wr|Rd);
		nxt_state = (Wr|Rd) ? ((C_hit & C_valid)? IDLE : ((C_valid)&C_dirty? WBANK0 : RBANK0 ) ):IDLE;
				  

		end


		WDATA: begin  // 1 just update the cache
		C_comp = 1'b1;  // set valid bit to 1
		C_stall = 1'b1;
		C_write = 1'b1;
		//nxt_state = (~C_hit)&C_valid&C_dirty ? WBANK0: IDLE; // if not hit but valid, need to write back first
		nxt_state = (C_valid&(~C_hit)&C_dirty)? WBANK0:  // need to write back
					(C_valid&(~C_hit)&(~C_dirty))? RBANK0:
					((~C_valid)) ?  RBANK0 :      //read first
					IDLE;

		true_hit= (C_hit & C_valid);


		done =(C_valid&(~C_hit)&C_dirty)? 1'b0:  // need to write back
			  ((~C_valid)) ?  1'b0:      //read first
			  1'b1;

		//true_hit =(~C_hit)&C_valid&C_dirty ? 1'b0: 1'b1;
		end

		
		RDATA: begin  //11
		C_comp = 1'b1;
		C_write = 1'b0;
		nxt_state = (C_valid&C_hit)? IDLE : 
					(C_valid& C_dirty)?      WBANK0:
					RBANK0;
		done = (C_valid&C_hit)? 1'b1 :1'b0;
		true_hit= (C_hit & C_valid);
		//true_hit = (C_valid&C_hit)? 1'b1 :1'b0;
		C_stall= 1'b1;
		//sel_addr = (C_valid&C_hit)? 0 : 1;
		end


		WBANK0: begin  // start write back to  bank0
		C_stall = 1'b1;
		C_offset = 3'b000;
		C_write = 1'b0;

		M_offset = 3'b000;
		M_wr = 1'b1;

		sel_addr = 1'b1;
		sel_M_datain = 1'b0;
		nxt_state = WBANK1;
		end

		WBANK1: begin //start write back to bank1
		C_stall = 1'b1;
		M_offset = 3'b010;
		sel_addr = 1'b1;
		C_offset = 3'b010;
		nxt_state = WBANK2;
		sel_M_datain = 1'b0;
		M_wr = 1'b1;
		end

		WBANK2: begin // start Wb to bank2
		C_stall = 1'b1;
		M_offset = 3'b100;
		C_offset = 3'b100;
		sel_addr = 1'b1;
		nxt_state = WBANK3;
		sel_M_datain = 1'b0;
		M_wr = 1'b1;
		end

		WBANK3:	begin // start wb to bank3
		Miss = 1'b0;
		C_stall = 1'b1;
		M_offset = 3'b110;
		sel_addr = 1'b1;  // the address is the tag out of the cache
		M_wr = 1'b1;
		C_offset = 3'b110;
		sel_M_datain = 1'b0;
		nxt_state = RBANK0;
		end


		RBANK0:begin 
		Miss = 1'b0;
		C_stall = 1'b1;
		sel_addr = 1'b0;
		MR_addr = 1'b1;
		M_offset = 3'b000;
		M_rd = 1'b1;
		nxt_state = RBANK1;
		end
		
		RBANK1:begin 
		C_stall = 1'b1;
		sel_addr = 1'b0;
		MR_addr = 1'b1;
		M_offset = 3'b010;
		M_rd = 1'b1;
		nxt_state = RBANK2;
		C_write = 1'b1;

		//C_comp = 1'b1;

		end
		
		RBANK2:begin 
		C_stall = 1'b1;
		sel_addr = 1'b0;
		MR_addr = 1'b1;
		M_offset = 3'b100;
		M_rd = 1'b1;
		nxt_state = RBANK3;
		// bank0 read finish
		C_offset = 3'b000;
		C_write = 1'b1;
		C_comp = 1'b0;
		sel_C_Data_in = 1'b1; // choose the source of cache data in 

		end
		
		RBANK3:begin 
		C_stall = 1'b1;
		MR_addr = 1'b1;
		sel_addr = 1'b0;
		
		M_offset = 3'b110;   // memory read offset 
		M_rd = 1'b1;
		nxt_state = RFINISH;

		C_offset = 3'b010; // bank1 read finish 
		C_write = 1'b1;
		C_comp = 1'b0;
		sel_C_Data_in = 1'b1; // choose the source of cache data from cache  
		end

		RFINISH:begin // write valid data  to cache BANK2 read finish
		C_stall = 1'b1;  //set valid bit to 1;  
		nxt_state= RFINAL;
		C_offset = 3'b100; //  bank 2 read finish
		C_write = 1'b1;
		C_comp = 1'b0;
		sel_C_Data_in = 1'b1; // choose the source of cache data in 
		
	//	MR_addr = 1'b1;
	//	M_offset = offset_in;
	//	M_rd = 1'b1;
		end

		RFINAL:begin  //17 BANK3 read finish 
		C_stall = 1'b1;
		C_offset = 3'b110; //  bank 3 read finish
		C_write = 1'b1;
		C_comp = 1'b0;
		sel_C_Data_in = 1'b1; // choose the source of cache data in `
		nxt_state =  Wr? WCACHE : RCACHE;
		end

		WCACHE:begin   
		C_comp = 1'b1;  // set write dirty =1;
		C_stall = 1'b1;
		C_write = 1'b1;
		nxt_state = IDLE;
		done = 1'b1;

		end

		RCACHE:begin 
		C_stall = 1'b1;
		C_write = 1'b0;
		C_comp = 1'b1;
		done = 1'b1;
		nxt_state = IDLE;

		end

		default : nxt_state = IDLE;




		endcase // state
	
	end


endmodule