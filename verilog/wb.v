/*
   CS/ECE 552 Spring '20
  
   Filename        : wb.v
   Description     : This is the module for the overall Write Back stage of the processor.
*/
module wb (data_ALU, data_MEM, data_toReg, Mux_MtoReg);

	input 	[15:0]	data_MEM;
	input 			Mux_MtoReg;

	output 	[15:0]	data_toReg;
	input 	[15:0]  data_ALU;

	assign data_toReg = (Mux_MtoReg == 1'b1) ?  data_MEM : data_ALU ;
	
endmodule
