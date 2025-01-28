`include "top.sv"

// Top file used for iverilog.  Note this is mostly a stub that includes the 
// top which Verilator uses.

`timescale 1ns / 1ps

module itop();

logic clk = 0;
logic reset = 1;
logic halt;

top the_top(
    .clk(clk)
    ,.reset(reset)
    ,.halt(halt));

always #5 clk = ~clk;

initial begin
// Uncomment these two lines to create "waveform.vcd"
//    $dumpfile("waveform.vcd");
//    $dumpvars(0);
    reset = 1;
    #20 reset = 0;
end

always #15 if (halt == 1'b1) $finish;
 
endmodule
