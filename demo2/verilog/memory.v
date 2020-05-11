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
	input [15:0] data_in, //write data

	input wr, 
	input enable,
	input createdump,

	output [15:0] data_out,// read data
	output [15:0] addr_2WB// write the EX result to the register directly

	);


	// this is the MEM_stage

	//memory module 
	memory2c D_MEM(
		.data_in(data_in),
		.addr(addr),
		.enable(enable), //enable read & write set to 1 
		.clk(clk), 
		.rst(rst), // rst_h
		.createdump(createdump),  // dump out the memory to file
		.data_out(data_out),
		.wr(wr)
	);
   
   assign addr_2WB = addr;
   
endmodule
