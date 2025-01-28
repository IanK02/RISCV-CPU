`ifndef _core_v
`define _core_v
`include "system.sv"
`include "base.sv"
`include "memory_io.sv"
`include "memory.sv"
`include "lab1.sv"

module core(
    input logic       clk,
    input logic       reset,
    input logic       [`word_address_size-1:0] reset_pc,
    output memory_io_req32   inst_mem_req,  //instruction memory request
    input  memory_io_rsp32   inst_mem_rsp,  //instruction memory response
    output memory_io_req32   data_mem_req,  //data memory request
    input  memory_io_rsp32   data_mem_rsp   //data memory response
);

typedef enum {
    stage_fetch,
    stage_decode,
    stage_execute,
    stage_mem,
    stage_writeback
} stage;

stage current_stage;

// Registers
word pc, n_pc;
word rs1_value, rs2_value, n_rs1_value, n_rs2_value;
Imm32 imm32, n_imm32;
RegAddr rs1, rs2, rd, n_rs1, n_rs2, n_rd;
word write_data, n_write_data;
logic reg_write_enable, n_req_write_enable;
Opcode opcode, n_opcode;
Funct3 funct3, n_funct3;
Funct7 funct7, n_funct7;
word instr, n_instr;
word alu_result, alu_result_written;
instruction_name decoded_instr_name, n_decoded_instr_name;

//for debug only! delete before submitting
//word rd_value, n_rd_value;

// Register File
logic [`word_size-1:0] register_file [31:0];

// Fetch stage
always_comb begin
    if (current_stage == stage_fetch) begin
        inst_mem_req.addr = pc;
        inst_mem_req.do_read = 4'b1111;
        inst_mem_req.valid = true;
        //$display("Instruction Request Address 0x%08h", inst_mem_req.addr);
        //$display("a5 (x15) value in decode stage: 0x%08h", register_file[15]);
    end else begin
        inst_mem_req = memory_io_no_req;
    end
end

// Decode Stage Combinational logic

always_comb begin
    // Default values
    n_rs1 = '0;
    n_rs2 = '0;
    n_rd = '0;
    n_opcode = '0;
    n_funct3 = '0;
    n_funct7 = '0;
    n_imm32 = '0;
    n_rs1_value = '0;
    n_rs2_value = '0;
    n_decoded_instr_name = UNKNOWN;
    n_instr = '0;
    if (current_stage == stage_decode) begin
        n_instr = inst_mem_rsp.data;
        n_decoded_instr_name = decode_instruction_name(inst_mem_rsp.data);
        n_rs1 = getRs1(inst_mem_rsp.data);
        n_rs2 = getRs2(inst_mem_rsp.data);
        n_rd = getRd(inst_mem_rsp.data);
        n_opcode = getOpcode(inst_mem_rsp.data);
        n_funct3 = getFunct3(inst_mem_rsp.data);
        n_funct7 = getFunct7(inst_mem_rsp.data);
        n_imm32 = getImm32(inst_mem_rsp.data);
        n_rs1_value = register_file[n_rs1];
        n_rs2_value = register_file[n_rs2];
        $display("RS1 Value in Decode Stage:  0x%08h", n_rs1_value);
        $display("RS2 Value in Decode Stage:  0x%08h", n_rs2_value);
    end 
end

// Decode Stage ff 
always_ff @(posedge clk) begin
    if(current_stage == stage_decode) begin
        
        decoded_instr_name <= n_decoded_instr_name;
        instr <= n_instr;
        rs1 <= n_rs1;
        rs2 <= n_rs2;
        rd <= n_rd;
        opcode <= n_opcode;
        funct3 <= n_funct3;
        funct7 <= n_funct7;
        imm32 <= n_imm32;
        rs1_value <= n_rs1_value;
        rs2_value <= n_rs2_value;

        /*
        instr <= inst_mem_rsp.data;
        decoded_instr_name <= decode_instruction_name(inst_mem_rsp.data);
        rs1 <= getRs1(inst_mem_rsp.data);
        rs2 <= getRs2(inst_mem_rsp.data);
        rd <= getRd(inst_mem_rsp.data);
        opcode <= getOpcode(inst_mem_rsp.data);
        funct3 <= getFunct3(inst_mem_rsp.data);
        funct7 <= getFunct7(inst_mem_rsp.data);
        imm32 <= getImm32(inst_mem_rsp.data);
        //rs1_value <= register_file[rs1];
        //rs2_value <= register_file[rs2];
        //rd_value <= register_file[rd];
        */
    end
end


// Execute stage
always_comb begin
    if (current_stage == stage_execute) begin
        print_instruction(pc, instr);   
        //$display("Decoded Instruction Name: %b", decoded_instr_name);
        //rs1_value = register_file[rs1];
        //rs2_value = register_file[rs2];
        //rd_value = register_file[rd];
        case (decoded_instr_name)
            // R-type instructions
            ADD:  alu_result = rs1_value + rs2_value;
            SUB:  alu_result = rs1_value - rs2_value;
            AND:  alu_result = rs1_value & rs2_value;
            OR:   alu_result = rs1_value | rs2_value;
            XOR:  alu_result = rs1_value ^ rs2_value;
            SLL:  alu_result = rs1_value << (rs2_value & 32'h1F); //extract bottom 5 bits of rs2_value
            SRL:  alu_result = rs1_value >> (rs2_value & 32'h1F);
            SRA:  alu_result = $signed(rs1_value) >>> (rs2_value & 32'h1F);
            SLT:  alu_result = ($signed(rs1_value) < $signed(rs2_value)) ? 1 : 0;
            SLTU: alu_result = (rs1_value < rs2_value) ? 1 : 0;
            // I-type instructions
            ADDI:  alu_result = rs1_value + imm32;
            ANDI:  alu_result = rs1_value & imm32;
            ORI:   alu_result = rs1_value | imm32;
            XORI:  alu_result = rs1_value ^ imm32;
            SLLI:  alu_result = rs1_value << (imm32 & 32'h1F);
            SRLI:  alu_result = rs1_value >> (imm32 & 32'h1F);
            SRAI:  alu_result = $signed(rs1_value) >>> (imm32 & 32'h1F);
            SLTI:  alu_result = ($signed(rs1_value) < imm32) ? 1 : 0;
            SLTIU: alu_result = (rs1_value < $unsigned(imm32)) ? 1 : 0;
            // Load instructions (I-type)
            LB, LH, LW, LBU, LHU: alu_result = rs1_value + imm32;
            // JALR (I-type)
            JALR: alu_result = pc + 4;
            default: alu_result = 0;
        endcase
        $display("Immediate Value %d", imm32);
        $display("RS1: %b, RS1 Value:  0x%08h", rs1, rs1_value);
        $display("RS2: %b, RS2 Value:  0x%h", rs2, rs2_value);
        $display("RD: %b", rd);
        $display("ALU Result: 0x%8h", alu_result);
    end
end

//Memory stage
//nothing here yet

// Writeback stage
always_comb begin
    if (current_stage == stage_writeback) begin
        case (decoded_instr_name)
            // R-type instructions
            ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU,
            // I-type instructions
            ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU: begin
                //reg_write_enable = 1'b1;
                //write_data <= alu_result;
                register_file[rd] = alu_result;
                $display("Writing [0x%08h] to register[%b]\n", alu_result, rd);
            end
            default: begin
                //reg_write_enable = 1'b0;
                //write_data <= 'x;
                //register_file[rd] <= alu_result;
            end
        endcase
        $display("-----------------------------------------------------");
    end 
end


// PC update
always_comb begin
    if (current_stage == stage_writeback) begin
        if (decoded_instr_name == JALR)
            n_pc = (rs1_value + imm32) & ~1;
        else
            n_pc = pc + 4;
    end else begin
        n_pc = pc;
    end
end

// PC Update
always_ff @(posedge clk) begin
    if(reset)begin
        pc <= reset_pc;
    end else begin
        pc <= n_pc;
    end
end

// Stage progression
always_ff @(posedge clk) begin
    if (reset)
        current_stage <= stage_fetch;
    else begin
        case (current_stage)
            stage_fetch:    current_stage <= stage_decode;
            stage_decode:   current_stage <= stage_execute;
            stage_execute:  current_stage <= stage_mem;
            stage_mem:      current_stage <= stage_writeback;
            stage_writeback: current_stage <= stage_fetch;
            default: begin
                $display("Should never get here\n");
                current_stage <= stage_fetch;
            end
        endcase
    end
end

endmodule

`endif