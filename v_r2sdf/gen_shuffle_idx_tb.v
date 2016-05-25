`timescale 1ns/100ps
`define CLK 20
`define CLKH (`CLK/2)

module gen_shuffle_idx_tb();
  parameter N=4;
  reg clk;
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
  initial begin
    $display("--- gen shuffle idx ---");
    $dumpfile("gen_shuffle_idx.dump");
    $dumpvars();
    clk = 0;
    #(`CLK) $finish;
  end
  
  always #(`CLKH) clk=~clk;
  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx(shuffle_idx));
 
endmodule
