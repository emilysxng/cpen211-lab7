/*
Arithmetic Logic Unit

00      Ain + Bin
01      Ain - Bin
10      Ain & Bin
11      ~Bin

If the result is 0 the 1 bit output Z should be 1 (and otherwise 0).
*/

module ALU(Ain, Bin, ALUop, out, ZNV);
    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output reg [15:0] out;
    reg [15:0] unsignoutput;
    output reg [2:0] ZNV;
    wire [15:0] UnAin;
    wire [15:0] UnBin;

    assign UnAin = Ain[15] ? ((~Ain) + 16'b1) : Ain;
    assign UnBin = Bin[15] ? ((~Bin) + 16'b1) : Bin;

    always @ (*) begin
        unsignoutput = 16'b0;
        case (ALUop)
            2'b00: begin
                out = Ain + Bin;
                unsignoutput = UnAin + UnBin;
                ZNV[0] = out[15] ^ unsignoutput[15];
                ZNV[2] = (out == 16'b0) ? 1'b1 : 1'b0;
                ZNV[1] = (out[15] == 1'b1) ? 1'b1 : 1'b0;
            end 
            2'b01: begin
                out = Ain - Bin;
                unsignoutput = UnAin - UnBin;
                ZNV[0] = out[15] ^ unsignoutput[15];
                ZNV[2] = (out == 16'b0) ? 1'b1 : 1'b0;
                ZNV[1] = (out[15] == 1'b1) ? 1'b1 : 1'b0;
            end 
            2'b10: begin
                out = Ain & Bin;
                ZNV[2] = (out == 16'b0) ? 1'b1 : 1'b0;
                ZNV[1] = (out[15] == 1'b1) ? 1'b1 : 1'b0;
                ZNV[0] = 1'b0;
            end
            2'b11: begin
                out = ~Bin;
                ZNV[2] = (out == 16'b0) ? 1'b1 : 1'b0;
                ZNV[1] = (out[15] == 1'b1) ? 1'b1 : 1'b0;
                ZNV[0] = 1'b0;
            end 
            default: begin
                out = 16'b0;
                ZNV[2] = 1'b0;
                ZNV[1] = 1'b0;
                ZNV[0] = 1'b0;
                unsignoutput = 16'b0;
            end
        endcase
    end
endmodule: ALU