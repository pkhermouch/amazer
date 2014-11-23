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

wire reg_type_0;
wire reg_type_1;
wire reg_type_dbg;

wire[15:0] reg_value_0;
wire[15:0] reg_value_1;
wire[15:0] reg_dbg;

reg[2:0] reg_addr_0;
reg[2:0] reg_addr_1;

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
wire [2:0] memoreer_0_dest_in; // E 
wire [2:0] memoreer_0_dest_out;
wire [15:0] memoreer_0_result;
wire [15:0] memoreer_0_pc_out;

wire [3:0] writeout_register;
wire [15:0] writeout_value;
wire [15:0] writeout_enable;

// Used to reserve what you are computing
wire [15:0] claim_name;
wire [3:0] claim_addr;

committed_registers(
	.clk(clk),
	.read_addr(SW[2:0]),
	.read_value(reg_dbg),
	.write_addr(writeout_register),
	.write_value(writeout_value),
	.write_enable(writeout_enable) 
	);

inflight_registers #(3, 3) (
	.clk(clk),
	.read_addrs({
		reg_addr_0,
		reg_addr_1,
		SW[2:0]
		}),
	.read_values({
		reg_value_0,
		reg_value_1,
		reg_dbg
		}),
	.read_types({
		reg_type_0,
		reg_type_1,
		reg_type_dbg
		}),
	.write_names({
		mather_0_name_out,
		mather_1_name_out,
		memoreer_0_name_out,
		}),
	.write_values({
		mather_0_result,
		mather_1_result,
		memoreer_0_result,
		}),
	.claim_addr(claim_addr),
	.claim_name(claim_name)
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

reg [15:0] memoreer_0_operand_2;

memoreer(
	.clk(clk),
	.pc_in(memoreer_0_pc_in),
	.operand_0(memoreer_0_operand_0),
	.operand_1(memoreer_0_operand_1),
	.operand_2(memoreer_0_operand_2),
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

reorder_buffer( 
	.clk(clk), 
	.mather_0_pc(mather_0_pc_out), 
	.mather_0_register(mather_0_dest_out), 
	.mather_0_value(mather_0_result), 
	.mather_1_pc(mather_1_pc_out), 
	.mather_1_register(mather_1_dest_out), 
	.mather_1_value,(mather_1_result) 
	.memoreer_0_pc(memoreer_0_pc_out), 
	.memoreer_0_register(memoreer_0_dest_out), 
	.memoreer_0_value(memoreer_0_result), 
	.writeout_register(writeout_register), 
	.writeout_value(writeout_value)
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
			if (Source_Register_1_Ready[MEMOREER_0] == READY) begin
				reg_addr_5 = Source_Register_1[MEMOREER_0][2:0];
				memoreer_0_operand_2 = reg_value_5;
			end
			memoreer_0_operand_1 = Operand_Values_1[MEMOREER_0];
		end
	end

end

always @(posedge clk) begin
	// This is where we issue things
	if (resource_to_use != NO_RESOURCE) begin
		Register_Status[scorebored_dest] <= resource_to_use;
		Busy[resource_to_use] <= BUSY;
		Dest_Register[resource_to_use] <= scorebored_dest;
		Source_Register_0[resource_to_use] <= scorebored_source_0;
		Source_Register_1[resource_to_use] <= scorebored_source_1;
		FU_Operations[resource_to_use] <= scorebored_op;
		if (scorebored_source_0 == USE_PC) begin
			Operand_Values_0[resource_to_use] <= scorebored_pc + 16'h1;
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
		if (scorebored_op == DO_STORE) begin
		   if (scorebored_source_1 == USE_PC) begin
				Operand_Values_1[resource_to_use] <= scorebored_pc + 16'h1;
			end else begin
				Operand_Values_1[resource_to_use] <= immediate_out;
					end
					   // end else
							Source_Register_1[resource_to_use] <= {1'h0, scorebored_dest};
			Source_Register_1_Resource[resource_to_use] <= Register_Status[scorebored_dest];
			if (Register_Status[scorebored_dest] != NO_RESOURCE) begin
				Source_Register_1_Ready[resource_to_use] <= NOT_READY;
			end else begin
				Source_Register_1_Ready[resource_to_use] <= READY;
			end
			Register_Status[scorebored_dest] <= NO_RESOURCE;
		end else
		if (scorebored_source_1 == USE_PC) begin
			Operand_Values_1[resource_to_use] <= scorebored_pc + 16'h1;
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
		
	end
	
	// This is where we dispatch things
	
	if (mather_0_operation != DO_NOP) begin
		Busy[MATHER_0] <= BUSY_AND_WORKING;
	end
	
	if (mather_1_operation != DO_NOP) begin
		Busy[MATHER_1] <= BUSY_AND_WORKING;
	end
	
	if (memoreer_0_operation != DO_NOP) begin
		Busy[MEMOREER_0] <= BUSY_AND_WORKING;
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
assign memoreer_0_dest_in = Dest_Register[MEMOREER_0];

///////////////////
// debug support //
///////////////////
reg [15:0]debug;

assign LEDR = fetch_pc[9:0];
assign LEDG = {should_fetch_stall, memoreer_0_done, memory_wren, 5'h0};

display(debug[15:12], HEX3);
display(debug[11:8], HEX2);
display(debug[7:4], HEX1);
display(debug[3:0], HEX0);

// what do we display
always @(*) begin
	if (SW[8]) begin
		if (SW[1]) begin
			debug = memory_value_in;
		end else if (SW[0]) begin
			debug = memory_value_out;
		end else begin
			debug = memoreer_addr;
		end
	// MATHER_0 debug
	end else if (SW[7]) begin
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
			if (SW[3]) begin
				debug = memoreer_0_operand_2;
				end else begin
			debug = memoreer_0_result; end
		end else if (SW[3]) begin
			debug = {1'b0, Source_Register_0_Resource[MEMOREER_0], 1'b0, Source_Register_0_Ready[MEMOREER_0], 1'b0, Source_Register_1_Resource[MEMOREER_0], 1'b0, Source_Register_1_Ready[MEMOREER_0]};
		end else if (SW[2]) begin
			debug = {1'b0, Busy[MEMOREER_0], 1'b0, Dest_Register[MEMOREER_0], Source_Register_0[MEMOREER_0], Source_Register_1[MEMOREER_0]};
		end else if (SW[1]) begin
			debug = memoreer_0_operand_1;
		end else if (SW[0]) begin
			debug = memoreer_0_operand_0;
		end else begin
			debug = {3'h0, memoreer_0_done, 1'h0, memoreer_0_operation, 1'h0, memoreer_0_dest_out, 1'h0, memoreer_0_dest_in};
		end
	end else if (SW[4]) begin
		if (SW[3]) begin
			debug = {5'b0, Register_Status[SW[2:0]]};
		end else begin
			debug = {1'b0, scorebored_op, scorebored_source_0, scorebored_source_1, 1'b0, scorebored_dest};
		end
   end else if (SW[3]) begin
		if (SW[2]) begin
			debug = immediate_out;
		end else if (SW[1]) begin
			debug = {5'h0, resource_to_use, 5'h0, scorebored_op};
		end else if (SW[0]) begin
			debug = instruction_addr;
		end else begin
			debug = instruction;
		end
	end else begin
		debug = reg_dbg;
	end
end

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
	reg [15:0] pc_store_place_for_stalling_reg;
	reg [15:0] immediate_out_reg;
	reg [2:0] dest_reg;
	reg [15:0] pc_out_reg;

	reg [15:0] stupid_save_thingy_for_instruction;
	reg there_is_something_in_stupid_save_thingy_for_instruction;
	reg [15:0] instruction;

	wire [4:0] opcode = instruction[15:11];
	always @(*) begin

		instruction = there_is_something_in_stupid_save_thingy_for_instruction == 1 ? stupid_save_thingy_for_instruction : instruction_in;
		pc_out_reg = there_is_something_in_stupid_save_thingy_for_instruction == 1 ? pc_store_place_for_stalling_reg : pc_in;
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
				immediate_out_reg = $signed (instruction[7:0]);
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
				immediate_out_reg = $signed (instruction[7:0]);
			end
		endcase


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
				pc_store_place_for_stalling_reg <= pc_in;
			end
		end else begin
			there_is_something_in_stupid_save_thingy_for_instruction <= 0;
		end
	end

	assign pc_out = pc_out_reg;
	assign execute_op = execute_op_reg;
	assign arg_0 = arg_0_reg;
	assign arg_1 = arg_1_reg;
	assign immediate_out = immediate_out_reg;
	assign dest = dest_reg;

endmodule


module memoreer(clk, pc_in,	operand_0, operand_1,
	operation, 	destination_in,	destination_out, 	mem_addr_out, operand_2,
	mem_wren, 	load_value,	store_value, result,	pc_out, done);

	parameter DO_LOAD= 3'h2;
	parameter DO_STORE=3'h3;
	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [15:0] operand_2;
	input [3:0]  operation;
	input [3:0]  destination_in;
	input [15:0] load_value;
	output [3:0] destination_out;
	output [15:0] mem_addr_out;
	output [15:0] store_value;
	output [15:0] result;
	output [15:0] pc_out;	
	output mem_wren;

	output done;

	reg [15:0] pc_in_reg;
	reg [15:0] operand_0_reg;
	reg [15:0] operand_1_reg;
	reg [15:0] operand_2_reg;
	reg [3:0]  operation_reg;
	reg [3:0]  destination_in_reg;
	
	reg [15:0] mem_addr_out_reg;
	reg [31:0] cycles_we_have_stalled;
	reg start_stalin;
	reg mem_wren_reg;
	reg [15:0] store_value_reg;

	reg [15:0] result_save;
	reg [15:0] pc_save;
	reg [2:0]  destination_save;
	reg done_reg;
	reg [3:0]  operation_save;
	
	initial begin
		done_reg = 0;
		cycles_we_have_stalled = 72;
	end

	always @(*) begin
		mem_wren_reg = 0;
		start_stalin = 0;
		case(operation_reg)
			DO_LOAD: begin
				mem_addr_out_reg = operand_0_reg + operand_1_reg;
				start_stalin = 1;
			end
			DO_STORE: begin
				mem_addr_out_reg = operand_0_reg + operand_1_reg;
				mem_wren_reg = 1;
				start_stalin = 1;
			end
		endcase
		
	end

	always @(posedge clk) begin
		if (start_stalin == 1) begin
			cycles_we_have_stalled <= 0;
			pc_save <= pc_in;
			operation_save <= operation_reg;
			destination_save <= destination_in;
		end else begin
			cycles_we_have_stalled <= cycles_we_have_stalled + 1;
		end
		if(cycles_we_have_stalled == 2) begin
			done_reg <= 1;
			if (operation_save == DO_LOAD) begin
				result_save <= load_value;
			end else begin
				destination_save <= 7;
			end
		end else begin
			done_reg <= 0;
		end
		pc_in_reg <= pc_in;
		operand_0_reg <= operand_0;
		operand_1_reg <= operand_1;
		operand_2_reg <= operand_2;
		store_value_reg <= operand_2;
		operation_reg <= operation;
		destination_in_reg <= destination_in;
	end
	
	assign mem_addr_out = mem_addr_out_reg;
	assign destination_out = destination_save;
	assign done = done_reg;
	assign pc_out = pc_save;
	assign result = result_save;
	assign mem_wren = mem_wren_reg;
	assign store_value = store_value_reg;
endmodule

////////////////////
// REORDER BUFFER //
////////////////////
module reorder_buffer(clk, 
		mather_0_pc, mather_0_register, mather_0_value, 
		mather_1_pc, mather_1_register, mather_1_value, 
		memoreer_0_pc, memoreer_0_register, memoreer_0_value, 
		writeout_register, writeout_value)
	
	input clk;
	
	input [15:0] mather_0_pc;
	input [3:0] mather_0_register;
	input [15:0] mather_0_value;
	
	input [15:0] mather_1_pc;
	input [3:0] mather_1_register;
	input [15:0] mather_1_value;
	
	input [15:0] memoreer_0_pc;
	input [3:0] memoreer_0_register;
	input [15:0] memoreer_0_value;
	
	output [3:0] writeout_register; 
	output [15:0] writeout_value;
	
	reg [3:0] writeout_register_reg;
	reg [15:0] writeout_value_reg;
	
	reg [15:0] current_reorder_pc;
	reg [15:0] reorder_values [15:0];
	reg [3:0]  reorder_registers [15:0];
	reg reorder_valid [15:0];
	
	reg [15:0] mather_0_index_reg;
	reg [3:0] mather_0_register_reg;
	reg [15:0] mather_0_value_reg;
	
	
	initial begin
		for (i = 0; i < 16; i = i + 1) begin
			reorder_registers[i] = 16'h8;
			reorder_valid[i] = 0;
		end
	end
	
	always @(*) begin
	
		mather_0_index_reg = mather_0_pc - current_reorder_pc;
		mather_1_index_reg = mather_1_pc - current_reorder_pc;
		memoreer_0_index_reg = memoreer_0_pc - current_reorder_pc;
	
		if (reorder_valid[0]) begin
			writeout_register_reg = reorder_registers[0];
			writeout_value_reg = reorder_value[0];
		end else begin
			writeout_register_reg = 7;
			writeout_value_reg = 0;
		end
	
	end 
	
	always @(posedge clk) begin
		if (mather_0_register != 8) begin
			reorder_values[mather_0_index_reg] <= mather_0_value;
			reorder_register[mather_0_index_reg] <= mather_0_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
		if (mather_1_register != 8) begin
			reorder_values[mather_1_index_reg] <= mather_1_value;
			reorder_register[mather_1_index_reg] <= mather_1_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
		if (memoreer_0_register != 8) begin
			reorder_values[memoreer_0_index_reg] <= memoreer_0_value;
			reorder_register[memoreer_0_index_reg] <= memoreer_0_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
	
		if (reorder_valid[0]) begin
			for (i = 0; i < 15; i = i + 1) begin
				reorder_values[i] <= reorder_values[i + 1];
				reorder_register[i] <= reorder_register[i + 1];
				reorder_valid[i] <= reorder_valid[i + 1];
			end
			reorder_valid[15] <= 0;
		end
	
	end

	assign writeout_register = writeout_register_reg;
	assign writeout_value = writeout_value_reg;
endmodule

//////////////////////////
// RESERVATION STATIONS //
//////////////////////////
module reservationer(clk, pc_in, operand_in, src1_in, src2_in, src1_type, src2_type, name, dest, all_names, all_values,
	op_out, arg1_out, arg2_out, pc_out, dest_out, name_out, stall_out)

	parameter functional_unit_number = 1;

	parameter VALUE = 1'b1;
	parameter NAME = 1'b0;

	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [3:0] operand_in;
	input [15:0] src1_in;
	input [15:0] src2_in;
	input src1_type;
	input src2_type;
	input [15:0] name;
	input [2:0] dest; //architected reg num
	input [16 * functional_unit_number - 1:0] all_names;
	input [16 * functional_unit_number - 1:0] all_values;
	
	output [3:0] op_out;
	output [15:0] arg1_out;
	output [15:0] arg2_out;
	output [15:0] pc_out;
	output [2:0] dest_out; //archtected reg num
	output [15:0] name_out;
	output stall_out;

	reg [3:0] ops_buffer [15:0];
	reg [15:0] arg1_buffer [15:0];
	reg [15:0] arg2_buffer [15:0];
	reg [15:0] pc_buffer [15:0];
	reg [2:0] dest_buffer [15:0];
	reg [15:0] name_buffer [15:0];
	reg arg1_type_buffer [15:0];
	reg arg2_type_buffer [15:0];

	reg [3:0] op_reg;
	reg [15:0] arg1_reg;
	reg [15:0] arg2_reg;
	reg [15:0] pc_reg;
	reg [2:0] dest_reg; //archtected reg num
	reg [15:0] name_reg;
	reg stall_reg;

	reg[3:0] open_slot;
	reg[3:0] ready_slot;
	reg [3:0] i;
	reg [3:0] j;
	reg      buffer_is_full = 1;
	reg is_there_something_ready;

	always @(*) begin
		buffer_is_full = 1;
		is_there_something_ready = 0;
		stall_reg = 0;
		for(i = 0; i < 16; i = i + 1) begin
			if(ops_buffer[i] == DO_NOP) begin
				open_slot = i;
				buffer_is_full = 0;
			end else if(arg1_type_buffer[i] == VALUE && arg2_type_buffer[i] == VALUE) begin
				ready_slot = i;
				is_there_something_ready = 1;
			end
		end
		if (buffer_is_full && op_in != DO_NOP) begin
			stall_reg = 1;
		end
	end

	always @(posedge clk) begin
		if (is_there_something_ready) begin
			op_reg <= ops_buffer[ready_slot];
			arg1_reg <= arg1_buffer[ready_slot];
			arg2_reg <= arg2_buffer[ready_slot];
			pc_reg <= pc_buffer[ready_slot];
			dest_reg <= dest_buffer[ready_slot];
			name_reg <= name_buffer[ready_slot];
			ops_buffer[ready_slot] <= DO_NOP; // indicate that this slot is now empty
		end else begin
			op_reg <= DO_NOP;
		end
		if (op_in != DO_NOP && !buffer_is_full) begin
			ops_buffer[open_slot] <= op_in;
			arg1_buffer[open_slot] <= src1_in;
			arg2_buffer[open_slot] <= src2_in;
			arg1_type_buffer[open_slot] <= src1_type;
			arg2_type_buffer[open_slot] <= src2_type;
			pc_buffer[open_slot] <= pc_in;
			dest_buffer[open_slot] <= dest_in;//y
			name_buffer[open_slot] <= name_in; //spree
		end
		for (i = 0; i < 16; i = i + 1) begin
			for (j = 0; j < functional_unit_number; j = j + 1) begin
				if (arg1_type_buffer[i] == NAME &&/*and*/all_names[16 * (j + 1) - 1:16 * j] == arg1_buffer[i]) begin
					arg1_buffer[i] <= all_values[16 * (j + 1) - 1:16 * j];
					arg1_type_buffer[i] <= VALUE;
				end
				if (arg2_type_buffer[i] == NAME &&/*and*/all_names[16 * (j + 1) - 1:16 * j] == arg2_buffer[i]) begin
					arg2_buffer[i] <= all_values[16 * (j + 1) - 1:16 * j];
					arg2_type_buffer[i] <= VALUE;
				end
			end
		end
	end

	assign op_out = op_reg;
	assign arg1_out = arg1_reg;
	assign arg2_out = arg2_reg;
	assign pc_out = pc_reg;
	assign dest_out = dest_reg; //archtected reg num
	assign name_out = name_reg;
	assign stall_out = stall_reg;

endmodule

////////////////////////////
// INFLIGHT REGISTER FILE //
////////////////////////////
module inflight_registers(
		clk,
		read_addrs,
		read_values,
		read_types,
		write_names,
		write_values,
		claim_addr,
		claim_name
		);

	parameter read_port_number  = 1;
	parameter write_port_number = 1;
	parameter VALUE = 1'b1;
	parameter NAME = 1'b0;

	input clk;

	input[3 * read_port_number - 1:0] read_addrs;
	input[16 * write_port_number - 1:0] write_names;
	input[16 * write_port_number - 1:0] write_values;

	input[2:0] claim_addr;
	input[15:0] claim_name;

	output[16 * read_port_number - 1:0] read_values;
	output[read_port_number - 1:0] read_types;

	// How do I for loop?
	reg[3:0] i;
	reg[3:0] j;

	reg[16 * read_port_number - 1:0] read_values_reg;
	reg[read_port_number - 1:0] read_types_reg;

	reg[15:0] regs [7:0];
	reg reg_types [7:0];
	
	initial begin
		for (i = 0; i < 8; i = i + 1) begin
			reg_types[i] = VALUE;
			regs[0] = 0;
		end
	end

	always @(*) begin
		for (i = 0; i < read_port_number; i = i + 1) begin
			read_values_reg[16 * (i + 1) - 1:16 * i] = regs[read_addrs[3* (i + 1) - 1:3 * i]];
			read_types_reg[i] = reg_types[i];
			// If we're getting a name, check if it just finished
			if (reg_types[i] == NAME) begin
				for (j = 0; j < write_port_number; j = j + 1) begin
					if (write_names[16 * (j + 1) - 1:16 * j] == regs[read_addrs[3* (i + 1) - 1:3 * i]]) begin
						read_values_reg[16 * (i + 1) - 1:16 * i] = write_values[16 * (j + 1) - 1:16 * j];
						read_types_reg[i] = VALUE;
					end
				end
			end
		end
	end

	assign read_values = read_values_reg;
	assign read_types = read_types_reg;

	always @(posedge clk) begin
		for (i = 0; i < 8; i = i + 1) begin
			// If there's a name in a reg, check if we got the value
			if (reg_types[i] == NAME) begin
				for (j = 0; j < write_port_number; j = j + 1) begin
					if (write_names[16 * (j + 1) - 1:16 * j] == regs[i]) begin
						regs[i] <= write_values[16 * (j + 1) - 1:16 * j];
						reg_types[i] <= VALUE;
					end
				end
			end
		end
		// If you are going to compute a register, then claim it
		if (claim_addr != 7) begin
			regs[claim_addr] <= claim_name;
			reg_types[claim_addr] <= NAME;
		end
	end
endmodule

/////////////////////////////
// COMMITTED REGISTER FILE //
/////////////////////////////
module committed_registers(
		clk, read_addr, read_value,
		write_addr, write_value, write_enable 
		);

	input clk;
	input write_enable;
	input[2:0] read_addr;
	input[2:0] write_addr;
	input[15:0] write_value;

	output[15:0] read_value;

	reg[15:0] rv;
	reg[15:0] regs [7:0];

	reg[3:0] i;
	
	initial begin
		for (i = 0; i < 8; i = i + 1) begin
			regs[0] = 0;
		end
	end

	always @(*) begin
		rv = regs[read_addr];
		if (write_enable && read_addr == write_addr) begin
			rv = write_value;
		end
	end

	assign read_value = rv;

	always @(posedge clk) begin
		if (write_addr != 7) begin
			regs[write_addr] <= write_value;
		end
	end
endmodule
