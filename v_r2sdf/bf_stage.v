`include "sys_macro.vh"
module bf_stage (reset, clk, shuffle_idx, cos_arr, sin_arr, 
                  ip, op, start_ip, start_op);
  parameter N=3;  // number of inputs to FFT: 2^N
  parameter n=1;  // stage of the butterfly unit, start from 1.
  parameter delay = 1<<(N-n); // DON'T pass in this parameter!!

  input reset, clk;
  input [N-1:0] shuffle_idx[(1<<N)-1:0];
  reg [N-1:0] shuffle_idx_reg[(1<<N)-1:0];
  input fpt cos_arr[1<<(N-1)];
  input fpt sin_arr[1<<(N-1)];
  input fpt ip[1:0];
  fpt ip_reg[1:0];
  output fpt op[1:0];
  input start_ip;
  output reg start_op;

  reg timemux_clk;
  fpt twiddle_val[1:0];
  integer twiddle_idx;
  reg [N-n-1:0] timemux_clk_count;
  reg [N-n:0] period_count;
  fpt buf_real[delay-1:0];   // buffer to store the delayed value
  fpt buf_img[delay-1:0];
  
  integer stage_launch, output_countdown;
  // ----------------------------------
  // ----------------------------------
  function automatic fpt f_mul(fpt a, fpt b);
    fpt_mul temp;
    fpt_mul a_ext,b_ext;
    begin
      // sign extension first
      if (a[15] == 0)
        a_ext = {32'h0000_0000,a};
      else
        a_ext = {32'hffff_ffff,a};
      if (b[15] == 0)
        b_ext = {32'h0000_0000,b};
      else
        b_ext = {32'hffff_ffff,b};
      temp = a_ext*b_ext;
      f_mul = temp[47:16];
    end
  endfunction
  // ---------------------------------
  initial begin
    begin
      twiddle_idx = -1;
      period_count = 0;

      stage_launch = 0;
      output_countdown = -1;
    end
  end
  // ----------------------------------
  // ----------------------------------
  function automatic void ctrl_timemux (
                  ref reg [N-n-1:0] timemux_clk_count, 
                  ref reg [N-n:0] period_count,
                  ref reg timemux_clk,
                  ref integer twiddle_idx);
    // update timemux_clk signals
    // update twiddle_idx
    begin
      if (n == N)
        timemux_clk =~ timemux_clk;
      else
      begin
        if (timemux_clk_count == 0)
          timemux_clk =~ timemux_clk;
        else
          timemux_clk = timemux_clk;
      end
      if (period_count == 0)
        twiddle_idx = twiddle_idx + 1;
      else
        twiddle_idx = twiddle_idx;
      timemux_clk_count = timemux_clk_count + 1;
      period_count = period_count + 1;
    end
  endfunction
  // ---------------------------------
  function automatic cpx get_twiddle_val(
                  reg timemux_clk,
                  integer twiddle_idx,
                  const ref reg [N-1:0] shuffle_idx[(1<<N)-1:0]);
    // return twiddle value
    //  [1]:  real part
    //  [0]: imaginary part
    integer twiddle_exp;
    begin
      if (timemux_clk == 1)
      begin
`ifdef DTYPE_FIXED_POINT
        get_twiddle_val[1] = 1<<16;
        get_twiddle_val[0] = 0;
`else
        get_twiddle_val[1] = 1.0;
        get_twiddle_val[0] = 0.0;
`endif
      end
      else
      begin
        twiddle_exp = shuffle_idx[twiddle_idx]>>(N-n+1);
        get_twiddle_val = expj(twiddle_exp);
      end
    end
  endfunction
  // ---------------------------------
  function automatic cpx get_op_shift_buf(
                  ref fpt buf_real[delay-1:0],
                  ref fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0]);
    // Last In First Out Queue.
    integer i;
    begin
      get_op_shift_buf[1] = buf_real[delay-1];
      get_op_shift_buf[0] = buf_img[delay-1];
      for (i=delay-2; i>=0; i=i-1)
      begin
        buf_real[i+1] = buf_real[i];
        buf_img[i+1] = buf_img[i];
      end
      buf_real[0] = ip[1];
      buf_img[0] = ip[0];
    end
  endfunction
  // ---------------------------------
  function automatic cpx get_op_butterfly(
                  ref fpt buf_real[delay-1:0],
                  ref fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0]);
    // ip <butterfly> buf[delay-1]
    // "+" value: push to op
    // "-" value: push to buf
    fpt bufN[1:0];
    fpt product[1:0];
    integer i;
    begin
      product = mul(ip,twiddle_val);
      bufN[1] = buf_real[delay-1];
      bufN[0] = buf_img[delay-1];
      // Shift LIFO Queue.
      for (i=delay-2; i>=0; i=i-1) begin
        buf_real[i+1] = buf_real[i];
        buf_img[i+1] = buf_img[i];
      end
      buf_real[0] = bufN[1] - product[1];
      buf_img[0] = bufN[0] - product[0];
      get_op_butterfly[1] = bufN[1] + product[1];
      get_op_butterfly[0] = bufN[0] + product[0];
    end
  endfunction
  // ---------------------------------
  function automatic cpx mul(fpt a[1:0], fpt b[1:0]);
    // complex number multiplication
    begin
      mul[1] = f_mul(a[1],b[1]) - f_mul(a[0],b[0]);
      mul[0] = f_mul(a[1],b[0]) + f_mul(a[0],b[1]);
    end
  endfunction
  // ---------------------------------
  function automatic cpx expj(integer twiddle_exp);
    begin
      expj[1] = cos_arr[twiddle_exp];
      expj[0] = sin_arr[twiddle_exp];
    end
  endfunction
  // ---------------------------------
  // ---------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      stage_launch = 0;
      output_countdown = -1;
    end else begin
      ip_reg = ip;
      if (start_ip == 1) begin // restart
        timemux_clk = 0;
        timemux_clk_count = 0;
        period_count = 0;
        twiddle_idx = -1;
        output_countdown = 1<<(N-n);
        shuffle_idx_reg = shuffle_idx;
        stage_launch = 1;
      end else begin
        // idle
      end

      if (stage_launch == 1) begin
        ctrl_timemux(timemux_clk_count, period_count, timemux_clk, twiddle_idx);
        twiddle_val = get_twiddle_val(timemux_clk,twiddle_idx,shuffle_idx_reg);
        if (timemux_clk == 1) begin
          op = get_op_shift_buf(buf_real,buf_img,ip_reg,twiddle_val);
        end else begin
          op = get_op_butterfly(buf_real,buf_img,ip_reg,twiddle_val);
        end
      end else begin
        // idle
      end

      if (start_op == 1)
        start_op = 0;   // signal lasts for 1 clk
      if (output_countdown == 0) begin
        start_op = 1;
        output_countdown = -1;
      end else if (output_countdown > 0 ) begin
        output_countdown = output_countdown - 1;
      end else begin
        // do nothing
      end
    end
  end

endmodule
