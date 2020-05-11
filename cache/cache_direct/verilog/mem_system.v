/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err,
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        Rd;
   input        Wr;
   input        createdump;
   input        clk;
   input        rst;
   
   output [15:0] DataOut;
   output Done;
   output Stall;
   output CacheHit;
   output err;

   //wire[3:0] busy;

    wire [15:0] M_data_in;
    wire [15:0] M_addr ;
    wire [15:0] M_data_out;

    wire [15:0] C_data_out;
    wire [4:0] tag_out;

    wire [3:0] M_busy;

   wire Wr_ff, Rd_ff;
   wire [15:0]Addr_ff,DataIn_ff,C_data_in;
   wire [2:0] C_offset;
   wire [2:0] M_offset;
   wire sel_offset;
   wire [4:0]M_Tag;


   dff_16bit ADDRff(.q(Addr_ff), .d(Addr), .clk(clk), .rst(rst));
   dff_16bit DataInff(.q(DataIn_ff), .d(DataIn), .clk(clk), .rst(rst));

   dff WRff (.q(Wr_ff), .d(Wr), .clk(clk), .rst(rst));
   dff RDff (.q(Rd_ff), .d(Rd), .clk(clk), .rst(rst));

   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out),
                          //  When "write"=0, the tag selected by "index" appears on this output. (This value is needed during a writeback.)
                          .data_out             (DataOut),
                          .hit                  (C_hit), // high if tag at  "index" lines matches "tag_in" 
                          .dirty                (C_dirty),
                          .valid                (C_valid),
                          .err                  (err_cache),

                          // Inputs
                          .enable               (enable),  // set to 1
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),

                          .tag_in               (Addr_ff[15:11]), //"comp"=1, compared with stored tags; "comp"=0 and "write"=1 written.

                          .index                (Addr_ff[10:3]), //The address bits used to index into the cache memory.
                          .offset               (C_offset), //  offset[2:1] selects which word to access in the cache line. The least significant bit should be 0 for word alignment. If the least significant bit is 1, it is an error condition.
                          .data_in              (C_data_in),
                          .comp                 (comp),
                          .write                (C_write),
                          .valid_in             (C_valid_in));

   four_bank_mem mem(// Outputs
                     .data_out          (M_data_out),
                     //Two cycles after rd="1", 
                     //the data at Mem[Addr] will be shown here.
                     
                     .stall             (M_stall),
                      //Is set to high when the operation requested 
                      //at the input cannot be completed because the required bank is busy.

                     .busy              (M_busy),
                     // Shows the current status of each bank. 
                     //High means the bank cannot be accessed.

                     .err               (err_mem),
                     //The error signal is raised on an unaligned access.

                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (M_addr),
                     .data_in           (M_data_in),

                     //When wr="1", the data on DataIn 
                     //will be written to Mem[Addr] four cycles after wr is asserted.
                     .wr                (M_wr),

                     //When rd="1", the DataOut will show the 
                    //value of Mem[Addr] two cycles after rd is asserted.
                     .rd                (M_rd));


   mem_control   Mem_ctrl(
                     .clk               (clk),
                     .rst               (rst),
                    //p[p] .stall             (Stall),

                     //input from outside
                     .Wr                (Wr_ff ),
                     .Rd                (Rd_ff),
                     .Mbank             (Addr_ff[2:1]),
                     .offset_in         (Addr_ff[2:0]),
                     .C_Tag_out          (tag_out),

                    // state of Cache 
                     .C_hit             (C_hit), 
                     .C_dirty           (C_dirty),
                     .C_valid           (C_valid),

                    // sate of Mem
                     .M_busy            (M_busy),
                     .M_stall           (M_stall),   


                    //Cache Control
                     .C_comp            (comp),
                     .C_write           (C_write),
                     .C_valid_in        (C_valid_in),
                     .C_offset           (C_offset),
                    //mem control 
                     .M_wr              (M_wr),
                     .M_rd              (M_rd),
                     .M_offset          (M_offset),

                     .sel_addr         (sel_M_addr), 
                     .sel_M_datain      (sel_M_datain), //0 write from cache 
                    // .sel_M_addr          (sel_M_addr),
                     .true_hit          (true_hit),

                     .sel_data_out      (sel_data_out),  // 0 output the cache. 1 from Mem

                     .done              (Done),
                     .C_stall (C_stall),
                     .sel_C_Data_in(sel_C_Data_in),
                      .M_Tag(M_Tag), 
                      .MR_addr(MR_addr) 


    );





   assign err = (err_mem |err_cache);
   assign Stall = M_stall|C_stall;
   assign DataOut = sel_data_out ?  M_data_out: C_data_out;
   assign CacheHit = true_hit;  // the output is hit and valid 



   assign enable = 1;

   assign M_data_in = sel_M_datain ? DataIn :  DataOut ;
      //sel addr =1 , come from cache output //, else come from outside
   assign M_addr = sel_M_addr ? {tag_out,Addr_ff[10:3],M_offset} : 
                  MR_addr?{Addr_ff[15:3],M_offset}:
                  Addr_ff;
   assign C_data_in = sel_C_Data_in ? M_data_out :DataIn;
   
  
 
   
endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
