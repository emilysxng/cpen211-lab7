`define WAIT 5'b00000
`define DECODE 5'b00001
`define GET_A 5'b00010
`define GET_B 5'b00011
`define ADD 5'b00100
`define WRITE_REG 5'b00101
`define CMP 5'b00110
`define AND 5'b00111
`define MVN 5'b01000
`define Rd 3'b010
`define Rm 3'b001
`define Rn 3'b100

module FSM_controller (clk, reset, s, opcode, op, nsel, asel, bsel, w, loada, loadb, loadc, loads, ALUop, vsel, write);
    input clk, reset, s;
    input [2:0] opcode;
    input [1:0] op;
    output reg [2:0] nsel;
    output reg asel,bsel,loada,loadb,loadc,write,loads;
    output reg [1:0] vsel, ALUop;
    output reg w;
    reg [4:0] present_state;

    always_ff @( posedge clk ) begin 

        if (reset) begin
            present_state = `WAIT;
        end

        case (present_state)
            `WAIT: begin
                w = 1'b1;
                if (s) begin
                    present_state = `DECODE;
                end
                else begin
                    present_state = `WAIT;
                end
                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
                nsel = 3'b000;
                asel = 1'b0;
                bsel = 1'b0;
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

                loadc = 1'b0;
                loadb = 1'b0;
                loada = 1'b0;
                write = 1'b0;
                loads = 1'b0;
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
            end

            `GET_B: begin
                w = 1'b0;
                nsel = `Rm;
                loada = 1'b0;
                loadb = 1'b1;
                write = 1'b0;
                loadc = 1'b0;
                loads = 1'b0;

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
                if (opcode == 3'b101) begin
                    asel = 1'b0;
                end
                else if (opcode == 3'b110) begin
                    asel = 1'b1;
                end
                bsel = 1'b0;
                present_state = `WRITE_REG;
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
                present_state = `WAIT; //Do not need to go to write_reg
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
                present_state = `WRITE_REG;
            end

            `WRITE_REG: begin //Writing to Rn or Rd
                w = 1'b0;
                if ((op == 2'b11) & (opcode == 3'b101)) begin //MVN
                    nsel = `Rd;
                    vsel = 2'b11;
                end
                else if ((op == 2'b00) & (opcode == 3'b110)) begin //MOV reg -> reg
                    nsel = `Rd;
                    vsel = 2'b11;
                end
                else if ((op == 2'b10) & (opcode == 3'b110)) begin //MOV sximm8 (writing to Rn!!!)
                    nsel = `Rn;
                    vsel = 2'b01;
                end
                else begin //ADD, AND (CMP never reaches this state)
                    nsel = `Rd;
                    vsel = 2'b11;
                end
                loadc = 1'b0;
                write = 1'b1;
                loadb = 1'b0;
                loada = 1'b0;
                loads = 1'b0;
                asel = 1'b0;
                bsel = 1'b0;
                present_state = `WAIT;
            end
            default: present_state = present_state;
        endcase
    end
endmodule