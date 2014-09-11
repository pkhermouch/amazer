
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

endmodule
