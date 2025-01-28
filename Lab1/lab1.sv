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

// Function to decode and print a human-readable string for a given RV32I instruction
function automatic void print_instruction(logic [31:0] pc, logic [31:0] instruction);
    //$display("%x   ", instruction);
    // Extract the fields from the instruction using helper functions
    Opcode opcode = getOpcode(instruction);
    RegAddr rd = getRd(instruction);
    Funct3 funct3 = getFunct3(instruction);
    RegAddr rs1 = getRs1(instruction);
    RegAddr rs2 = getRs2(instruction);
    Funct7 funct7 = getFunct7(instruction);
    Imm12 imm12 = getImm12(instruction);
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
                3'b000: outputStr = $sformatf("addi x%0d, x%0d, %0d", rd, rs1, $signed(imm12));
                3'b001: outputStr = $sformatf("slli x%0d, x%0d, %0d", rd, rs1, $signed(imm12[4:0]));
                3'b010: outputStr = $sformatf("slti x%0d, x%0d, %0d", rd, rs1, $signed(imm12));
                3'b011: outputStr = $sformatf("sltiu x%0d, x%0d, %0d", rd, rs1, $signed(imm12));
                3'b100: outputStr = $sformatf("xori x%0d, x%0d, %0d", rd, rs1, $signed(imm12));
                3'b101: outputStr = (funct7 == 7'b0100000) ?
                                    $sformatf("srai x%0d, x%0d, %0d", rd, rs1, $signed(imm12[4:0])) :
                                    $sformatf("srli x%0d, x%0d, %0d", rd, rs1, $signed(imm12[4:0]));
                3'b110: outputStr = $sformatf("ori x%0d, x%0d, %0d", rd, rs1, $signed(imm12)); 
                3'b111: outputStr = $sformatf("andi x%0d, x%0d, %0d", rd, rs1, $signed(imm12));
                default: outputStr = "Unknown I-type instruction";
            endcase
        end
        7'b0000011: begin // Load instructions
            case (funct3)
                3'b000: outputStr = $sformatf("lb x%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
                3'b001: outputStr = $sformatf("lh x%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
                3'b010: outputStr = $sformatf("lw x%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
                3'b100: outputStr = $sformatf("lbu x%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
                3'b101: outputStr = $sformatf("lhu x%0d, %0d(x%0d)", rd, $signed(imm12), rs1);
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
        7'b0110111: outputStr = $sformatf("lui x%0d, %0d", rd, $signed(immU)); // U-type LUI
        7'b0010111: outputStr = $sformatf("auipc x%0d, %0d", rd, $signed(immU)); // U-type AUIPC
        7'b1101111: outputStr = $sformatf("jal x%0d, %0d", rd, $signed(immJ)); // J-type JAL
        7'b1100111: outputStr = $sformatf("jalr x%0d, x%0d, %0d", rd, rs1, $signed(imm12)); // I-type JALR
        7'b1110011: begin // System instructions
            case (funct3)
                3'b000: begin
                    if (imm12 == 12'b000000000000)
                        outputStr = "ecall";
                    else if (imm12 == 12'b000000000001)
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
