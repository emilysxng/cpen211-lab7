module FSM_controller (clk, reset, opcode, op, nsel, asel, bsel, loada, loadb, loadc , load_ir, load_addr, addr_sel, reset_pc, loadpc, mem_cmd, loads, ALUop, vsel, write);
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

                else if (opcode == 3'b100) begin
                    present_state = `GET_A;
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

            `GET_A: begin
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
