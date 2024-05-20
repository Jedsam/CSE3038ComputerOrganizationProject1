module shift_26bit(out, i0);
output [27:0] out;
input [25:0]i0;
assign out = {i0[25:0],'b00};
endmodule