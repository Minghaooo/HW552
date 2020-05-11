/*
   CS/ECE 552 Spring '20
  
   Filename        : memory.v
   Description     : This module contains all components in the Memory stage of the 
                     processor.
*/
module memory (

	input clk,
	input rst,

	input [15:0] addr, 
	input [15:0] data_in, //write data Rd

	input wr, 
	input enable,
	input createdump,

	output [15:0] data_out,	// read data
	output [15:0] addr_2WB,	// write the EX result to the register directly
	
	output mem_err,			// Error from memory stage
	
	output d_mem_done, d_mem_stall

	);

wire [15:0] addrin;

assign addrin = enable? addr : 16'h0000;
	// this is the MEM_stage

	//memory module 
	/*memory2c D_MEM(
		.data_in(data_in),
		.addr(addr),
		.enable(enable), //enable read & write set to 1 
		.clk(clk), 
		.rst(rst), // rst_h
		.createdump(createdump),  // dump out the memory to file
		.data_out(data_out),
		.wr(wr)
	);*/
	/*
	memory2c_align D_MEM(
		.data_in(data_in),
		.addr(addr),
		.enable(enable), //enable read & write set to 1 
		.clk(clk), 
		.rst(rst), // rst_h
		.createdump(createdump),  // dump out the memory to file
		.data_out(data_out),
		.wr(wr),
		.err(mem_err)
	);*/
	
	wire D_MEM_Hit;
	parameter mem_type = 1;
	mem_system #(1) D_MEM(
	//stallmem D_MEM(
		.clk(clk),
		.rst(rst),
		.DataIn(data_in),
		.DataOut(data_out),
		.Addr(addrin), 
		.err(/*mem_err*/),
		.createdump(createdump),
		.Rd(enable & ~wr),
		.Wr(enable & wr),
		.Stall(d_mem_stall),
		.Done(d_mem_done),
		.CacheHit(D_MEM_Hit)
	);
   
   assign addr_2WB = addr;
   
endmodule
