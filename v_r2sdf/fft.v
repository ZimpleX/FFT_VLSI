`include "sys_macro.vh"
`ifdef DTYPE_FIXED_POINT
  `include "trigonometric_table_fpt.v"
`else
  `include "trigonometric_table_real.v"
`endif
module fft (reset, clk, start_ip, ip, op_raw, op_shuffled, op_ready,
          _db_neg_product_n, _db_neg_sum_n, _db_trig_n);
  parameter N=3;
  input reset, clk;
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
  reg [N-1:0] shuffle_idx[(1<<N)-1:0];
  integer countdown;
  // DEBUG  ********************************
  output fpt _db_neg_product_n[N-1:0][2:0];
  output fpt _db_trig_n[N-1:0][1:0];
  output fpt _db_neg_sum_n[N-1:0];
  // ***************************************

  generate
    genvar n;
    for (n=1; n<=N; n++) begin : bf_stage_instance
      fpt cos_arr[1<<(N-1)] = cos_arr_n(n);
      fpt sin_arr[1<<(N-1)] = sin_arr_n(n);
      bf_stage #(.N(N),.n(n)) (.reset,.clk,.shuffle_idx,.cos_arr,.sin_arr,
              .ip(sig[n-1]),.op(sig[n]),.start_ip(start_sig[n-1]),.start_op(start_sig[n]),
              ._db_neg_product(_db_neg_product_n[n-1]),
              ._db_trig(_db_trig_n[n-1]),
              ._db_neg_sum(_db_neg_sum_n[n-1]));
    end
  endgenerate
  // -----------------------------
  // -----------------------------
  function automatic t_shuffle_idx gen_shuffle_idx();
    integer j;
    reg [N:0] i;  // i must be N+1 bits. Otherwise below will be finite loop.
    reg [N-1:0] rev_i;
    begin
      for (i=0; i<(1<<N); i=i+1) begin
        for (j=0; j<N; j=j+1) begin
          rev_i[j] = i[N-1-j];
        end
        gen_shuffle_idx[i] = rev_i;
      end
    end
  endfunction
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
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      countdown = -1;
      shuffle_idx = gen_shuffle_idx();
    end else begin
      start_sig[0] = start_ip;
      sig[0][1] = ip;
      sig[0][0] = 0;
      if (countdown == 0) begin
        countdown = (1<<N);
        op_arr_bk = op_arr;
        op_ready = 1;
      end else begin
        op_ready = 0;
      end
      if (start_sig[N] == 1)
        countdown = (1<<N);
      if (countdown > 0) begin
        op_raw = sig[N];
        op_shuffled = op_arr_bk[(1<<N)-countdown];
        op_arr[shuffle_idx[(1<<N)-countdown]] = op_raw;
        countdown = countdown - 1;
      end
    end
  end

endmodule
