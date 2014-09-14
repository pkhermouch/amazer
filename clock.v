
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
	 
	 reg ENABLE;
	 
	 reg[3:0] IN1;
	 reg[3:0] IN2;
	 reg[3:0] IN3;
	 reg[3:0] IN4;
	 
	 wire[3:0] SLOWSTATE;
	 wire[3:0] STATE1;
	 wire[3:0] STATE2;
	 wire[3:0] STATE3;
	 wire[3:0] STATE4;
	 
	 reg[3:0] DISP0;
	 reg[3:0] DISP1;
	 reg[3:0] DISP2;
	 reg[3:0] DISP3;
	 
	 wire SECONDS0;
	 wire SECONDS1;
	 wire SLOWER;
	 reg SPEED;
	 
	 wire MINUTES0;
	 wire MINUTES1;
	 
	 wire IGNORE;
	 
	 display d0 (DISP0, HEX0);
	 display d1 (DISP1, HEX1);
	 display d2 (DISP2, HEX2);
	 display d3 (DISP3, HEX3);
	 
	 
	 clockDivider #(5000000,31) clk0 (CLK, 1'b1, 1'b0, 32'b0, STATE0, SECONDS0); 
	 clockDivider #(9,3)   clk1 (CLK, SPEED, ENABLE, IN1, STATE1, SECONDS1); 
	 clockDivider #(5,3)   clk2 (CLK, SECONDS1, ENABLE, IN2, STATE2, MINUTES0); 
	 clockDivider #(9,3)   clk3 (CLK, MINUTES0, ENABLE, IN3, STATE3, MINUTES1); 
	 clockDivider #(5,3)   clk4 (CLK, MINUTES1, ENABLE, IN4, STATE4, IGNORE);
	 
	 clockDivider #(9,3)   speed (CLK, SECONDS0, 1'b0, 4'b0, SLOWSTATE, SLOWER); 
	 
	 always @(*) begin
		 if (KEY[1]) begin
			DISP0 <= STATE1;
			DISP1 <= STATE2;
			DISP2 <= STATE3;
			DISP3 <= STATE4;
		 end else begin
			DISP0 <= DISP0;
			DISP1 <= DISP1;
			DISP2 <= DISP2;
			DISP3 <= DISP3;
		 end
		 if (!KEY[0]) begin
			ENABLE <= 1'b1;
			IN1 <= 4'h0;
			IN2 <= 4'h0;
			IN3 <= 4'h0;
			IN4 <= 4'h0;
		 end else if (!KEY[3]) begin
			ENABLE <= 1'b1;
			IN1 <= 4'h0;
			IN2 <= 4'h0;
			IN3 <= 4'h9;
			IN4 <= 4'h5;
		 end else begin
			ENABLE <= 1'b0;
		 end
		 if (!KEY[2]) begin
			SPEED <= SECONDS0;
		 end else begin
			SPEED <= SLOWER;
		 end
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

module clockDivider(CLK, INC, WRITE, VALUE, CLKSTATE, CLKOUT);
parameter count = 0;
parameter state_bits = 25;

	input CLK;
	input INC;
	input WRITE;
	input[state_bits:0] VALUE;
	
	output CLKOUT;
	output[state_bits:0] CLKSTATE;
	reg CLKOUT;
	reg[state_bits:0] CLKSTATE;
		
	 always @(posedge CLK) begin
		if (WRITE) begin
			CLKSTATE <= VALUE;
		end else begin
			if (CLKSTATE > count) begin
				CLKSTATE <= 31'h0;
				CLKOUT <= 1;
			end else begin
				CLKSTATE <= CLKSTATE + INC;
				CLKOUT <= 0;
			end
		end
	end
endmodule
