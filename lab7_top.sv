`define MREAD 2'b10
`define MWRITE 2'b01
`define MNONE 2'b00

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire msel, and_result1, and_result2, dout;

    // INPUTS: mem_cmd, mem_addr, read_data, write_data 

    // The memory is initialized with instructions contained in a file data.txt. The
    // format of each line in data.txt is “@<addr> <contents>”.

    assign msel = (mem_addr[8] == 1'b0) ? 1'b1 : 1'b0;
    assign and_result1 = ((mem_cmd == `MWRITE) ? 1'b1 : 1'b0) & msel;
    assign and_result2 =  ((mem_cmd == `MREAD) ? 1'b1 : 1'b0) & msel;

    //tri-state driver
    assign read_data = and_result1 ? dout : {16{1'bz}};

    RAM MEM(clk, mem_addr[7:0], mem_addr[7:0], and_result2, write_data, dout);


    /*** LDR / Switches combinational logic ***/

    reg tri_enabler;

    always_comb begin
        if (mem_cmd == `MREAD) begin
            if (mem_addr == 9'h140)
                tri_enabler = 1'b1;
            else
                tri_enabler = 1'b0;
        end
        else
            tri_enabler = 1'b0;
    end

    assign read_data[15:8] = tri_enabler ? 8'h00 : {16{1'bz}};
    assign read_data[7:0] = tri_enabler ? SW[7:0] : {16{1'bz}};


    /*** STR / LEDR combinational logic ***/

    reg en;
    
    always_comb begin
        if (mem_cmd == `MWRITE) begin
            if (mem_addr == 9'h100)
                en = 1'b1;
            else
                en = 1'b0;
        end
        else
            en = 1'b0;
    end

    vDFFE #(8) buffer (clk, en, write_data[7:0], LEDR[7:0]);

endmodule


module RAM(clk,read_address,write_address,write,din,dout);
  parameter data_width = 32; 
  parameter addr_width = 4;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
    dout <= mem[read_address]; // dout doesn't get din in this clock cycle 
                               // (this is due to Verilog non-blocking assignment "<=")
  end 
endmodule

// en is the 1 bit "check"
module vDFFE(clk, en, in, out) ;
    parameter n = 1;  // width
    input clk, en;
    input  [n-1:0] in;
    output [n-1:0] out;
    reg    [n-1:0] out;
    reg   [n-1:0] next_out;

    assign next_out = en ? in : out;

    always @(posedge clk)
    out = next_out;
endmodule
