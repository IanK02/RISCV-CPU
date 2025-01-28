`include "lab1.sv"

module top(input clk, input reset, output logic halt);

logic [31:0] code[0:4095];

initial $readmemh("code.hex", code, 0);

logic [31:0] pc;
logic [31:0] offset;
logic [31:0] stop_at;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h0;
        offset <=  32'h00010000;	// import, keys to the loader layout
        stop_at <= 32'h00000100;	// arbitrary 
        halt <= 1'b0;
    end else begin
        if (pc >= stop_at)
            halt <= 1'b1;
        else
            halt <= 1'b0;
        print_instruction((pc*4) + offset, code[pc]);
        pc <= pc + 1;
    end
end

endmodule
