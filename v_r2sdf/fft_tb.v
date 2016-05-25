`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
module fft_tb ();
  parameter N = 4;
  reg clk;
  real ip_arr[(1<<N)-1:0] = '{0,10,2,3,
                              1,3,21,31,
                              0,4,3,7,
                              90,24,4,1};
  real ip;
  real op_real[(1<<N)-1:0];
  real op_img[(1<<N)-1:0];

  fft #(.N(N)) fft_instance(.clk,.ip,.);

  initial begin
    clk = 1;
  end

  always #(`CLKH) clk =~ clk;
end
