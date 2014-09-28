
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

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
	 // Not sure if these should be 4'
	 parameter I = 3'h0;
    parameter F = 3'h1;
    parameter D = 3'h2;
    parameter X = 3'h3;
    parameter M = 3'h4;
    parameter W = 3'h5;
	 // Execute ops
    parameter ADD = 4'h0;
    parameter SUB = 4'h1;
    parameter MUL = 4'h2;
    parameter SET = 4'h3;
    parameter NOP = 4'h4;
    parameter SHFT = 4'h5;
    parameter CMP = 4'h5;
	 // Memory ops
	 parameter MEM_LD = 4'h0;
	 parameter MEM_ST = 4'h1;
	 // NOP from above reused
	 // Write Back OPS
	 parameter WB_REG = 4'h0;
	 parameter WB_PC = 4'h1;
	 // NOP from above reused
	 

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


/////////////////////////
// The processor state //
/////////////////////////
	 
    reg [15:0]regs[7:0];     // register
    reg [15:0]pc;             // the pc
	 reg [2:0]cur_state = I;
	 reg [2:0]next_state = F;
	 
	wire clk = KEY[0];        // single step using key0
	initial begin
		pc = 0;
		regs[0] = 0;
		regs[1] = 0;
		regs[2] = 0;
		regs[3] = 0;
		regs[4] = 0;
		regs[5] = 0;
		regs[6] = 0;
		regs[7] = 0;
	end
	 
///////////
// fetch //
///////////
	 
	 reg [15:0]mem_addr;
	 reg [15:0]mem_input;
	 reg mem_wren;
	 wire [15:0]mem_out;
	 ram (mem_addr, clk, mem_input, mem_wren, mem_out);
	 
	///////////////////
	// decode & regs //
	///////////////////

    // Fields in the instruction
    reg [15:0]inst;           // the instruction
	 reg [3:0]x_op;
	 reg [3:0]m_op;
	 reg [3:0]wb_op;
	 reg [3:0]next_x_op;
	 reg [3:0]next_m_op;
	 reg [3:0]next_wb_op;
    wire [4:0] opcode = inst[15:11];
    wire [2:0] rd = inst[10:8];
    wire [2:0] ra = inst[7:5];
    wire [2:0] rb = inst[2:0];
    // Immediate values, sign extended using our custom module
	 wire [15:0]imm5;
	 wire [15:0]imm8;
    sign_extend_16 #(5) (inst[4:0], imm5);
    sign_extend_16 #(8) (inst[7:0], imm8);
    // Values loaded from registers
    wire [15:0] va = regs[ra];
    wire [15:0] vb = regs[rb];
    wire [15:0] vd = regs[rd];
	 // Values for execute stage
	 reg [15:0]next_xv_0;
	 reg [15:0]next_xv_1;
	 reg [15:0]xv_0;
	 reg [15:0]xv_1;
 
/////////////
// execute //
/////////////
 
reg [15:0] nextpc;        // the next pc
reg [15:0]rfdata;         // the register value
 
always @(*) begin
    next_wb_op = NOP;
    rfdata = 0;
    nextpc = pc + 1;
	 mem_wren = 0;
	 mem_input = 0;
	 
	 case (next_state)
		I: begin
		end
		F: begin
			mem_addr = pc;
		end
		D: begin
			case (opcode)
			  // Add, f = 0
			  5'b00000: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = WB_REG;
			  end
			  
			  // Add, f = 1
			  5'b00001: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = vb;
					next_wb_op = WB_REG;
			  end
					 
			  // Slt, f = 0
			  5'b00100: begin
					next_x_op = SET;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = WB_REG;
			  end
				
			  // Slt, f = 1
			  5'b00101: begin
					next_x_op = SET;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = vb;
					next_wb_op = WB_REG;
			  end
					
			  // Lea, f = 0
			  5'b11000: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = WB_REG;
			  end
					
			  // Lea, f = 1
			  5'b11001: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = pc;
					next_xv_1 = imm8;
					next_wb_op = WB_REG;
			  end
					
				// Call, f = 0
			  5'b11010: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = WB_PC;
			  end
					
			  // Call, f = 1
			  5'b11011: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = pc;
					next_xv_1 = imm8;
					next_wb_op = WB_PC;
			  end
					
			  // brz, f = 0
			  5'b11110: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = va;
					next_xv_1 = imm5;
					if (vd == 0)
						 next_wb_op = WB_PC;
			  end
					
			  // brz, f = 1
			  5'b11111: begin
					next_x_op = ADD;
					next_m_op = NOP;
					next_xv_0 = pc;
					next_xv_1 = imm8;
					if (vd == 0)
						 next_wb_op = WB_PC;
			  end
			  
			  // ld, f = 0
			  5'b10100: begin
					next_x_op = ADD;
					next_m_op = MEM_LD;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = WB_REG;
			  end
			  
			  // ld, f = 1
			  5'b10101: begin
					next_x_op = ADD;
					next_m_op = MEM_LD;
					next_xv_0 = pc;
					next_xv_1 = imm8;
					next_wb_op = WB_REG;
			  end
			  
			  // st, f = 0
			  5'b10110: begin
					next_x_op = ADD;
					next_m_op = MEM_ST;
					next_xv_0 = va;
					next_xv_1 = imm5;
					next_wb_op = NOP;
			  end
			  
			  // st, f = 1
			  5'b10111: begin
					next_x_op = ADD;
					next_m_op = MEM_ST;
					next_xv_0 = pc;
					next_xv_1 = imm8;
					next_wb_op = NOP;
			  end
		 endcase
		end
		X: begin
			case (x_op)
				ADD: begin
				end
				SUB: begin
				end
				MUL: begin
				end
				NOP: begin
				end
				SET: begin
				end
				SHFT: begin
				end
			endcase
		end
		M: begin
			case (m_op)
				MEM_ST: begin
				end
				MEM_LD: begin
				end
				NOP: begin
				end
			endcase
		end
		W: begin
		end
	 endcase
    
end
	 
	 
///////////////////
// debug support //
///////////////////
reg [15:0]debug;
assign LEDG[0] = cur_state == I;
assign LEDG[1] = cur_state == F;
assign LEDG[2] = cur_state == D;
assign LEDG[3] = cur_state == X;
assign LEDG[4] = cur_state == M;
assign LEDG[5] = cur_state == W;
assign LEDR = pc[9:0];
display(debug[15:12], HEX3);
display(debug[11:8], HEX2);
display(debug[7:4], HEX1);
display(debug[3:0], HEX0);

// what do we display
always @(*) begin
    if (SW[3]) debug = inst;
    else debug = regs[SW[2:0]];
end

/////////////////////////
// The sequential part //
/////////////////////////
	 
always @(posedge clk) begin
	 case (cur_state)
		I: begin
		end
		F: begin
			inst <= mem_out;
		end
		D: begin
			m_op <= next_m_op;
			x_op <= next_x_op;
			xv_0 <= next_xv_0;
			xv_1 <= next_xv_1;
			wb_op <= next_wb_op;
		end
		X: begin
		end
		M: begin
		end
		W: begin
			// If the target is R7, don't write out the value
			case (wb_op)
				WB_REG: begin
					if (rd != 7) regs[rd] <= rfdata;
				end
				WB_PC: begin
					pc <= rfdata;
				end
				NOP: begin
				end
			endcase
		end
	 endcase
    cur_state <= next_state;
    
end

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











// Sign extension module
module sign_extend_16(IN, OUT);
    // The width of the input value in bits
    parameter INPUT_WIDTH;
    input [INPUT_WIDTH - 1:0]IN;
    output [15:0]OUT;
    
    reg [15:0] result;
    reg [15:0] all1 = 16'hffff;
    reg [15:0] all0 = 16'h0;
    
    always @(*)
        if (IN[INPUT_WIDTH - 1]) begin
            result[INPUT_WIDTH - 1:0] = IN;
            result[15:INPUT_WIDTH] = all1[15:INPUT_WIDTH];
        end else begin
            result[INPUT_WIDTH - 1:0] = IN;
            result[15:INPUT_WIDTH] = all0[15:INPUT_WIDTH];
        end
    
    assign OUT = result;
    
endmodule
