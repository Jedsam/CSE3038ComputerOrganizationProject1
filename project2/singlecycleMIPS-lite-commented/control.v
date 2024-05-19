// control.v: Added support for the ori and bltzal instruction
module control(in, regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, ori,bltzal);
input [5:0] in;
output regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, ori,bltzal;
wire rformat, lw, sw, beq;

assign rformat = ~|in;
assign lw = in[5] & (~in[4]) & (~in[3]) & (~in[2]) & in[1] & in[0];
assign sw = in[5] & (~in[4]) & in[3] & (~in[2]) & in[1] & in[0];
assign beq = ~in[5] & (~in[4]) & (~in[3]) & in[2] & (~in[1]) & (~in[0]);
assign ori = (in == 6'b001101);  // as opcode is 13 
assign bltzal = (in == 6'b100010);  // as opcode is 34

assign regdest = rformat;
assign alusrc = lw | sw | ori | bltzal;
assign memtoreg = lw;
assign regwrite = rformat | lw | ori;
assign memread = lw;
assign memwrite = sw;
assign branch = beq | bltzal;
assign aluop1 = rformat | ori;  // ori uses a different ALU operation
assign aluop2 = beq;
endmodule
