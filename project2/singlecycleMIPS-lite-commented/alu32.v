module alu32(sum,a,b,zout, vout,gin);//ALU operation according to the ALU control line values
output [31:0] sum;
input [31:0] a,b; 
input [2:0] gin;//ALU control line
reg [31:0] sum;
reg [31:0] less;

//for "balrnv"
output zout, vout;
reg zout, vout;

always @(a or b or gin) begin
	case(gin)
		3'b010: begin //ALU control line=010, ADD
			sum=a+b; 		
			 // Detect overflow for addition
            vout=((a[31] && b[31] && !sum[31]) || (!a[31] && !b[31] && sum[31]));
        end
	
	
		3'b110: begin  //ALU control line=110, SUB
			sum=a+1+(~b);	
			// Detect overflow for subtraction
            vout=((a[31] && !b[31] && !sum[31]) || (!a[31] && b[31] && sum[31]));
        end
		
		3'b111: begin  	//ALU control line=111, set on less than
		less=a+1+(~b);
			if (less[31]) sum=1;	
			else sum=0;
	    end
		  
		3'b000: sum=a & b;	//ALU control line=000, AND
		
		3'b001: sum=a|b;		//ALU control line=001, OR
		
		default: sum=31'bx;	
	endcase
	zout=~(|sum); //zero flag
end
endmodule
