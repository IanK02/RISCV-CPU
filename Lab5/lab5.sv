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

// Pipeline Stage Registers (Instances of the structs)
fd_reg FD;
dex_reg DEX;
exmem_reg EXMEM;
memwb_reg MEMWB;

// Added DEX registers for rs1_value and rs2_value
word DEX_rs1_value, DEX_rs2_value;
word rs1_value_used; //the actual rs1 value that got used in the execute stage calculation

// Registers
word pc;
word write_data, clocked_write_data;
RegAddr rs1, rs2;
word alu_result;
ImmB decoded_immb;

// Hazard detection and forwarding signals
logic stall_flag; 
logic rs1_forward_dex, rs1_forward_exmem;
logic rs2_forward_dex, rs2_forward_exmem;
logic rs1_forward_exmem_load, rs2_forward_exmem_load;
logic rs1_forward_dex_load, rs2_forward_dex_load;
logic rs1_forward_dwb, rs2_forward_dwb;
Forwarding_Flags forwarding_flags;
logic branch_forward_ex_rs1, branch_forward_ex_rs2;
logic branch_forward_mem_rs1, branch_forward_mem_rs2;
logic branch_forward_wb_rs1, branch_forward_wb_rs2;
logic branch_taken;
logic jal_taken;
logic jalr_taken;
logic branch_stall_flag;

//Register File Read/Write
logic [`word_size-1:0] register_file [31:0];
logic read_reg_valid;
logic write_reg_valid;
RegAddr previous_rd_written;


//Other Vars
instr32 fetched_instruction;
instr32 latched_instruction_read;
basemask base_mask;

//Register File Read/Write + Forwarding
always_ff @(posedge clk) begin //this clocked read works because rs1 and rs2 get valid values right at the start of the decode stage, and read_reg_valid goes hot at the same time
    if (read_reg_valid) begin //used to be  if (read_reg_valid && (!stall_flag) && DEX.valid)
        DEX_rs1_value <= register_file[rs1];
        DEX_rs2_value <= register_file[rs2];
        $display("Reading from registers %d and %d", rs1, rs2);
    end
    //if(rs1_forward_dwb) begin
    //    DEX_rs1_value <= write_data;
    //    $display("Forwarding %8h to DEX_rs1_value", write_data);
    //end
    //if(rs2_forward_dwb) begin
    //    DEX_rs2_value <= write_data;
    //    $display("Forwarding %8h to DEX_rs2_value", write_data);
    //end
    $display("Forwarding Flags: %6b", forwarding_flags); 
    previous_rd_written <= MEMWB.rd;
    if (write_reg_valid) begin//Check MEMWB.valid    else if(write_reg_valid && MEMWB.rd != 0 && MEMWB.wbv && MEMWB.valid)
        register_file[MEMWB.rd] <= write_data;
        $display("Writing %8h to Register #%d", write_data, MEMWB.rd);
    end else begin
        $display("write_reg_valid is false");
    end
end
always_comb begin //Forwarding and Stalling Logic
    rs1_forward_dex = (EXMEM.rd == DEX.rs1 && (EXMEM.rd != 0) && EXMEM.wbv);
    rs2_forward_dex = (EXMEM.rd == DEX.rs2 && (EXMEM.rd != 0) && EXMEM.wbv);
    rs1_forward_exmem = (MEMWB.wbv && (MEMWB.rd != 0) && !(EXMEM.wbv && (EXMEM.rd != 0) && (EXMEM.rd == DEX.rs1)) && (MEMWB.rd == DEX.rs1));
    rs2_forward_exmem = (MEMWB.wbv && (MEMWB.rd != 0) && !(EXMEM.wbv && (EXMEM.rd != 0) && (EXMEM.rd == DEX.rs2)) && (MEMWB.rd == DEX.rs2));
    rs1_forward_dwb = ((DEX.rs1 == previous_rd_written) && (previous_rd_written != 0) && (DEX.rs1 != 0));
    rs2_forward_dwb = ((DEX.rs2 == previous_rd_written) && (previous_rd_written != 0) && (DEX.rs2 != 0));
    forwarding_flags = {rs2_forward_dwb, rs1_forward_dwb, rs2_forward_exmem, rs1_forward_exmem, rs2_forward_dex, rs1_forward_dex};

    //rs1_forward_dwb = (MEMWB.wbv && (MEMWB.rd == rs1) && (MEMWB.rd != 0));
    //rs2_forward_dwb = (MEMWB.wbv && (MEMWB.rd == rs2) && (MEMWB.rd != 0));
    stall_flag = ((DEX.is_load && ((DEX.rd == rs1) || (DEX.rd == rs2))));
    //branch_stall_flag = branch_forward_ex_rs1 || branch_forward_ex_rs2 || branch_forward_mem_rs1 || branch_forward_mem_rs2;

    // Forwarding logic for rs1
    /*
    if (rs1_forward_dex && EXMEM.valid) begin //these flags don't go hot until the end of the execution stage, that's why we can't use a blocking assignment
        DEX_rs1_value = alu_result;
        $display("Forwarding %8h to rs1_value", alu_result);
    end else if (rs1_forward_exmem && MEMWB.valid) begin //Check MEMWB.valid
        DEX_rs1_value = EXMEM.alu_result;
        $display("Forwarding %8h to rs1_value", EXMEM.alu_result);
    end

    // Forwarding logic for rs2
    if (rs2_forward_dex && EXMEM.valid) begin //Check EXMEM.valid
        DEX_rs2_value = alu_result;
        $display("Forwarding %8h to rs2_value", alu_result);
    end else if (rs2_forward_exmem && MEMWB.valid) begin //Check MEMWB.valid
        DEX_rs2_value = EXMEM.alu_result;
        $display("Forwarding %8h to rs2_value", EXMEM.alu_result);
    end
    */
    $display("-----------------------------------------------------");
end


// Ensure x0 is always 0
always_ff @(posedge clk) begin
    register_file[0] <= 0;
end

//Latched instruction read just in case
always_ff @(posedge clk) begin
    if (inst_mem_rsp.valid) begin
        latched_instruction_read <= inst_mem_rsp.data;
    end
end
assign fetched_instruction = (inst_mem_rsp.valid) ? inst_mem_rsp.data : latched_instruction_read;
//assign fetched_instruction = inst_mem_rsp.data; 

// Memory response reading
word load_result;
always_ff @(posedge clk) begin
    if (data_mem_rsp.valid)
        load_result <= data_mem_rsp.data;
end

// DEBUG //printing
always_ff @(posedge clk) begin
    $write("FETCH STAGE ");
    print_instruction(pc, fetched_instruction);
    $write("DECODE STAGE: ");
    print_instruction(pc-4, FD.instruction);   
    $write("EXECUTE STAGE: ");
    print_instruction(pc - 8, DEX.instruction);
    $display("Register Values 1-10: %d,%d,%d,%d,%d,%d,%d,%d,%d,%d", register_file[1],$signed(register_file[2]),$signed(register_file[3]),register_file[4],
    register_file[5],register_file[6],register_file[7],register_file[8],register_file[9],register_file[10]);
    $write("MEMORY STAGE: ");
    print_instruction(pc-12, EXMEM.instruction);
    $write("WRITEBACK STAGE: ");
    print_instruction(pc-16, MEMWB.instruction);
    $display("Instruction memory request address %8h", inst_mem_req.addr);
end

// FETCH stage
always_comb begin
    
    if(branch_taken)begin
        if(jal_taken)begin
            inst_mem_req.addr = DEX.pc + $signed(DEX.immj) - `word_size_bytes;
        end else if(jalr_taken)begin
            inst_mem_req.addr = rs1_value_used + $signed(DEX.imm32) - `word_size_bytes;
        end else begin
            inst_mem_req.addr = DEX.pc + $signed(decoded_immb) - `word_size_bytes;
        end
    end else begin
        inst_mem_req.addr = pc;
    end
    
    //assign inst_mem_req.addr = pc;
    assign inst_mem_req.valid = inst_mem_rsp.ready && (!stall_flag); //&& (!stall_flag); Use FD.valid and remove current_stage dependancy
    assign inst_mem_req.do_read = 4'b1111; //Always read 4 bytes
end

// FETCH stage
always_ff @(posedge clk) begin
    if (branch_taken) begin//used to be  if (!reset && (!stall_flag))
        /*
        if(decoded_immb > ( `word_size_bytes)) begin
            FD <= 0;
            //DEX <= 0; /DEX GETS UPDATED TO 0 IN DECODE STAGE
            $display("Setting FD to no op as result of branch");
        end else begin
            FD.instruction <= fetched_instruction;
            FD.pc <= pc;
            FD.pc_plus_4 <= pc + 4;
            FD.valid <= inst_mem_rsp.valid;
        end
        */
        FD <= 0;
        $display("Setting FD to no op as result of branch");
    end else if(!reset && (!stall_flag)) begin //add nop if branch is taken and instr needs flushing
        print_instruction(pc, fetched_instruction);
        FD.instruction <= fetched_instruction;
        FD.pc <= pc;
        FD.pc_plus_4 <= pc + 4;
        FD.valid <= inst_mem_rsp.valid; 
    end else begin
        $display("STALLING");
    end
end

// DECODE stage
decode_stage u_decode_stage (
    .clk(clk),
    .reset(reset),
    .FD(FD),
    .EXMEM(EXMEM),
    .MEMWB(MEMWB),
    .DEX(DEX),
    .read_reg_valid(read_reg_valid),
    .rs1(rs1),
    .rs2(rs2),
    .branch_forward_ex_rs1(branch_forward_ex_rs1),
    .branch_forward_ex_rs2(branch_forward_ex_rs2),
    .branch_forward_mem_rs1(branch_forward_mem_rs1),
    .branch_forward_mem_rs2(branch_forward_mem_rs2),
    .branch_forward_wb_rs1(branch_forward_wb_rs1),
    .branch_forward_wb_rs2(branch_forward_wb_rs2),
    .DEX_rs1_value(DEX_rs1_value),
    .DEX_rs2_value(DEX_rs2_value),
    .forwarded_exstage_data(alu_result),
    .forwarded_memstage_data(EXMEM.alu_result),
    .forwarded_wbstage_data(write_data),
    .stall_flag(stall_flag),
    .branch_taken(branch_taken)
);

// EXECUTE stage
execute_stage u_execute_stage (
    .clk(clk),
    .reset(reset),
    .DEX(DEX),
    .DEX_rs1_value(DEX_rs1_value),
    .DEX_rs2_value(DEX_rs2_value),
    .EXMEM(EXMEM),
    .alu_result(alu_result),
    .rs1_value_used(rs1_value_used),
    .stall_flag(stall_flag),
    .branch_taken(branch_taken),
    .forwarding_flags(forwarding_flags),
    .forwarded_memstage_data(EXMEM.alu_result),
    .forwarded_wbstage_data(write_data),
    .forwarded_last_written_data(clocked_write_data),
    .decoded_immb(decoded_immb),
    .jal_taken(jal_taken),
    .jalr_taken(jalr_taken)
);

// MEMORY stage
RegAddr MEMWB_next_rd;
logic MEMWB_next_wbv;
instruction_name MEMWB_next_decoded_instr_name;
logic MEMWB_next_valid;
word MEMWB_next_instruction;
word MEMWB_next_alu_result;
Funct3 MEMWB_next_funct3;
// Combinatorial Portion
always_comb begin
    // Default memory request is inactive
    if (EXMEM.valid) begin
        case (EXMEM.decoded_instr_name)
            LB, LH, LW, LBU, LHU: begin
                data_mem_req.addr    = EXMEM.alu_result;
                data_mem_req.valid   = 1'b1;
                data_mem_req.do_write = 4'b0000;
                data_mem_req.do_read = shuffle_store_mask(memory_mask(cast_to_memory_op(EXMEM.funct3)), EXMEM.alu_result);
            end
            SB, SH, SW: begin
                data_mem_req.addr    = EXMEM.alu_result;
                data_mem_req.valid   = 1'b1;
                data_mem_req.do_read = 4'b0000;
                data_mem_req.do_write = shuffle_store_mask(memory_mask(cast_to_memory_op(EXMEM.funct3)), EXMEM.alu_result);
                data_mem_req.data = shuffle_store_data(EXMEM.store_data, EXMEM.alu_result);
            end
            default: begin
                // No memory access
                
            end
        endcase
    end

    // Prepare next values for MEMWB
    MEMWB_next_rd = EXMEM.rd;
    MEMWB_next_wbv = EXMEM.wbv;
    MEMWB_next_decoded_instr_name = EXMEM.decoded_instr_name;
    MEMWB_next_valid = EXMEM.valid;
    MEMWB_next_instruction = EXMEM.instruction;
    MEMWB_next_alu_result = EXMEM.alu_result;
    MEMWB_next_funct3 = EXMEM.funct3;

end

// Clocked Portion
always_ff @(posedge clk) begin
    // Update registers
    MEMWB.rd <= MEMWB_next_rd;
    MEMWB.wbv <= MEMWB_next_wbv;
    MEMWB.decoded_instr_name <= MEMWB_next_decoded_instr_name;
    MEMWB.valid <= MEMWB_next_valid;
    MEMWB.instruction <= MEMWB_next_instruction;
    MEMWB.alu_result <= MEMWB_next_alu_result;
    MEMWB.funct3 <= MEMWB_next_funct3;
    MEMWB.is_branch <= EXMEM.is_branch;
    MEMWB.pc <= EXMEM.pc;
end


// WRITEBACK stage 
always_comb begin
    write_reg_valid = MEMWB.wbv;
    if (MEMWB.valid) begin
        case (MEMWB.decoded_instr_name)
            // Arithmetic instructions: just write the ALU result.
            ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU,
            ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU, LUI: begin
                write_data = MEMWB.alu_result;
                //$write("Writeback tasks for: ");
                ////print_instruction(pc-16, MEMWB.instruction);
                //$display("Writing 0x%08h to register[%b]", EXMEM.alu_result, MEMWB.rd);
            end
            // Load instructions: first “unshuffle” the memory data then extract (and extend) the sub–word.
            LB, LH, LW, LBU, LHU: begin
                // Use the shuffling function with the effective address.
                write_data = subset_load_data(
                    shuffle_load_data(data_mem_rsp.valid ? data_mem_rsp.data : load_result, MEMWB.alu_result & 32'h3),
                    cast_to_memory_op(MEMWB.funct3)); //how the fuck am i getting away with using DEX.funct3? - im not
                //$write("Writeback tasks for: ");
                ////print_instruction(pc-16, MEMWB.instruction);
                //$display("Loading 0x%08h to register[%b]", MEMWB.write_data, MEMWB.rd);
            end
            // JAL and JALR: write pc+4 as the return address.
            JAL, JALR: begin
                write_data = MEMWB.alu_result;
                //$write("WRITEBACK STAGE: ");
                ////print_instruction(pc-16, MEMWB.instruction);
                //$display("JAL/JALR: Writing 0x%08h to register[%b]", MEMWB.write_data, MEMWB.rd);
            end
            default: begin
                $write("WRITEBACK STAGE: ");
                //print_instruction(pc-16, MEMWB.instruction);
                $display("No writeback occuring");
            end
        endcase
    end
end

//Writeback clocked stage
always_ff @(posedge clk) begin
    clocked_write_data <= write_data;
end

// PC Update (with simple branch prediction: assume not taken)
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= reset_pc; // Reset the PC to a known value
        //FD.valid <= 1'b1; //Indicate FD has valid data after reset
    end else begin
        if ((!stall_flag)) begin
            //FD.valid <= 1'b1;

            //Branch/Jump Logic. 
            if(branch_taken) begin
                //pc <= pc + $signed(decoded_immb) - 8;
                if(jal_taken) begin
                    pc <= DEX.pc + $signed(DEX.immj);
                end else if (jalr_taken) begin
                    pc <= rs1_value_used + $signed(DEX.imm32);
                end else begin
                    pc <= DEX.pc + $signed(decoded_immb);
                end
                $display("Jumping to new pc as result of branch/jump");
            end else begin
                pc <= pc + 4; //Default PC increment
            end
        end else begin
            //FD.valid <= 1'b0; //Stall the Fetch stage
        end
    end
end

endmodule

`endif
