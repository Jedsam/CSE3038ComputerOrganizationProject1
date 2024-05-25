// control.v: Added support for the ori and bltzal instruction
module control(in, regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, jump, ori, bltzal, jspal, baln);
input [5:0] in;
output regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, jump, ori, bltzal, jspal, baln;
wire rformat, lw, sw, beq;
wire [5:0] inst_var;

assign inst_var = {in[5], in[4], in[3],  in[2],  in[1],  in[0]};
assign rformat = ~|in;
assign lw = inst_var[0] & (~inst_var[1]) & (~inst_var[2]) & (~inst_var[3]) & inst_var[4] & inst_var[5];
assign sw = inst_var[0] & (~inst_var[1]) & inst_var[2] & (~inst_var[3]) & inst_var[4] & inst_var[5];
assign beq = ~inst_var[0] & (~inst_var[1]) & (~inst_var[2]) & inst_var[3] & (~inst_var[4]) & (~inst_var[5]);

assign jump = (inst_var == 6'b000010); // opcode 2
assign ori = (inst_var == 6'b001101);  // as opcode is 13 
assign bltzal = (inst_var == 6'b100010);  // as opcode is 34
assign jspal = (inst_var == 6'b010011);  // as opcode is 19
assign baln = (inst_var == 6'b011011);  // as opcode is 27

assign regdest = lw || sw || beq;
assign alusrc = lw | sw | ori | bltzal;
assign memtoreg = lw;
//by having "link address" in baln and bltzal, we have regwrite:  
assign regwrite = rformat | lw | ori | baln | bltzal ;
assign memread = lw;
//by having "link address" in jspal, we have memwrite:
assign memwrite = sw | jspal;
assign branch = beq;
assign aluop1 = rformat | ori;  // ori uses a different ALU operation
assign aluop2 = beq;
endmodule
