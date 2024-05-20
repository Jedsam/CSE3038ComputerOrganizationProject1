module alu32(result,a,b,zout,vout,nout,gin);//ALU operation according to the ALU control line values
output [31:0] result;
input [31:0] a,b; 
input [2:0] gin;//ALU control line
reg [31:0] result;
reg [31:0] less;


output zout, vout, nout;	// vout and nout added here n=negative, v=overflow
reg zout, vout, nout;

always @(a or b or gin) begin
	case(gin)
	
		3'b010: begin //ALU control line=010, ADD
			result=a+b; 		
			 // Detect overflow for addition
            vout=((a[31] && b[31] && !result[31]) || (!a[31] && !b[31] && result[31]));
        end
	
		3'b110: begin  //ALU control line=110, SUB
			result=a+1+(~b);	
			// Detect overflow for subtraction
            vout=((a[31] && !b[31] && !result[31]) || (!a[31] && b[31] && result[31]));
        end
		
		3'b111: begin  	//ALU control line=111, set on less than
		less=a+1+(~b);
			if (less[31]) result=1;	
			else result=0;
	    end
		  
		3'b000: result=a & b;	//ALU control line=000, AND
		
		3'b001: result=a|b;		//ALU control line=001, OR
		
		3'b011: sum = ~(a | b);            // new,for "jmnor", NOR
	
		
		default: result=31'bx;	
	endcase
	zout=~(|result); //zero flag
	if (result[31]) nout=1;
	else nout=0;
end
endmodule
