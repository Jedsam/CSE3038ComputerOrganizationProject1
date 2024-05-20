//Added support for the ori, bltzal and jmnor instruction
module control(in, regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, ori,bltzal, jmnor);
input [5:0] in;
output regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, ori,bltzal, jmnor;
wire rformat, lw, sw, beq;

assign rformat = ~|in;
assign lw = in[5] & (~in[4]) & (~in[3]) & (~in[2]) & in[1] & in[0];
assign sw = in[5] & (~in[4]) & in[3] & (~in[2]) & in[1] & in[0];
assign beq = ~in[5] & (~in[4]) & (~in[3]) & in[2] & (~in[1]) & (~in[0]);
assign ori = (in == 6'b001101);  // as opcode is 13 
assign bltzal = (in == 6'b100010);  // as opcode is 34

//im hoping this is right:
assign jmnor = rformat & (in[5:0] == 6'b100101); // funct code 37

assign regdest = rformat; //do we have to make this conditional for different instructions?

assign alusrc = lw | sw | ori | bltzal;

assign jump = jmnor //

//FIX THIS JUMP


//and the rest..
assign memtoreg = lw;
assign regwrite = rformat | lw | ori;
assign memread = lw;
assign memwrite = sw;
assign branch = beq | bltzal | jmnor;
assign aluop1 = rformat | ori;  // ori uses a different ALU operation
assign aluop2 = beq;
endmodule
