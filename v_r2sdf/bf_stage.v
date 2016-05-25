`timescale 1ns/100ps
module bf_stage (clk, shuffle_idx, cos_arr, sin_arr, 
                  ip_real, ip_img, op_real, op_img);
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
  input real ip_real, ip_img;
  output reg real op_real, op_img;

  reg timemux_clk;
  real twiddle_val_real;
  real twiddle_val_img;
  integer twiddle_idx;
  integer period;
  reg [N-n-1:0] timemux_clk_count;
  reg [N-n:0] period_count;
  real buf_real[delay-1:0];   // buffer to store the delayed value
  real buf_img[delay-1:0];
  // ----------------------------------
  // ----------------------------------
  initial begin
    if (N > MAX_N_1 + 1)
    begin
      // TODO: error msg!!!
    end
    warmup = 0;//n-1; // this is because output is reg.
    integer i;
    for (i=1; i<=n-1; i=i+1)
    begin
      warmup = warmup + 1<<(N-i);
    end
    warmup_count = 0;

    timemux_clk = 0;
    twiddle_val_real = 1.;
    twiddle_val_img  = 0.;
    twiddle_idx = -1;
    period = 2*delay;
    timemux_clk_count = 0;
    period_count = 0;
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
  endfunction
  // ---------------------------------
  function real[1:0] get_twiddle_val(
                  reg timemux_clk,
                  integer twiddle_idx,
                  const ref reg [N-1:0] shuffle_idx[(1<<N)-1:0]);
    // return twiddle value
    //  [1]:  real part
    //  [0]: imaginary part
    if (timemux_clk == 1)
    begin
      get_twiddle_val[1] = 1.;
      get_twiddle_val[0] = 0.;
    end
    else
    begin
      integer twiddle_exp = shuffle_idx[twiddle_idx]>>(N-n+1);
      get_twiddle_val = expj(twiddle_exp);
    end
  endfunction
  // ---------------------------------
  function real[1:0] get_op_shift_buf(
                  const ref real buf_real[delay-1:0],
                  const ref real buf_img[delay-1:0],
                  real ip_real,
                  real ip_img,
                  real twiddle_val_real,
                  real twiddle_val_img);
    // Last In First Out Queue.
    get_op_shift_buf[1] = buf_real[delay-1];
    get_op_shift_buf[0] = buf_img[delay-1];
    integer i;
    for (i=delay-2; i>=0; i=i-1)
    begin
      buf_real[i+1] = buf_real[i];
      buf_img[i+1] = buf_img[i];
    end
    buf_real[0] = ip_real;
    buf_img[0] = ip_img;
  endfunction
  // ---------------------------------
  function real[1:0] get_op_butterfly(
                  const ref real buf_real[delay-1:0],
                  const ref real buf_img[delay-1:0],
                  real ip_real,
                  real ip_img,
                  real twiddle_val_real,
                  real twiddle_val_img);
    // ip <butterfly> buf[delay-1]
    // "+" value: push to op
    // "-" value: push to buf
    {product_real,product_img} = \
        mul(ip_real,ip_img,twiddle_val_real,twiddle_val_img);
    real bufN_real = buf_real[delay-1];
    real bufN_img = buf_img[delay-1];
    // Shift LIFO Queue.
    integer i;
    for (i=delay-2; i>=0; i=i-1)
    begin
      buf_real[i+1] = buf_real[i];
      buf_img[i+1] = buf_img[i];
    end
    buf_real[0] = bufN_real - product_real;
    buf_img[0] = bufN_img - product_img;
    get_op_butterfly[1] = bufN_real + product_real;
    get_op_butterfly[0] = bufN_img + product_img;
  endfunction
  // ---------------------------------
  function real[1:0] mul(real Ra, real Ia, real Rb, real Ib);
    // complex number multiplication
    mul[1] = Ra*Rb - Ia*Ib;
    mul[0] = RaIb + IaRb;
  endfunction
  // ---------------------------------
  function real[1:0] expj(real twiddle_exp);
    // Complex exponent (cos + sin i)
    /*
    real theta = -twiddle_exp/twiddle_base;
    integer sign_sin, sign_cos;
    if (theta < -0.5)
      sign_sin = 1;
    else
      sign_sin = -1;
    if (theta > -0.75 && theta < -0.25)
      sign_cos = -1;
    else
      sign_cos = 1;
    // Observation: twiddle_exp/twiddle_base <= 0.5
    if (theta < -0.25)
      theta = 0.5 + theta;
    else
      theta = -theta;
    expj[1] = sign_cos*cos[4*twiddle_exp*((1<<MAX_N_1)/twiddle_base)];
    expj[0] = sign_sin*sin[4*twiddle_exp*((1<<MAX_N_1)/twiddle_base)];
    */
    expj[1] = cos_arr[twiddle_exp];
    expj[0] = sin_arr[twiddle_exp];
  endfunction
  // ---------------------------------
  // ---------------------------------
  always @(posedge clk)
  begin
    if (warmup_count == warmup)
    begin
      // Don't increment warmup_count anymore
      ctrl_timemux(timemux_clk_count, period_count, timemux_clk, twiddle_idx);
      {twiddle_val_real,twiddle_val_img} = \
          get_twiddle_val(timemux_clk,twiddle_idx,shuffle_idx);
      if (timemux_clk == 1)
      begin
        {op_real,op_img} = \
            get_op_shift_buf(buf_real,buf_img,ip_real,ip_img,twiddle_val_real,twiddle_val_img);
      end
      else
      begin
        {op_real,op_img} = \
            get_op_butterfly(buf_real,buf_img,ip_real,ip_img,twiddle_val_real,twiddle_val_img);
      end
    end
    else
    begin
      // TODO: should use a signal to indicate the start of data transfer
      warmup_count = warmup_count + 1;
    end
  end

endmodule
