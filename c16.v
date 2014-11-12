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

wire[15:0] reg_0;
wire[15:0] reg_1;
wire[15:0] reg_2;
wire[15:0] reg_3;
wire[15:0] reg_4;
wire[15:0] reg_dbg;

wire[2:0] reg_addr_0;
wire[2:0] reg_addr_1;
wire[2:0] reg_addr_2;
wire[2:0] reg_addr_3;
wire[2:0] reg_addr_4;

wire [15:0] mather_0_pc_in;
wire [15:0] mather_0_operand_0;
wire [15:0] mather_0_operand_1;
wire [2:0] mather_0_operation;
wire [2:0] mather_0_dest_in; // E 
wire [2:0] mather_0_dest_out;
wire [15:0] mather_0_result;
wire [15:0] mather_0_pc_out;

wire [15:0] mather_1_pc_in;
wire [15:0] mather_1_operand_0;
wire [15:0] mather_1_operand_1;
wire [2:0] mather_1_operation;
wire [2:0] mather_1_dest_in; // E 
wire [2:0] mather_1_dest_out;
wire [15:0] mather_1_result;
wire [15:0] mather_1_pc_out;

wire [15:0] memoreer_pc_in;
wire [15:0] memoreer_operand_0;
wire [15:0] memoreer_operand_1;
wire [2:0] memoreer_operation;
wire [2:0] memoreer_dest_in; // E 
wire [2:0] memoreer_dest_out;
wire [15:0] memoreer_result;
wire [15:0] memoreer_pc_out;

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
	.write_addr_2(memoreer_dest_out),
	.write_value_2(memoreer_result),
	.read_value_0(reg_0),
	.read_value_1(reg_1),
	.read_value_2(reg_2),
	.read_value_3(reg_3),
	.read_value_4(reg_4),
	.read_value_dbg(reg_dbg)
	);

wire[15:0] instruction_addr;
wire[15:0] instruction;
wire[15:0] branch_pc;
wire[15:0] fetch_pc;

wire pc_write_enable;

fetcher(
	.clk(clk),
	.pc_write_enable(pc_write_enable),
	.pc_in(branch_pc),
	.pc_out(fetch_pc),
	.instruction(instruction)
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

decoder_uno(
	.clk(clk),
	.instruction(instruction),
	.pc_in(fetch_pc),
	.execute_op(scorebored_op),
	.arg_0(scorebored_source_0),
	.arg_1(scorebored_source_1),
	.pc_out(scorebored_pc),
	.dest(scorebored_dest)
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
	.pc_in(memoreer_pc_in),
	.operand_0(memoreer_operand_0),
	.operand_1(memoreer_operand_1),
	.operation(memoreer_operation),
	.destination_in(memoreer_dest_in), // E 
	.destination_out(memoreer_dest_out),
	.mem_addr_out(memoreer_addr),
	.mem_wren(memory_wren),
	.mem_value_out(memory_value_in),
	.mem_value_in(memory_value_out),
	.result(memoreer_result),
	.pc_out(memoreer_pc_out)
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

output should_fetch_stall;

reg should_fetch_stall_reg;


reg [2:0] Instruction_Status [2:0]; // goes with IN_???_STATE
reg [2:0] Register_Status [7:0];  //   what functional unit will produce the value for each register

reg [2:0] Busy [2:0]; // indexed by MATHER_0 and shit

reg [2:0] FU_Operations[2:0]; // the operation each FU will perform
reg [2:0] Dest_Register [2:0];
reg [2:0] Source_Register_0 [2:0]; // register number for operand 0
reg [2:0] Source_Register_1 [2:0];
reg [2:0] Source_Register_0_Resource [2:0];  // where operand 0 is being computed
reg [2:0] Source_Register_1_Resource [2:0]; 
reg [2:0] Source_Register_0_Ready [2:0];     // whether or not the register for operand 0 is ready to be used or in use by something else
reg [2:0] Source_Register_1_Ready [2:0];

reg [15:0] Operand_Values_0[2:0];
reg [15:0] Operand_Values_1[2:0];

reg [2:0] Result [2:0];

reg [2:0] resource_to_use;

initial begin
	Busy[0] = NOT_BUSY;
	Busy[1] = NOT_BUSY;

	Busy[2] = NOT_BUSY;
	Busy[3] = NOT_BUSY;
	
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
				read_addr_0 = Source_Register_0[MATHER_0];
				Operand_Values_0[MATHER_0] = read_value_0;
			end else if(Source_Register_0_Ready[MATHER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
			end

			if (Source_Register_1_Ready[MATHER_0] == READY) begin
				read_addr_1 = Source_Register_1[MATHER_0];
				Operand_Values_1[MATHER_0] = read_value_1;
			end else if(Source_Register_1_Ready[MATHER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
			end

		end
	end

	if (Busy[MATHER_1] == BUSY) begin
		if (Source_Register_0_Ready[MATHER_1] != NOT_READY  && Source_Register_1_Ready[MATHER_1] != NOT_READY) begin
			mather_1_operation = FU_Operations[MATHER_1];

			// both sources are ready. send data to functional unit
			if (Source_Register_0_Ready[MATHER_1] == READY) begin
				read_addr_2 = Source_Register_0[MATHER_1];
				Operand_Values_0[MATHER_1] = read_value_2;
			end else if(Source_Register_0_Ready[MATHER_1] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
			end

			if (Source_Register_1_Ready[MATHER_1] == READY) begin
				read_addr_3 = Source_Register_1[MATHER_1];
				Operand_Values_1[MATHER_1] = read_value_3;
			end else if(Source_Register_1_Ready[MATHER_1] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
			end

		end
	end

	if (Busy[MEMOREER_0] == BUSY) begin
		if (Source_Register_0_Ready[MEMOREER_0] != NOT_READY  && Source_Register_1_Ready[MEMOREER_0] != NOT_READY) begin
			memoreer_0_operation = FU_Operations[MEMOREER_0];

			// both sources are ready. send data to functional unit
			if (Source_Register_0_Ready[MEMOREER_0] == READY) begin
				read_addr_4 = Source_Register_0[MEMOREER_0];
				Operand_Values_0[MEMOREER_0] = read_value_4;
			end else if(Source_Register_0_Ready[MEMOREER_0] == ACTUALLY_IMMEDIATE_VALUE) begin
				//n nothing, because immediate value are by default placed in Operand_Values_0/1
			end

		end
	end

end

always @(posedge clk) begin
	if (resource_to_use != NO_RESOURCE) begin
		Busy[resource_to_use] <= BUSY;
		Dest_Register[resource_to_use] <= scorebored_dest;
		Source_Register_0[resource_to_use] <= scorebored_source_0;
		Source_Register_1[resource_to_use] <= scorebored_source_1;
		Source_Register_0_Resource[resource_to_use] <= Register_Status[scorebored_source_0];
		Source_Register_1_Resource[resource_to_use] <= Register_Status[scorebored_source_1];
		Source_Register_0_Ready[resource_to_use] <= NOT_READY;
		Register_Status[scorebored_dest] <= resource_to_use;
	end
end
	
assign should_fetch_stall = should_fetch_stall_reg;

///////////////////
// debug support //
///////////////////
reg [15:0]debug;

assign LEDR = next_x_pc[9:0];//fetch_pc[9:0];

display(debug[15:12], HEX3);
display(debug[11:8], HEX2);
display(debug[7:4], HEX1);
display(debug[3:0], HEX0);

// what do we display
always @(*) begin
   if (SW[3]) begin
		debug = instruction;
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

	reg[15:0] all_read_addrs[5:0] = {read_addr_0,read_addr_1,read_add_2,read_addr_3,read_addr_4,read_addr_dbg};
	reg[15:0] all_write_addrs[2:0] = {write_addr_0,write_addr_1,write_addr_2};
	reg[15:0] all_write_values[2:0] = {write_value_0,write_value_1,write_value_2};
	reg[15:0] all_rv[5:0];

	reg [15:0]regs[7:0];
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
			all_rv[i] = all_read_addrs[i];
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
	assign read_value_0 = all_rv[1];
	assign read_value_0 = all_rv[2];
	assign read_value_0 = all_rv[3];
	assign read_value_0 = all_rv[4];
	assign read_value_dbg = all_rv[5];

endmodule


/////////////////////////
// FETCH STAGE         //
/////////////////////////
module fetcher(clk, pc_write_enable, pc_in, pc_out, instruction);

	input clk;
	input pc_write_enable;

	input[15:0] pc_in;

	output[15:0] pc_out;
	output[15:0] instruction;

	reg[15:0] fetch_pc;
	reg[15:0] next_fetch_pc;

	wire [15:0]mem_out;

	initial begin
		fetch_pc = -1;
	end

	always @(*) begin
		if(pc_write_enable == 1) begin
			next_fetch_pc = pc_in;
		end else begin
			next_fetch_pc = fetch_pc + 1;
		end
	end

	always @(posedge clk) begin
		fetch_pc <= next_fetch_pc;
	end

	assign instruction = mem_out;
	assign pc_out = fetch_pc;

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


	input clk;
	input [15:0] pc_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [15:0] operation;
	input [2:0]  destination_in;

	output [2:0] destination_out;
	output [15:0] result;
	output [15:0] pc_out;

	reg [15:0] result_reg;
	reg [15:0] result_latch;
	reg [15:0] dest_latch;
	reg [15:0] pc_latch;

	always @(*)
		case (operation)
			DO_ADD: result_reg = operand_0 + operand_1;
			DO_SUB: result_reg = operand_0 - operand_1;
		endcase

	always @(posedge clk) begin
		result_latch <= result_reg;
		dest_latch <= destination_in;
		pc_latch <= pc_in;
	end

	assign result = result_latch;
	assign destination_out = dest_latch;
	assign pc_out = pc_latch;
endmodule

/*
Data structure[edit]
To control the execution of the instructions, the scoreboard maintains three status tables:

Instruction Status: Indicates, for each instruction being executed, which of the four stages it is in.
Functional Unit Status: Indicates the state of each functional unit. Each function unit maintains 9 fields in the table:
Busy: Indicates whether the unit is being used or not
Op: Operation to perform in the unit (e.g. MUL, DIV or MOD)
Fi: Destination register
Fj,Fk: Source-register numbers
Qj,Qk: Functional units that will produce the source registers Fj, Fk
Rj,Rk: Flags that indicates when Fj, Fk are ready
Register Status: Indicates, for each register, which function unit will write results into it.
The algorithm[edit]
The detailed algorithm for the scoreboard control is described below:

 function issue(op, dst, src1, src2)
    wait until (!Busy[FU] AND !Register_Status[dst]); // FU can be any functional unit that can execute operation op
    Busy[FU] ← Yes;
    Op[FU] ← op;
    Fi[FU] ← dst;
    Fj[FU] ← src1;
    Fk[FU] ← src2;
    Qj[FU] ← Result[src1];
    Qk[FU] ← Result[src2];
    Rj[FU] ← not Qj;
    Rk[FU] ← not Qk;
    Register_Status[dst] ← FU;

 function read_operands(FU)
    wait until (Rj[FU] AND Rk[FU]);
    Rj[FU] ← No;
    Rk[FU] ← No;

 function execute(FU)
    // Execute whatever FU must do

 function write_back(FU)
    wait until (\forallf {(Fj[f]≠Fi[FU] OR Rj[f]=No) AND (Fk[f]≠Fi[FU] OR Rk[f]=No)})
    foreach f do
        if Qj[f]=FU then Rj[f] ← Yes;
        if Qk[f]=FU then Rk[f] ← Yes;
    Result[Fi[FU]] ← 0;
    Busy[FU] ← No;
*/

module decoder_uno();
endmodule

module decoder_deux();
endmodule

module memoreer(clk, pc_in, operand_0, operand_1, operation, destination_in, destination_out, result, pc_out);
endmodule
