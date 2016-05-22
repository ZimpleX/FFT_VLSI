`timescale 1ns/100ps
module gen_shuffle_idx (clk,shuffle_idx);
  parameter  N=3;	// number of inputs to FFT: 2^N
  input clk;
  output reg [N-1:0] shuffle_idx[2**N-1:0];

  function [N-1:0] rev_bit;
    input [N-1:0] orig;
    reg [N:0] i;
    for (i=0; i<N; i=i+1) 
    begin
      rev_bit[i] = orig[N-1-i];
    end
  endfunction
    
  initial begin
    reg [N:0] i;
    for (i=0; i<2**N; i=i+1) 
    begin
      shuffle_idx[i] = rev_bit(i);
    end

  end
 
endmodule
