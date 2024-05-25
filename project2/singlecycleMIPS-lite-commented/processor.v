module processor;

reg [31:0] pc; //32-bit program counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)

wire [31:0] 
	readdata1,	//Read data 1 output of Register File
	readdata2,	//Read data 2 output of Register File
	writedata,	//Write data input of Register File
	out2,		//Output of mux with ALUSrc control-mult2
	out3,		//Output of mux with MemToReg control-mult3
	out4,		//Output of mux with (Branch&ALUZero) control-mult4
	out5,		//Output of mux with jump adress and mux4 result inputs,
	out7, 		//Output of mux 7
	out8,
	out9,		//Output of mux 9
	alu_result,	//ALU result
	extad,		//Output of sign-extend unit 
	adder1out,	//Output of adder which adds PC and 4-add1
	adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
	sextad,		//Output of shift left 2 unit (bottom)
	jump_adress;
wire [5:0] 
	inst31_26;	//31-26 bits of instruction (opcode)
wire [4:0] 
	inst25_21,	//25-21 bits of instruction
	inst20_16,	//20-16 bits of instruction
	inst15_11,	//15-11 bits of instruction
	out1;		//Write register select input of Register File, output of mux with RegDst control signal
wire [15:0] 
	inst15_0;	//15-0 bits of instruction
wire [25:0] 
	inst25_0;	//25-0 bits of instruction
wire [27:0]
	shl2_jump;	//Output of shift left 2 unit (upper/jump part)
wire [31:0] 
	instruc,	//current instruction
	dpack;	//Read data output of memory (data read from memory)
wire [2:0] 
	gout;	//Output of ALU control unit
wire zout,	//Zero output of ALU
	mult5select,	//Selector of mux with jump adress and mux4 result inputs, originally controlled by jump control signal)
	mult4select,	//Output of AND gate with Branch and ZeroOut inputs
	link,		// Signal to control the link address storage	(mult6select)
	//Control signals
	regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0,jump,balrnv,jmnor,ori,bltzal,jspal,baln; 

	assign balrnv = ((inst31_26 == 6'b000000) && (instruc[5:0] == 6'b010111)); // balrnv and jmnor control signals opcode=0 and funct codes for each
	assign jmnor = ((inst31_26 == 6'b000000) && (instruc[5:0] == 6'b100101));

//wire for zero-extended immediate, for "ori"
	wire [31:0] zextad;
	// Instantiate the zero extension unit
	zeroext zext(instruc[15:0], zextad);

//added for "balrnv"; new overflow check (the V flag), new status register:
	wire vout, nout; // Overflow and negative flags from ALU
	wire v_flag, z_flag, n_flag; // Status register outputs
	// Instantiate ALU with overflow detection
	alu32 alu1(alu_result, readdata1, out2, zout, vout, nout, gout);
	// Status register to capture ALU flags
	status_register sr1(clk, vout, zout, nout, v_flag, z_flag, n_flag);

	
integer i;

//Data Memory Write
	always @(posedge clk)
	if (memwrite) 	begin 
	//sum stores address,readdata2 stores the value to be written
	datmem[alu_result[4:0]+3]=out9[7:0];
	datmem[alu_result[4:0]+2]=out9[15:8];
	datmem[alu_result[4:0]+1]=out9[23:16];
	datmem[alu_result[4:0]]=out9[31:24];
	end

//Instruction memory read
	//4-byte instruction
	 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
	 assign inst31_26=instruc[31:26];
	 assign inst25_21=instruc[25:21];
	 assign inst25_0=instruc[25:0];
	 assign inst20_16=instruc[20:16];
	 assign inst15_11=instruc[15:11];
	 assign inst15_0=instruc[15:0];
	 
	 
// Register file connections
    	reg [31:0] registerfile[0:31];
    	assign readdata1 = registerfile[inst25_21]; // Read register 1
    	assign readdata2 = registerfile[inst20_16]; // Read register 2
    

	

//Data Memory Read (sum stores adress)
	assign dpack={datmem[alu_result[5:0]],datmem[alu_result[5:0]+1],datmem[alu_result[5:0]+2],datmem[alu_result[5:0]+3]};

//Multiplexers
	//1st mux (with RegDst control)
	mult2_to_1_5  mult1(out1, instruc[15:11], instruc[20:16], regdest);	//mux 11 comes after this
	
	//2nd mux (with ALUSrc control, MODIFIED WITH new ZEXTAD)
	mult2_to_1_32 mult2(out2, readdata2, ori ? zextad : extad, alusrc);
	
	//3rd mux (with MemToReg control)
	mult2_to_1_32 mult3(out3, alu_result,dpack,memtoreg);
	
	//4th mux (with PC+4 and Add component input)
	assign mult4select = ((branch && zout) || (bltzal && nout));
	mult2_to_1_32 mult4(out4, adder1out,adder2out, mult4select);

	// 5th mux (with jump adress and 4th branch inputs / last branch before PC)
	assign jump_adress={adder1out[31:28], shl2_jump[27:0]};
	assign mult5select = (jump || jmnor || jspal || (balrnv && v_flag) || (baln && n_flag));
	mult2_to_1_32 mult5(out5, out4, out8, mult5select);

	// MUX to select write data (output of mux3 or PC+4)
	assign link = ((balrnv && v_flag) || jmnor || (bltzal && nout) || jspal || (baln && n_flag));
    	mult2_to_1_32 mult6(writedata, out3, adder1out, link);	
	
	//7th MUX for selecting between Read Data 1 or Jump Address based on balrnv control signal
	mult2_to_1_32 mult7(out7, jump_adress, readdata1, balrnv);

	//8th MUX for selecting between Data Memory Read or output of first MUX based on jmnor or jspal
	wire mult8select = jmnor || jspal;
	mult2_to_1_32 mult8(out8, out7, dpack, mult8select);

	//9th MUX for selecting between Read Data 2 or pc+4
	mult2_to_1_32 mult9(out9, readdata2, adder1out, jspal);

	//10th MUX to select Read Register 1 address based on jspal control signal
	wire [4:0] read_reg1_select;
	mult2_to_1_5 mult10(read_reg1_select, instruc[25:21], 5'b11101, jspal);
	assign readdata1 = registerfile[read_reg1_select]; // updating where readdata1 is originally assigned

	//11th MUX to select Write Register destination for bltzal instruction
	wire [4:0] write_reg_select;
	mult2_to_1_5 mult11(write_reg_select, out1, 5'b11001, bltzal);

	//Write data to register file
	always @(posedge clk) begin
    		if (regwrite) begin
        		registerfile[write_reg_select] <= writedata;
    		end 
	end


// alu, adder and control logic connections
	//ALU unit
	//alu32 alu1(alu_result,readdata1,out2,zout,gout); original alu

	//adder which adds PC and 4
	adder add1(pc,32'h4,adder1out);

	//adder which adds PC+4 and 2 shifted sign-extend result
	adder add2(adder1out,sextad,adder2out);

	//Control unit
	control cont(instruc[31:26],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
	aluop1,aluop0,jump,ori,bltzal,jspal,baln);

	//Sign extend unit
	signext sext(instruc[15:0],extad);

	//ALU control unit
	alucont acont(aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] , instruc[31:26], gout);

	//Shift-left 2 unit
	shift shift2(sextad,extad);
	
	shift_26bit shift2_jump(shl2_jump, inst25_0);

    

	always @(posedge clk)
	pc = out5;

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial begin
	$readmemb("initDM.dat",datmem); //read Data Memory
	$readmemb("initIM.dat",mem);//read Instruction Memory
	$readmemb("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial begin
	pc=0;
	
	#400 $finish;
end

initial begin
	clk=0;
	//40 time unit for each cycle
	forever #20  clk=~clk;
end

initial begin
	  $monitor($time,"PC %h",pc,"  SUM %h",alu_result,"   INST %h",instruc[31:0],
	"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end

endmodule

