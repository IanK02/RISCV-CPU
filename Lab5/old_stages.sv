/*
always_ff @(posedge clk) begin
    //EXMEM <= DEX; // Copy DEX to EXMEM
    if (DEX.valid) begin // Execute only if DEX has valid data
        case (DEX.decoded_instr_name)
            // R-type instructions
            ADD:  EXMEM.alu_result <= DEX_rs1_value + DEX_rs2_value;
            SUB:  EXMEM.alu_result <= DEX_rs1_value - DEX_rs2_value;
            AND:  EXMEM.alu_result <= DEX_rs1_value & DEX_rs2_value;
            OR:   EXMEM.alu_result <= DEX_rs1_value | DEX_rs2_value;
            XOR:  EXMEM.alu_result <= DEX_rs1_value ^ DEX_rs2_value;
            SLL:  EXMEM.alu_result <= DEX_rs1_value << (DEX_rs2_value & 32'h1F);
            SRL:  EXMEM.alu_result <= DEX_rs1_value >> (DEX_rs2_value & 32'h1F);
            SRA:  EXMEM.alu_result <= $signed(DEX_rs1_value) >>> (DEX_rs2_value & 32'h1F);
            SLT:  EXMEM.alu_result <= ($signed(DEX_rs1_value) < $signed(DEX_rs2_value)) ? 1 : 0;
            SLTU: EXMEM.alu_result <= (DEX_rs1_value < DEX_rs2_value) ? 1 : 0;
            // I-type instructions
            ADDI:  EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            ANDI:  EXMEM.alu_result <= DEX_rs1_value & DEX.imm32;
            ORI:   EXMEM.alu_result <= DEX_rs1_value | DEX.imm32;
            XORI:  EXMEM.alu_result <= DEX_rs1_value ^ DEX.imm32;
            SLLI:  EXMEM.alu_result <= DEX_rs1_value << (DEX.imm32 & 32'h1F);
            SRLI:  EXMEM.alu_result <= DEX_rs1_value >> (DEX.imm32 & 32'h1F);
            SRAI:  EXMEM.alu_result <= $signed(DEX_rs1_value) >>> (DEX.imm32 & 32'h1F);
            SLTI:  EXMEM.alu_result <= ($signed(DEX_rs1_value) < DEX.imm32) ? 1 : 0;
            SLTIU: EXMEM.alu_result <= (DEX_rs1_value < $unsigned(DEX.imm32)) ? 1 : 0;
            // Load instructions (I-type)
            LB:    EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            LH:    EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            LW:    EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            LBU:   EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            LHU:   EXMEM.alu_result <= DEX_rs1_value + DEX.imm32;
            // Store instructions (S-type)
            SB: EXMEM.alu_result <= DEX_rs1_value + DEX.imms;
            SH: EXMEM.alu_result <= DEX_rs1_value + DEX.imms;
            SW: EXMEM.alu_result <= DEX_rs1_value + DEX.imms;
            // LUI (U-type)
            LUI: EXMEM.alu_result <= DEX.immu << 12; // Shift the immediate value left by 12 bits
            // JAL (J-type)
            JAL: EXMEM.alu_result <= DEX.pc_plus_4;
            // JALR (I-type)
            JALR: EXMEM.alu_result <= DEX.pc_plus_4;
            // Branch instructions (B-type)
            BEQ:  EXMEM.alu_result <= (DEX_rs1_value == DEX_rs2_value) ? 1 : 0;
            BNE:  EXMEM.alu_result <= (DEX_rs1_value != DEX_rs2_value) ? 1 : 0;
            BLT:  EXMEM.alu_result <= ($signed(DEX_rs1_value) < $signed(DEX_rs2_value)) ? 1 : 0;
            BGE:  EXMEM.alu_result <= ($signed(DEX_rs1_value) >= $signed(DEX_rs2_value)) ? 1 : 0;
            BLTU: EXMEM.alu_result <= (DEX_rs1_value < DEX_rs2_value) ? 1 : 0;
            BGEU: EXMEM.alu_result <= (DEX_rs1_value >= DEX_rs2_value) ? 1 : 0;
            default: EXMEM.alu_result <= 0;
        endcase
        EXMEM.rd <= DEX.rd;
        EXMEM.wbv <= DEX.wbv;
        EXMEM.decoded_instr_name <= DEX.decoded_instr_name;
        EXMEM.store_data <= DEX_rs2_value;
        EXMEM.is_load <= (DEX.decoded_instr_name == LB || DEX.decoded_instr_name == LH ||
                        DEX.decoded_instr_name == LW || DEX.decoded_instr_name == LBU ||
                        DEX.decoded_instr_name == LHU);
        EXMEM.pc_plus_4 <= DEX.pc_plus_4;
        EXMEM.valid <= 1'b1;
        EXMEM.instruction <= DEX.instruction;
    end else begin
       EXMEM.valid <= 1'b0;
    end
end
*/

// DECODE Stage - quizas lo hago en dos partes, uno con un always_ff, y uno con always_comb
always_ff @(posedge clk) begin
    //if (!stall_flag) begin
        //DEX = FD; //Copy FD register into DEX register (Struct copy)
        if (FD.valid) begin
           DEX.decoded_instr_name <= decode_instruction_name(FD.instruction);
           DEX.rs1 <= getRs1(FD.instruction);
           DEX.rs2 <= getRs2(FD.instruction);
           DEX.rd <= getRd(FD.instruction);
           DEX.opcode <= getOpcode(FD.instruction);
           DEX.funct3 <= getFunct3(FD.instruction);
           DEX.funct7 <= getFunct7(FD.instruction);
           DEX.imm32 <= getImm32(FD.instruction);
           DEX.imms <= getImmS(FD.instruction);
           DEX.immu <= getImmU(FD.instruction);
           DEX.immb <= getImmB(FD.instruction);
           DEX.immj <= getImmJ(FD.instruction);
           DEX.wbv <= getWriteback(DEX.opcode);
           DEX.pc_plus_4 <= pc + 4;
           DEX.instruction <= FD.instruction;
           DEX.valid <= 1'b1;
        end else begin
           DEX.valid <= 1'b0; //If FD was invalid, DEX is invalid too.
        end
    //end
end //somehow get DEX_rs1_value and DEX_rs2_value in decode stage
