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
    // OUTPUTS: 

    // The memory is initialized with instructions contained in a file data.txt. The
    // format of each line in data.txt is “@<addr> <contents>”.

    assign msel = (mem_addr[8] == 1'b0) ? 1'b1 : 1'b0;
    assign and_result1 = ((mem_cmd == `MWRITE) ? 1'b1 : 1'b0) & msel;
    assign and_result2 =  ((mem_cmd == `MREAD) ? 1'b1 : 1'b0) & msel;

    //tri-state driver
    assign read_data = and_result1 ? dout : {16{1'bz}};

    RAM MEM(clk, mem_addr[7:0], mem_addr[7:0], and_result2, write_data, dout);

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
