`define MREAD 2'b10
`define MWRITE 2'b01
`define MNONE 2'b00

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire msel, and_result1, and_result2;
    wire reset, N, V, Z;
    wire [15:0] write_data, dout;
    wire [15:0] read_data;
    wire [8:0] mem_addr;
    wire [1:0] mem_cmd;
    wire clk;

    assign reset = ~KEY[1];
    assign clk = ~KEY[0];
    assign HEX0 = 7'b1111111;
    assign HEX1 = 7'b1111111;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

    cpu CPU(clk, reset, N, V, Z, mem_addr, mem_cmd, read_data, write_data);

    assign msel = (mem_addr[8] == 1'b0);
    assign and_result1 = ((mem_cmd == `MREAD) & msel);
    assign and_result2 = ((mem_cmd == `MWRITE) & msel);

    //tri-state driver
    assign read_data = and_result1 ? dout : {16{1'bz}};

    RAM #(16,8,"data.txt") MEM(clk, mem_addr[7:0], mem_addr[7:0], and_result2, write_data, dout);

    /*** LDR / Switches combinational logic ***/

    reg tri_enabler = 1'b0;

    always_comb begin
        if ((mem_cmd == `MREAD) & (mem_addr == 9'h140))
            tri_enabler = 1'b1;
        else
            tri_enabler = 1'b0;
    end

    assign read_data[15:8] = tri_enabler ? 8'h00 : {16{1'bz}};
    assign read_data[7:0] = tri_enabler ? SW[7:0] : {16{1'bz}};


    /*** STR / LEDR combinational logic ***/

    reg en = 1'b0;
    
    always_comb begin
        if ((mem_cmd == `MWRITE) & (mem_addr == 9'h100)) 
            en = 1'b1;
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