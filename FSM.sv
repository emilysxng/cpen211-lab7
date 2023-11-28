`define RST 5'b00000
`define IF1 5'b10000
`define IF2 5'b11000
`define UpdatePC 5'b11111
`define STRADD 5'b10101
`define STRGET_B_AND_GET_A 5'b11110
`define DECODE 5'b00001
`define GET_A 5'b00010
`define GET_B 5'b00011
`define ADD 5'b00100
`define WRITE_REG 5'b00101
`define CMP 5'b00110
`define AND 5'b00111
`define MVN 5'b01000
`define HALT 5'b11100
`define Rd 3'b010
`define Rm 3'b001
`define Rn 3'b100
`define MREAD 2'b10
`define MWRITE 2'b01
`define MNONE 2'b00

module cpu(clk, reset, load, N, V, Z, mem_addr, mem_cmd, read_data, write_data);
    input clk, reset, load;
    input [15:0] read_data;
    output N, V, Z;
    output [1:0] mem_cmd;
    output [8:0] mem_addr;
    output [15:0] write_data;

    reg [15:0] current_instruction, mdata;
    reg [7:0] imm8;
    reg [5:0] imm5;
    reg [15:0] sximm5;
    reg [15:0] sximm8;
    reg [1:0] shift;
    reg [2:0] Rd, Rm, Rn, readnum, writenum, nsel, opcode;
    reg [1:0] ALUop, op;
    wire write, loada, loadb, asel, bsel, loadc, loads, clk, load_ir, addr_sel, reset_pc, loadpc;
    wire [1:0] vsel;
    wire [8:0] PC;
    wire [2:0] ZNV_out;
    wire [8:0] next_pc;
    wire [8:0] data_out;
 
    //INSTRUCTION REGISTER: The instruction currently being executed is stored in the 16 bit instruction register
    //Input: clk, load, read_data
    //Output: current_instruction

    always @(posedge clk) begin
        case (load)
            1'b0 : current_instruction = current_instruction; //nothing happens
            1'b1 : current_instruction <= read_data; //in is copied to IR
            default: current_instruction = current_instruction;
        endcase
    end

    //INSTRUCTION DECODER: (Combinational) Extracts information from the current instruction that is used to control the datapath. (takes in nsel from FSM)
    //Input: current_instruction, nsel
    //Output: opcode, op/ALuop, shift, readnum, writenum, sximm5, sximm8

    always @(*) begin
        //extract data from current_instruction
        opcode = current_instruction[15:13];
        op = current_instruction[12:11];
        Rn = current_instruction[10:8];
        Rd = current_instruction[7:5];
        Rm = current_instruction[2:0];
        shift = current_instruction[4:3];
        imm8 = current_instruction[7:0];
        imm5 = current_instruction[4:0];

        shift = (opcode == 3'b100) ? 2'b00 : shift; //Shifter will be set to 0 to retrieve a value that is stored in register B for STR

        //with nsel, make a mux for Rn, Rd, Rm to readnum and writenum
        case(nsel)
            3'b100: readnum = Rn;
            3'b010: readnum = Rd;
            3'b001: readnum = Rm;
            default: readnum = Rn;
        endcase

        writenum = readnum;

        //sign extend imm5 and imm8
        if (imm8[7] == 1) begin
            sximm8 = {8'b11111111, imm8};
        end else begin
            sximm8 = {8'b00000000, imm8};
        end

        if (imm5[4] == 1) begin
            sximm5 = {11'b11111111111, imm5};
        end else begin
            sximm5 = {11'b00000000000, imm5};
        end
    end

    //FSM: Sets the inputs to the datapath based on stuff. (takes in opcode and op from decoder)

    FSM_controller Controller (clk, reset, opcode, op, nsel, asel, bsel, w, loada, loadb, loadc , load_ir, load_addr, addr_sel, reset_pc, loadpc, mem_cmd, loads, ALUop, vsel, write);
    datapath DP (read_data, PC, write_data, sximm8, sximm5, writenum, readnum, write, loada, loadb, asel, bsel, vsel, loadc, loads, shift, ALUop, ZNV_out, clk);

    assign next_pc = reset_pc ? 9'b0 : (PC+1);

    vDFFE #(9) programCounter (clk, loadpc, next_pc, PC);

    assign mem_addr = addr_sel ? PC : data_out;

    vDFFE #(9) Data_Address (clk, load_addr, write_data[8:0], data_out);

    assign N = ZNV_out[1];
    assign Z = ZNV_out[2];
    assign V = ZNV_out[0];
endmodule: cpu

module FSM_controller (clk, reset, opcode, op, nsel, asel, bsel, w, loada, loadb, loadc , load_ir, load_addr, addr_sel, reset_pc, loadpc, mem_cmd, loads, ALUop, vsel, write);
    input clk, reset;
    input [2:0] opcode;
    input [1:0] op;
    output reg [2:0] nsel;
    output reg asel,bsel,loada,loadb,loadc,write, loads, loadpc, addr_sel, load_ir, reset_pc, load_addr;
    output reg [1:0] vsel, ALUop, mem_cmd;
    output reg w;
    reg [4:0] present_state;

    always_ff @( posedge clk ) begin 

        if (reset) begin
            present_state = `RST;
        end

        case (present_state)
            `RST: begin
                present_state = `IF1;
                reset_pc = 1'b1;
                load_ir = 1'b0;
                loadpc = 1'b1;  
                addr_sel = 1'b0;  
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
            end 

            `IF1: begin
                addr_sel = 1'b1;
                reset_pc = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                mem_cmd = `MREAD;
                present_state = `IF2;
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
            end

            `IF2: begin
                addr_sel = 1'b1;
                load_ir = 1'b1;
                loadpc = 1'b0;  
                mem_cmd = `MREAD;
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
                present_state = `UpdatePC;
            end

            `UpdatePC: begin
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b1;  
                mem_cmd = `MREAD;
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
                present_state = `DECODE;
            end

            `DECODE: begin
                w = 1'b0;
                if (opcode == 3'b101) begin //ALU instructions
                    if ((op == 2'b00) | (op == 2'b01) | (op == 2'b10)) begin //ADD, CMP, AND
                        present_state = `GET_A;
                    end
                    else if (op == 2'b11) begin //MVN
                        present_state = `GET_B;
                    end
                end

                else if (opcode == 3'b110) begin //MOVE instructions
                    if (op == 2'b00) begin //MOV reg -> reg
                        present_state = `GET_B;
                    end
                    else if (op == 2'b10) begin //MOV sximm8
                        present_state = `WRITE_REG;
                    end
                end

                else if (opcode == 3'b011) begin //LDR
                    present_state = `GET_A;
                end

                else if (opcode == 3'b100) begin // STR
                    present_state = `GET_A;
                end

                else if (opcode == 3'b111) begin // HALT
                    present_state = `HALT;
                end

                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                mem_cmd = `MNONE;
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
            end

            `HALT: begin
                if (reset)
                    present_state = `RST;
                else
                    present_state = `HALT;
            end

            `GET_A: begin
                w = 1'b0;
                nsel = `Rn;
                loada = 1'b1;
                write = 1'b0;
                loadb = 1'b0;
                loadc = 1'b0;
                loads = 1'b0;
                present_state = `GET_B;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
            end

            `GET_B: begin
                w = 1'b0;
                if (opcode == 3'b100) begin
                    nsel = `Rd;
                end
                else begin
                    nsel = `Rm;
                end
                loada = 1'b0;
                loadb = 1'b1;
                write = 1'b0;
                loadc = 1'b0;
                loads = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  

                bsel = (opcode == 3'b011 | opcode == 3'b100) ? 1'b1 : 1'b0; 

                if (op == 2'b00) begin
                     present_state = `ADD;

                end
                else if (op == 2'b01) begin
                    present_state = `CMP;
                end

                else if (op == 2'b10) begin
                    present_state = `AND;
                end

                else if (op == 2'b11) begin
                    present_state = `MVN;
                end
            end

            `ADD: begin
                w = 1'b0;
                ALUop = 2'b00;
                loadc = 1'b1;
                loadb = 1'b0;
                write = 1'b0;
                loada = 1'b0;
                loads = 1'b0;
                bsel = 1'b0;
                asel = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  

                if (opcode == 3'b011) begin
                    mem_cmd = `MREAD;
                    load_addr = 1'b1;
                    addr_sel = 1'b0;
                end

                else if (opcode == 3'b100) begin
                    mem_cmd = `MWRITE;
                    load_addr = 1'b1;
                    addr_sel = 1'b0;
                end

                if ((opcode == 3'b101) | (opcode == 3'b011)) begin
                    asel = 1'b0;
                end
                else if (opcode == 3'b110) begin
                    asel = 1'b1;
                end
                
                bsel = 1'b0;

                if (opcode == 3'b100) begin
                    present_state = `STRGET_B_AND_GET_A;
                end
                else begin
                    present_state = `WRITE_REG;
                end
            end

            `CMP: begin
                w = 1'b0;
                ALUop = 2'b01;
                loads = 1'b1;
                bsel = 1'b0;
                asel = 1'b0;
                write = 1'b0;
                loadb = 1'b0;
                loadc = 1'b0;
                loada = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                present_state = `IF1; //Do not need to go to write_reg
            end

            `AND : begin
                w = 1'b0;
                ALUop = 2'b10;
                loadc = 1'b1;
                loadb = 1'b0;
                asel = 1'b0;
                bsel = 1'b0;
                write = 1'b0;
                loada = 1'b0;
                loads = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                present_state = `WRITE_REG;
            end

            `MVN : begin
                w = 1'b0;
                ALUop = 2'b11;
                loadc = 1'b1;
                loada = 1'b0;
                asel = 1'b0;
                bsel = 1'b0;
                write = 1'b0;
                loadb = 1'b0;
                loads = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                present_state = `WRITE_REG;
            end

            `STRGET_B_AND_GET_A: begin
                if (opcode == 3'b100) begin
                    nsel = `Rd;
                end
                else begin
                    nsel = `Rm;
                end
                bsel = 1'b0;
                asel = 1'b1;
                loada = 1'b1;
                loadb = 1'b1;
                write = 1'b0;
                loadc = 1'b0;
                loads = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                load_addr = 1'b0;
                present_state = `STRADD;
            end

            `STRADD : begin
                ALUop = 2'b00;
                loadc = 1'b1;
                loadb = 1'b0;
                write = 1'b0;
                loada = 1'b0;
                loads = 1'b0;
                bsel = 1'b0;
                asel = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                load_addr = 1'b0;
                asel = 1'b1;
                bsel = 1'b0;
                present_state = `WRITE_REG;
            end

            `WRITE_REG: begin //Writing to Rn or Rd
                w = 1'b0;
                if ((op == 2'b11) & (opcode == 3'b101)) begin //MVN
                    nsel = `Rd;
                    vsel = 2'b11;
                    write = 1'b1;
                    mem_cmd = `MNONE;
                end
                else if ((op == 2'b00) & (opcode == 3'b110)) begin //MOV reg -> reg
                    nsel = `Rd;
                    vsel = 2'b11;
                    write = 1'b1;
                    mem_cmd = `MNONE;
                end
                else if ((op == 2'b10) & (opcode == 3'b110)) begin //MOV sximm8 (writing to Rn!!!)
                    nsel = `Rn;
                    vsel = 2'b01;
                    write = 1'b1;
                    mem_cmd = `MNONE;
                end
                else if (opcode == 3'b100) begin //Moving the data that we got from memory into the Rd.
                    mem_cmd = `MWRITE;
                    write = 1'b0;
                end

                else if (opcode == 3'b011) begin
                    nsel = `Rd;
                    vsel = 2'b00;
                    write = 1'b1;
                    mem_cmd = `MREAD;
                end
                else begin //ADD, AND (CMP never reaches this state)
                    nsel = `Rd;
                    vsel = 2'b11;
                    write = 1'b1;
                    mem_cmd = `MNONE;
                end

                load_addr = 1'b0;
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                loads = 1'b0;
                asel = 1'b0;
                bsel = 1'b0;
                addr_sel = 1'b0;
                load_ir = 1'b0;
                loadpc = 1'b0;  
                present_state = `IF1;
            end
            default: present_state = present_state;
        endcase
    end
endmodule

module datapath (mdata, PC,datapath_out, sximm8, sximm5, writenum, readnum, write, loada, loadb, asel, bsel, vsel, loadc, loads, shift, ALUop, ZNV_out, clk);
    input [15:0] mdata;
    input [8:0] PC;
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