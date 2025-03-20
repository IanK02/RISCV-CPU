module execute_stage (
    input logic clk,
    input logic reset,
    input dex_reg DEX,
    input word DEX_rs1_value,
    input word DEX_rs2_value,
    output logic stall_flag,
    output exmem_reg EXMEM
);

logic alu_result_comb;
logic is_load_comb;
logic valid_comb;
word alu_result_comb_word;

always_comb begin : execute_comb
    valid_comb = 1'b0;
    alu_result_comb_word = 32'h0; // Default ALU result
    is_load_comb = 1'b0;
    stall_flag = 1'b0; // Default no stall

    if (DEX.valid) begin
        valid_comb = 1'b1;

        case (DEX.decoded_instr_name)
            // R-type instructions
            ADD:  alu_result_comb_word = DEX_rs1_value + DEX_rs2_value;
            SUB:  alu_result_comb_word = DEX_rs1_value - DEX_rs2_value;
            AND:  alu_result_comb_word = DEX_rs1_value & DEX_rs2_value;
            OR:   alu_result_comb_word = DEX_rs1_value | DEX_rs2_value;
            XOR:  alu_result_comb_word = DEX_rs1_value ^ DEX_rs2_value;
            SLL:  alu_result_comb_word = DEX_rs1_value << (DEX_rs2_value & 32'h1F);
            SRL:  alu_result_comb_word = DEX_rs1_value >> (DEX_rs2_value & 32'h1F);
            SRA:  alu_result_comb_word = $signed(DEX_rs1_value) >>> (DEX_rs2_value & 32'h1F);
            SLT:  alu_result_comb_word = ($signed(DEX_rs1_value) < $signed(DEX_rs2_value)) ? 1 : 0;
            SLTU: alu_result_comb_word = (DEX_rs1_value < DEX_rs2_value) ? 1 : 0;
            // I-type instructions
            ADDI:  alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            ANDI:  alu_result_comb_word = DEX_rs1_value & DEX.imm32;
            ORI:   alu_result_comb_word = DEX_rs1_value | DEX.imm32;
            XORI:  alu_result_comb_word = DEX_rs1_value ^ DEX.imm32;
            SLLI:  alu_result_comb_word = DEX_rs1_value << (DEX.imm32 & 32'h1F);
            SRLI:  alu_result_comb_word = DEX_rs1_value >> (DEX.imm32 & 32'h1F);
            SRAI:  alu_result_comb_word = $signed(DEX_rs1_value) >>> (DEX.imm32 & 32'h1F);
            SLTI:  alu_result_comb_word = ($signed(DEX_rs1_value) < DEX.imm32) ? 1 : 0;
            SLTIU: alu_result_comb_word = (DEX_rs1_value < $unsigned(DEX.imm32)) ? 1 : 0;
            // Load instructions (I-type)
            LB:    alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            LH:    alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            LW:    alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            LBU:   alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            LHU:   alu_result_comb_word = DEX_rs1_value + DEX.imm32;
            // Store instructions (S-type)
            SB: alu_result_comb_word = DEX_rs1_value + DEX.imms;
            SH: alu_result_comb_word = DEX_rs1_value + DEX.imms;
            SW: alu_result_comb_word = DEX_rs1_value + DEX.imms;
            // LUI (U-type)
            LUI: alu_result_comb_word = DEX.immu << 12; // Shift the immediate value left by 12 bits
            // JAL (J-type)
            JAL: alu_result_comb_word = DEX.pc_plus_4;
            // JALR (I-type)
            JALR: alu_result_comb_word = DEX.pc_plus_4;
            // Branch instructions (B-type)
            BEQ:  alu_result_comb_word = (DEX_rs1_value == DEX_rs2_value) ? 1 : 0;
            BNE:  alu_result_comb_word = (DEX_rs1_value != DEX_rs2_value) ? 1 : 0;
            BLT:  alu_result_comb_word = ($signed(DEX_rs1_value) < $signed(DEX_rs2_value)) ? 1 : 0;
            BGE:  alu_result_comb_word = ($signed(DEX_rs1_value) >= $signed(DEX_rs2_value)) ? 1 : 0;
            BLTU: alu_result_comb_word = (DEX_rs1_value < DEX_rs2_value) ? 1 : 0;
            BGEU: alu_result_comb_word = (DEX_rs1_value >= DEX_rs2_value) ? 1 : 0;
            default: alu_result_comb_word = 0;
        endcase

        is_load_comb = (DEX.decoded_instr_name == LB || DEX.decoded_instr_name == LH ||
                        DEX.decoded_instr_name == LW || DEX.decoded_instr_name == LBU ||
                        DEX.decoded_instr_name == LHU);
    end
end

always_ff @(posedge clk) begin
    if (reset) begin
        EXMEM.valid <= 1'b0;
    end else begin
        EXMEM.alu_result <= alu_result_comb_word;
        EXMEM.rd <= DEX.rd;
        EXMEM.wbv <= DEX.wbv;
        EXMEM.decoded_instr_name <= DEX.decoded_instr_name;
        EXMEM.store_data <= DEX_rs2_value;
        EXMEM.is_load <= is_load_comb;
        EXMEM.pc_plus_4 <= DEX.pc_plus_4;
        EXMEM.valid <= valid_comb;
        EXMEM.instruction <= DEX.instruction;
    end
end

endmodule
