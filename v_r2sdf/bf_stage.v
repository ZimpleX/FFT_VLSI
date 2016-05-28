`include "sys_macro.vh"
module bf_stage (reset, clk, shuffle_idx, cos_arr, sin_arr, 
                  ip, op, start_ip, start_op, 
                  _db_neg_product, _db_trig, _db_neg_sum);
  parameter N=3;  // number of inputs to FFT: 2^N
  parameter n=1;  // stage of the butterfly unit, start from 1.
  parameter delay = 1<<(N-n); // DON'T pass in this parameter!!

  input reset, clk;
  input [N-1:0] shuffle_idx[(1<<N)-1:0];
  reg [N-1:0] shuffle_idx_reg[(1<<N)-1:0];
  input fpt cos_arr[1<<(N-1)];
  input fpt sin_arr[1<<(N-1)];
  // TODO: may switch to fixed point representation
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
  cpx_buf buf_inout;
  
  integer stage_launch, output_countdown;
  // DEBUG SIGNAL *********************
  output fpt _db_neg_product[2:0];  // 0: a;  1: b; 2: a*b;
  output fpt _db_trig[1:0];         // 0: sin;  1: cos
  output fpt _db_neg_sum;
  integer shift_count;
  // **********************************
  // ----------------------------------
  // ----------------------------------
`ifdef DTYPE_FIXED_POINT
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
`else
  function automatic fpt f_mul(fpt a, fpt b);
    f_mul = a*b;
  endfunction
`endif
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
  // ref
  function automatic [(N-n+N-n+1+32):0] ctrl_timemux (
                  reg [N-n-1:0] timemux_clk_count, 
                  reg [N-n:0] period_count,
                  reg timemux_clk,
                  integer twiddle_idx);
    // update timemux_clk         [0]
    // update timemux_clk_count   [(N-n):1]
    // update period_count        [(N-n+N-n+1):(N-n+1)]
    // update twiddle_idx         [(N-n+N-n+1+32):(N-n+N-n+2)]
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
      ctrl_timemux[0] = timemux_clk;
      ctrl_timemux[(N-n):1] = timemux_clk_count;
      ctrl_timemux[(N-n+N-n+1):(N-n+1)] = period_count;
      ctrl_timemux[(N-n+N-n+1+32):(N-n+N-n+2)] = twiddle_idx;
    end
  endfunction
  // ---------------------------------
  function automatic cpx get_twiddle_val(
                  reg timemux_clk,
                  integer twiddle_idx,
                  reg [N-1:0] shuffle_idx[(1<<N)-1:0],
                  fpt _db_trig[1:0]);
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
      // DEBUG  ******************************
      _db_trig = get_twiddle_val;
      // *************************************
    end
  endfunction
  // ---------------------------------
  // ref
  function automatic cpx_buf op_shift_buf(
                  fpt buf_real[delay-1:0],
                  fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0]);
    begin
      op_shift_buf[1][1] = buf_real[delay-1];
      op_shift_buf[1][0] = buf_img[delay-1];
      op_shift_buf[0] = ip;
    end
  endfunction

  function automatic cpx_buf op_butterfly(
                  fpt buf_real[delay-1:0],
                  fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0]);
    fpt product[1:0];
    begin
      product = mul(ip,twiddle_val);
      op_butterfly[1][1] = buf_real[delay-1] + product[1];
      op_butterfly[1][0] = buf_img[delay-1] + product[0];
      op_butterfly[0][1] = buf_real[delay-1] - product[1];
      op_butterfly[0][0] = buf_img[delay-1] - product[0];
    end
  endfunction
  /*
  struct {
    cpx buf_element[delay:0];
  } buf_return;
  function automatic buf_return get_op_shift_buf(
                  fpt buf_real[delay-1:0],
                  fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0]);
    // Last In First Out Queue.
    // return a queue with delay+1 elements, first element is the one just
    // shifted out.
    begin
      get_op_shift_buf.buf_element[1][delay:1] = buf_real;
      get_op_shift_buf.buf_element[0][delay:1] = buf_img;
      get_op_shift_buf.buf_element[1][0] = ip[1];
      get_op_shift_buf.buf_element[0][0] = ip[0];
    end
  endfunction
  */
  // ---------------------------------
  // ref
  /*
  function automatic buf_return get_op_butterfly(
                  fpt buf_real[delay-1:0],
                  fpt buf_img[delay-1:0],
                  fpt ip[1:0],
                  fpt twiddle_val[1:0],
                  fpt _db_neg_product[2:0],
                  fpt _db_neg_sum);
    // ip <butterfly> buf[delay-1]
    // "+" value: push to op
    // "-" value: push to buf
    fpt product[1:0];
    begin
      get_op_butterfly.buf_element[1][delay-1:1] = buf_real[delay-2:0];
      get_op_butterfly.buf_element[0][delay-1:1] = buf_img[delay-2:0];
      product = mul(ip,twiddle_val);
      {get_op_butterfly.buf_element[1][0],get_op_butterfly.buf_element[0][0]} = 
            {buf_real[delay-1],buf_img[delay-1]} - product;
      {get_op_butterfly.buf_element[1][delay],get_op_butterfly.buf_element[0][delay]} = 
            {buf_real[delay-1],buf_img[delay-1]} + product;
      // DEBUG  ****************************
      _db_neg_product[0] = ip[1];
      _db_neg_product[1] = twiddle_val[1];
      _db_neg_product[2] = product[1];
      _db_neg_sum = get_op_butterfly.buf_element[delay][1];
      // ***********************************
    end
  endfunction
  */
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
        {twiddle_idx,period_count,timemux_clk_count,timemux_clk} = 
          ctrl_timemux(timemux_clk_count, period_count, timemux_clk, twiddle_idx);
        twiddle_val = get_twiddle_val(timemux_clk,twiddle_idx,shuffle_idx_reg, _db_trig);
        if (timemux_clk == 1) begin
          //{op[1],buf_real,op[0],buf_img} = 
          //  get_op_shift_buf(buf_real,buf_img,ip_reg,twiddle_val).buf_element;
          buf_inout = op_shift_buf(buf_real,buf_img,ip,twiddle_val);
        end else begin
          //{op[1],buf_real,op[0],buf_img} = 
          //  get_op_butterfly(buf_real,buf_img,ip_reg,twiddle_val,_db_neg_product,_db_neg_sum).buf_element;
          buf_inout = op_butterfly(buf_real,buf_img,ip,twiddle_val);
        end
        // shift buffer
        for (shift_count=0; shift_count<delay-1; shift_count=shift_count+1) begin
          buf_real[shift_count+1] = buf_real[shift_count];
          buf_img[shift_count+1] = buf_img[shift_count];
        end
        buf_real[0] = buf_inout[0][1];
        buf_img[0] = buf_inout[0][0];
        op = buf_inout[1];
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
