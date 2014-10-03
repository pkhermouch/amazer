
// Execute ops
`define ADD = 4'h0;
`define SUB = 4'h1;
`define MUL = 4'h2;
`define SET = 4'h3;
`define NOP = 4'h4;
`define SHFT = 4'h5;
`define CMP = 4'h6;


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
//  PARAMETER declarations
//=======================================================
	 
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

assign LEDR = fetch_pc[9:0];

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
module registers(read_addr_0, read_addr_1, read_addr_dbg, write_addr, write_value, write_enable, read_value_0, read_value_1, read_value_dbg);

	input[2:0] read_addr_0;
	input[2:0] read_addr_1;
	input[2:0] read_addr_dbg;
	input[2:0] write_addr;
	
	input write_enable;
	
	input[15:0] write_value;
	
	output[15:0] read_value_0;
	output[15:0] read_value_1;
	output[15:0] read_value_dbg;
	
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
// DECODE STAGE        //
/////////////////////////
module decoder(clk, instruction, pc_in, reg_0, reg_1, execute_op, reg_addr_0, reg_addr_1, arg_0, arg_1, pc_out, dest);

	input clk;

	input[15:0] instruction;
	input[15:0] pc_in;
	input[15:0] reg_0;
	input[15:0] reg_1;
	
	output[15:0] arg_0;
	output[15:0] arg_1;
	output[15:0] pc_out;

	output[2:0] dest;
	output[3:0] execute_op;
	output[3:0] reg_addr_0;
	output[3:0] reg_addr_1;
	
	
   wire [4:0] opcode = instruction[15:11];
   wire [2:0] rd = instruction[10:8];
   wire [2:0] ra = instruction[7:5];
   wire [2:0] rb = instruction[2:0];
	
	wire [15:0]imm5 = $signed(instruction[4:0]);
	wire [15:0]imm8 = $signed(instruction[7:0]);
	
	always @(*) begin
		case (opcode)
			// Add, f = 0
			5'b00000: begin
			end
			  
			// Add, f = 1
			5'b00001: begin
			end
					 
			// Slt, f = 0
			5'b00100: begin
			end
				
			// Slt, f = 1
			5'b00101: begin
			end
					
			// Lea, f = 0
			5'b11000: begin
			end
					
			// Lea, f = 1
			5'b11001: begin
			 end
					
			// Call, f = 0
			5'b11010: begin
			end
					
			// Call, f = 1
			5'b11011: begin
			end
					
			// brz, f = 0
			5'b11110: begin
			end
					
			// brz, f = 1
			5'b11111: begin
			end
		endcase
	end
	
endmodule


/////////////////////////
// EXECUTE STAGE       //
/////////////////////////
module executor(clk, execute_op, arg_0, arg_1, dest_in, pc_in, dest_out, reg_value_out, reg_write_enable, pc_value_out, pc_write_enable);

	input clk;
	
	input[3:0] execute_op;
	input[3:0] dest_in;
	
	input[15:0] arg_0;
	input[15:0] arg_1;
	input[15:0] pc_in;

	output[3:0] dest_out;
	
	output[15:0] reg_value_out;
	output[15:0] pc_value_out;
	
	output reg_write_enable;
	output pc_write_enable;

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
