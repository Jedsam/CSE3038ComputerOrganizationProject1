module shift_26bit(shout, shin);
output [27:0] shout;
input [25:0] shin;
wire [27:0] extended_shin;

assign extended_shin = {2'b0, shin}; // 26 bit'i 28 bit'e geni?letme
assign shout = extended_shin << 2;
endmodule