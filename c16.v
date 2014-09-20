
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
	 
    reg [15:0]regs[15:0];     // register
    reg [15:0]pc;             // the pc
	 
 ///////////
 // fetch //
 ///////////
	 
    reg [15:0]inst;           // the instruction
	 
    // hardwired program, need to start some where
    always @(*) begin
        case(pc)
            16'b0000000000000000 : inst = 16'hf011;    // li r1,1
	    16'b0000000000000010 : inst = 16'hf022;    // li r2,2
	    16'b0000000000000100 : inst = 16'h0012;    // add r2,r1
	    16'b0000000000000110 : inst = 16'he004;    // ji 4
	    default : inst = 16'bxxxxxxxxxxxxxxxx;
	endcase
    end
	 
	 ///////////////////
	 // decode & regs //
	 ///////////////////
	 
	 wire [3:0]src = inst[7:4];
	 wire [3:0]dest = inst[3:0];
	 wire [15:0]v0 = regs[src];
	 wire [15:0]v1 = regs[dest];
	 
	 /////////////
	 // execute //
	 /////////////
	 
	 reg [15:0] nextpc;        // the next pc
	 reg rfen;                 // this instructions modifies a register
	 reg [15:0]rfdata;         // the register value
	 
	 always @(*) begin
             rfen = 0;
             rfdata = 0;
             nextpc = pc + 2;
	     case(inst[15:12])
             4'b1110 : begin // ji imm
	         rfen = 0;
		 nextpc = {4'b0000, inst[11:0]};
	     end
             4'b1111 : begin // li dest,imm
		 rfen = 1;
                 rfdata = {8'b00000000, inst[11:4]};
                 nextpc = pc + 2;
             end
             default : begin
                 case(inst[15:8])
	         8'b00000000 : begin // add dest,src
                     rfen = 1;
		     rfdata = v0 + v1;
		     nextpc = pc + 2;
	         end
                 default: begin
                     rfen = 0;
                     nextpc = pc;
                 end
                 endcase
             end
             endcase
         end
	 
	 wire clk = KEY[0];        // single step using key0
	 
	 ///////////////////
         // debug support //
	 ///////////////////
         reg [15:0]debug;
	 assign LEDG = debug[7:0];
	 assign LEDR = debug[15:8];
	 
	 // what do we display
	 always @(*) begin
	     if (SW[4]) debug = pc;
             else debug = regs[SW[3:0]];
	 end
	 
	 /////////////////////////
	 // The sequential part //
	 /////////////////////////
	 
	 always @(posedge clk) begin
             pc <= nextpc;
             if (rfen) regs[dest] <= rfdata;
	 end


endmodule

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
