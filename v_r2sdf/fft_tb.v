`include "sys_macro.vh"
module fft_tb ();
  parameter N = `N_;
  reg reset, clk;
  fpt ip_arr_converted[3*(1<<N)-1:0];
  fpt ip;
  reg start_ip;
  reg op_ready;
  fpt op_raw[1:0];
  fpt op_shuffled[1:0];
  integer idx;
  integer f;

 
  convert_ip #(.length(3*(1<<N))) convert_ip_instance(ip_arr_converted);
  fft #(.N(N)) fft_instance(.reset,.clk,.start_ip,.ip,.op_raw,.op_shuffled,.op_ready);

  initial begin
    f = $fopen("fft_op.log", "w");
    clk = 1;
    reset = 1;
    idx = -1;
    #(`CLK) reset = 0;
    idx = 0;
    start_ip = 1;
    #(`CLK) start_ip = 0;
    #(`CLK*(1<<N)*15) $fclose(f);
    $finish;
  end

  always @(posedge clk) begin
    if (idx >= 0) begin
      ip = ip_arr_converted[idx];
      idx = idx + 1;
    end
    $fwrite(f,"%h, %h\n", op_shuffled[1], op_shuffled[0]);
  end

  always #(`CLKH) clk =~ clk;
endmodule
