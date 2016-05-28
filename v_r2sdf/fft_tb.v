`include "sys_macro.vh"
module fft_tb ();
  parameter N = 4;
  reg reset, clk;
  fpt ip_arr_converted[3*(1<<N)-1:0];
  fpt ip;
  reg start_ip;
  reg op_ready;
  fpt op_raw[1:0];
  fpt op_shuffled[1:0];
  integer idx;

  // DEBUG  ***************************
  fpt _db_neg_product_n[N-1:0][2:0];
  fpt _db_trig_n[N-1:0][1:0];
  fpt _db_neg_sum_n[N-1:0];
  // **********************************
  
  convert_ip #(.length(3*(1<<N))) convert_ip_instance(ip_arr_converted);
  fft #(.N(N)) fft_instance(.reset,.clk,.start_ip,.ip,.op_raw,.op_shuffled,.op_ready,
      ._db_neg_product_n,._db_trig_n,._db_neg_sum_n);

  initial begin
    clk = 1;
    reset = 1;
    idx = -1;
    #(`CLK) reset = 0;
    idx = 0;
    start_ip = 1;
    #(`CLK) start_ip = 0;
    #(`CLK*(1<<N)*15) $finish;
  end

  always @(posedge clk) begin
    if (idx >= 0) begin
      ip = ip_arr_converted[idx];
      idx = idx + 1;
    end
  end

  always #(`CLKH) clk =~ clk;
endmodule
