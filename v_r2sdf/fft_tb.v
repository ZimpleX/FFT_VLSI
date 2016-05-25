`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
module fft_tb ();
  parameter N = 4;
  reg clk;
  real ip_arr[(1<<N)-1:0];
  real ip;
  reg start_ip;
  real op_arr[(1<<N)-1:0][1:0];
  integer idx;

  fft #(.N(N)) fft_instance(.clk,.start_ip,.ip,.op_arr);

  initial begin
`include "ip_arr.v"
    clk = 1;
    idx = 0;
    start_ip = 1;
    #(`CLK) start_ip = 0;
    #(`CLK*(1<<N)*3) $finish;
  end

  always @(posedge clk) begin
    ip = ip_arr[idx];
    idx = idx + 1;
  end

  always #(`CLKH) clk =~ clk;
endmodule
