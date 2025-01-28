module register_file(
    input logic clk,
    input logic write_enable,
    input logic [4:0] rs1, rs2, rd,
    input logic [63:0] write_data,
    output logic [63:0] read_data1, read_data2
);

    logic [63:0] registers [31:0];

    // Read operations (combinational)
    assign read_data1 = registers[rs1];
    assign read_data2 = registers[rs2];

    // Write operation (sequential)
    always_ff @(posedge clk) begin
        if (write_enable && rd != 0) // x0 is hardwired to 0
            registers[rd] <= write_data;
    end

endmodule