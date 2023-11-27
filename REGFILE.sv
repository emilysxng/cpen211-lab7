module Decoder (in, out);
    input [2:0] in;
    output reg [7:0] out;
    always @(in) begin
        out = 8'b00000000;  // Initialize output to 0
        case (in)
            3'b000: out[0] = 1'b1;
            3'b001: out[1] = 1'b1;
            3'b010: out[2] = 1'b1;
            3'b011: out[3] = 1'b1;
            3'b100: out[4] = 1'b1;
            3'b101: out[5] = 1'b1;
            3'b110: out[6] = 1'b1;
            3'b111: out[7] = 1'b1;
            default: out = 8'b00000000;
        endcase
    end
endmodule

module vDFFE(clk, en, in, out) ;
  parameter n = 1;  // width
  input clk, en ;
  input  [n-1:0] in ;
  output [n-1:0] out ;
  reg    [n-1:0] out ;
  wire   [n-1:0] next_out ;

  assign next_out = en ? in : out;

  always @(posedge clk)
    out = next_out;
endmodule

module regfile(data_in,writenum,write,readnum,clk,data_out);
    input [15:0] data_in;
    input [2:0] writenum;
    input [2:0] readnum;
    input write;
    input clk;
    output reg [15:0] data_out;
    reg [15:0] outdata;
    wire [7:0] oneHotWriting;
    wire [7:0] oneHotReading;
    wire [15:0] R0;
    wire [15:0] R1;
    wire [15:0] R2;
    wire [15:0] R3;
    wire [15:0] R4;
    wire [15:0] R5;
    wire [15:0] R6;
    wire [15:0] R7;

    //Need 2 3:8 decoders for reading and writing
    Decoder writing (writenum,oneHotWriting);
    Decoder reading (readnum,oneHotReading);

    vDFFE #(16) r0 (clk, (oneHotWriting[0]&write), data_in, R0);
    vDFFE #(16) r1 (clk, (oneHotWriting[1]&write), data_in, R1);
    vDFFE #(16) r2 (clk, (oneHotWriting[2]&write), data_in, R2);
    vDFFE #(16) r3 (clk, (oneHotWriting[3]&write), data_in, R3);
    vDFFE #(16) r4 (clk, (oneHotWriting[4]&write), data_in, R4);
    vDFFE #(16) r5 (clk, (oneHotWriting[5]&write), data_in, R5);
    vDFFE #(16) r6 (clk, (oneHotWriting[6]&write), data_in, R6);
    vDFFE #(16) r7 (clk, (oneHotWriting[7]&write), data_in, R7);


    always@(*) begin
        case (oneHotReading)
            8'b00000001: outdata = R0;
            8'b00000010: outdata = R1;
            8'b00000100: outdata = R2;
            8'b00001000: outdata = R3;
            8'b00010000: outdata = R4;
            8'b00100000: outdata = R5;
            8'b01000000: outdata = R6;
            8'b10000000: outdata = R7;
            default: outdata = 16'bxxxxxxxxxxxxxxxx;
        endcase
        data_out = outdata;
    end
endmodule