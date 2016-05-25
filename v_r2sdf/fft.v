// generate block: 
// http://stackoverflow.com/questions/33899691/instantiate-modules-in-generate-for-loop-in-verilog
`timescale 1ns/100ps
typedef real t_trig_arr[$]
module fft (clk, ip, op_real_arr, op_img_arr);
  parameter N=3;
  input clk;
  //input [32:0] ip;
  // TODO: convert data type
  input real ip;
  // TODO: shuffle the op arr
  output real op_real_arr[(1<<N)-1:0];
  output real op_img_arr[(1<<N)-1:0];
  // TODO: should be what type??
  real sig_real[N:0];
  real sig_img[N:0];
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
`include "trigonometric_table.v"
  // NOTE: reg / output reg: when is it updated?
  //      should be indicated by the "always" block!!
  //      Should use wire to connect modules, cuz bf module output is already
  //      regged. 
  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx);
  generate
    genvar n;
    for (n=1; n<=N; n++) begin : bf_stage_instance
      real cos_arr[1<<(n-1)] = cos_arr_n(n);
      real sin_arr[1<<(n-1)] = sin_arr_n(n);
      bf_stage #(.N(N),.n(n)) (.clk,.shuffle_idx,.cos_arr,.sin_arr,
            .ip_real(sig_real[n-1]),.ip_img(sig_img[n-1]),
            .op_real(sig_real[n]),.op_img(sig_img[n]));
    end
  endgenerate

  initial begin
    sig_real[0] = ip;
    sig_img[0] = 0.;
    op_real = sig_real[N];
    op_img = sig_img[N];
  end
  // -----------------------------
  // -----------------------------
  function t_trig_arr trig_arr_n(real n);
    // prepare smaller array for the intermediate stage
    integer exp = 0;
    begin
      for (exp=0; exp<(1<<(n-1)); exp=exp+1)
        cos_arr_n[exp] = cos[(1<<(MAX_N-n+1))*exp];
    end
  endfunction
  function t_trig_arr sin_arr_n(real n);
    integer exp = 0;
    begin
      for (exp=0; exp<(1<<(n-1)); exp=exp+1)
        sin_arr_n[exp] = sin[(1<<(MAX_N-n+1))*exp];
    end
  endfunction
  // TODO:
  // final shuffle output
  // -----------------------------
  // -----------------------------
  //always @(posedge clk)
  //begin

  //end

endmodule
