module processor;

reg [31:0] pc; //32-bit program counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)

wire [31:0] 
	readdata1,	//Read data 1 output of Register File
	readdata2,	//Read data 2 output of Register File
	out2,		//Output of mux with ALUSrc control-mult2
	out3,		//Output of mux with MemToReg control-mult3
	out4,		//Output of mux with (Branch&ALUZero) control-mult4
	out5,		//Output of mux with jump adress and mux4 result inputs,
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
	out1,		//Write register select input of Register File, output of mux with RegDst control signal
	link_reg;
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
	//Control signals
	regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0,ori; 
	//bltzal signal is added later in the code

//wires for "balrnv"
	// Decode additional control signals
	wire link;  // Signal to control the link address storage
	wire [4:0] rd;  // To hold the rd field from the instruction

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

// wires for bltzal branching ("nout" flag is already defined for balrnv before), "bltzal" is also a control signal:
	wire bltzal, pcsrc_bltzal, final_branch;
	// New AND gate for bltzal and nout (negative out)
	assign pcsrc_bltzal = bltzal && nout;
	// OR gate to determine final branch decision
	assign final_branch = (mult4select) | pcsrc_bltzal;


// Register file connections
    	reg [31:0] registerfile[0:31];
    	assign readdata1 = registerfile[inst25_21]; // Read register 1
    	assign readdata2 = registerfile[inst20_16]; // Read register 2
    

	//assign mult5select = 	buraya jump || jspal || (balrnv && Status[V]) || (baln && Status[N]) gelecek
  	//for "balrnv"
    	assign rd = instruc[15:11];  // Extracting rd from the instruction
	assign link = (inst31_26 == 6'b101111);  // link = balrnv && jmnor && bltzal && jspal && baln gibi bir ?ey olacak, ?u an sadaece balrnv.

integer i;

//Data Memory Write
	always @(posedge clk)
	if (memwrite) 	begin 
	//sum stores address,readdata2 stores the value to be written
	datmem[alu_result[4:0]+3]=readdata2[7:0];
	datmem[alu_result[4:0]+2]=readdata2[15:8];
	datmem[alu_result[4:0]+1]=readdata2[23:16];
	datmem[alu_result[4:0]]=readdata2[31:24];
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


//Registers
	assign readdata1=registerfile[inst25_21];//Read register 1
	assign readdata2=registerfile[inst20_16];//Read register 2

//Data Memory Read (sum stores adress)
	assign dpack={datmem[alu_result[5:0]],datmem[alu_result[5:0]+1],datmem[alu_result[5:0]+2],datmem[alu_result[5:0]+3]};

//Multiplexers
	//mux with RegDst control
	mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);
	//mux with ALUSrc control, MODIFIED WITH new ZEXTAD
	mult2_to_1_32 mult2(out2, readdata2, ori ? zextad : extad, alusrc);
	//mux with MemToReg control
	mult2_to_1_32 mult3(out3, alu_result,dpack,memtoreg);
	//mux with (Branch&ALUZero) control
	mult2_to_1_32 mult4(out4, adder1out,adder2out, final_branch);

	assign jump_adress={adder1out[31:28], shl2_jump};
	mult2_to_1_32 mult5(out5, out4, jump_adress, mult5select);
	
	// MUX to select link register (either rd or $31), for "balrnv"
    	mult2_to_1_5 link_reg_select(link_reg, rd, 5'd31, link);	// bu ?u an sadece balrnv için link yap?yor ama 5 instructionda link var, hepsi için düzenlenmesi gerekiyor.
									// link = balrnv && jmnor && bltzal && jspal && baln gibi bir ?ey olacak
									// zaten link 1 oldu?unda link_reg = rd oluyor link 0 olursa da lik_reg kulan?lm?yor, di?er durumda 31 yapmam?z?n bence manas? yok.

//Write data to register file, for "balrnv"
	always @(posedge clk) begin
	    if (regwrite) begin
  	      if (link && !v_flag) begin
  	          // Special case for balrnv: Write link address (PC + 4) to link register
   	         registerfile[link_reg] <= adder1out;
		  end else begin
   	         // Normal register write operation
    	        registerfile[out1] <= out3;
    	  end
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
	aluop1,aluop0, ori, bltztal);

	//Sign extend unit
	signext sext(instruc[15:0],extad);

	//ALU control unit
	alucont acont(aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

	//Shift-left 2 unit
	shift shift2(sextad,extad);
	
	shift_26bit shift2_jump(shl2_jump, inst25_0);

	assign mult4select=branch && zout; 

    
//PC update logic to handle normal operation and branch, for "balrnv"
    // Branching logic
    	always @(negedge clk) begin
        	if ((branch && z_flag) || (link && !v_flag))
            	pc <= registerfile[inst25_21];  // Branch to address in $rs
        	else
           	 pc <= out4;  // Normal PC update (e.g., PC + 4 or branch target)
    	end


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

