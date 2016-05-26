`include "data_type.vh"
`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
module fft_tb ();
  parameter N = 4;
  reg clk;
  fpt ip_arr[3*(1<<N)-1:0];
  fpt ip;
  reg start_ip;
  fpt op_raw[1:0];
  fpt op_shuffled[1:0];
  integer idx;

  fft #(.N(N)) fft_instance(.clk,.start_ip,.ip,.op_raw,.op_shuffled);

  initial begin
`include "ip_arr.v"
    clk = 1;
    idx = 0;
    start_ip = 1;
    #(`CLK) start_ip = 0;
    #(`CLK*(1<<N)*15) $finish;
  end

  always @(posedge clk) begin
    ip = ip_arr[idx];
    idx = idx + 1;
  end

  always #(`CLKH) clk =~ clk;
endmodule
