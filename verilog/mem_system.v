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

    wire [15:0] C_data_out0;
    wire [15:0] C_data_out1;
    wire [4:0] tag_out0;
    wire [4:0] tag_out1;

    wire [3:0] M_busy;

   wire Wr_ff, Rd_ff;
   wire [15:0]Addr_ff,DataIn_ff,C_data_in;
   wire [2:0] C_offset;
   wire [2:0] M_offset;
   wire sel_offset;
   wire C_sel, hit0,hit1,C_valid0,C_valid1,C_dirty0,C_dirty1,C_write,C_hit0,C_hit1;
   wire C_sel_nxt,C_sel_ff;
   wire FSM_state;

   dff_16bit ADDRff(.q(Addr_ff), .d(Addr), .clk(clk), .rst(rst));
   dff_16bit DataInff(.q(DataIn_ff), .d(DataIn), .clk(clk), .rst(rst));

   dff WRff (.q(Wr_ff), .d(Wr), .clk(clk), .rst(rst));
   dff RDff (.q(Rd_ff), .d(Rd), .clk(clk), .rst(rst));


   dff VICTIM_FF(.q(victimway), .d(next_victimway), .clk(clk), .rst(rst));
   assign next_victimway = Done ? ~victimway: victimway;

   assign hit0 = (C_hit0 &C_valid0);
   assign hit1 = (C_hit1&C_valid1);

  
   assign C_sel_nxt =(~C_valid0)&(~C_valid1) ? victimway:
                     (hit0)&(~hit1)? 0:  // c0 hit , c1 not hit
                     (hit1)&(~hit0)? 1:   // c1hit , c0 not 
                    //(hit0)&(hit1)&C_dirty0 ? 0:  // c0 c1 hit, then  
                    //          (hit0)&(hit1)&C_dirty1 ? 1:
                     (~hit0)&(~hit1)&(C_valid0)&(~C_valid1)? 1:
                     (~hit0)&(~hit1)&(C_valid1)&(~C_valid0)? 0:
                     victimway;
   // assign C_sel = 1'b0;
   assign C_sel = (FSM_state) ? C_sel_nxt : C_sel_ff;

   assign C_sel_nxt_ff = (Done)? C_sel_ff : C_sel_nxt;

   dff C_Sel_FF(.q(C_sel_ff), .d(C_sel_nxt_ff), .clk(clk), .rst(rst));



   assign C_hit = (C_hit0 &C_valid0)|(C_hit1&C_valid1);
   assign C_valid = C_sel ? C_valid1 : C_valid0;
   assign C_dirty = C_sel ? C_dirty1 : C_dirty0; 
   assign C_write0 = (~C_sel) &(C_write);
   assign C_write1 = (C_sel)&(C_write); 
   


   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (tag_out0),
                          //  When "write"=0, the tag selected by "index" appears on this output. (This value is needed during a writeback.)
                          .data_out             (C_data_out0),
                          .hit                  (C_hit0), // high if tag at  "index" lines matches "tag_in" 
                          .dirty                (C_dirty0),
                          .valid                (C_valid0),
                          .err                  (err_cache0),

                          // Inputs
                          .enable               (enable),  // set to 1
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),

                          .tag_in               (Addr[15:11]), //"comp"=1, compared with stored tags; "comp"=0 and "write"=1 written.

                          .index                (Addr[10:3]), //The address bits used to index into the cache memory.
                          .offset               (C_offset), //  offset[2:1] selects which word to access in the cache line. The least significant bit should be 0 for word alignment. If the least significant bit is 1, it is an error condition.
                          .data_in              (C_data_in),
                          .comp                 (comp),
                          .write                (C_write0),
                          .valid_in             (C_valid_in));


   cache #(2 + memtype) c1(// Outputs
                          .tag_out              (tag_out1), // output of tag
                          .data_out             (C_data_out1),  // out put of data
                          .hit                  (C_hit1),  // out put of hit
                          .dirty                (C_dirty1), // output of dirty
                          .valid                (C_valid1),  //output of valid 
                          .err                  (err_cache1), 
                          // Inputs
                          .enable               (enable),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (Addr[15:11]),
                          .index                (Addr[10:3]),
                          .offset               (C_offset),
                          .data_in              (C_data_in),
                          .comp                 (comp),
                          .write                (C_write1), // write select
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
                     .Wr                (Wr),
                     .Rd                (Rd),
                     .Mbank             (Addr[2:1]),
                     .offset_in         (Addr[2:0]),

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

                     .sel_addr           (sel_M_addr), 
                     .sel_M_datain       (sel_M_datain), //0 write from cache 
                    // .sel_M_addr          (sel_M_addr),
                     .true_hit           (true_hit),


                     .done               (Done),
                     .C_stall (C_stall),
                     .sel_C_Data_in(sel_C_Data_in),
                      .MR_addr(MR_addr),
                      .FSM_state (FSM_state) 


    );





   assign err = (err_mem |err_cache0|err_cache1);
   assign Stall = M_stall|C_stall;
   assign DataOut = C_sel? C_data_out1 :C_data_out0;
   assign CacheHit = true_hit;  // the output is hit and valid 



   assign enable = 1;

   assign M_data_in = sel_M_datain ? DataIn :  (C_sel? C_data_out1 : C_data_out0) ;
      //sel addr =1 , come from cache output //, else come from outside
   assign M_addr = sel_M_addr ? ( C_sel ? {tag_out1,Addr[10:3],M_offset} : {tag_out0,Addr[10:3],M_offset}) : 
                  MR_addr?{Addr[15:3],M_offset}:
                  Addr;
   assign C_data_in = sel_C_Data_in ? M_data_out :DataIn;
   
  
 
   
endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
