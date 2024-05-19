// zeroext.v: Zero extension module
module zeroext(in, out);
input [15:0] in;
output [31:0] out;
assign out = {16'h0, in};  // Zero extend the input
endmodule
