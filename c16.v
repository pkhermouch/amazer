
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
wire[15:0] reg_dbg;
wire[15:0] reg_write_value;

wire[2:0] reg_addr_0;
wire[2:0] reg_addr_1;
wire[2:0] reg_write_dest;
wire[2:0] memory_value_dest;

wire reg_write_enable;
wire memory_value_enable;

registers(
	.clk(clk),
	.read_addr_0(reg_addr_0),
	.read_addr_1(reg_addr_1),
	.read_addr_dbg(SW[2:0]),
	.write_addr(reg_write_dest),
	.write_value(reg_write_value),
	.write_enable(reg_write_enable),
	.read_value_0(reg_0),
	.read_value_1(reg_1),
	.read_value_dbg(reg_dbg),
	.memory_value(memory_out),
	.memory_value_dest(memory_value_dest), //value from decode for load isntructions
	.memory_value_enable(memory_value_enable) //value from decode for load instructions
	);

wire memory_write_enable;

wire[15:0] instruction_addr;
wire[15:0] memory_addr;
wire[15:0] instruction;
wire[15:0] memory_out;
wire[15:0] memory_in;
	
ram2 (
	.address_a(instruction_addr),
	.address_b(memory_addr),
	.clock(clk),
	.data_a(0),
	.data_b(memory_in),
	.wren_a(0),
	.wren_b(memory_write_enable),
	.q_a(instruction),
	.q_b(memory_out) // value out for load instructions
	);

wire[15:0] branch_pc;
wire[15:0] fetch_pc;

wire pc_write_enable;
wire stall;

fetcher(
	.clk(clk),
	.pc_write_enable(pc_write_enable),
	.pc_in(branch_pc),
	.stall(stall),
	.next_pc(instruction_addr),
	.pc_out(fetch_pc),
	);

wire[2:0] next_x_dest;
wire[3:0] next_x_op;

wire[15:0] next_x_pc;
wire[15:0] arg_0;
wire[15:0] arg_1;

decoder(
	.clk(clk),
	.instruction(instruction),
	.pc_in(fetch_pc),
	.reg_0(reg_0),
	.reg_1(reg_1),
	.execute_op(next_x_op),
	.stall(stall),
	.reg_addr_0(reg_addr_0),
	.reg_addr_1(reg_addr_1),
	.arg_0(arg_0),
	.arg_1(arg_1),
	.pc_out(next_x_pc),
	.dest(next_x_dest),
	.memory_write_enable(memory_write_enable),
	.memory_value_dest(memory_value_dest),
	.memory_value_enable(memory_value_enable)
	);


executor(
	.clk(clk),
	.execute_op(next_x_op),
	.arg_0(arg_0),
	.arg_1(arg_1),
	.dest_in(next_x_dest),
	.pc_in(next_x_pc),
	.dest_out(reg_write_dest),
	.reg_value_out(reg_write_value),
	.reg_write_enable(reg_write_enable),
	.pc_value_out(branch_pc),
	.pc_write_enable(pc_write_enable)
	);

	assign memory_addr = reg_write_value;
	assign memory_in = reg_1;//reg_0;

///////////////////
// debug support //
///////////////////
reg [15:0]debug;

assign LEDR = next_x_pc[9:0];

display(debug[15:12], HEX3);
display(debug[11:8], HEX2);
display(debug[7:4], HEX1);
display(debug[3:0], HEX0);

// what do we display
always @(*) begin
	if (SW[7]) begin
		debug = memory_in;
	end else if (SW[6]) begin
		debug = reg_write_value;
	end else if (SW[5]) begin
		debug = {1'b0, memory_value_dest, memory_value_enable, 11'b0};
	end else if (SW[4]) begin
		debug = memory_out;
	end else if (SW[3]) begin
		debug = instruction;
	end else begin
		debug = reg_dbg;
	end
end


endmodule


/////////////////////////
// REGISTER FILE       //
/////////////////////////
module registers(clk, read_addr_0, read_addr_1, read_addr_dbg, write_addr, write_value, 
	write_enable, read_value_0, read_value_1, read_value_dbg, memory_value, memory_value_dest, memory_value_enable);

	input[2:0] read_addr_0;
	input[2:0] read_addr_1;
	input[2:0] read_addr_dbg;
	input[2:0] write_addr;
	input[2:0] memory_value_dest;
	
	input write_enable;
	input clk;
	input memory_value_enable;

	input[15:0] write_value;
	input[15:0] memory_value;

	output[15:0] read_value_0;
	output[15:0] read_value_1;
	output[15:0] read_value_dbg;
	
	reg[15:0] rv0;
	reg[15:0] rv1;
	reg[15:0] rvdbg;

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
		rv0 = regs[read_addr_0];
		rv1 = regs[read_addr_1];
		rvdbg = regs[read_addr_dbg];
		if (write_enable && write_addr != 7) begin
			if (write_addr == read_addr_0) begin
				rv0 = write_value;
			end
			if (write_addr == read_addr_1) begin
				rv1 = write_value;
			end
			if (write_addr == read_addr_dbg) begin
				rvdbg = write_value;
			end
		end
		if (memory_value_enable && memory_value_dest != 7) begin
			if (memory_value_dest == read_addr_0) begin
				rv0 = memory_value;
			end
			if (memory_value_dest == read_addr_1) begin
				rv1 = memory_value;
			end
			if (memory_value_dest == read_addr_dbg) begin
				rvdbg = memory_value;
			end
		end
	end

	always @(posedge clk) begin
		if (write_enable && write_addr != 7) begin
			regs[write_addr] <= write_value;
		end
		if (memory_value_enable && memory_value_dest != 7) begin
			regs[memory_value_dest] <= memory_value;
		end
	end

	assign read_value_0 = rv0;
	assign read_value_1 = rv1;
	assign read_value_dbg = rvdbg;

endmodule


/////////////////////////
// FETCH STAGE         //
/////////////////////////
module fetcher(clk, pc_write_enable, pc_in, stall, next_pc, pc_out);

	input clk;
	input pc_write_enable;
	input stall;

	input[15:0] pc_in;
	
	
	output[15:0] next_pc;
	output[15:0] pc_out;

	reg[15:0] fetch_pc;
	reg[15:0] next_fetch_pc;

	initial begin
		fetch_pc = -1;
	end

	always @(*) begin
		if(pc_write_enable == 1) begin
			next_fetch_pc = pc_in;
		end else if (stall) begin
			next_fetch_pc = fetch_pc;
		end else begin
			next_fetch_pc = fetch_pc + 1;
		end
	end

	always @(posedge clk) begin
		fetch_pc <= next_fetch_pc;
	end

	assign next_pc = next_fetch_pc;
	assign pc_out = fetch_pc;

endmodule

/////////////////////////
// DECODE STAGE        //
/////////////////////////
module decoder(clk, instruction, pc_in, reg_0, reg_1, execute_op, stall, reg_addr_0, reg_addr_1,
	arg_0, arg_1, pc_out, dest, memory_write_enable, memory_value_dest, memory_value_enable);

	// Execute stage's parameters
	parameter ADD = 4'h0;
	parameter SET = 4'h1;
	parameter NOP = 4'h2;
	parameter SHFT = 4'h3;
	parameter CALL = 4'h4;
	parameter BRZ = 4'h5;
	// Decode stage's parameters for micro-ops
	parameter LD = 4'h6;
	parameter ST = 4'h7;
	parameter LD_WB = 4'h8;

	input clk;

	input[15:0] instruction;
	input[15:0] pc_in;
	input[15:0] reg_0;
	input[15:0] reg_1;

	output[15:0] arg_0;
	output[15:0] arg_1;
	output[15:0] pc_out;
	
	output stall;

	output[2:0] dest;
	output[3:0] execute_op;
	output[2:0] reg_addr_0;
	output[2:0] reg_addr_1;
	
	output[15:0] memory_value_dest;
	output memory_value_enable;
	output memory_write_enable;

	reg[3:0] execute_op_reg;
	reg[15:0] arg_0_reg;
	reg[15:0] arg_1_reg;
	reg[15:0] pc_out_reg;
	reg[2:0] dest_reg;
	reg[15:0] memory_value_dest_reg;
	reg memory_value_enable_reg;
	reg memory_write_enable_reg;

	reg[3:0] execute_op_out;
	reg[15:0] arg_0_out;
	reg[15:0] arg_1_out;
	reg[15:0] pc_out_out;
	reg[2:0] dest_out;
	reg[15:0] memory_value_dest_out;
	reg memory_value_enable_out;

	// Used to implement brz
	reg[2:0] reg_addr_1_reg;
	// Used to implement branching and count how many cycles we need to do nothing
	reg[1:0] cycles_to_stall;
	
	// Used for micro-ops
	reg[3:0] next_decode_op;
	reg[3:0] decode_op;
	reg[2:0] decode_op_rd;
	
	reg stall_reg;
	
	initial begin
		decode_op = NOP;
	end

	wire [4:0] opcode = instruction[15:11];
	wire [2:0] rd = instruction[10:8];

	wire [15:0]imm5 = $signed(instruction[4:0]);
	wire [15:0]imm8 = $signed(instruction[7:0]);

	always @(*) begin
		pc_out_reg = pc_in;
		dest_reg = rd;
		execute_op_reg = NOP;
		next_decode_op = NOP;
		arg_0_reg = 0;
		arg_1_reg = 0;
		reg_addr_1_reg = instruction[2:0];
		stall_reg = 0;
		memory_value_dest_reg = 7;
		memory_value_enable_reg = 0;
		memory_write_enable_reg = 0;
		case (opcode)
			// Add, f = 0
			5'b00000: begin
				execute_op_reg = ADD;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end

			// Add, f = 1
			5'b00001: begin
				execute_op_reg = ADD;
				arg_0_reg = reg_0;
				arg_1_reg = reg_1;
			end

			// Slt, f = 0
			5'b00100: begin
				execute_op_reg = SET;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end

			// Slt, f = 1
			5'b00101: begin
				execute_op_reg = SET;
				arg_0_reg = reg_0;
				arg_1_reg = reg_1;
			end

			// Lea, f = 0
			5'b11000: begin
				execute_op_reg = ADD;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end

			// Lea, f = 1
			5'b11001: begin
				execute_op_reg = ADD;
				arg_0_reg = pc_in;
				arg_1_reg = imm8;
			 end

			// Call, f = 0
			5'b11010: begin
				execute_op_reg = CALL;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end

			// Call, f = 1
			5'b11011: begin
				execute_op_reg = CALL;
				arg_0_reg = pc_in;
				arg_1_reg = imm8;
			end

			// brz, f = 0
			5'b11110: begin
				execute_op_reg = BRZ;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
				reg_addr_1_reg = rd;
			end

			// brz, f = 1
			5'b11111: begin
				execute_op_reg = BRZ;
				arg_0_reg = pc_in;
				arg_1_reg = imm8;
				reg_addr_1_reg = rd;
			end

			// shl, f = 0
			5'b10000: begin
				execute_op_reg = SHFT;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end

			// shl, f = 1
			5'b10001: begin
				execute_op_reg = SHFT;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
			end
			
			// loads and stores are broken up into two micro ops
			// the first does the addition and pipes the result to magical register 8,
			// and the second micro op issues a load/store from/to the value in register 8
			
			// ld, f = 0
			5'b10100: begin
				execute_op_reg = ADD;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
				dest_reg = 7;
				next_decode_op = LD;
				stall_reg = 1;
			end
			
			// ld, f = 1
			5'b10101: begin
				execute_op_reg = ADD;
				arg_0_reg = pc_in;
				arg_1_reg = imm8;
				dest_reg = 7;
				next_decode_op = LD;
				stall_reg = 1;
			end
			
			// st, f = 0
			5'b10110: begin
				execute_op_reg = ADD;
				arg_0_reg = reg_0;
				arg_1_reg = imm5;
				dest_reg = 7;
				next_decode_op = ST;
				stall_reg = 1;
			end
			
			//st, f = 1
			5'b10111: begin
				execute_op_reg = ADD;
				arg_0_reg = pc_in;
				arg_1_reg = imm8;
				dest_reg = 7;
				next_decode_op = ST;
				stall_reg = 1;
			end
		endcase
		
		case (decode_op)
			NOP: begin
			end
			
			// if either of these are true then the address is in R8 and it is ready
			LD: begin
				execute_op_reg = NOP;
				next_decode_op = LD_WB;
				stall_reg = 1;
			end
			ST: begin
				execute_op_reg = NOP;
				next_decode_op = NOP;
				reg_addr_1_reg = decode_op_rd;
				memory_write_enable_reg = 1;
				stall_reg = 0;
			end
			
			// we started reading last cycle and the memory is about to be ready
			LD_WB: begin
				execute_op_reg = NOP;
				next_decode_op = NOP;
				memory_value_dest_reg = decode_op_rd;
				memory_value_enable_reg = 1;
				stall_reg = 0;
			end
		endcase
	end

	assign reg_addr_0 = instruction[7:5];
	assign reg_addr_1 = reg_addr_1_reg;
	assign stall = stall_reg;//& (cycles_to_stall == 0);
	assign memory_write_enable = memory_write_enable_reg;

	always @(posedge clk) begin
		arg_0_out <= arg_0_reg;
		arg_1_out <= arg_1_reg;
		execute_op_out <= execute_op_reg;
		// Special case for BRZ
		if (execute_op_reg == BRZ) begin
			if (reg_1 != 0) begin
				execute_op_out <= NOP;
			end
			else if (cycles_to_stall == 0) begin
				cycles_to_stall <= 2'h2;
			end
		end
		// If we're jumping unconditionally, set the cycles to stall to 2
		if (execute_op_reg == CALL && cycles_to_stall == 0) begin
			cycles_to_stall <= 2'h2;
		end
		/*
		if (execute_op_reg == BRZ && reg_1 != 0) begin
			execute_op_out <= NOP;
		end
		*/
		pc_out_out <= pc_out_reg;
		dest_out <= dest_reg;
		decode_op <= next_decode_op;
		memory_value_dest_out <= memory_value_dest_reg;
		memory_value_enable_out <= memory_value_enable_reg;
		if (next_decode_op == LD || next_decode_op == ST) begin
			decode_op_rd <= rd;
		end else begin
			decode_op_rd <= decode_op_rd;
		end
		if (cycles_to_stall > 0) begin
			execute_op_out <= NOP;
			decode_op_rd <= NOP;
			memory_value_enable_out <= 0;
			cycles_to_stall <= cycles_to_stall - 1;
		end
	end

	assign arg_0 = arg_0_out;
	assign arg_1 = arg_1_out;
	assign execute_op = execute_op_out;
	assign pc_out = pc_out_out;
	assign dest = dest_out;
	assign memory_value_dest = memory_value_dest_out;
	assign memory_value_enable = memory_value_enable_out;


endmodule


/////////////////////////
// EXECUTE STAGE       //
/////////////////////////
module executor(clk, execute_op, arg_0, arg_1, dest_in, pc_in, dest_out, reg_value_out, reg_write_enable, pc_value_out, pc_write_enable);

	parameter ADD = 4'h0;
	parameter SET = 4'h1;
	parameter NOP = 4'h2;
	parameter SHFT = 4'h3;
	parameter CALL = 4'h4;
	parameter BRZ = 4'h5;

	input clk;

	input[3:0] execute_op;
	input[2:0] dest_in;

	input[15:0] arg_0;
	input[15:0] arg_1;
	input[15:0] pc_in;

	reg[2:0] dest_out_reg;
	reg[15:0] reg_value_out_reg;
	reg[15:0] pc_value_out_reg;
	reg reg_write_enable_reg;
	reg pc_write_enable_reg;

	reg[2:0] dest_out_out;
	reg[15:0] reg_value_out_out;
	reg[15:0] pc_value_out_out;
	reg reg_write_enable_out;
	reg pc_write_enable_out;

	output[2:0] dest_out;

	output[15:0] reg_value_out;
	output[15:0] pc_value_out;

	output reg_write_enable;
	output pc_write_enable;

	always @(*) begin
		dest_out_reg = dest_in; //y
		reg_value_out_reg = 0;
		pc_value_out_reg = 0;
		reg_write_enable_reg = 0;
		pc_write_enable_reg = 0;
		case (execute_op)
			NOP: begin
			end
			ADD: begin
				reg_value_out_reg = arg_0 + arg_1;
				reg_write_enable_reg = 1;
			end
			SET: begin
				reg_value_out_reg = (arg_0 < arg_1);
				reg_write_enable_reg = 1;
			end
			SHFT: begin
				reg_value_out_reg = arg_0 << arg_1[3:0];
				reg_write_enable_reg = 1;
			end
			CALL: begin
				reg_value_out_reg = pc_in;
				pc_value_out_reg = arg_0 + arg_1;
				pc_write_enable_reg = 1;
				reg_write_enable_reg = 1;
			end
			BRZ: begin
				pc_value_out_reg = arg_0 + arg_1;
				pc_write_enable_reg = 1;
			end
		endcase
	end

	assign dest_out = dest_out_reg;
	assign reg_value_out = reg_value_out_reg;
	assign pc_value_out = pc_value_out_reg;
	assign reg_write_enable = reg_write_enable_reg;
	assign pc_write_enable = pc_write_enable_reg;

	
	
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
