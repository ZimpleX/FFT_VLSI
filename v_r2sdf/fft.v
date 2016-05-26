// generate block: 
// http://stackoverflow.com/questions/33899691/instantiate-modules-in-generate-for-loop-in-verilog
`timescale 1ns/100ps
module fft (clk, start_ip, ip, op_raw, op_shuffled);
  parameter N=3;
  input clk;
  // TODO: convert data type
  input real ip;
  input start_ip;
  real op_arr[(1<<N)-1:0][1:0];
  real op_arr_bk[(1<<N)-1:0][1:0];
  // TODO: should be what type??
  real sig[N:0][1:0];
  reg [N:0] start_sig;
  output real op_raw[1:0];
  output real op_shuffled[1:0];
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
  integer countdown;
`include "trigonometric_table.v"
  // NOTE: reg / output reg: when is it updated?
  //      should be indicated by the "always" block!!
  //      Should use wire to connect modules, cuz bf module output is already
  //      regged. 
  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx);
  generate
    genvar n;
    for (n=1; n<=N; n++) begin : bf_stage_instance
      real cos_arr[1<<(N-1)] = cos_arr_n(n);
      real sin_arr[1<<(N-1)] = sin_arr_n(n);
      bf_stage #(.N(N),.n(n)) (.clk,.shuffle_idx,.cos_arr,.sin_arr,
              .ip(sig[n-1]),.op(sig[n]),.start_ip(start_sig[n-1]),.start_op(start_sig[n]));
    end
  endgenerate

  initial begin
    countdown = -1;
    sig[0][1] = ip;
    sig[0][0] = 0.0;
  end
  // -----------------------------
  // -----------------------------
  typedef real t_trig_arr[1<<(N-1)];
  function t_trig_arr cos_arr_n(integer n);
    // prepare smaller array for the intermediate stage
    integer exp = 0;
    begin
      for (exp=0; exp<(1<<(n-1)); exp=exp+1)
        cos_arr_n[exp] = cos[(1<<(MAX_N-n+1))*exp];
    end
  endfunction
  function t_trig_arr sin_arr_n(integer n);
    integer exp = 0;
    begin
      for (exp=0; exp<(1<<(n-1)); exp=exp+1)
        sin_arr_n[exp] = -sin[(1<<(MAX_N-n+1))*exp];
    end
  endfunction
  // TODO:
  // final shuffle output
  // -----------------------------
  // -----------------------------
  always @(posedge clk)
  begin
    start_sig[0] = start_ip;
    sig[0][1] = ip;
    if (countdown == 0)
    begin
      countdown = (1<<N);
      op_arr_bk = op_arr;
    end
    if (start_sig[N] == 1)
      countdown = (1<<N);
    if (countdown > 0)
    begin
      op_raw = sig[N];
      op_shuffled = op_arr_bk[(1<<N)-countdown];
      op_arr[shuffle_idx[(1<<N)-countdown]] = op_raw;
      countdown = countdown - 1;
    end
  end

endmodule
