
module clock(
    CLK,                 // 50MHz clock
    KEY,                 // 4 KEYS
    HEX0,                // 7-segment
    HEX1,
    HEX2,
    HEX3 
);
    input CLK;
    input [3:0]KEY;

    output [6:0]HEX0;
    output [6:0]HEX1;
    output [6:0]HEX2;
    output [6:0]HEX3;
	 
	 wire[31:0] STATE0;
	 
	 wire[3:0] STATE1;
	 wire[3:0] STATE2;
	 wire[3:0] STATE3;
	 wire[3:0] STATE4;
	 
	 wire SECONDS0;
	 wire SECONDS1;
	 
	 wire MINUTES0;
	 wire MINUTES1;
	 
	 wire IGNORE;
	 /**
	 display d0 (STATE0[19:16], HEX0);
	 display d1 (STATE0[23:20], HEX1);
	 display d2 (STATE0[27:24], HEX2);
	 display d3 (STATE0[31:28], HEX3);
	 **/
	 
	 display d0 (STATE1, HEX0);
	 display d1 (STATE2, HEX1);
	 display d2 (STATE3, HEX2);
	 display d3 (STATE4, HEX3);
	 
	 
	 clockDivider #(50000000,31) clk0 (CLK, STATE0, SECONDS0); 
	 clockDivider #(8,3)   clk1 (SECONDS0, STATE1, SECONDS1); 
	 clockDivider #(4,3)    clk2 (SECONDS1, STATE2, MINUTES0); 
	 clockDivider #(8,3)   clk3 (MINUTES0, STATE3, MINUTES1); 
	 clockDivider #(4,3)    clk4 (MINUTES1, STATE4, IGNORE); 
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

module clockDivider(CLKIN, CLKSTATE, CLKOUT);
parameter count = 0;
parameter state_bits = 25;

	input CLKIN;
	
	output CLKOUT;
	output[state_bits:0] CLKSTATE;
	reg CLKOUT;
	reg[state_bits:0] CLKSTATE;
	
	always @(posedge CLKIN)
	if (CLKSTATE > count) begin
		CLKSTATE <= 31'h0;
		CLKOUT <= 1;
	end else begin
		CLKSTATE <= CLKSTATE + 1;
		CLKOUT <= 0;
	end
endmodule
