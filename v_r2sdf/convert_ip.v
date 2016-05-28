`include "sys_macro.vh"
module convert_ip (ip_arr_converted);
  parameter length=8;
  t_ip_raw ip_arr_raw[length-1:0];
  output fpt ip_arr_converted[length-1:0];

  initial begin
    integer i,j;
    begin

  `include "ip_arr_int.v"

      for (i=0; i<length; i=i+1)
        ip_arr_converted[i] = (ip_arr_raw[i][31:0])<<16;
    end
  end

endmodule
