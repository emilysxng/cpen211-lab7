module datapath (mdata, PC,datapath_out, sximm8, sximm5, writenum, readnum, write, loada, loadb, asel, bsel, vsel, loadc, loads, shift, ALUop, ZNV_out, clk);
    input [15:0] mdata;
    input [7:0] PC;
    output [15:0] datapath_out;
    input [2:0] writenum, readnum;
    input write, loada, loadb, asel, bsel, loadc, loads, clk;
    input [1:0] vsel;
    input [1:0] shift, ALUop;
    input [15:0] sximm8, sximm5;
    output [2:0] ZNV_out;
    wire [15:0] data_in;
    wire [15:0] data_out;
    wire [15:0] fromA ;
    wire [15:0] fromB;
    wire [15:0] fromShift;
    wire [15:0] Ain;
    wire [15:0] Bin;
    wire [15:0] toC;
    wire [2:0]  ZNV;

    assign data_in = vsel[1] ? (vsel[0] ? datapath_out : {8'b0, PC}) : (vsel[0] ? sximm8 : mdata);

    regfile REGFILE (data_in,writenum,write,readnum,clk,data_out);
    //left branch
    vDFFE #(16) registerA (clk,loada,data_out,fromA);
    assign Ain = asel ? 16'b0 : fromA;
    //right branch
    vDFFE #(16) registerB (clk,loadb,data_out,fromB);
    shifter Shift (fromB, shift, fromShift);
    assign Bin = bsel ? sximm5 :fromShift ;

    //all into the same ALU
    ALU Arithmetic(Ain, Bin, ALUop, toC, ZNV);
    vDFFE #(16) registerC (clk,loadc,toC,datapath_out);

    //status 
    vDFFE #(3) status (clk,loads,ZNV,ZNV_out);

endmodule: datapath

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
