module top(
	input logic clk
	,output logic [31:0] result);

	logic [2:0] op[0:15];
	logic [32:0] input1[0:15];

	alu test_alu(.op(op_read), .input1(input1_read), .input2(input2_read));

endmodule
