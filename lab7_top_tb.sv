module lab7_top_tb;
  reg [3:0] KEY;
  reg [9:0] SW;
  wire [9:0] LEDR; 
  wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  reg err;

  lab7_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);

  initial forever begin
    KEY[0] = 0; #5;
    KEY[0] = 1; #5;
  end

  initial begin
    err = 0;
    KEY[1] = 1'b0; // reset 

    // check if program is loaded correctly in memory

    if (DUT.MEM.mem[0] !== 16'b1101000000000101) begin 
        err = 1; $display("mem[0] wrong"); 
        end
    if (DUT.MEM.mem[1] !== 16'b0110000000100000) begin 
        err = 1; 
        $display("mem[1] wrong"); 
        end
    if (DUT.MEM.mem[2] !== 16'b1101001100000110) begin 
        err = 1; 
        $display("mem[2] wrong"); 
        end
    if (DUT.MEM.mem[3] !== 16'b1000001100100000) begin 
        err = 1; 
        $display("mem[3] wrong"); 
        end
    if (DUT.MEM.mem[4] !== 16'b1110000000000000) begin 
        err = 1; 
        $display("mem[4] wrong"); 
        end
    if (DUT.MEM.mem[5] !== 16'b0100001100100001) begin //0x4321
        err = 1; 
        $display("mem[5] wrong"); 
        end
    if (DUT.MEM.mem[6] !== 16'b1111101011111010) begin //0xFAFA
        err = 1; 
        $display("mem[6] wrong"); 
        end

    @(negedge KEY[0]);

    KEY[1] = 1'b1; 

    #10;

    //check if PC is on the right cycle and if LDR & STR works

    if (DUT.CPU.PC !== 9'b0) begin 
        err = 1; 
        $display("FAILED: PC is not reset to zero."); 
        end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC); 

    if (DUT.CPU.PC !== 9'h1) begin 
        err = 1; $display("FAILED: PC should be 1.");
        end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC); 

    if (DUT.CPU.PC !== 9'h2) begin 
        err = 1; 
        $display("FAILED: PC should be 2."); 
        end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC); 
    
    if (DUT.CPU.PC !== 9'h3) begin 
        err = 1; 
        $display("FAILED: PC should be 3.");
        end

    if (DUT.CPU.DP.REGFILE.R1 !== 16'h4321) begin 
        err = 1; 
        $display("FAILED: R1 should be 0x4321, there is a problem with LDR"); // check if X has been loaded from memory into R1
        end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);

    if (DUT.CPU.PC !== 9'h4) begin 
        err = 1; 
        $display("FAILED: PC should be 4.");
        end

    if (DUT.CPU.DP.REGFILE.R3 !== 16'h6) begin 
        err = 1; 
        $display("FAILED: R3 should be 6.");
        end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC); 
   
    if (DUT.CPU.PC !== 9'h5) begin
        err = 1; 
        $display("FAILED: PC should be 5."); 
        end

    if (DUT.MEM.mem[7] !== 16'hFAFA) begin 
        err = 1; 
        $display("FAILED: mem[7] should be 0xFAFA, there is a problem with STR"); // check if X has been written to memory in address 7
        end

    if (~err) $display("tests passed");
    $stop;
  end
endmodule
