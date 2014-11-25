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

wire [15:0] committed_dbg;
wire [15:0] in_flight_dbg;


wire[15:0] reg_value_0;
wire[15:0] reg_value_1; 

reg[2:0] reg_addr_0;
reg[2:0] reg_addr_1;

wire [15:0] mather_0_pc_in;
wire [15:0] mather_0_operand_0;
wire [15:0] mather_0_operand_1;
wire [2:0] mather_0_operation;
wire [2:0] mather_0_dest_in; // E 
wire [2:0] mather_0_dest_out;
wire [15:0] mather_0_result;
wire [15:0] mather_0_pc_out;
wire [15:0] mather_0_name_out;
wire [15:0] mather_0_name_in;

wire [15:0] mather_1_pc_in;
wire [15:0] mather_1_operand_0;
wire [15:0] mather_1_operand_1;
wire [2:0] mather_1_operation;
wire [2:0] mather_1_dest_in; // E 
wire [2:0] mather_1_dest_out;
wire [15:0] mather_1_result;
wire [15:0] mather_1_pc_out;
wire [15:0] mather_1_name_out;
wire [15:0] mather_1_name_in;


wire [15:0] memoreer_0_pc_in;
wire [15:0] memoreer_0_operand_0;
wire [15:0] memoreer_0_operand_1;
wire [2:0] memoreer_0_operation;
wire [2:0] memoreer_0_dest_in; // E 
wire [2:0] memoreer_0_dest_out;
wire [15:0] memoreer_0_result;
wire [15:0] memoreer_0_pc_out;
wire [15:0] memoreer_0_name_out;
wire [15:0] memoreer_0_name_in;

wire [3:0] writeout_register;
wire [15:0] writeout_value;
wire [15:0] writeout_enable;

// Used to reserve what you are computing
reg [15:0] claim_name;
reg [3:0] claim_addr;

committed_registers a(
	.clk(clk),
	.read_addr(SW[2:0]),
	.read_value(committed_dbg),
	.write_addr(writeout_register),
	.write_value(writeout_value)
	);

inflight_registers  #(3, 3)b  (
	.clk(clk),
	.read_addrs({
		reg_addr_0,
		reg_addr_1,
		SW[2:0]
		}),
	.read_values({
		reg_value_0,
		reg_value_1,
		in_flight_dbg
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
wire reservationer_0_stall;
wire reservationer_1_stall;
wire reservationer_2_stall;
wire should_fetch_stall;

assign should_fetch_stall = reservationer_0_stall | reservationer_1_stall | reservationer_2_stall;
fetcher c(
	.clk(clk),
	.fetch_addr(instruction_addr),
	.pc_out(fetch_pc),
	.stall(should_fetch_stall)
	);

wire [15:0] memoreer_addr;
wire memory_wren;
wire [15:0] memory_value_in;
wire [15:0] memory_value_out;

ram2 d (
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

reg [15:0] next_name;
wire [2:0] next_op;
wire [3:0] next_source_0;
wire [3:0] next_source_1;
wire [15:0] next_pc;
wire [2:0] next_dest;
wire [15:0] immediate_out;
wire memoreer_0_done;

decoder_uno e(
	.clk(clk),
	.instruction_in(instruction),
	.pc_in(fetch_pc),
	.execute_op(next_op),
	.arg_0(next_source_0),
	.arg_1(next_source_1),
	.pc_out(next_pc),
	.immediate_out(immediate_out),
	.dest(next_dest),
	.stall(should_fetch_stall)
	);

mather f(
	.clk(clk),
	.pc_in(mather_0_pc_in),
	.operand_0(mather_0_operand_0),
	.operand_1(mather_0_operand_1),
	.operation(mather_0_operation),
	.destination_in(mather_0_dest_in), // E 
	.destination_out(mather_0_dest_out),
	.result(mather_0_result),
	.pc_out(mather_0_pc_out),
	.name_in(mather_0_name_in),
	.name_out(mather_0_name_out)
	);

mather g(
	.clk(clk),
	.pc_in(mather_1_pc_in),
	.operand_0(mather_1_operand_0),
	.operand_1(mather_1_operand_1),
	.operation(mather_1_operation),
	.destination_in(mather_1_dest_in), // E 
	.destination_out(mather_1_dest_out),
	.result(mather_1_result),
	.pc_out(mather_1_pc_out),
	.name_in(mather_1_name_in),
	.name_out(mather_1_name_out)
	);

reg [15:0] memoreer_0_operand_2;
wire [47:0] all_names = {mather_0_name_out, mather_1_name_out, memoreer_0_name_out};
wire [47:0] all_values = {mather_0_result, mather_1_result, memoreer_0_result};

memoreer h(
	.clk(clk),
	.pc_in(memoreer_0_pc_in),
	.operand_0(memoreer_0_operand_0),
	.operand_1(memoreer_0_operand_1),
	.operation(memoreer_0_operation),
	.destination_in(memoreer_0_dest_in), // E 
	.destination_out(memoreer_0_dest_out),
	.mem_addr_out(memoreer_addr),
	.mem_wren(memory_wren),
	.load_value(memory_value_out),
	.result(memoreer_0_result),
	.pc_out(memoreer_0_pc_out),
	.done(memoreer_0_done),
	.name_in(memoreer_0_name_in),
	.name_out(memoreer_0_name_out)
	);

// mather 0
reservationer     #(3)fgd (
	.clk(clk),
	.pc_in(next_pc),
	.op_in(reservationer_0_op),
	.src1_in(src_1_input),
	.src2_in(src_2_input),
	.src1_type(src_1_type),
	.src2_type(src_2_type),
	.name(next_name),
	.dest(next_dest),
	.all_names(all_names),
	.all_values(all_values),
	.op_out(mather_0_operation),
	.arg1_out(mather_0_operand_0),
	.arg2_out(mather_0_operand_1),
	.pc_out(mather_0_pc_in),
	.dest_out(mather_0_dest_in), // E
	.name_out(mather_0_name_in),
	.stall_out(reservationer_0_stall)
	);
	
reservationer  #(3) kljfgd(
	.clk(clk),
	.pc_in(next_pc),
	.op_in(reservationer_1_op),
	.src1_in(src_1_input),
	.src2_in(src_2_input),
	.src1_type(src_1_type),
	.src2_type(src_2_type),
	.name(next_name),
	.dest(next_dest),
	.all_names(all_names),
	.all_values(all_values),
	.op_out(mather_1_operation),
	.arg1_out(mather_1_operand_0),
	.arg2_out(mather_1_operand_1),
	.pc_out(mather_1_pc_in),
	.dest_out(mather_1_dest_in), // E
	.name_out(mather_1_name_in),
	.stall_out(reservationer_1_stall)
	);

reservationer  #(3)sazvdc (
	.clk(clk),
	.pc_in(next_pc),
	.op_in(reservationer_2_op),
	.src1_in(src_1_input),
	.src2_in(src_2_input),
	.src1_type(src_1_type),
	.src2_type(src_2_type),
	.name(next_name),
	.dest(next_dest),
	.all_names(all_names),
	.all_values(all_values),
	.op_out(memoreer_0_operation),
	.arg1_out(memoreer_0_operand_0),
	.arg2_out(memoreer_0_operand_1),
	.pc_out(memoreer_0_pc_in),
	.dest_out(memoreer_0_dest_in), // E
	.name_out(memoreer_0_name_in),
	.stall_out(reservationer_2_stall)
	);

	reorder_buffer i( 
	.clk(clk), 
	.mather_0_pc(mather_0_pc_out), 
	.mather_0_register(mather_0_dest_out), 
	.mather_0_value(mather_0_result), 
	.mather_1_pc(mather_1_pc_out), 
	.mather_1_register(mather_1_dest_out), 
	.mather_1_value(mather_1_result),
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
parameter DO_STORE=3'h3; // NONE OF THESE
parameter DO_NOP  =3'h4; 

parameter USE_PC = 4'he;
parameter USE_IMMEDIATE = 4'hf;

parameter VALUE = 1'b1;
parameter NAME = 1'b0;

reg[2:0] reservationer_0_op;
reg[2:0] reservationer_2_op;
reg[2:0] reservationer_1_op;

reg[15:0] src_1_input;
reg[15:0] src_2_input;
reg src_1_type;
reg src_2_type;

initial begin
	next_name = 0;
end

always @(*) begin
	reservationer_0_op = DO_NOP;
	reservationer_1_op = DO_NOP;
	reservationer_2_op = DO_NOP;
	if (next_op ==  DO_LOAD) begin
		reservationer_2_op = DO_LOAD;
	end else if (next_pc[0]) begin
		reservationer_0_op = next_op;
	end else begin
		reservationer_1_op = next_op;
	end

	if (next_op != DO_NOP) begin
		claim_addr = next_dest;
		claim_name = next_name;
	end
	if (next_source_0 == USE_PC) begin
		src_1_input = next_pc + 1;
		src_1_type = VALUE;
	end else if (next_source_0 == USE_IMMEDIATE) begin
		src_1_input = immediate_out;
		src_1_type = VALUE;
	end else begin
		reg_addr_0 = next_source_0[2:0];
		src_1_input = reg_value_0;
		src_1_type = reg_type_0;
	end
	if (next_source_1 == USE_PC) begin
		src_2_input = next_pc + 1;
		src_2_type = VALUE;
	end else if (next_source_1 == USE_IMMEDIATE) begin
		src_2_input = immediate_out;
		src_2_type = VALUE;
	end else begin
		reg_addr_1 = next_source_1[2:0];
		src_2_input = reg_value_1;
		src_2_type = reg_type_1;
	end

end

always @(posedge clk) begin
	next_name = next_name + 1;
end

///////////////////
// debug support //
///////////////////
reg [15:0]debug;

assign LEDR = fetch_pc[9:0];
assign LEDG = {reservationer_0_stall, reservationer_1_stall, reservationer_2_stall, 5'h0};

display fjff(debug[15:12], HEX3);
display jfjfjfj(debug[11:8], HEX2);
display jjjj(debug[7:4], HEX1);
display jj(debug[3:0], HEX0);

//do we display? no
always @(*) begin
	debug = 0;
	if (SW[9]) begin
		debug = instruction;
		if (SW[8])
			debug = {1'b0, next_op, next_source_0, next_source_1, 1'b0, next_dest};
		else if (SW[7])
			debug = immediate_out;
	end else if (SW[8]) begin
		debug = {1'b0, reservationer_0_op, 1'b0, reservationer_1_op, 1'b0, reservationer_2_op};
		if (SW[7]) begin
			debug = {1'b0, next_dest, 7'b0, src_1_type, 3'b0, src_2_type};
			if (SW[2])
				debug = next_name;
			else if (SW[1])
				debug = src_1_input;
			else if (SW[0])
				debug = src_2_input;
			end
	end else if (SW[7]) begin
		debug = {5'b0, mather_0_operation, 1'b0, mather_0_dest_in, 1'b0, mather_0_dest_out};
		if (SW[3])
			debug = mather_0_result;
		else if (SW[2])
			debug = mather_0_name_in;
		else if (SW[1])
			debug = mather_0_operand_1;
		else if (SW[0])
			debug = mather_0_operand_0;
	end else if (SW[6]) begin
		debug = {5'b0, mather_1_operation, 1'b0, mather_1_dest_in, 1'b0, mather_1_dest_out};
		if (SW[3])
			debug = mather_1_result;
		else if (SW[2])
			debug = mather_1_name_in;
		else if (SW[1])
			debug = mather_1_operand_1;
		else if (SW[0])
			debug = mather_1_operand_0;
	end else if (SW[5]) begin
		debug = {5'b0, memoreer_0_operation, 1'b0, memoreer_0_dest_in, 1'b0, memoreer_0_dest_out};
		if (SW[3])
			debug = memoreer_0_result;
		else if (SW[2])
			debug = memoreer_0_name_in;
		else if (SW[1])
			debug = memoreer_0_operand_1;
		else if (SW[0])
			debug = memoreer_0_operand_0;
	end else if (SW[4]) begin
		if(SW[3])
			debug = in_flight_dbg;
		else
			debug = {15'b0, reg_type_dbg};
	end else if (SW[3]) begin
		debug = committed_dbg;
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

module mather (clk, pc_in, operand_0, operand_1, operation, destination_in, destination_out, result, pc_out, name_in, name_out);

	parameter DO_ADD = 4'h0;
	parameter DO_SUB = 4'h1;
	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [15:0] operation;
	input [2:0]  destination_in;
	input [15:0] name_in;

	output [2:0] destination_out;
	output [15:0] result;
	output [15:0] pc_out;
	output [15:0] name_out;

	reg [15:0] operand_0_reg;
	reg [15:0] operand_1_reg;
	reg [15:0] operation_reg;
	reg [2:0]  destination_in_reg;
	
	reg [15:0] result_reg;
	reg [15:0] result_latch;
	reg [2:0] dest_latch;
	reg [15:0] pc_latch;
	reg [15:0] name_latch;
	
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
		name_latch <= name_in;
	end

	assign result = result_latch;
	assign destination_out = dest_latch;
	assign pc_out = pc_latch;
	assign name_out = name_latch;
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
	operation, 	destination_in,	destination_out, 	mem_addr_out,
	mem_wren, 	load_value,	result,	pc_out, done, name_in, name_out);

	parameter DO_LOAD= 3'h2;
	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [15:0] name_in;
	input [15:0] operand_0;
	input [15:0] operand_1;
	input [3:0]  operation;
	input [3:0]  destination_in;
	input [15:0] load_value;
	output [3:0] destination_out;
	output [15:0] mem_addr_out;
	output [15:0] result;
	output [15:0] pc_out;	
	output [15:0] name_out;	
	output mem_wren;

	output done;

	reg [15:0] pc_in_reg;
	reg [15:0] name_in_reg;
	reg [15:0] operand_0_reg;
	reg [15:0] operand_1_reg;
	reg [3:0]  operation_reg;
	reg [3:0]  destination_in_reg;
	
	reg [15:0] mem_addr_out_reg;
	reg [31:0] cycles_we_have_stalled;
	reg start_stalin;
	reg mem_wren_reg;

	reg [15:0] result_save;
	reg [15:0] pc_save;
	reg [15:0] name_save;
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
			
		endcase
		
	end

	always @(posedge clk) begin
		if (start_stalin == 1) begin
			cycles_we_have_stalled <= 0;
			pc_save <= pc_in_reg;
			name_save <= name_in_reg;
			operation_save <= operation_reg;
			destination_save <= destination_in_reg;
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
		name_in_reg <= name_in;
		operand_0_reg <= operand_0;
		operand_1_reg <= operand_1;
		operation_reg <= operation;
		destination_in_reg <= destination_in;
	end
	
	assign mem_addr_out = mem_addr_out_reg;
	assign destination_out = destination_save;
	assign done = done_reg;
	assign pc_out = pc_save;
	assign name_out = name_save;
	assign result = result_save;
	assign mem_wren = mem_wren_reg;
endmodule

////////////////////
// REORDER BUFFER //
////////////////////
module reorder_buffer(clk, 
		mather_0_pc, mather_0_register, mather_0_value, 
		mather_1_pc, mather_1_register, mather_1_value, 
		memoreer_0_pc, memoreer_0_register, memoreer_0_value, 
		writeout_register, writeout_value);
	
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
	reg [15:0] mather_1_index_reg;
	reg [3:0] mather_1_register_reg;
	reg [15:0] mather_1_value_reg;
	reg [15:0] memoreer_0_index_reg;
	reg [3:0] memoreer_0_register_reg;
	reg [15:0] memoreer_0_value_reg;
	reg [4:0] i;
	
	initial begin
		current_reorder_pc = 0;
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
			writeout_value_reg = reorder_values[0];
		end else begin
			writeout_register_reg = 7;
			writeout_value_reg = 0;
		end
	
	end 
	
	always @(posedge clk) begin
		if (mather_0_register != 8) begin
			reorder_values[mather_0_index_reg] <= mather_0_value;
			reorder_registers[mather_0_index_reg] <= mather_0_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
		if (mather_1_register != 8) begin
			reorder_values[mather_1_index_reg] <= mather_1_value;
			reorder_registers[mather_1_index_reg] <= mather_1_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
		if (memoreer_0_register != 8) begin
			reorder_values[memoreer_0_index_reg] <= memoreer_0_value;
			reorder_registers[memoreer_0_index_reg] <= memoreer_0_register;
			reorder_valid[mather_0_index_reg] <= 1;
		end
	
		if (reorder_valid[0]) begin
			for (i = 0; i < 15; i = i + 1) begin
				reorder_values[i] <= reorder_values[i + 1];
				reorder_registers[i] <= reorder_registers[i + 1];
				reorder_valid[i] <= reorder_valid[i + 1];
			end
			reorder_valid[15] <= 0;
			current_reorder_pc <= current_reorder_pc + 1;
		end
	
	end

	assign writeout_register = writeout_register_reg;
	assign writeout_value = writeout_value_reg;
endmodule

//////////////////////////
// RESERVATION STATIONS //
//////////////////////////
module reservationer(clk, pc_in, op_in, src1_in, src2_in, src1_type, src2_type, name, dest, all_names, all_values,
	op_out, arg1_out, arg2_out, pc_out, dest_out, name_out, stall_out);

	parameter functional_unit_number = 1;

	parameter VALUE = 1'b1;
	parameter NAME = 1'b0;

	parameter DO_NOP  =3'h4; 

	input clk;
	input [15:0] pc_in;
	input [3:0] op_in;
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
	reg [4:0] i;
	reg [4:0] j;
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
			dest_buffer[open_slot] <= dest;//y
			name_buffer[open_slot] <= name; //spree
		end
		for (i = 0; i < 16; i = i + 1) begin
			for (j = 0; j < functional_unit_number; j = j + 1) begin
				if (arg1_type_buffer[i] == NAME &&/*and*/all_names[16 * j+:16] == arg1_buffer[i]) begin
					arg1_buffer[i] <= all_values[16 * j+:16];
					arg1_type_buffer[i] <= VALUE;
				end
				if (arg2_type_buffer[i] == NAME &&/*and*/all_names[16 * j+:16] == arg2_buffer[i]) begin
					arg2_buffer[i] <= all_values[16 * j+:16];
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
			regs[i] = 0;
		end
	end

	always @(*) begin
		for (i = 0; i < read_port_number; i = i + 1) begin
			read_values_reg[16 * i+:16] = regs[read_addrs[3* i+:3]];
			read_types_reg[i] = reg_types[i];
			// If we're getting a name, check if it just finished
			if (reg_types[i] == NAME) begin
				for (j = 0; j < write_port_number; j = j + 1) begin
					if (write_names[16 * j+:16] == regs[read_addrs[3* i+:3]]) begin
						read_values_reg[16 * i+:16] = write_values[16 * j+:16];
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
					if (write_names[16 * j+:16] == regs[i]) begin
						regs[i] <= write_values[16 * j+:16];
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
		write_addr, write_value
		);

	input clk;
	input[2:0] read_addr;
	input[2:0] write_addr;
	input[15:0] write_value;

	output[15:0] read_value;

	reg[15:0] rv;
	reg[15:0] regs [7:0];

	reg[3:0] i;
	
	initial begin
		for (i = 0; i < 8; i = i + 1) begin
			regs[i] = 0;
		end
	end

	always @(*) begin
		rv = regs[read_addr];
		if (write_addr != 7 && read_addr == write_addr) begin
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
