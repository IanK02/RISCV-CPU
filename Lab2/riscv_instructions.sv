`ifndef _riscv_instructions_sv
`define _riscv_instructions_sv
`include "lab1.sv"

/*
// Define types for each instruction field
typedef logic [6:0] Opcode;
typedef logic [4:0] RegAddr;
typedef logic [2:0] Funct3;
typedef logic [6:0] Funct7;
typedef logic [11:0] Imm12;
typedef logic [11:0] ImmS;
typedef logic [12:0] ImmB;
typedef logic [19:0] ImmU;
typedef logic [20:0] ImmJ;

// Helper functions to extract fields
function automatic Opcode getOpcode(input logic [31:0] instruction);
    return instruction[6:0];
endfunction

function automatic RegAddr getRd(input logic [31:0] instruction);
    return instruction[11:7];
endfunction

function automatic Funct3 getFunct3(input logic [31:0] instruction);
    return instruction[14:12];
endfunction

function automatic RegAddr getRs1(input logic [31:0] instruction);
    return instruction[19:15];
endfunction

function automatic RegAddr getRs2(input logic [31:0] instruction);
    return instruction[24:20];
endfunction

function automatic Funct7 getFunct7(input logic [31:0] instruction);
    return instruction[31:25];
endfunction

function automatic signed [11:0] getImm12(input logic [31:0] instruction);
    return $signed(instruction[31:20]);
endfunction

function automatic signed [11:0] getImmS(input logic [31:0] instruction);
    return $signed({instruction[31:25], instruction[11:7]});
endfunction

function automatic signed [12:0] getImmB(input logic [31:0] instruction);
    return $signed({instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0});
endfunction

function automatic signed [19:0] getImmU(input logic [31:0] instruction);
    return $signed(instruction[31:12]);
endfunction

function automatic signed [20:0] getImmJ(input logic [31:0] instruction);
    return $signed({instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0});
endfunction
*/

typedef enum logic [5:0] {
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
    LBU,
    LHU,
    JALR,
    NOP,
    UNKNOWN
} instruction;

function automatic instruction decode_instruction(logic [31:0] instr);
    Opcode opcode = getOpcode(instr);
    RegAddr rd = getRd(instr);
    Funct3 funct3 = getFunct3(instr);
    RegAddr rs1 = getRs1(instr);
    RegAddr rs2 = getRs2(instr);
    Funct7 funct7 = getFunct7(instr);
    Imm12 imm12 = getImm12(instr);

    case (opcode)
        7'b0110011: begin // R-type instructions
            case (funct3)
                3'b000: return (funct7 == 7'b0000000) ? ADD : 
                        (funct7 == 7'b0100000) ? SUB : UNKNOWN;
                3'b111: return AND;
                3'b110: return OR;
                3'b100: return XOR;
                3'b001: return SLL;
                3'b101: return (funct7 == 7'b0000000) ? SRL : 
                        (funct7 == 7'b0100000) ? SRA : UNKNOWN;
                3'b010: return SLT;
                3'b011: return SLTU;
                default: return UNKNOWN;
            endcase
        end
        7'b0010011: begin // I-type ALU instructions
            case (funct3)
                3'b000: return ADDI;
                3'b111: return ANDI;
                3'b110: return ORI;
                3'b100: return XORI;
                3'b001: return SLLI;
                3'b101: return (imm12[11:5] == 7'b0000000) ? SRLI :
                        (imm12[11:5] == 7'b0100000) ? SRAI : UNKNOWN;
                3'b010: return SLTI;
                3'b011: return SLTIU;
                default: return UNKNOWN;
            endcase
        end
        7'b0000011: begin // I-type load instructions
            case (funct3)
                3'b000: return LB;
                3'b001: return LH;
                3'b010: return LW;
                3'b100: return LBU;
                3'b101: return LHU;
                default: return UNKNOWN;
            endcase
        end
        7'b1100111: begin // JALR instruction
            if (funct3 == 3'b000) return JALR;
            else return UNKNOWN;
        end
        default: return UNKNOWN;
    endcase
endfunction

`endif
