// Define types for each instruction field
typedef logic [6:0] Opcode;
typedef logic [4:0] RegAddr;
typedef logic [2:0] Funct3;
typedef logic [6:0] Funct7;
typedef logic signed [11:0] ImmI;
typedef logic signed [31:0] ImmS;
typedef logic signed [31:0] ImmB;
typedef logic signed [31:0] ImmU;
typedef logic signed [31:0] ImmJ;
typedef logic signed [31:0] Imm32;
typedef logic [31:0] instr32;
typedef logic [3:0] basemask;
typedef logic [5:0] Forwarding_Flags;
typedef enum logic [6:0] {
    // R-type instructions
    ADD,
    SUB,
    AND,
    OR,
    XOR,
    SLL,
    SRL,
    SRA,
    SLT,
    SLTU,
    // I-type instructions
    ADDI,
    ANDI,
    ORI,
    XORI,
    SLLI,
    SRLI,
    SRAI,
    SLTI,
    SLTIU,
    LB,
    LH,
    LW,
    LUI,
    LBU,
    LHU,
    SB,
    SH,
    SW,
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU,
    JAL,
    JALR,
    UNKNOWN
} instruction_name;

typedef enum logic [2:0] {
     memory_b = 0
    ,memory_h = 1
    ,memory_w = 2
    ,memory_bu = 4
    ,memory_hu = 5
}   memory_op;

//CPU Stages (No longer used for explicit stage tracking)
typedef enum {
    stage_fetch,
    stage_decode,
    stage_execute,
    stage_mem,
    stage_writeback
} stage;

// Pipeline Register Structures
typedef struct packed {
    instr32 instruction;
    word pc; //Store the PC *before* increment
    word pc_plus_4;
    logic valid; //Indicates if this register contains valid data
} fd_reg;

typedef struct packed {
    instr32 instruction;
    Imm32 imm32;
    ImmS imms;
    ImmU immu;
    ImmB immb;
    ImmJ immj;
    RegAddr rs1, rs2, rd;
    Opcode opcode;
    Funct3 funct3;
    Funct7 funct7;
    word pc_plus_4;
    word pc;
    instruction_name decoded_instr_name;
    logic wbv;
    logic valid;
    logic is_load;
    logic is_branch;
} dex_reg;

typedef struct packed {
    word alu_result;
    word store_data;
    RegAddr rd;
    logic wbv;
    instruction_name decoded_instr_name;
    logic is_load; // Indicates if the instruction is a load
    word pc;
    logic valid;
    Funct3 funct3;
    word instruction; //GET RID OF THIS IN FINAL VERSION, ONLY FOR DEBUGGING
    logic is_branch;
} exmem_reg;

typedef struct packed {
    word write_data;
    RegAddr rd;
    logic wbv;
    instruction_name decoded_instr_name;
    word pc;
    logic valid;
    word alu_result;
    Funct3 funct3;
    word instruction; //GET RID OF THIS IN FINAL VERSION, ONLY FOR DEBUGGING
    logic is_branch;
} memwb_reg;

// Helper functions to extract fields
function automatic Opcode getOpcode(input logic [31:0] instruction);
    return Opcode'(instruction & 32'h7f);
endfunction

function automatic RegAddr getRd(input logic [31:0] instruction);
    return RegAddr'((instruction >> 7) & 32'h1f);
endfunction

function automatic Funct3 getFunct3(input logic [31:0] instruction);
    return Funct3'((instruction >> 12) & 32'h7);
endfunction

function automatic RegAddr getRs1(input logic [31:0] instruction);
    return RegAddr'((instruction >> 15) & 32'h1f);
endfunction

function automatic RegAddr getRs2(input logic [31:0] instruction);
    return RegAddr'((instruction >> 20) & 32'h1f);
endfunction

function automatic Funct7 getFunct7(input logic [31:0] instruction);
    return Funct7'((instruction >> 25) & 32'h7f);
endfunction

function automatic ImmI getImmI(input logic [31:0] instruction);
    return ImmI'((instruction >> 20) & 32'hfff);
endfunction

function automatic Imm32 getImm32(input logic [31:0] instruction);
    return Imm32'({{20{instruction[31]}}, instruction[31:20]});
endfunction

function automatic ImmS getImmS(input logic [31:0] instruction);
    return ImmS'({{20{instruction[31]}}, instruction[31:25], instruction[11:7]});
endfunction

function automatic ImmB getImmB(input logic [31:0] instruction);
    return ImmB'({{20{instruction[31]}},  // Sign extend (imm[12])
                  instruction[7],         // imm[11]
                  instruction[30:25],     // imm[10:5]
                  instruction[11:8],      // imm[4:1]
                  1'b0});                 // Always 0 (word-aligned)
endfunction

function automatic ImmU getImmU(input logic [31:0] instruction);
    return ImmU'(instruction & 32'hfffff000) >> 12;
endfunction

function automatic ImmJ getImmJ(input logic [31:0] instruction);
    return ImmJ'({{12{instruction[31]}}, // Sign extend (imm[20])
                  instruction[19:12],    // imm[19:12]
                  instruction[20],       // imm[11]
                  instruction[30:21],    // imm[10:1]
                  1'b0});    
endfunction

function automatic logic getWriteback(input Opcode opc);
    case (opc)
        // R-type instructions (e.g., ADD, SUB, AND, OR, XOR, etc.)
        7'b0110011: return 1'b1;

        // I-type instructions (e.g., ADDI, ANDI, ORI, XORI, etc.)
        7'b0010011: return 1'b1;

        // Load instructions (e.g., LB, LH, LW, LBU, LHU)
        7'b0000011: return 1'b1;

        // U-type instructions (e.g., LUI, AUIPC)
        7'b0110111, 7'b0010111: return 1'b1;

        // J-type instructions (e.g., JAL)
        7'b1101111: return 1'b1;

        // I-type JALR
        7'b1100111: return 1'b1;

        // System instructions (e.g., ECALL, EBREAK) - no writeback
        7'b1110011: return 1'b0;

        // S-type instructions (e.g., SB, SH, SW) - no writeback
        7'b0100011: return 1'b0;

        // B-type instructions (e.g., BEQ, BNE, BLT, BGE, etc.) - no writeback
        7'b1100011: return 1'b0;

        // Default case: assume no writeback for unknown instructions
        default: return 1'b0;
    endcase
endfunction

function automatic word shuffle_load_data(word in, word low_addr); begin
    logic [7:0] b0 = in[7:0];
    logic [7:0] b1 = in[15:8];
    logic [7:0] b2 = in[23:16];
    logic [7:0] b3 = in[31:24];

    case (low_addr[1:0])
        2'b00:  return { b3, b2, b1, b0 };
        2'b01:  return { b0, b3, b2, b1 };
        2'b10:  return { b1, b0, b3, b2 };
        2'b11:  return { b2, b1, b0, b3 };
    endcase
end
endfunction

function automatic word shuffle_store_data(word in, word low_addr); begin
    logic [7:0] b0 = in[7:0];
    logic [7:0] b1 = in[15:8];
    logic [7:0] b2 = in[23:16];
    logic [7:0] b3 = in[31:24];

    case (low_addr[1:0])
        2'b00:  return { b3, b2, b1, b0 };
        2'b01:  return { b2, b1, b0, b3 };
        2'b10:  return { b1, b0, b3, b2 };
        2'b11:  return { b0, b3, b2, b1 };
    endcase
end
endfunction

function word subset_load_data(word in, memory_op op);
    case (op)
        memory_b:   return { {24{in[7]}}, in[7:0] };
        memory_h:   return { {16{in[15]}}, in[15:0] };
        memory_w:   return in;
        memory_bu:  return { {24{1'b0}}, in[7:0] };
        memory_hu:  return { {16{1'b0}}, in[15:0] };
        default:    return in;
    endcase
endfunction

function automatic logic [3:0] shuffle_store_mask(logic [3:0] mask, word low_addr);
    case (low_addr[1:0])
        2'b00:  return { mask[3], mask[2], mask[1], mask[0] };
        2'b01:  return { mask[2], mask[1], mask[0], mask[3] };
        2'b10:  return { mask[1], mask[0], mask[3], mask[2] };
        2'b11:  return { mask[0], mask[3], mask[2], mask[1] };
    endcase
endfunction

function automatic logic [3:0] memory_mask(memory_op op);
    case (op)
        memory_b, memory_bu:    return 4'b0001;
        memory_h, memory_hu:    return 4'b0011;
        default:                return 4'b1111;
    endcase
endfunction

function automatic memory_op cast_to_memory_op(Funct3 in);
// This works, except Vivado complains. So we take the long way (below)
//    return in;  // Yes really
    case (in)
        memory_b: return memory_b;
        memory_h: return memory_h;
        memory_w: return memory_w;
        memory_bu: return memory_bu;
        memory_hu: return memory_hu;
        default: return memory_b;
    endcase;
endfunction

// Function to decode and print a human-readable string for a given RV32I instruction
function automatic void print_instruction(logic [31:0] pc, logic [31:0] instruction);
    // Extract the fields from the instruction using helper functions
    instruction_name result;
    Opcode opcode = getOpcode(instruction);
    RegAddr rd = getRd(instruction);
    Funct3 funct3 = getFunct3(instruction);
    RegAddr rs1 = getRs1(instruction);
    RegAddr rs2 = getRs2(instruction);
    Funct7 funct7 = getFunct7(instruction);
    ImmI immI = getImmI(instruction);
    ImmS immS = getImmS(instruction);
    ImmB immB = getImmB(instruction);
    ImmU immU = getImmU(instruction);
    ImmJ immJ = getImmJ(instruction);

    string outputStr;
    // Decode based on opcode
    case (opcode)
        7'b0110011: begin // R-type
            case (funct3)
                3'b000: begin
                    if (funct7 == 7'b0100000)
                        outputStr = $sformatf("sub x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("mul x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else
                        outputStr = $sformatf("add x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b001: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("sll x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("mulh x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b010: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("slt x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("mulhsu x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b011: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("sltu x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("mulhu x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b100: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("xor x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("div x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b101: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("srl x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0100000)
                        outputStr = $sformatf("sra x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("divu x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b110: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("or x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("rem x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                3'b111: begin
                    if (funct7 == 7'b0000000)
                        outputStr = $sformatf("and x%0d, x%0d, x%0d", rd, rs1, rs2);
                    else if (funct7 == 7'b0000001)
                        outputStr = $sformatf("remu x%0d, x%0d, x%0d", rd, rs1, rs2);
                end
                default: outputStr = "Unknown R-type instruction";
            endcase
        end
        7'b0010011: begin // I-type
            case (funct3)
                3'b000: begin
                    if (rs1 == 5'b00000) // x0
                        outputStr = $sformatf("li x%0d, %0d", rd, $signed(immI));
                    else
                        outputStr = $sformatf("addi x%0d, x%0d, %0d", rd, rs1, $signed(immI));
                end
                3'b001: outputStr = $sformatf("slli x%0d, x%0d, %0d", rd, rs1, $signed(immI[4:0]));
                3'b010: outputStr = $sformatf("slti x%0d, x%0d, %0d", rd, rs1, $signed(immI));
                3'b011: outputStr = $sformatf("sltiu x%0d, x%0d, %0d", rd, rs1, $signed(immI));
                3'b100: outputStr = $sformatf("xori x%0d, x%0d, %0d", rd, rs1, $signed(immI));
                3'b101: outputStr = (funct7 == 7'b0100000) ?
                                    $sformatf("srai x%0d, x%0d, %0d", rd, rs1, $signed(immI[4:0])) :
                                    $sformatf("srli x%0d, x%0d, %0d", rd, rs1, $signed(immI[4:0]));
                3'b110: outputStr = $sformatf("ori x%0d, x%0d, %0d", rd, rs1, $signed(immI)); 
                3'b111: outputStr = $sformatf("andi x%0d, x%0d, %0d", rd, rs1, $signed(immI));
                default: outputStr = "Unknown I-type instruction";
            endcase
        end
        7'b0000011: begin // Load instructions
            case (funct3)
                3'b000: outputStr = $sformatf("lb x%0d, %0d(x%0d)", rd, $signed(immI), rs1);
                3'b001: outputStr = $sformatf("lh x%0d, %0d(x%0d)", rd, $signed(immI), rs1);
                3'b010: outputStr = $sformatf("lw x%0d, %0d(x%0d)", rd, $signed(immI), rs1);
                3'b100: outputStr = $sformatf("lbu x%0d, %0d(x%0d)", rd, $signed(immI), rs1);
                3'b101: outputStr = $sformatf("lhu x%0d, %0d(x%0d)", rd, $signed(immI), rs1);
                default: outputStr = "Unknown load instruction";
            endcase
        end
        7'b0100011: begin // Store instructions
            case (funct3)
                3'b000: outputStr = $sformatf("sb x%0d, %0d(x%0d)", rs2, $signed(immS), rs1);
                3'b001: outputStr = $sformatf("sh x%0d, %0d(x%0d)", rs2, $signed(immS), rs1);
                3'b010: outputStr = $sformatf("sw x%0d, %0d(x%0d)", rs2, $signed(immS), rs1);
                default: outputStr = "Unknown store instruction";
            endcase
        end
        7'b1100011: begin // B-type
            case (funct3)
                3'b000: outputStr = $sformatf("beq x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                3'b001: outputStr = $sformatf("bne x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                3'b100: outputStr = $sformatf("blt x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                3'b101: outputStr = $sformatf("bge x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                3'b110: outputStr = $sformatf("bltu x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                3'b111: outputStr = $sformatf("bgeu x%0d, x%0d, %0d", rs1, rs2, $signed(immB));
                default: outputStr = "Unknown B-type instruction";
            endcase
        end
        7'b0110111: begin // U-type LUI
            if (immU == 0)
                outputStr = $sformatf("li x%0d, 0", rd);
            else
                outputStr = $sformatf("lui x%0d, %0d", rd, $signed(immU));
        end
        7'b0010111: outputStr = $sformatf("auipc x%0d, %0d", rd, $signed(immU)); // U-type AUIPC
        7'b1101111: outputStr = $sformatf("jal x%0d, %0d", rd, $signed(immJ)); // J-type JAL
        7'b1100111: outputStr = $sformatf("jalr x%0d, x%0d, %0d", rd, rs1, $signed(immI)); // I-type JALR
        7'b1110011: begin // System instructions
            case (funct3)
                3'b000: begin
                    if (immI == 12'b000000000000)
                        outputStr = "ecall";
                    else if (immI == 12'b000000000001)
                        outputStr = "ebreak";
                    else
                        outputStr = "Unknown system instruction";
                end
                default: outputStr = "Unknown system instruction";
            endcase
        end
        7'b0101111: begin // Atomic instructions
            case (funct3)
                3'b010: begin
                    case (funct7[6:2])
                        5'b00010: outputStr = $sformatf("lr.w x%0d, (x%0d)", rd, rs1);
                        5'b00011: outputStr = $sformatf("sc.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b00001: outputStr = $sformatf("amoswap.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b00000: outputStr = $sformatf("amoadd.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b01100: outputStr = $sformatf("amoand.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b01000: outputStr = $sformatf("amoor.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b00100: outputStr = $sformatf("amoxor.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b10000: outputStr = $sformatf("amomax.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        5'b10100: outputStr = $sformatf("amomin.w x%0d, x%0d, (x%0d)", rd, rs2, rs1);
                        default: outputStr = "Unknown atomic instruction";
                    endcase
                end
                default: outputStr = "Unknown atomic instruction";
            endcase
        end
        default: outputStr = "Unknown instruction";
    endcase

    $write("%x: ", pc);
    $write("%x   ", instruction);
    $write("%s\n", outputStr);
endfunction

function automatic instruction_name decode_instruction_name (logic [31:0] instruction);
    instruction_name result;
    Opcode opcode = getOpcode(instruction);
    Funct3 funct3 = getFunct3(instruction);
    Funct7 funct7 = getFunct7(instruction);

    case (opcode)
        7'b0110011: begin // R-type
            case (funct3)
                3'b000: begin
                    if (funct7 == Funct7'(7'b0100000))  // Explicit cast for funct7 comparison
                        result = SUB;
                    else
                        result = ADD;
                end
                3'b111: result = AND;
                3'b110: result = OR;
                3'b100: result = XOR;
                3'b001: result = SLL;
                3'b101: begin
                    if (funct7 == Funct7'(7'b0100000))  // Explicit cast for funct7 comparison
                         result = SRA;
                    else
                        result = SRL;
                end
                3'b010: result = SLT;
                3'b011: result = SLTU;
                default: result = UNKNOWN;
            endcase
        end
        7'b0010011: begin // I-type
            case (funct3)
                3'b000: result = ADDI;
                3'b111: result = ANDI;
                3'b110: result = ORI;
                3'b100: result = XORI;
                3'b001: result = SLLI;
                3'b101: begin
                    if (funct7 == Funct7'(7'b0100000))  // Explicit cast for funct7 comparison
                        result = SRAI;
                    else
                        result = SRLI;
                end
                3'b010: result = SLTI;
                3'b011: result = SLTIU;
                default: result = UNKNOWN;
            endcase
        end
        7'b0000011: begin // (I - type) Load instructions 
            case (funct3)
                3'b000: result = LB;
                3'b001: result = LH;
                3'b010: result = LW;
                3'b100: result = LBU;
                3'b101: result = LHU;
                default: result = UNKNOWN;
            endcase
        end
        7'b0100011: begin // S-type (Store instructions)
            case (funct3)
                3'b000: result = SB; // Store byte
                3'b001: result = SH; // Store halfword
                3'b010: result = SW; // Store word
                default: result = UNKNOWN;
            endcase
        end
        7'b1100011: begin // B-type (Branch instructions)
            case (funct3)
                3'b000: return BEQ;
                3'b001: return BNE;
                3'b100: return BLT;
                3'b101: return BGE;
                3'b110: return BLTU;
                3'b111: return BGEU;
                default: return UNKNOWN;
            endcase
        end
        7'b0110111: result = LUI; // U-type LUI
        7'b1101111: return JAL; // J-type JAL 
        7'b1100111: result = JALR; // I-type JALR
        default: result = UNKNOWN;
    endcase

    return result;
endfunction

module execute_stage (
    input logic clk,
    input logic reset,
    input dex_reg DEX,
    input word DEX_rs1_value,
    input word DEX_rs2_value,
    output exmem_reg EXMEM,
    output word alu_result,
    output word rs1_value_used,
    input logic stall_flag,
    output logic branch_taken,
    input Forwarding_Flags forwarding_flags,
    input word forwarded_memstage_data,
    input word forwarded_wbstage_data,
    input word forwarded_last_written_data,
    output ImmB decoded_immb,
    output logic jal_taken,
    output logic jalr_taken
);

logic alu_result_comb;
word rs1_value, rs2_value;
logic valid_comb;
word alu_result_comb_word;

always_comb begin : execute_comb
    valid_comb = 1'b0;
    alu_result_comb_word = 32'h0; // Default ALU result
    jal_taken = 0;
    jalr_taken = 0; //jal and jalr not taken by default
    rs1_value = DEX_rs1_value;
    rs2_value = DEX_rs2_value;
    if(forwarding_flags[0]) begin
        rs1_value = forwarded_memstage_data;
    end
    if(forwarding_flags[1]) begin
        rs2_value = forwarded_memstage_data;
    end
    if(forwarding_flags[2]) begin
        rs1_value = forwarded_wbstage_data;
    end
    if(forwarding_flags[3]) begin
        rs2_value = forwarded_wbstage_data;
    end
    if(forwarding_flags[4]) begin
        rs1_value = forwarded_last_written_data;
    end
    if(forwarding_flags[5]) begin
        rs2_value = forwarded_last_written_data;
    end
    rs1_value_used = rs1_value;

    if (1'b1) begin
        valid_comb = 1'b1;

        case (DEX.decoded_instr_name)
            // R-type instructions
            ADD:  alu_result_comb_word = rs1_value + rs2_value;
            SUB:  alu_result_comb_word = rs1_value - rs2_value;
            AND:  alu_result_comb_word = rs1_value & rs2_value;
            OR:   alu_result_comb_word = rs1_value | rs2_value;
            XOR:  alu_result_comb_word = rs1_value ^ rs2_value;
            SLL:  alu_result_comb_word = rs1_value << (rs2_value & 32'h1F);
            SRL:  alu_result_comb_word = rs1_value >> (rs2_value & 32'h1F);
            SRA:  alu_result_comb_word = $signed(rs1_value) >>> (rs2_value & 32'h1F);
            SLT:  alu_result_comb_word = ($signed(rs1_value) < $signed(rs2_value)) ? 1 : 0;
            SLTU: alu_result_comb_word = (rs1_value < rs2_value) ? 1 : 0;
            // I-type instructions
            ADDI:  alu_result_comb_word = rs1_value + DEX.imm32;
            ANDI:  alu_result_comb_word = rs1_value & DEX.imm32;
            ORI:   alu_result_comb_word = rs1_value | DEX.imm32;
            XORI:  alu_result_comb_word = rs1_value ^ DEX.imm32;
            SLLI:  alu_result_comb_word = rs1_value << (DEX.imm32 & 32'h1F);
            SRLI:  alu_result_comb_word = rs1_value >> (DEX.imm32 & 32'h1F);
            SRAI:  alu_result_comb_word = $signed(rs1_value) >>> (DEX.imm32 & 32'h1F);
            SLTI:  alu_result_comb_word = ($signed(rs1_value) < DEX.imm32) ? 1 : 0;
            SLTIU: alu_result_comb_word = (rs1_value < $unsigned(DEX.imm32)) ? 1 : 0;
            // Load instructions (I-type)
            LB:    alu_result_comb_word = rs1_value + DEX.imm32;
            LH:    alu_result_comb_word = rs1_value + DEX.imm32;
            LW:    alu_result_comb_word = rs1_value + DEX.imm32;
            LBU:   alu_result_comb_word = rs1_value + DEX.imm32;
            LHU:   alu_result_comb_word = rs1_value + DEX.imm32;
            // Store instructions (S-type)
            SB: alu_result_comb_word = rs1_value + DEX.imms;
            SH: alu_result_comb_word = rs1_value + DEX.imms;
            SW: alu_result_comb_word = rs1_value + DEX.imms;
            // LUI (U-type)
            LUI: alu_result_comb_word = DEX.immu << 12; // Shift the immediate value left by 12 bits
            // JAL (J-type)
            JAL: begin
                alu_result_comb_word = DEX.pc + 4;
                jal_taken = 1;
            end
            // JALR (I-type)
            JALR: begin
                alu_result_comb_word = DEX.pc + 4;
                jalr_taken = 1;
            end
            // Branch instructions (B-type)
            BEQ:  alu_result_comb_word = (rs1_value == rs2_value) ? 1 : 0;
            BNE:  alu_result_comb_word = (rs1_value != rs2_value) ? 1 : 0;
            BLT:  alu_result_comb_word = ($signed(rs1_value) < $signed(rs2_value)) ? 1 : 0;
            BGE:  alu_result_comb_word = ($signed(rs1_value) >= $signed(rs2_value)) ? 1 : 0;
            BLTU: alu_result_comb_word = (rs1_value < rs2_value) ? 1 : 0;
            BGEU: alu_result_comb_word = (rs1_value >= rs2_value) ? 1 : 0;
            default: alu_result_comb_word = 0;
        endcase
        //assigning output signals
        alu_result = alu_result_comb_word;
        branch_taken = is_branch_taken(
            DEX.decoded_instr_name,
            rs1_value,
            rs2_value,
            DEX.is_branch
        );
        decoded_immb = DEX.immb;
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
        EXMEM.store_data <= rs2_value;
        EXMEM.is_load <= DEX.is_load;
        EXMEM.pc <= DEX.pc;
        EXMEM.valid <= valid_comb;
        EXMEM.instruction <= DEX.instruction;
        EXMEM.funct3 <= DEX.funct3;
        EXMEM.is_branch <= DEX.is_branch;
    end
    //if(branch_taken) $display("Branch was taken");
    $display("RS1 Value: %h,RS2 Value: %h,ALU Result: %h", rs1_value, rs2_value, alu_result_comb_word);
    //if(jal_taken) $display("Jumping to %8h because of jal", DEX.pc + $signed(DEX.immj));
    //("Decoded instr name used in branch calculations %d", DEX.decoded_instr_name);
end

endmodule

module decode_stage (
    input logic clk,
    input logic reset,
    input fd_reg FD,
    input exmem_reg EXMEM,
    input memwb_reg MEMWB,
    output dex_reg DEX,
    output read_reg_valid,
    output RegAddr rs1,
    output RegAddr rs2,
    output logic branch_forward_ex_rs1,
    output logic branch_forward_ex_rs2,
    output logic branch_forward_mem_rs1,
    output logic branch_forward_mem_rs2,
    output logic branch_forward_wb_rs1,
    output logic branch_forward_wb_rs2,
    input word DEX_rs1_value,
    input word DEX_rs2_value,
    input word forwarded_exstage_data,
    input word forwarded_memstage_data,
    input word forwarded_wbstage_data,
    input logic stall_flag,
    input logic branch_taken
);

// Combinatorial Decoding Logic
instruction_name decoded_instr_name_comb; // was instruction_name, changed to logic [31:0]
RegAddr rs1_comb;
RegAddr rs2_comb;
RegAddr rd_comb;
Opcode opcode_comb;
Funct3 funct3_comb;
Funct7 funct7_comb;
Imm32 imm32_comb;
ImmS imms_comb;
ImmU immu_comb;
ImmB immb_comb;
ImmJ immj_comb;
logic wbv_comb;
word pc_comb;
instr32 instruction_comb;
logic valid_comb;
logic is_load_comb;
logic is_branch_comb;

always_comb begin : decode_comb
    // Default Assignments (in case FD.valid is false)
    decoded_instr_name_comb = UNKNOWN; // Or some default value
    rs1_comb = 0;
    rs2_comb = 0;
    rd_comb = 0;
    opcode_comb = 0;
    funct3_comb = 0;
    funct7_comb = 0;
    imm32_comb = 0;
    imms_comb = 0;
    immu_comb = 0;
    immb_comb = 0;
    immj_comb = 0;
    wbv_comb = 0;
    pc_comb = 0;
    instruction_comb = 0;
    valid_comb = 0;
    is_load_comb = 0;
    is_branch_comb = 0;

    if (1'b1) begin
        decoded_instr_name_comb = decode_instruction_name(FD.instruction);
        rs1_comb = getRs1(FD.instruction);
        rs2_comb = getRs2(FD.instruction);
        rd_comb = getRd(FD.instruction);
        opcode_comb = getOpcode(FD.instruction);
        funct3_comb = getFunct3(FD.instruction);
        funct7_comb = getFunct7(FD.instruction);
        imm32_comb = getImm32(FD.instruction);
        imms_comb = getImmS(FD.instruction);
        immu_comb = getImmU(FD.instruction);
        immb_comb = getImmB(FD.instruction);
        immj_comb = getImmJ(FD.instruction);
        wbv_comb = getWriteback(opcode_comb);  // Use the combinational opcode
        pc_comb = FD.pc;
        instruction_comb = FD.instruction;
        valid_comb = 1'b1;
        is_load_comb = (decoded_instr_name_comb == LB || decoded_instr_name_comb == LH ||
                decoded_instr_name_comb == LW || decoded_instr_name_comb == LBU ||
                decoded_instr_name_comb == LHU);
        is_branch_comb = (decoded_instr_name_comb == BEQ || decoded_instr_name_comb == BNE ||
                decoded_instr_name_comb == BLT || decoded_instr_name_comb == BGE ||
                decoded_instr_name_comb == BLTU || decoded_instr_name_comb == BGEU);
        case (opcode_comb) 
            7'b0010011: begin //I-type
                rs2_comb = 0;
            end
            7'b0000011: begin //I-type
                rs2_comb = 0;
            end
            7'b1110011: begin //I-type
                rs2_comb = 0;
            end
            7'b1100111: begin //I-type(JALR)
                rs2_comb = 0;
            end
            7'b1101111: begin //J-type(JAL)
                rs1_comb = 0;
                rs2_comb = 0;
                funct3_comb = 0;
            end
            7'b0110111: begin //U-type
                rs1_comb = 0;
                rs2_comb = 0;
                funct3_comb = 0;
            end
            7'b0010111: begin //U-type
                rs1_comb = 0;
                rs2_comb = 0;
                funct3_comb = 0;
            end
            7'b0100011: begin //S-type
                rd_comb = 0;
            end
            7'b1100011: begin //B-type
                rd_comb = 0;
            end
            default: begin

            end
        endcase
    end else begin
        valid_comb = 1'b0;
    end
    //assigning output signals
    read_reg_valid = valid_comb;
    rs1 = rs1_comb;
    rs2 = rs2_comb;
    branch_forward_ex_rs1 = ((DEX.rd == rs1) && (DEX.rd != 0) && (DEX.wbv) && is_branch_comb);
    branch_forward_ex_rs2 = ((DEX.rd == rs2) && (DEX.rd != 0) && (DEX.wbv) && is_branch_comb);
    branch_forward_mem_rs1 = ((EXMEM.rd == rs1) && (EXMEM.rd != 0) && (EXMEM.wbv) && is_branch_comb);  
    branch_forward_mem_rs2 = ((EXMEM.rd == rs2) && (EXMEM.rd != 0) && (EXMEM.wbv) && is_branch_comb);
    branch_forward_wb_rs1 = ((MEMWB.rd == rs1) && (MEMWB.rd != 0) && (MEMWB.wbv) && is_branch_comb);
    branch_forward_wb_rs2 = ((MEMWB.rd == rs2) && (MEMWB.rd != 0) && (MEMWB.wbv) && is_branch_comb);
    /*
    branch_taken = is_branch_taken(
        decoded_instr_name_comb,
        DEX_rs1_value,
        DEX_rs2_value,
        forwarded_exstage_data,
        forwarded_memstage_data,
        forwarded_wbstage_data,
        branch_forward_ex_rs1,
        branch_forward_ex_rs2,
        branch_forward_mem_rs1,
        branch_forward_mem_rs2,
        branch_forward_wb_rs1,
        branch_forward_wb_rs2,
        rs1_value_used,
        rs2_value_used
    ); 
    */
end

// Sequential Update of DEX Register
always_ff @(posedge clk) begin
    if (!reset && !stall_flag && !branch_taken) begin
        DEX.decoded_instr_name <= decoded_instr_name_comb;
        DEX.rs1 <= rs1_comb;
        DEX.rs2 <= rs2_comb;
        DEX.rd <= rd_comb;
        DEX.opcode <= opcode_comb;
        DEX.funct3 <= funct3_comb;
        DEX.funct7 <= funct7_comb;
        DEX.imm32 <= imm32_comb;
        DEX.imms <= imms_comb;
        DEX.immu <= immu_comb;
        DEX.immb <= immb_comb;
        DEX.immj <= immj_comb;
        DEX.wbv <= wbv_comb;
        DEX.pc <= pc_comb;
        DEX.instruction <= instruction_comb;
        DEX.valid <= valid_comb;
        DEX.is_load <= is_load_comb;
        DEX.is_branch <= is_branch_comb;
        //$display("Branch Forwarding Flags: %6b", {branch_forward_wb_rs2, branch_forward_wb_rs1, branch_forward_mem_rs2, branch_forward_mem_rs1, branch_forward_ex_rs2, branch_forward_ex_rs1});
        //$display("Forwarded EX Data %8h, Forwarded MEM Data %8h, Forwarded WB Data %8h", forwarded_exstage_data, forwarded_memstage_data, forwarded_wbstage_data);
        //$display("DEX_rs1_value %8h, DEX_rs2_value %8h", DEX_rs1_value, DEX_rs2_value);
        //$display("RS1_value_used %8h, RS2_value_used %8h", rs1_value_used, rs2_value_used);
        if(branch_taken) $display("Branch was taken");
    end else begin
        $display("Branch or stall flag caused DEX to get filled with no op");
        $display("Reset, Stall, Branch Taken: %3b", {reset, stall_flag, branch_taken});
        DEX <= 0;
    end
end
endmodule

function logic is_branch_taken(
    input instruction_name instr_name,
    input word rs1_val,
    input word rs2_val,
    input logic is_branch
);
    //$display("InstrName %d, rs1_val %8h, rs2_val %8h, is_branch %b", instr_name, rs1_val, rs2_val, is_branch);
    case (instr_name)
        BEQ:  return (rs1_val == rs2_val);
        BNE:  return (rs1_val != rs2_val);
        BLT:  return ($signed(rs1_val) < $signed(rs2_val));
        BGE:  return ($signed(rs1_val) >= $signed(rs2_val));
        BLTU: return (rs1_val < rs2_val);
        BGEU: return (rs1_val >= rs2_val);
        JAL:  return 1;
        JALR: return 1;
        default: return 0;
    endcase

endfunction
/*
function logic is_branch_taken(
    input instruction_name instr_name,
    input word rs1_val,
    input word rs2_val,
    input word forwarded_exstage_data,
    input word forwarded_memstage_data,
    input word forwarded_wbstage_data,
    input logic branch_forward_ex_rs1,
    input logic branch_forward_ex_rs2,
    input logic branch_forward_mem_rs1,
    input logic branch_forward_mem_rs2,
    input logic branch_forward_wb_rs1,
    input logic branch_forward_wb_rs2,
    output word rs1_value_used,
    output word rs2_value_used
);

    word rs1_val_comb, rs2_val_comb;
    rs1_val_comb = rs1_val;
    rs2_val_comb = rs2_val;
    if(branch_forward_wb_rs1) rs1_val_comb = forwarded_wbstage_data;
    if(branch_forward_wb_rs2) rs2_val_comb = forwarded_wbstage_data;
    if(branch_forward_mem_rs1) rs1_val_comb = forwarded_memstage_data;
    if(branch_forward_mem_rs2) rs2_val_comb = forwarded_memstage_data;
    if(branch_forward_ex_rs1) rs1_val_comb = forwarded_exstage_data;
    if(branch_forward_ex_rs2) rs2_val_comb = forwarded_exstage_data;
    case (instr_name)
        BEQ:  return (rs1_val_comb == rs2_val_comb);
        BNE:  return (rs1_val_comb != rs2_val_comb);
        BLT:  return ($signed(rs1_val_comb) < $signed(rs2_val_comb));
        BGE:  return ($signed(rs1_val_comb) >= $signed(rs2_val_comb));
        BLTU: return (rs1_val_comb < rs2_val_comb);
        BGEU: return (rs1_val_comb >= rs2_val_comb);
        default: return 1'b0;
    endcase
    rs1_value_used = rs1_val_comb;
    rs2_value_used = rs2_val_comb;

endfunction
*/

