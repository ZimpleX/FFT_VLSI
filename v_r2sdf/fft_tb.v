`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
module fft_tb ();
  parameter N = 4;
  reg clk;
  real ip_arr[(1<<N)-1:0];
  real ip;
  real op_real_arr[(1<<N)-1:0];
  real op_img_arr[(1<<N)-1:0];
  integer idx;

  fft #(.N(N)) fft_instance(.clk,.ip,.op_real_arr,.op_img_arr);

  initial begin
`include "ip_arr.v"
    clk = 1;
    idx = 0;
    #(`CLK*2) $finish;
  end

  always @(posedge clk) begin
    ip = ip_arr[idx];
    idx = idx + 1;
  end

  always #(`CLKH) clk =~ clk;
end
