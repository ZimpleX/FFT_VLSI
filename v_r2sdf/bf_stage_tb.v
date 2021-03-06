`include "sys_macro.vh"
module bf_stage_tb();
  parameter N=3;
  parameter n=1;
  real ip_arr[(1<<N)-1:0];

  reg clk;
  wire [N-1:0] shuffle_idx[(1<<N)-1:0];
  real cos_arr[1<<(N-1)];
  real sin_arr[1<<(N-1)];
  real ip[1:0];
  real op[1:0];
  integer idx;
  reg start_ip, start_op;
  
  gen_shuffle_idx #(.N(N)) shuffle_instance(.shuffle_idx);
  bf_stage #(.N(N),.n(n)) bf_stage_instance(.clk,.shuffle_idx,
                  .cos_arr,.sin_arr,.ip,.op,.start_ip,.start_op);
  
  initial begin
    integer i;
    begin
`include "ip_arr.v"
      idx = 0;
      clk = 1;
      i = 0;
      for (i=0; i<(1<<(n-1)); i=i+1)
      begin
        cos_arr[i] = 1.0;
        sin_arr[i] = 0.0;
      end
      start_ip = 1;
      #(`CLK) start_ip = 0;
      #(`CLK*(1<<N)*1.5) $finish;
    end
  end

  always @(posedge clk) begin
    ip[1] = ip_arr[idx];
    ip[0] = 0.0;
    idx = idx + 1;
  end
  always #(`CLKH) clk=~clk;
endmodule
