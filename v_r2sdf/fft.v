`include "sys_macro.vh"
`ifdef DTYPE_FIXED_POINT
  `include "trigonometric_table_real.v"
`else
  `include "trigonometric_table_fpt.v"
`endif
module fft (clk, start_ip, ip, op_raw, op_shuffled, op_ready,
          _db_neg_sum_n, _db_trig_n, _db_neg_sum_n);
  parameter N=3;
  input clk;
  // TODO: convert data type
  input fpt ip;
  input start_ip;
  fpt op_arr[(1<<N)-1:0][1:0];
  fpt op_arr_bk[(1<<N)-1:0][1:0];
  fpt sig[N:0][1:0];
  reg [N:0] start_sig;
  output reg op_ready;
  output fpt op_raw[1:0];
  output fpt op_shuffled[1:0];
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
  integer countdown;
  // DEBUG  ********************************
  output fpt _db_neg_product_n[N-1:0][2:0];
  output fpt _db_trig_n[N-1:0][1:0];
  output fpt _db_neg_sum_n[N-1:0];
  // ***************************************

  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx);
  generate
    genvar n;
    for (n=1; n<=N; n++) begin : bf_stage_instance
      fpt cos_arr[1<<(N-1)] = cos_arr_n(n);
      fpt sin_arr[1<<(N-1)] = sin_arr_n(n);
      bf_stage #(.N(N),.n(n)) (.clk,.shuffle_idx,.cos_arr,.sin_arr,
              .ip(sig[n-1]),.op(sig[n]),.start_ip(start_sig[n-1]),.start_op(start_sig[n]),
              ._db_neg_product(_db_neg_product_n[n]),
              ._db_trig(_db_trig_n[n]),
              ._db_neg_sum(_db_neg_sum_n[n]));
    end
  endgenerate

  initial begin
    op_ready = 0;
    countdown = -1;
    sig[0][1] = ip;
    sig[0][0] = 0.0;
  end
  // -----------------------------
  // -----------------------------
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
        sin_arr_n[exp] = sin[(1<<(MAX_N-n+1))*exp];
    end
  endfunction
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
      op_ready = 1;
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
