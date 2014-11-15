module c16(

	//////////// LED //////////
	LEDG,
	LEDR,

	//////////// KEY //////////
	CPU_RESET_n,
	KEY,

	//////////// SW //////////
	SW,

	//////////// SEG7 //////////
	HEX0,
	HEX1,
	HEX2,
	HEX3
);

//=======================================================
//  PORT declarations
//=======================================================

//////////// LED //////////
output		     [7:0]		LEDG;
output		     [9:0]		LEDR;

//////////// KEY //////////
input 		          		CPU_RESET_n;
input 		     [3:0]		KEY;

//////////// SW //////////
input 		     [9:0]		SW;

//////////// SEG7 //////////
output		     [6:0]		HEX0;
output		     [6:0]		HEX1;
output		     [6:0]		HEX2;
output		     [6:0]		HEX3;

wire clk = KEY[0];        // single step using key0

wire[15:0] reg_value_0;
wire[15:0] reg_value_1;
wire[15:0] reg_value_2;
wire[15:0] reg_value_3;
wire[15:0] reg_value_4;
wire[15:0] reg_dbg;

reg[2:0] reg_addr_0;
reg[2:0] reg_addr_1;
reg[2:0] reg_addr_2;
reg[2:0] reg_addr_3;
reg[2:0] reg_addr_4;

reg [15:0] mather_0_pc_in;
reg [15:0] mather_0_operand_0;
reg [15:0] mather_0_operand_1;
reg [2:0] mather_0_operation;
wire [2:0] mather_0_dest_in; // E 
wire [2:0] mather_0_dest_out;
wire [15:0] mather_0_result;
wire [15:0] mather_0_pc_out;

reg [15:0] mather_1_pc_in;
reg [15:0] mather_1_operand_0;
reg [15:0] mather_1_operand_1;
reg [2:0] mather_1_operation;
wire [2:0] mather_1_dest_in; // E 
wire [2:0] mather_1_dest_out;
wire [15:0] mather_1_result;
wire [15:0] mather_1_pc_out;

reg [15:0] memoreer_0_pc_in;
reg [15:0] memoreer_0_operand_0;
reg [15:0] memoreer_0_operand_1;
reg [2:0] memoreer_0_operation;
reg [2:0] memoreer_0_dest_in; // E 
wire [2:0] memoreer_0_dest_out;
wire [15:0] memoreer_0_result;
wire [15:0] memoreer_0_pc_out;

registers(
	.clk(clk),
	.read_addr_0(reg_addr_0),
	.read_addr_1(reg_addr_1),
	.read_addr_2(reg_addr_2),
	.read_addr_3(reg_addr_3),
	.read_addr_4(reg_addr_4),
	.read_addr_dbg(SW[2:0]),
	.write_addr_0(mather_0_dest_out),
	.write_value_0(mather_0_result),
	.write_addr_1(mather_1_dest_out),
	.write_value_1(mather_1_result),
	.write_addr_2(memoreer_0_dest_out),
	.write_value_2(memoreer_0_result),
	.read_value_0(reg_value_0),
	.read_value_1(reg_value_1),
	.read_value_2(reg_value_2),
	.read_value_3(reg_value_3),
	.read_value_4(reg_value_4),
	.read_value_dbg(reg_dbg)
	);

wire[15:0] instruction_addr;
wire[15:0] instruction;
wire[15:0] fetch_pc;
wire should_fetch_stall;

fetcher(
	.clk(clk),
	.fetch_addr(instruction_addr),
	.pc_out(fetch_pc),
	.stall(should_fetch_stall)
	);
wire [15:0] memoreer_addr;
wire memory_wren;
wire [15:0] memory_value_in;
wire [15:0] memory_value_out;

ram2 (
	.address_a(instruction_addr),
	.address_b(memoreer_addr),
	.clock(clk),
	.data_a(0),
	.data_b(memory_value_in),
	.wren_a(0),
	.wren_b(memory_wren),
	.q_a(instruction),
	.q_b(memory_value_out) // value out for load instructions NOPE
 	);
wire [2:0] scorebored_op;
wire [3:0] scorebored_source_0;
wire [3:0] scorebored_source_1;
wire [15:0] scorebored_pc;
wire [2:0] scorebored_dest;
wire [15:0] immediate_out;
wire memoreer_0_done;

decoder_uno(
	.clk(clk),
	.instruction_in(instruction),
	.pc_in(fetch_pc),
	.execute_op(scorebored_op),
	.arg_0(scorebored_source_0),
	.arg_1(scorebored_source_1),
	.pc_out(scorebored_pc),
	.immediate_out(immediate_out),
	.dest(scorebored_dest),
	.stall(should_fetch_stall)
	);

mather(
	.clk(clk),
	.pc_in(mather_0_pc_in),
	.operand_0(mather_0_operand_0),
	.operand_1(mather_0_operand_1),
	.operation(mather_0_operation),
	.destination_in(mather_0_dest_in), // E 
	.destination_out(mather_0_dest_out),
	.result(mather_0_result),
	.pc_out(mather_0_pc_out)
	);

mather(
	.clk(clk),
	.pc_in(mather_1_pc_in),
	.operand_0(mather_1_operand_0),
	.operand_1(mather_1_operand_1),
	.operation(mather_1_operation),
	.destination_in(mather_1_dest_in), // E 
	.destination_out(mather_1_dest_out),
	.result(mather_1_result),
	.pc_out(mather_1_pc_out)
	);

memoreer(
	.clk(clk),
	.pc_in(memoreer_0_pc_in),
	.operand_0(memoreer_0_operand_0),
	.operand_1(memoreer_0_operand_1),
	.operation(memoreer_0_operation),
	.destination_in(memoreer_0_dest_in), // E 
	.destination_out(memoreer_0_dest_out),
	.mem_addr_out(memoreer_addr),
	.mem_wren(memory_wren),
	.store_value(memory_value_in),
	.load_value(memory_value_out),
	.result(memoreer_0_result),
	.pc_out(memoreer_0_pc_out),
	.done(memoreer_0_done)
	);
	
// Begin scoreb0r3d modulez
parameter MATHER_0 = 3'h0;
parameter MATHER_1 = 3'h1;
parameter MEMOREER_0 = 3'h2;
parameter NO_RESOURCE = 3'h3;

parameter DO_ADD = 3'h0;
parameter DO_SUB = 3'h1;
parameter DO_LOAD= 3'h2;
parameter DO_STORE=3'h3;
parameter DO_NOP  =3'h4; 

parameter IN_ISSUE_STATE = 3'h0;
parameter IN_READ_OPERANDS_STATE = 3'h1;
parameter IN_EXECUTE_STATE = 3'h2;
parameter IN_WRITEBACK_STATE = 3'h3;
parameter IN_INITIAL_STATE = 3'h4;
// ***RESOURCE STATUS, DO NOT DELETE***
parameter BUSY = 3'h0;
parameter NOT_BUSY = 3'h1;
parameter BUSY_AND_WORKING = 3'h2;
// register status, not as important
parameter READY = 3'h0;
parameter NOT_READY = 3'h1;
parameter ACTUALLY_IMMEDIATE_VALUE = 3'h2;


parameter USE_PC = 4'he;
parameter USE_IMMEDIATE = 4'hf;

reg should_fetch_stall_reg;


reg [2:0] Instruction_Status [2:0]; // goes with IN_???_STATE
reg [2:0] Register_Status [7:0];  //   what functional unit will produce the value for each register

reg [2:0] Busy [2:0]; // indexed by MATHER_0 and shit

reg [2:0] FU_Operations[2:0]; // the operation each FU will perform
reg [2:0] Dest_Register [2:0];
reg [3:0] Source_Register_0 [2:0]; // register number for operand 0
reg [3:0] Source_Register_1 [2:0];
reg [2:0] Source_Register_0_Resource [2:0];  // where operand 0 is being computed
reg [2:0] Source_Register_1_Resource [2:0]; 
reg [2:0] Source_Register_0_Ready [2:0];     // whether or not the register for operand 0 is ready to be used or in use by something else
reg [2:0] Source_Register_1_Ready [2:0];

reg [15:0] Operand_Values_0[2:0];
reg [15:0] Operand_Values_1[2:0];

reg [2:0] Result [2:0];
reg [2:0] i;

reg [2:0] resource_to_use;

initial begin
	Busy[0] = NOT_BUSY;
	Busy[1] = NOT_BUSY;
	Busy[2] = NOT_BUSY;
	
	FU_Operations[0] = DO_NOP;
	FU_Operations[1] = DO_NOP;
	FU_Operations[2] = DO_NOP;

	Instruction_Status[0] = IN_INITIAL_STATE;
	Instruction_Status[1] = IN_INITIAL_STATE;

	Instruction_Status[2] = IN_INITIAL_STATE;
	
	Register_Status[0] = NO_RESOURCE;
	Register_Status[1] = NO_RESOURCE;
	Register_Status[2] = NO_RESOURCE;
	Register_Status[3] = NO_RESOURCE;
	Register_Status[4] = NO_RESOURCE;
	Register_Status[5] = NO_RESOURCE;
	Register_Status[6] = NO_RESOURCE;
	Register_Status[7] = NO_RESOURCE;
end


always @(*) begin
	should_fetch_stall_reg = 0;
	resource_to_use = NO_RESOURCE;
	if (scorebored_op == DO_ADD || scorebored_op == DO_SUB) begin
		if ((Busy[MATHER_0] == NOT_BUSY || Busy[MATHER_1] == NOT_BUSY) && Register_Status[scorebored_dest] == NO_RESOURCE) begin
			// we can issue
			resource_to_use = Busy[MATHER_0] == NOT_BUSY ? MATHER_0 : MATHER_1;
		end else begin
			//stall
			should_fetch_stall_reg = 1;
		end
	end
	if (scorebored_op == DO_LOAD || scorebored_op == DO_STORE) begin
		if (Busy[MEMOREER_0] == NOT_BUSY && Register_Status[scorebored_dest] == NO_RESOURCE) begin
			resource_to_use = MEMOREER_0;
		end else begin
			should_fetch_stall_reg = 1;
		end
	end


	mather_0_operation = DO_NOP;
	mather_1_operation = DO_NOP;
	memoreer_0_operation = DO_NOP;
	
	if (Busy[MATHER_0] == BUSY) begin
		if (Source_Register_0_Ready[MATHER_0] != NOT_READY  && Source_Register_1_Ready[MATHER_0] != NOT_READY) begin
			mather_0_operation = FU_Operations[MATHER_0];

			// both sources are ready. send data to functional unit
			if (Source_Register_0_Ready[MATHER_0] == READY) begin
				reg_addr_0 = Source_Register_0[MATHER_0][2:0];
				mather_0_operand_0 = reg_value_0;
			end else if(Source_Register_0_Ready[MATHER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
				mather_0_operand_0 = Operand_Values_0[MATHER_0];
			end

			if (Source_Register_1_Ready[MATHER_0] == READY) begin
				reg_addr_1 = Source_Register_1[MATHER_0][2:0];
				mather_0_operand_1 = reg_value_1;
			end else if(Source_Register_1_Ready[MATHER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
				mather_0_operand_1 = Operand_Values_1[MATHER_0];
			end

		end
	end

	if (Busy[MATHER_1] == BUSY) begin
		if (Source_Register_0_Ready[MATHER_1] != NOT_READY  && Source_Register_1_Ready[MATHER_1] != NOT_READY) begin
			mather_1_operation = FU_Operations[MATHER_1];

			// both sources are ready. send data to functional unit
			if (Source_Register_0_Ready[MATHER_1] == READY) begin
				reg_addr_2 = Source_Register_0[MATHER_1][2:0];
				mather_1_operand_0 = reg_value_2;
			end else if(Source_Register_0_Ready[MATHER_1] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
				mather_1_operand_0 = Operand_Values_0[MATHER_1];
			end

			if (Source_Register_1_Ready[MATHER_1] == READY) begin
				reg_addr_3 = Source_Register_1[MATHER_1][2:0];
				mather_1_operand_1 = reg_value_3;
			end else if(Source_Register_1_Ready[MATHER_1] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
				mather_1_operand_1 = Operand_Values_1[MATHER_1];
			end

		end
	end

	if (Busy[MEMOREER_0] == BUSY) begin
		if (Source_Register_0_Ready[MEMOREER_0] != NOT_READY  && Source_Register_1_Ready[MEMOREER_0] != NOT_READY) begin
			memoreer_0_operation = FU_Operations[MEMOREER_0];

			// both sources are ready. send data to functional unit
			if (Source_Register_0_Ready[MEMOREER_0] == READY) begin
				reg_addr_4 = Source_Register_0[MEMOREER_0][2:0];
				memoreer_0_operand_0 = reg_value_4;
			end else if(Source_Register_0_Ready[MEMOREER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
				memoreer_0_operand_0 = Operand_Values_0[MEMOREER_0];
			end

		end
	end

end

always @(posedge clk) begin
	// This is where we issue things
	if (resource_to_use != NO_RESOURCE) begin
		Busy[resource_to_use] <= BUSY;
		Dest_Register[resource_to_use] <= scorebored_dest;
		Source_Register_0[resource_to_use] <= scorebored_source_0;
		Source_Register_1[resource_to_use] <= scorebored_source_1;
		FU_Operations[resource_to_use] <= scorebored_op;
		if (scorebored_source_0 == USE_PC) begin
			Operand_Values_0[resource_to_use] <= scorebored_pc;
			Source_Register_0_Resource[resource_to_use] <= NO_RESOURCE;
			Source_Register_0_Ready[resource_to_use] <= ACTUALLY_IMMEDIATE_VALUE;
		end else if (scorebored_source_0 == USE_IMMEDIATE) begin
			Operand_Values_0[resource_to_use] <= immediate_out;
			Source_Register_0_Resource[resource_to_use] <= NO_RESOURCE;
			Source_Register_0_Ready[resource_to_use] <= ACTUALLY_IMMEDIATE_VALUE;
		end else begin
			Source_Register_0_Resource[resource_to_use] <= Register_Status[scorebored_source_0];
			if (Register_Status[scorebored_source_0] != NO_RESOURCE) begin
				Source_Register_0_Ready[resource_to_use] <= NOT_READY;
			end else begin
				Source_Register_0_Ready[resource_to_use] <= READY;
			end 
				
		end

		if (scorebored_source_1 == USE_PC) begin
			Operand_Values_1[resource_to_use] <= scorebored_pc;
			Source_Register_1_Resource[resource_to_use] <= NO_RESOURCE;
			Source_Register_1_Ready[resource_to_use] <= ACTUALLY_IMMEDIATE_VALUE;
		end else if (scorebored_source_1 == USE_IMMEDIATE) begin
			Operand_Values_1[resource_to_use] <= immediate_out;
			Source_Register_1_Resource[resource_to_use] <= NO_RESOURCE;
			Source_Register_1_Ready[resource_to_use] <= ACTUALLY_IMMEDIATE_VALUE;
		end else begin
			Source_Register_1_Resource[resource_to_use] <= Register_Status[scorebored_source_1];
			if (Register_Status[scorebored_source_1] != NO_RESOURCE) begin
				Source_Register_1_Ready[resource_to_use] <= NOT_READY;
			end else begin
				Source_Register_1_Ready[resource_to_use] <= READY;
			end 
		end
		
		Register_Status[scorebored_dest] <= resource_to_use;
	end
	
	// This is where we dispatch things
	
	if (mather_0_operation != DO_NOP) begin
		Busy[MATHER_0] = BUSY_AND_WORKING;
	end
	
	if (mather_1_operation != DO_NOP) begin
		Busy[MATHER_1] = BUSY_AND_WORKING;
	end
	
	if (memoreer_0_operation != DO_NOP) begin
		Busy[MEMOREER_0] = BUSY_AND_WORKING;
	end
	
	
	// This is where the done things are

	if (mather_0_dest_out != 7) begin
		Register_Status[mather_0_dest_out] <= NO_RESOURCE;
		for (i = 0; i < 3; i = i + 1) begin
			if(Source_Register_0_Resource[i] == MATHER_0) begin
				Source_Register_0_Ready[i] <= READY;
			end

			if(Source_Register_1_Resource[i] == MATHER_0) begin
				Source_Register_1_Ready[i] <= READY;
			end
		end
		Busy[MATHER_0] <= NOT_BUSY;
	end

	if (mather_1_dest_out != 7) begin
		Register_Status[mather_1_dest_out] <= NO_RESOURCE;
		for (i = 0; i < 3; i = i + 1) begin
			if(Source_Register_0_Resource[i] == MATHER_1) begin
				Source_Register_0_Ready[i] <= READY;
			end

			if(Source_Register_1_Resource[i] == MATHER_1) begin
				Source_Register_1_Ready[i] <= READY;
			end
		end
		Busy[MATHER_1] <= NOT_BUSY;
	end

	if(memoreer_0_done == 1) begin
		Busy[MEMOREER_0] <= NOT_BUSY;
		if (memoreer_0_dest_out != 7) begin
			Register_Status[memoreer_0_dest_out] <= NO_RESOURCE;
			for (i = 0; i < 3; i = i + 1) begin
				if(Source_Register_0_Resource[i] == MEMOREER_0) begin
					Source_Register_0_Ready[i] <= READY;
				end

				if(Source_Register_1_Resource[i] == MEMOREER_0) begin
					Source_Register_1_Ready[i] <= READY;
				end
			end
		end
	end

end
	
assign should_fetch_stall = should_fetch_stall_reg;

assign mather_0_dest_in = Dest_Register[MATHER_0];

assign mather_1_dest_in = Dest_Register[MATHER_1];

///////////////////
// debug support //
///////////////////
reg [15:0]debug;

assign LEDR = fetch_pc[9:0];
assign LEDG = {should_fetch_stall, 7'h0};

display(debug[15:12], HEX3);
display(debug[11:8], HEX2);
display(debug[7:4], HEX1);
display(debug[3:0], HEX0);

// what do we display
always @(*) begin
	// MATHER_0 debug
	if (SW[7]) begin
		if (SW[4]) begin
			debug = mather_0_result;
		end else if (SW[3]) begin
			debug = {1'b0, Source_Register_0_Resource[MATHER_0], 1'b0, Source_Register_0_Ready[MATHER_0], 1'b0, Source_Register_1_Resource[MATHER_0], 1'b0, Source_Register_1_Ready[MATHER_0]};
		end else if (SW[2]) begin
			debug = {1'b0, Busy[MATHER_0], 1'b0, Dest_Register[MATHER_0], Source_Register_0[MATHER_0], Source_Register_1[MATHER_0]};
		end else if (SW[1]) begin
			debug = mather_0_operand_1;
		end else if (SW[0]) begin
			debug = mather_0_operand_0;
		end else begin
			debug = {5'h0, mather_0_operation, 1'h0, mather_0_dest_out, 1'h0, mather_0_dest_in};
		end
	// MATHER_1 debug
	end else if (SW[6]) begin
		if (SW[4]) begin
			debug = mather_1_result;
		end else if (SW[3]) begin
			debug = {1'b0, Source_Register_0_Resource[MATHER_1], 1'b0, Source_Register_0_Ready[MATHER_1], 1'b0, Source_Register_1_Resource[MATHER_1], 1'b0, Source_Register_1_Ready[MATHER_1]};
		end else if (SW[2]) begin
			debug = {1'b0, Busy[MATHER_1], 1'b0, Dest_Register[MATHER_1], Source_Register_0[MATHER_1], Source_Register_1[MATHER_1]};
		end else if (SW[1]) begin
			debug = mather_1_operand_1;
		end else if (SW[0]) begin
			debug = mather_1_operand_0;
		end else begin
			debug = {5'h0, mather_1_operation, 1'h0, mather_1_dest_out, 1'h0, mather_1_dest_in};
		end
	// MEMOREER_0 debug
	end else if (SW[5]) begin
		if (SW[4]) begin
			debug = memoreer_0_result;
		end else if (SW[3]) begin
			debug = {1'b0, Source_Register_0_Resource[MEMOREER_0], 1'b0, Source_Register_0_Ready[MEMOREER_0], 1'b0, Source_Register_1_Resource[MEMOREER_0], 1'b0, Source_Register_1_Ready[MEMOREER_0]};
		end else if (SW[2]) begin
			debug = {1'b0, Busy[MEMOREER_0], 1'b0, Dest_Register[MEMOREER_0], Source_Register_0[MEMOREER_0], Source_Register_1[MEMOREER_0]};
		end else if (SW[1]) begin
			debug = memoreer_0_operand_1;
		end else if (SW[0]) begin
			debug = memoreer_0_operand_0;
		end else begin
			debug = {5'h0, memoreer_0_operation, 1'h0, memoreer_0_dest_out, 1'h0, memoreer_0_dest_in};
		end
	end else if (SW[4]) begin
		if (SW[3]) begin
			debug = {5'b0, Register_Status[SW[2:0]]};
		end else begin
			debug = {1'b0, scorebored_op, scorebored_source_0, scorebored_source_1, 1'b0, scorebored_dest};
		end
   end else if (SW[3]) begin
		if (SW[0]) begin
			debug = instruction_addr;
		end else if (SW[1]) begin
			debug = {5'h0, resource_to_use, 5'h0, scorebored_op};
		end else begin
			debug = instruction;
		end
	end else begin
		debug = reg_dbg;
	end
end

endmodule


/////////////////////////
// REGISTER FILE       //
/////////////////////////
module registers(
		clk, read_addr_dbg, read_value_dbg,
		read_addr_0, read_addr_1, read_addr_2, read_addr_3, read_addr_4,  
		read_value_0, read_value_1, read_value_2, read_value_3, read_value_4,
		write_addr_0, write_addr_1, write_addr_2, 
		write_value_0, write_value_1, write_value_2 
		);

	input clk;
	input[2:0] read_addr_dbg;
	output[15:0] read_value_dbg;

	input[2:0] read_addr_0;
	input[2:0] read_addr_1;
	input[2:0] read_addr_2;
	input[2:0] read_addr_3;
	input[2:0] read_addr_4;
	input[2:0] write_addr_0;
	input[2:0] write_addr_1;
	input[2:0] write_addr_2;

	input[15:0] write_value_0;
	input[15:0] write_value_1;
	input[15:0] write_value_2;

	output[15:0] read_value_0;
	output[15:0] read_value_1;
	output[15:0] read_value_2;
	output[15:0] read_value_3;
	output[15:0] read_value_4;

	reg[15:0] rv0;
	reg[15:0] rv1;
	reg[15:0] rv2;
	reg[15:0] rv3;
	reg[15:0] rv4;
	reg[15:0] rvdbg;

	// How do I for loop?
	reg [3:0] i;
	reg [3:0] j;

	wire[15:0] all_read_addrs[5:0];
	wire[15:0] all_write_addrs[2:0];
	wire[15:0] all_write_values[2:0];
	reg[15:0] all_rv[5:0];

	reg [15:0]regs[7:0];
	
	assign all_read_addrs[0] = read_addr_0;
	assign all_read_addrs[1] = read_addr_1;
	assign all_read_addrs[2] = read_addr_2;
	assign all_read_addrs[3] = read_addr_3;
	assign all_read_addrs[4] = read_addr_4;
	assign all_read_addrs[5] = read_addr_dbg;
	
	assign all_write_addrs[0] = write_addr_0;
	assign all_write_addrs[1] = write_addr_1;
	assign all_write_addrs[2] = write_addr_2;
	assign all_write_values[0] = write_value_0;
	assign all_write_values[1] = write_value_1;
	assign all_write_values[2] = write_value_2;
	
	initial begin
		regs[0] = 0;
		regs[1] = 0;
		regs[2] = 0;
		regs[3] = 0;
		regs[4] = 0;
		regs[5] = 0;
		regs[6] = 0;
		regs[7] = 0;
	end

	always @(*) begin
		for(i = 0; i < 6; i = i + 1) begin
			all_rv[i] = regs[all_read_addrs[i]];
			for(j = 0; j < 3; j = j + 1) begin
				if(all_write_addrs[j] != 7 && all_read_addrs[i] == all_write_addrs[j]) begin
					all_rv[i] = all_write_values[j];
				end
			end
		end
	end

	always @(posedge clk) begin
		for(i = 0; i < 3; i = i + 1) begin		
			if (all_write_addrs[i] != 7) begin
				regs[all_write_addrs[i]] <= all_write_values[i];
			end
		end
	end

	assign read_value_0 = all_rv[0];
	assign read_value_1 = all_rv[1];
	assign read_value_2 = all_rv[2];
	assign read_value_3 = all_rv[3];
	assign read_value_4 = all_rv[4];
	assign read_value_dbg = all_rv[5];

endmodule


/////////////////////////
// FETCH STAGE         //
/////////////////////////
module fetcher(clk, fetch_addr, pc_out, stall);

	input clk;
	input stall;

	output[15:0] pc_out;
	output[15:0] fetch_addr;

	reg[15:0] fetch_pc;
	reg[15:0] temp_pc;
	reg[15:0] next_fetch_pc;

	initial begin
		fetch_pc = -1;
		temp_pc = -1;
	end

	always @(*) begin
		if(stall == 1) begin
			next_fetch_pc = temp_pc;
		end else begin
			next_fetch_pc = temp_pc + 1;
		end
	end

	always @(posedge clk) begin
		temp_pc <= next_fetch_pc;
		fetch_pc <= temp_pc;
	end

	assign pc_out = fetch_pc;
	assign fetch_addr = next_fetch_pc;

endmodule


/////////////////////////
// 7 SEG               //
/////////////////////////
module display(NUM, HEX);
	input[3:0] NUM;

	output[6:0] HEX;
	reg[6:0] HEX;

	always @(*)
	case (NUM)
		4'h0 : HEX = 7'b1000000;
		4'h1 : HEX = 7'b1111001;
		4'h2 : HEX = 7'b0100100;
		4'h3 : HEX = 7'b0110000;
		4'h4 : HEX = 7'b0011001;
		4'h5 : HEX = 7'b0010010;
		4'h6 : HEX = 7'b0000010;
		4'h7 : HEX = 7'b1111000;
		4'h8 : HEX = 7'b0000000;
		4'h9 : HEX = 7'b0010000;
		4'hA : HEX = 7'b0001000;
		4'hB : HEX = 7'b0000011;
		4'hC : HEX = 7'b0100111;
		4'hD : HEX = 7'b0100001;
		4'hE : HEX = 7'b0000110;
		4'hF : HEX = 7'b0001110;
	endcase
endmodule

module mather (clk, pc_in, operand_0, operand_1, operation, destination_in, destination_out, result, pc_out);

	parameter DO_ADD = 4'h0;
	parameter DO_SUB = 4'h1;
	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [15:0] operation;
	input [2:0]  destination_in;

	output [2:0] destination_out;
	output [15:0] result;
	output [15:0] pc_out;

	
	reg [15:0] operand_0_reg;
	reg [15:0] operand_1_reg;
	reg [15:0] operation_reg;
	reg [2:0]  destination_in_reg;
	
	reg [15:0] result_reg;
	reg [15:0] result_latch;
	reg [2:0] dest_latch;
	reg [15:0] pc_latch;

	always @(*)
		case (operation_reg)
			DO_ADD: result_reg = operand_0_reg + operand_1_reg;
			DO_SUB: result_reg = operand_0_reg - operand_1_reg;
		endcase

	always @(posedge clk) begin
		result_latch <= result_reg;
		if (operation_reg == DO_NOP) begin
			dest_latch <= 3'h7;
		end else begin
			dest_latch <= destination_in_reg;
		end
		operand_0_reg <= operand_0;
		operand_1_reg <= operand_1;
		operation_reg <= operation;
		destination_in_reg <= destination_in;
		pc_latch <= pc_in;
	end

	assign result = result_latch;
	assign destination_out = dest_latch;
	assign pc_out = pc_latch;
endmodule

module decoder_uno(clk, instruction_in, pc_in, execute_op, arg_0, arg_1, pc_out, immediate_out, dest, stall);

	parameter DO_ADD = 3'h0;

	parameter DO_SUB = 3'h1;
	parameter DO_LOAD= 3'h2;
	parameter DO_STORE=3'h3;
	parameter DO_NOP  =3'h4; 

	parameter USE_PC = 4'he;
	parameter USE_IMMEDIATE = 4'hf;

	input clk;
	input stall;
	input [15:0] instruction_in;
	input [15:0] pc_in;

	output [2:0] execute_op;
	output [3:0] arg_0;
	output [3:0] arg_1;
	output [15:0] pc_out;
	output [15:0] immediate_out;
	output [2:0]  dest;

	reg [2:0] execute_op_reg;
	reg [3:0] arg_0_reg;
	reg [3:0] arg_1_reg;
	reg [15:0] immediate_out_reg;
	reg [2:0] dest_reg;

	reg [15:0] stupid_save_thingy_for_instruction;
	reg there_is_something_in_stupid_save_thingy_for_instruction;
	reg [15:0] instruction;

	wire [4:0] opcode = instruction[15:11];
	always @(*) begin

		instruction = there_is_something_in_stupid_save_thingy_for_instruction == 1 ? stupid_save_thingy_for_instruction : instruction_in;

		execute_op_reg = DO_NOP;
		arg_0_reg = 4'hb;
		arg_1_reg = 4'hb;

		dest_reg = instruction[10:8];	

		case (opcode)
			// Add, f = 0
			5'b00000: begin
				execute_op_reg = DO_ADD;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end

			// Add, f = 1
			5'b00001: begin
				execute_op_reg = DO_ADD;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = {1'b0, instruction[2:0]};
			end

			// do sub
			5'b00010: begin
				execute_op_reg = DO_SUB;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end

			// sub, f = 1
			5'b00011: begin
				execute_op_reg = DO_SUB;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = {1'b0, instruction[2:0]};
			end

			// ld, f = 0
			5'b10100: begin
				execute_op_reg = DO_LOAD;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end
			
			// ld, f = 1
			5'b10101: begin
				execute_op_reg = DO_LOAD;
				arg_0_reg = USE_PC;
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end
			
			// st, f = 0
			5'b10110: begin
				execute_op_reg = DO_STORE;
				arg_0_reg = {1'b0, instruction[7:5]};
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end
			
			//st, f = 1
			5'b10111: begin
				execute_op_reg = DO_STORE;
				arg_0_reg = USE_PC;
				arg_1_reg = USE_IMMEDIATE;
				immediate_out_reg = $signed (instruction[4:0]);
			end
		endcase
		/* Possibly loop
		if(stall == 1) begin
			execute_op_reg = DO_NOP;		
			dest_reg = 7;
		end
		*/

		if(pc_in == 16'hffff) begin
			execute_op_reg = DO_NOP;
		end
	end

	always @(posedge clk) begin

		if(stall == 1) begin
			if (there_is_something_in_stupid_save_thingy_for_instruction == 1) begin
				// nothing happens
			end else begin
				there_is_something_in_stupid_save_thingy_for_instruction <= 1;
				stupid_save_thingy_for_instruction <= instruction;
			end
		end else begin
			there_is_something_in_stupid_save_thingy_for_instruction <= 0;
		end
	end

	assign pc_out = pc_in;
	assign execute_op = execute_op_reg;
	assign arg_0 = arg_0_reg;
	assign arg_1 = arg_1_reg;
	assign immediate_out = immediate_out_reg;
	assign dest = dest_reg;

endmodule


module memoreer(clk, pc_in,	operand_0, operand_1,
	operation, 	destination_in,	destination_out, 	mem_addr_out,
	mem_wren, 	load_value,	store_value, result,	pc_out, done);

	parameter DO_LOAD= 3'h2;
	parameter DO_STORE=3'h3;
	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [3:0]  operation;
	input [3:0]  destination_in;
	output mem_wren;
	input [15:0] load_value;
	output [3:0] destination_out;
	output [15:0] mem_addr_out;
	output [15:0] store_value;
	output [15:0] result;
	output [15:0] pc_out;	

	output done;

	reg [15:0] mem_addr_out_reg;
	reg [3:0] cycles_we_have_stalled;
	reg start_stalin;
	reg mem_wren_reg;

	reg [15:0] result_save;
	reg [15:0] pc_save;
	reg [2:0]  destination_save;
	reg done_reg;
	reg [3:0]  operation_save;

	always @(*) begin
		mem_wren_reg = 0;
		case(operation)
			DO_LOAD: begin
				mem_addr_out_reg = operand_0 + operand_1;
				start_stalin = 1;
			end
			DO_STORE: begin
				mem_addr_out_reg = operand_0 + operand_1;
				mem_wren_reg = 1;
				start_stalin = 1;
			end
		endcase
		
	end

	always @(posedge clk) begin
		if (start_stalin == 1) begin
			cycles_we_have_stalled <= 0;
			pc_save <= pc_in;
			operation_save <= operation;
			destination_save <= destination_in;
		end else begin
			cycles_we_have_stalled <= cycles_we_have_stalled + 1;
		end
		if(cycles_we_have_stalled == 3) begin
			done_reg <= 1;
			if (operation_save == DO_LOAD) begin
				result_save <= load_value;
			end
		end else begin
			done_reg <= 0;
		end
	end
	assign mem_addr_out = mem_addr_out_reg;
	assign destination_out = destination_save;
	assign done = done_reg;
	assign pc_out = pc_save;
	assign result = result_save;
	assign mem_wren = mem_wren_reg;
endmodule
