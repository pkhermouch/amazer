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

wire reg_write_enable;

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
	.read_value_dbg(reg_dbg)
	);

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
	.reg_addr_0(reg_addr_0),
	.reg_addr_1(reg_addr_1),
	.arg_0(arg_0),
	.arg_1(arg_1),
	.pc_out(next_x_pc),
	.dest(next_x_dest)
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
module registers(clk, read_addr_0, read_addr_1, read_addr_dbg, write_addr, write_value, write_enable, read_value_0, read_value_1, read_value_dbg);

	input[2:0] read_addr_0;
	input[2:0] read_addr_1;
	input[2:0] read_addr_dbg;
	input[2:0] write_addr;

	input write_enable;
	input clk;

	input[15:0] write_value;

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
	end

	always @(posedge clk) begin
		if (write_enable && write_addr != 7) begin
			regs[write_addr] <= write_value;
		end
	end

	assign read_value_0 = rv0;
	assign read_value_1 = rv1;
	assign read_value_dbg = rvdbg;

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

	ram (next_fetch_pc, clk, 0, 0, mem_out);

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



module scorebored(clk, pc_in, opcode, destination_reg,source_0,source_1, should_fetch_stall);

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
	parameter BUSY = 1'h0;
	parameter NOT_BUSY = 1'h1;
	// register status, not as important
	parameter READY = 1'h0;
	parameter NOT_READY = 1'h1;

	input clk;
	input [15:0] pc_in;
	input [2:0] opcode;
	input [2:0] destination_reg;
	input [2:0] source_0;
	input [2:0] source_1;
	
	output should_fetch_stall;
	
   reg should_fetch_stall_reg;

	reg [2:0] Instruction_Status [2:0]; // goes with IN_???_STATE
	reg [2:0] Register_Status [7:0];  //   what functional unit will produce the value for each register

	reg [2:0] Busy [2:0]; // indexed by MATHER_0 and shit
	reg [2:0] FU_Operations[2:0]; // the operation each FU will perform
	reg [2:0] Dest_Register [2:0];
	reg [2:0] Source_Register_0 [2:0];
	reg [2:0] Source_Register_1 [2:0];
	reg [2:0] Source_Register_0_Resource [2:0];  
	reg [2:0] Source_Register_1_Resource [2:0]; 
	reg [2:0] Source_Register_0_Ready [2:0];
	reg [2:0] Source_Register_1_Ready [2:0];
	
	reg [2:0] Result [2:0];
	reg [2:0] mather_to_use;
	
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
		if (opcode == DO_ADD || opcode == DO_SUB) begin
			if((Busy[MATHER_0] == NOT_BUSY || Busy[MATHER_1] == NOT_BUSY) && Register_Status[destination_reg] == NO_RESOURCE) begin
				// we can issue
				mather_to_use = Busy[MATHER_0] == NOT_BUSY ? MATHER_0 : MATHER_1;
				Busy[mather_to_use] = BUSY;
				Dest_Register[mather_to_use] = destination_reg;
				Source_Register_0[mather_to_use] = source_0;
				Source_Register_1[mather_to_use] = source_1;
				Source_Register_0_Resource[mather_to_use] = Register_Status[source_0];
				Source_Register_1_Resource[mather_to_use] = Register_Status[source_1];
				Source_Register_0_Ready[mather_to_use] = NOT_READY;
				Register_Status[destination_reg] = mather_to_use;
			end else begin
				//stall
				should_fetch_stall_reg = 1;
			end
		end
	end
		
	assign should_fetch_stall = should_fetch_stall_reg;

endmodule
