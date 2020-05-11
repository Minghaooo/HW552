// Rotate In by Cnt digits. Direction indicated by Left.
module rotator(In, Cnt, Left, Out);
	
	input [15:0] In;
	input [3:0] Cnt;
	input Left;
	output [15:0] Out;

	reg [3:0] Rot_Cnt;

	wire [15:0] left_Rot, right_Rot;

	assign left_Rot = 	(Cnt == 4'd0)	?	In	:
						(Cnt == 4'd1)	?	{In[14:0], In[15]}	:
						(Cnt == 4'd2)	?	{In[13:0], In[15:14]}	:
						(Cnt == 4'd3)	?	{In[12:0], In[15:13]}	:
						(Cnt == 4'd4)	?	{In[11:0], In[15:12]}	:
						(Cnt == 4'd5)	?	{In[10:0], In[15:11]}	:
						(Cnt == 4'd6)	?	{In[9:0], In[15:10]}	:
						(Cnt == 4'd7)	?	{In[8:0], In[15:9]}	:
						(Cnt == 4'd8)	?	{In[7:0], In[15:8]}	:
						(Cnt == 4'd9)	?	{In[6:0], In[15:7]}	:
						(Cnt == 4'd10)	?	{In[5:0], In[15:6]}	:
						(Cnt == 4'd11)	?	{In[4:0], In[15:5]}	:
						(Cnt == 4'd12)	?	{In[3:0], In[15:4]}	:
						(Cnt == 4'd13)	?	{In[2:0], In[15:3]}	:
						(Cnt == 4'd14)	?	{In[1:0], In[15:2]}	:
						(Cnt == 4'd15)	?	{In[0], In[15:1]}	:
						In;

	assign right_Rot = 	(Cnt == 4'd0)	?	In	:
						(Cnt == 4'd1)	?	{In[0], In[15:1]}	:
						(Cnt == 4'd2)	?	{In[1:0], In[15:2]}	:
						(Cnt == 4'd3)	?	{In[2:0], In[15:3]}	:
						(Cnt == 4'd4)	?	{In[3:0], In[15:4]}	:
						(Cnt == 4'd5)	?	{In[4:0], In[15:5]}	:
						(Cnt == 4'd6)	?	{In[5:0], In[15:6]}	:
						(Cnt == 4'd7)	?	{In[6:0], In[15:7]}	:
						(Cnt == 4'd8)	?	{In[7:0], In[15:8]}	:
						(Cnt == 4'd9)	?	{In[8:0], In[15:9]}	:
						(Cnt == 4'd10)	?	{In[9:0], In[15:10]}	:
						(Cnt == 4'd11)	?	{In[10:0], In[15:11]}:
						(Cnt == 4'd12)	?	{In[11:0], In[15:12]}	:
						(Cnt == 4'd13)	?	{In[12:0], In[15:13]}	:
						(Cnt == 4'd14)	?	{In[13:0], In[15:14]}	:
						(Cnt == 4'd15)	?	{In[14:0], In[15]}	:
						In;

	assign Out = (Left == 1'b1)? left_Rot	:	right_Rot;

endmodule
