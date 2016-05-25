`timescale 1ns/100ps
`define CLK 20
`define CLKH (`CLK/2)

module bf_stage_tb();
  parameter N=3;
  parameter n=1;
  real ip_arr[(1<<N)-1:0];

  reg clk;
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
  real cos_arr[1<<(n-1)];
  real sin_arr[1<<(n-1)];
  real ip_real, ip_img;
  real op_real, op_img;
  integer idx;
  
  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx);
  bf_stage #(.N(N),.n(n)) bf_stage_instance(.clk,.shuffle_idx,
          .cos_arr,.sin_arr,.ip_real,.ip_img,.op_real,.op_img);
  
  initial begin
    integer i;
    begin
`include "ip_arr.v"
      idx = 0;
      clk = 1;
      i = 0;
      for (i=0; i<(1<<(n-1)); i=i+1)
      begin
        cos_arr[i] = 1.0;
        sin_arr[i] = 0.0;
      end
      #(`CLK*(1<<N)) $finish;
    end
  end

  always @(posedge clk) begin
    ip_real <= ip_arr[idx];
    ip_img <= 0.0;
    idx <= idx + 1;
  end
  always #(`CLKH) clk=~clk;
endmodule
