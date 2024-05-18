module status_register(clk, v_in, z_in, n_in, v_out, z_out, n_out);
    input clk;
    input v_in, z_in, n_in;
    output reg v_out, z_out, n_out;

    always @(posedge clk) begin
        v_out <= v_in;
        z_out <= z_in;
	n_out <= n_in;
    end
endmodule
