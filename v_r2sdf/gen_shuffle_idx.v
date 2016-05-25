`timescale 1ns/100ps
module gen_shuffle_idx (shuffle_idx);
  parameter  N=3;	// number of inputs to FFT: 2^N
  output reg [N-1:0] shuffle_idx[(1<<N)-1:0];

  function [N-1:0] rev_bit(reg [N:0] orig);
    integer i;
    for (i=0; i<N; i=i+1) 
    begin
      rev_bit[i] = orig[N-1-i];
    end
  endfunction
    
  initial begin
    reg [N:0] i;  // NOTE: must be [N:0], not [N-1:0],
                  // otherwise below will be infinite loop.
    for (i=0; i<(1<<N); i=i+1) 
    begin
      shuffle_idx[i] = rev_bit(i);
    end

  end
 
endmodule
