/* Naming scheme:
 * 1 fetcher, 1 decoder, 2 executors
 * executor has two halves: first and second
 * first stage takes precedence:
 *     if the two instructions have inter dependencies
 *         first stage executes
 *         second stage stalls, then its instruction is promoted to the first stage on the next cycle
 * low 16 bits go to first portion, high 16 bits go to the second portion
 * 
 * all in module variables must be suffixed with in_wire, out_wire, or reg, depending on if it is an input/output/neither
 * try not to suck
 * 
 * TODO:
 * [*]add 2 read ports and 1 write port to register file nå
 * [*]make a second execute module instance
 * [*]modify decode to 
 *      check for instruction inter dependencies
 *      output 2x as many execute thingies
 *      consume 2x as many register parameters
 * [*]need some kind of buffer (queuey)
 * [ ]update RAM module in Megawizard to be 32 bits wide, change module instantiation variables
 */


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
   output [9:0]                 LEDR;

   //////////// KEY //////////
   input 		          		CPU_RESET_n;
   input [3:0]                  KEY;

   //////////// SW //////////
   input [9:0]                  SW;

   //////////// SEG7 //////////
   output [6:0]                 HEX0;
   output [6:0]                 HEX1;
   output [6:0]                 HEX2;
   output [6:0]                 HEX3;

   wire                         clk = KEY[0];        // single step using key0

   wire [15:0]                  reg_0;
   wire [15:0]                  reg_1;
   wire [15:0]                  reg_dbg;
   wire [15:0]                  reg_write_value;

   wire [2:0]                   reg_addr_0;
   wire [2:0]                   reg_addr_1;
   wire [2:0]                   reg_write_dest;
   wire                         reg_write_enable;

   // For new register file
   wire [2:0]                   read_addr_first_0;
   wire [2:0]                   read_addr_first_1;
   wire [2:0]                   read_addr_second_0;
   wire [2:0]                   read_addr_second_1;

   wire [2:0]                   write_addr_first;
   wire [2:0]                   write_addr_second;
   
   wire                         write_enable_first;
   wire                         write_enable_second;

   wire [15:0]                  write_value_first;
   wire [15:0]                  write_value_second;
   
   wire [15:0]                  read_value_first_0;
   wire [15:0]                  read_value_first_1;
   wire [15:0]                  read_value_second_0;
   wire [15:0]                  read_value_second_1;
   wire [15:0]                  read_value_dbg;
   

   registers(.clk(clk),
             .read_addr_first_0(read_addr_first_0),
             .read_addr_first_1(read_addr_first_1),
             .read_addr_second_0(read_addr_second_0),
             .read_addr_second_1(read_addr_second_1),
             .read_addr_dbg(SW[2:0]),
		     .write_addr_first(write_addr_first),
             .write_value_first(write_value_first),
             .write_addr_second(write_addr_second),
             .write_value_second(write_value_second),
             .write_enable_first(write_enable_first),
             .write_enable_second(write_enable_second),
		     .read_value_first_0(read_value_first_0),
             .read_value_first_1(read_value_first_1),
             .read_value_second_0(read_value_second_0),
             .read_value_second_1(read_value_second_1),
             .read_value_dbg(read_value_dbg)
             );

   /*   
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
	);
    */

   wire [15:0]                  instruction_addr;
   wire [15:0]                  memory_addr;
   wire [31:0]                  instruction;
   wire [31:0]                  memory_out;
   wire [31:0]                  memory_in;
   
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

   wire [15:0]                  fetch_pc;

   wire                         stall;

   fetcher(
	       .clk(clk),
	       .stall(stall),
	       .next_pc(instruction_addr),
	       .pc_out(fetch_pc),
	       );

   wire [2:0]                   dest_first;
   wire [2:0]                   dest_second;
   wire [3:0]                   execute_op_first;
   wire [3:0]                   execute_op_second;

   wire [15:0]                  arg_first_0;
   wire [15:0]                  arg_first_1;
   wire [15:0]                  arg_second_0;
   wire [15:0]                  arg_second_1;

   decoder(.clk(clk),
           .instruction(instruction),
           .pc_in(fetch_pc),
           .reg_value_first_0(read_value_first_0),
           .reg_value_first_1(read_value_first_1),
           .reg_value_second_0(read_value_second_0), 
           .reg_value_second_1(read_value_second_1),
	       .reg_addr_first_0(read_addr_first_0),
           .reg_addr_first_1(read_addr_first_1),
           .reg_addr_second_0(read_addr_second_0),
           .reg_addr_second_1(read_addr_second_1),
           .execute_op_first(execute_op_first),
           .execute_op_second(execute_op_second),
           .stall(stall),
	       .arg_first_0(arg_first_0),
           .arg_first_1(arg_first_1),
           .arg_second_0(arg_second_0),
           .arg_second_1(arg_second_1),
           .dest_first(dest_first),
           .dest_second(dest_second)
           );

   executor(
	        .clk(clk),
	        .execute_op(execute_op_first),
	        .arg_0(arg_first_0),
	        .arg_1(arg_first_1),
	        .dest_in(dest_first),
	        .dest_out(write_addr_first),
	        .reg_value_out(write_value_first),
	        .reg_write_enable(write_enable_first),
	        );

   executor(
	        .clk(clk),
	        .execute_op(execute_op_second),
	        .arg_0(arg_second_0),
	        .arg_1(arg_second_1),
	        .dest_in(dest_second),
	        .dest_out(write_addr_second),
	        .reg_value_out(write_value_second),
	        .reg_write_enable(write_enable_second),
	        );
   
/*
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
	       );
*/

   ///////////////////
   // debug support //
   ///////////////////
   reg [15:0]                   debug;

   //assign LEDR = next_x_pc[9:0];

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
module registers(clk, read_addr_first_0, read_addr_first_1, read_addr_second_0, read_addr_second_1, read_addr_dbg, 
		         write_addr_first, write_value_first,  write_addr_second, write_value_second, write_enable_first, write_enable_second, 
		         read_value_first_0, read_value_first_1, read_value_second_0, read_value_second_1, read_value_dbg);

   input[2:0] read_addr_first_0;
   input [2:0] read_addr_first_1;
   input [2:0] read_addr_second_0;
   input [2:0] read_addr_second_1;

   input [2:0] read_addr_dbg;
   input [2:0] write_addr_first;
   input [2:0] write_addr_second;
   
   input       write_enable_first;
   input       write_enable_second;
   input       clk;

   input [15:0] write_value_first;
   input [15:0] write_value_second;
   
   output [15:0] read_value_first_0;
   output [15:0] read_value_first_1;
   output [15:0] read_value_second_0;
   output [15:0] read_value_second_1;
   output [15:0] read_value_dbg;

   // The values fetched from the register file, stored in latches
   reg [15:0]    rv_first_0_reg;
   reg [15:0]    rv_first_1_reg;
   reg [15:0]    rv_second_0_reg;
   reg [15:0]    rv_second_1_reg;
   reg [15:0]    rv_dbg_reg;

   reg [15:0]    regs[7:0];

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
      rv_first_0_reg = regs[read_addr_first_0];
      rv_first_1_reg = regs[read_addr_first_1];
      rv_second_0_reg = regs[read_addr_second_0];
      rv_second_1_reg = regs[read_addr_second_1];
      rv_dbg_reg = regs[read_addr_dbg];
      if (write_enable_first && write_addr_first != 7) begin
	     if (write_addr_first == read_addr_first_0) begin
	        rv_first_0_reg = write_value_first;
	     end
	     if (write_addr_first == read_addr_first_1) begin
	        rv_first_1_reg = write_value_first;
	     end
	     if (write_addr_first == read_addr_second_0) begin
	        rv_second_0_reg = write_value_first;
	     end
	     if (write_addr_first == read_addr_second_1) begin
	        rv_second_1_reg = write_value_first;
	     end
	     if (write_addr_first == read_addr_dbg) begin
	        rv_dbg_reg = write_value_first;
	     end
      end
      if (write_enable_second && write_addr_second != 7) begin
	     if (write_addr_second == read_addr_first_0) begin
	        rv_first_0_reg = write_value_second;
	     end
	     if (write_addr_second == read_addr_first_1) begin
	        rv_first_1_reg = write_value_second;
	     end
	     if (write_addr_second == read_addr_second_0) begin
	        rv_second_0_reg = write_value_second;
	     end
	     if (write_addr_second == read_addr_second_1) begin
	        rv_second_1_reg = write_value_second;
	     end
	     if (write_addr_second == read_addr_dbg) begin
	        rv_dbg_reg = write_value_second;
	     end
      end
      
   end

   always @(posedge clk) begin
      if (write_enable_first && write_enable_second) begin
	     regs[write_addr_second] = write_value_second;
	     if (write_addr_first != write_addr_second) begin
	        regs[write_addr_first] = write_value_first;
	     end
      end
      if (write_enable_first && write_addr_first != 7) begin
	     regs[write_addr_first] <= write_value_first;
      end
      if (write_enable_second && write_addr_second != 7) begin
	     regs[write_addr_second] <= write_value_second;
      end
   end

   assign read_value_first_0 = rv_first_0_reg;
   assign read_value_first_1 = rv_first_1_reg;
   assign read_value_second_0 = rv_second_0_reg;
   assign read_value_second_1 = rv_second_1_reg;
   assign read_value_dbg = rv_dbg;

endmodule


/////////////////////////
// FETCH STAGE         //
/////////////////////////
module fetcher(clk, stall, next_pc, pc_out);

   input clk;
   input stall;

   output [15:0] next_pc;
   output [15:0] pc_out;

   reg [15:0]    fetch_pc;
   reg [15:0]    next_fetch_pc;

   initial begin
      fetch_pc = -1;
   end

   always @(*) begin
      if (stall) begin
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
module decoder(clk, instruction, pc_in, reg_value_first_0, reg_value_first_1, reg_value_second_0, reg_value_second_1, execute_op_first, execute_op_second, stall,
	           reg_addr_first_0, reg_addr_first_1, reg_addr_second_0, reg_addr_second_1,
	           arg_first_0, arg_first_1, arg_second_0, arg_second_1, dest_first, dest_second);

   // Execute stage's parameters
   parameter ADD = 4'h0;
   parameter SUB = 4'h1;
   parameter NOP = 4'h2;

   input clk;

   input [31:0] instruction;
   input [15:0] pc_in;
   input [15:0] reg_value_first_0;
   input [15:0] reg_value_first_1;
   input [15:0] reg_value_second_0;
   input [15:0] reg_value_second_1;

   output [15:0] arg_first_0;
   output [15:0] arg_first_1;
   output [15:0] arg_second_0;
   output [15:0] arg_second_1;
   
   output        stall;

   output [2:0]  dest_first;
   output [2:0]  dest_second;
   output [3:0]  execute_op_first;
   output [3:0]  execute_op_second;
   output [2:0]  reg_addr_first_0;
   output [2:0]  reg_addr_first_1;
   output [2:0]  reg_addr_second_0;
   output [2:0]  reg_addr_second_1;

   reg [3:0]     execute_op_first_reg;
   reg [3:0]     execute_op_second_reg;
   reg [15:0]    arg_0_first_reg;
   reg [15:0]    arg_1_first_reg;
   reg [15:0]    arg_0_second_reg;
   reg [15:0]    arg_1_second_reg;
   reg [2:0]     dest_first_reg;
   reg [2:0]     dest_second_reg;

   reg [3:0]     execute_op_first_wire_out;
   reg [3:0]     execute_op_second_wire_out;
   reg [15:0]    arg_first_0_wire_out;
   reg [15:0]    arg_first_1_wire_out;
   reg [15:0]    arg_second_0_wire_out;
   reg [15:0]    arg_second_1_wire_out;
   reg [2:0]     dest_first_wire_out;
   reg [2:0]     dest_second_wire_out;

   // Communication between decode and queuey
   reg           cant_consume_both_reg;

   wire [15:0]   first_inst;
   wire [15:0]   second_inst;

   queuey (.from_memory/*32i*/(instruction),
	       .first_inst/*16o*/(first_inst),
	       .second_inst/*16o*/(second_inst),
	       .num_items_consumed/*1i*/(cant_consume_both_reg),
	       .should_memory_stall/*1o*/(stall)
	       );

   wire [4:0]    opcode_first = first_inst[15:11];
   wire [2:0]    rd_first = first_inst[10:8];
   wire [4:0]    opcode_second = second_inst[15:11];
   wire [2:0]    rd_second = second_inst[10:8];

   wire [15:0]   imm5_first = $signed(first_inst[4:0]);
   wire [15:0]   imm8_first = $signed(first_inst[7:0]);
   wire [15:0]   imm5_second = $signed(second_inst[4:0]);
   wire [15:0]   imm8_second = $signed(second_inst[7:0]);

   always @(*) begin
      dest_reg_first = rd_first;
      dest_reg_second = rd_second;
      execute_op_first_reg = NOP;
      execute_op_second_reg = NOP;
      arg_first_0_reg = 0;
      arg_first_1_reg = 0;
      arg_second_0_reg = 0;
      arg_second_1_reg = 0;
      stall_reg = 0;

      case (opcode_first)
	    // Add, f = 0
	    5'b00000: begin
	       execute_op_first_reg = ADD;
	       arg_first_0_reg = reg_value_first_0;
	       arg_first_1_reg = first_imm5;
	    end

	    // Add, f = 1
	    5'b00001: begin
	       execute_op_first_reg = ADD;
	       arg_first_0_reg = reg_value_first_0;
	       arg_first_1_reg = reg_value_first_1;
	    end
	    // Sub, f = 0
	    5'b00010: begin
	       execute_op_first_reg = SUB;
	       arg_first_0_reg = reg_value_first_0;
	       arg_first_1_reg = first_imm5;
	    end
	    5'b00011: begin
	       execute_op_first_reg = SUB;
	       arg_first_0_reg = reg_value_first_0;
	       arg_first_1_reg = reg_value_first_1;
	    end

      endcase // case (opcode_first)

      // 0 means we can consume 2 instructions
      cant_consume_both_reg = 0;
      case (opcode_second)
        // Add, f = 0
	    5'b00000: begin
	       execute_op_second_reg = ADD;
	       arg_second_0_reg = reg_value_second_0;
	       arg_second_1_reg = second_imm5;
	    end

	    // Add, f = 1
	    5'b00001: begin
	       execute_op_second_reg = ADD;
	       arg_second_0_reg = reg_value_second_0;
	       arg_second_1_reg = reg_value_second_1;
           if (dest_reg_first == reg_addr_second_1) begin
              cant_consume_both_reg = 1;
              execute_op_second_reg = NOP;
           end
	    end
	    // Sub, f = 0
	    5'b00010: begin
	       execute_op_second_reg = SUB;
	       arg_second_0_reg = reg_value_second_0;
	       arg_second_1_reg = second_imm5;
	    end
	    5'b00011: begin
	       execute_op_second_reg = SUB;
	       arg_second_0_reg = reg_value_second_0;
	       arg_second_1_reg = reg_value_second_1;
           if (dest_reg_first == reg_addr_second_1) begin
              cant_consume_both_reg = 1;
              execute_op_second_reg = NOP;
           end
	    end

      endcase // case (opcode_second)

      if (dest_reg_first == reg_addr_second_0) begin
         cant_consume_both_reg = 1;
         execute_op_second_reg = NOP;
      end

      /*
       Logic for determining whether or not we can do two instructions or only one
       This changes what goes to the second execute stage, as well as num_items_consumed in queuey
       Being implemented in the above case statement
       EDIT: Has been
       */

   end

   // The below code needs to be updated to reflect the new coding scheme
   assign reg_addr_first_0 = first_inst[7:5];
   assign reg_addr_first_1 = first_inst[2:0];
   assign reg_addr_second_0 = second_inst[7:5];
   assign reg_addr_second_1 = second_inst[2:0];
   
   always @(posedge clk) begin
      arg_first_0_out <= arg_first_0_reg;
      arg_first_1_out <= arg_first_1_reg;
      arg_second_0_out <= arg_second_0_reg;
      arg_second_1_out <= arg_second_1_reg; 
      execute_op_out <= execute_op_reg;
      pc_out_out <= pc_out_reg;
      dest_out <= dest_reg;
   end

   assign arg_first_0 = arg_first_0_wire_out;
   assign arg_first_1 = arg_first_1_wire_out;
   assign arg_second_0 = arg_second_0_wire_out;
   assign arg_second_1 = arg_second_1_wire_out;
   assign execute_op_first = execute_op_first_wire_out;
   assign execute_op_second = execute_op_second_wire_out;
   assign dest_first = dest_first_wire_out;
   assign dest_second = dest_second_wire_out;

endmodule


/////////////////////////
// EXECUTE STAGE       //
/////////////////////////
module executor(clk, execute_op, arg_0, arg_1, dest_in, dest_out, reg_value_out, reg_write_enable);

   parameter ADD = 4'h0;
   parameter SUB = 4'h1;
   parameter NOP = 4'h2;
   input clk;

   input [3:0] execute_op;
   input [2:0] dest_in;

   input [15:0] arg_0;
   input [15:0] arg_1;

   reg [2:0]    dest_out_reg;
   reg [15:0]   reg_value_out_reg;
   reg          reg_write_enable_reg;

   reg [2:0]    dest_out_out;
   reg [15:0]   reg_value_out_out;
   reg          reg_write_enable_out;

   output [2:0] dest_out;
   output [15:0] reg_value_out;
   output        reg_write_enable;

   always @(*) begin
      dest_out_reg = dest_in; //y
      reg_value_out_reg = 0;
      reg_write_enable_reg = 0;
      case (execute_op)
	    NOP: begin
	    end
	    ADD: begin
	       reg_value_out_reg = arg_0 + arg_1;
	       reg_write_enable_reg = 1;
	    end
	    SUB: begin
	       reg_value_out_reg = arg_0 - arg_1;
	       reg_write_enable_reg = 1;
	    end
      endcase
   end

   assign dest_out = dest_out_reg;
   assign reg_value_out = reg_value_out_reg;
   assign reg_write_enable = reg_write_enable_reg;
   
endmodule // executor

module queuey(clk,
              from_memory/*32i*/,
	          first_inst/*16o*/,
	          second_inst/*16o*/,
	          num_items_consumed/*2i*/,
	          should_memory_stall/*1o*/
	          );

   input clk;
   input [31:0] from_memory;
   input        num_items_consumed;

   output [15:0] first_inst;
   output [15:0] second_inst;
   output        should_memory_stall;

   reg [15:0]    queue[1:0];
   reg [1:0]     queue_size;

   reg [15:0]    first_inst_reg;
   reg [15:0]    second_inst_reg;
   reg           should_memory_stall_reg;

   reg [15:0]    next_queue_0;
   reg [15:0]    next_queue_1;

   initial begin
      queue[0] = 16'h0;
      queue[1] = 16'h1;
      queue_size = 2'h0;
   end

   always @(*) begin
      if (queue_size == 0) begin
         // first inst: 0-15, second: 16-31
         first_inst_reg = from_memory[15:0];
         second_inst_reg = from_memory[31:16];
         next_queue_0 = from_memory[31:16];
      end else if (queue_size == 1) begin
         first_inst_reg = queue[0];
         second_inst_reg = from_memory[15:0];
         next_queue_0 = from_memory[15:0];
         next_queue_1 = from_memory[31:16];
      end else begin
         first_inst_reg = queue[0];
         second_inst_reg = queue[1];
         next_queue_0 = queue[1];
         next_queue_1 = from_memory[15:0];
      end
   end // always @ begin
   
   always @(posedge clk) begin
      queue_size <= queue_size;
      if (num_items_consumed == 0) begin // 2 were consumed
         if (queue_size == 1) begin
            queue[0] <= next_queue_1;
         end else if (queue_size == 2) begin
            queue_size <= 0;
         end
      end else begin
         if (queue_size == 0) begin
            queue_size <= 1;
            queue[0] <= next_queue_0;
            should_memory_stall_reg <= 1;
         end else if (queue_size == 1) begin
            queue_size <= 2;
            queue[0] <= next_queue_0;
            queue[1] <= next_queue_1;
            should_memory_stall_reg = 1;
         end else if (queue_size == 2) begin
            queue[0] <= next_queue_0;
            queue[1] <= next_queue_1;
         end
      end // else: !if(num_items_consumed == 0)
   end

   assign first_inst = first_inst_reg;
   assign second_inst = second_inst_reg;
   assign should_memory_stall = should_memory_stall_reg;

endmodule // queuey


/////////////////////////
// 7 SEG               //
/////////////////////////
module display(NUM, HEX);
   input[3:0] NUM;

   output [6:0] HEX;
   reg [6:0]    HEX;

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
