module left_rotator(In, Cnt, Out);
	
	input [15:0] In;
	input [3:0] Cnt;
	output [15:0] Out;
	
	wire [15:0] left_Rot;

	assign left_Rot = 	(Cnt == 4'd0)	?	In						:
						(Cnt == 4'd1)	?	{In[14:0], In[15]}		:
						(Cnt == 4'd2)	?	{In[13:0], In[15:14]}	:
						(Cnt == 4'd3)	?	{In[12:0], In[15:13]}	:
						(Cnt == 4'd4)	?	{In[11:0], In[15:12]}	:
						(Cnt == 4'd5)	?	{In[10:0], In[15:11]}	:
						(Cnt == 4'd6)	?	{In[9:0], In[15:10]}	:
						(Cnt == 4'd7)	?	{In[8:0], In[15:9]}		:
						(Cnt == 4'd8)	?	{In[7:0], In[15:8]}		:
						(Cnt == 4'd9)	?	{In[6:0], In[15:7]}		:
						(Cnt == 4'd10)	?	{In[5:0], In[15:6]}		:
						(Cnt == 4'd11)	?	{In[4:0], In[15:5]}		:
						(Cnt == 4'd12)	?	{In[3:0], In[15:4]}		:
						(Cnt == 4'd13)	?	{In[2:0], In[15:3]}		:
						(Cnt == 4'd14)	?	{In[1:0], In[15:2]}		:
						(Cnt == 4'd15)	?	{In[0], In[15:1]}		:
						In;

	assign Out = left_Rot;

endmodule
