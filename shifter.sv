/*
00     return in as is
01     in is shifted left one bit, least significant bit is 0
10     in is shifted right one bit, MSB is 0
11     in is shifted right one bit, MSB is a copy of in[15]
*/

module shifter(in, shift, sout);
    input [15:0] in;
    input [1:0] shift;
    output reg [15:0] sout;

    always @* begin
        case (shift)
            2'b00: sout = in;
            2'b01: sout = in << 1;
            2'b10: sout = in >> 1;
            2'b11: sout = {in[15], in[15:1]};
            default: sout = in;
        endcase
    end
endmodule: shifter