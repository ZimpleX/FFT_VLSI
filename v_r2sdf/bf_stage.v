`timescale 1ns/100ps
module bf_stage (clk, shuffle_idx, cos_arr, sin_arr, 
                  ip, op);
  parameter N=3;  // number of inputs to FFT: 2^N
  parameter n=1;  // stage of the butterfly unit, start from 1.
  parameter delay = 1<<(N-n); // DON'T pass in this parameter!!
  integer warmup; // wait for some cycles for synchronous among stages
  integer warmup_count;

  input clk;
  input [N-1:0] shuffle_idx[(1<<N)-1:0];
  input real cos_arr[1<<(n-1)];
  input real sin_arr[1<<(n-1)];
  // TODO: may switch to fixed point representation
  input real ip[1:0];
  output real op[1:0];

  reg timemux_clk;
  real twiddle_val[1:0];
  integer twiddle_idx;
  integer period;
  reg [N-n-1:0] timemux_clk_count;
  reg [N-n:0] period_count;
  real buf_real[delay-1:0];   // buffer to store the delayed value
  real buf_img[delay-1:0];
  // ----------------------------------
  // ----------------------------------
  initial begin
    integer i;
    begin
      warmup = 0;//n-1; // this is because output is reg.
      for (i=1; i<=n-1; i=i+1)
      begin
        warmup = warmup + 1<<(N-i);
      end
      warmup_count = 0;

      timemux_clk = 0;
      twiddle_val[1] = 1.0;
      twiddle_val[0]  = 0.0;
      twiddle_idx = -1;
      period = 2*delay;
      timemux_clk_count = 0;
      period_count = 0;
    end
  end
  // ----------------------------------
  // ----------------------------------
  function void ctrl_timemux (
                  ref reg [N-n-1:0] timemux_clk_count, 
                  ref reg [N-n:0] period_count,
                  ref reg timemux_clk,
                  ref integer twiddle_idx);
    // update timemux_clk signals
    // update twiddle_idx
    begin
      if (timemux_clk_count == 0)
        timemux_clk =~ timemux_clk;
      else
        timemux_clk = timemux_clk;
      if (period_count == 0)
        twiddle_idx = twiddle_idx + 1;
      else
        twiddle_idx = twiddle_idx;
      timemux_clk_count = timemux_clk_count + 1;
      period_count = period_count + 1;
    end
  endfunction
  // ---------------------------------
  function [31:0][1:0] get_twiddle_val(
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
        get_twiddle_val[1] = 1.0;
        get_twiddle_val[0] = 0.0;
      end
      else
      begin
        twiddle_exp = shuffle_idx[twiddle_idx]>>(N-n+1);
        get_twiddle_val = expj(twiddle_exp);
      end
    end
  endfunction
  // ---------------------------------
  function [31:0][1:0] get_op_shift_buf(
                  const ref real buf_real[delay-1:0],
                  const ref real buf_img[delay-1:0],
                  real ip[1:0],
                  real twiddle_val[1:0];
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
  function [31:0][1:0] get_op_butterfly(
                  const ref real buf_real[delay-1:0],
                  const ref real buf_img[delay-1:0],
                  real ip[1:0],
                  real twiddle_val[1:0]);
    // ip <butterfly> buf[delay-1]
    // "+" value: push to op
    // "-" value: push to buf
    real bufN[1:0];
    real product[1:0];
    integer i;
    begin
      product = mul(ip,twiddle_val);
      bufN[1] = buf_real[delay-1];
      bufN[0] = buf_img[delay-1];
      // Shift LIFO Queue.
      for (i=delay-2; i>=0; i=i-1)
      begin
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
  function [31:0][1:0] mul(real a[1:0], real b[1:0]);
    // complex number multiplication
    begin
      mul[1] = a[1]*b[1] - a[0]*b[0];
      mul[0] = a[1]*b[0] + a[0]*b[1];
    end
  endfunction
  // ---------------------------------
  function [31:0][1:0] expj(real twiddle_exp);
    begin
      expj[1] = cos_arr[twiddle_exp];
      expj[0] = sin_arr[twiddle_exp];
    end
  endfunction
  // ---------------------------------
  // ---------------------------------
  always @(posedge clk)
  begin
    if (warmup_count == warmup)
    begin
      // Don't increment warmup_count anymore
      ctrl_timemux(timemux_clk_count, period_count, timemux_clk, twiddle_idx);
      twiddle_val = get_twiddle_val(timemux_clk,twiddle_idx,shuffle_idx);
      if (timemux_clk == 1)
      begin
        op = get_op_shift_buf(buf_real,buf_img,ip,twiddle_val);
      end
      else
      begin
        op = get_op_butterfly(buf_real,buf_img,ip,twiddle_val);
      end
    end
    else
    begin
      // TODO: should use a signal to indicate the start of data transfer
      warmup_count = warmup_count + 1;
    end
  end

endmodule
