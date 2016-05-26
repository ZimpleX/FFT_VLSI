`include "sys_macro.vh"
module convert_ip (ip_arr_converted);
  parameter length=8;
  t_ip_raw ip_arr_raw[length-1:0];
  output fpt ip_arr_converted[length-1:0];

  initial begin
    integer i,j;
    reg [31:0] temp;
    begin
`include "ip_arr.v"
      for (i=0; i<length; i=i+1)
      begin
        for (j=0; j<32; j=j+1)
        begin
          temp[j] = ip_arr_raw[i][j];
        end
        ip_arr_converted[i] = temp<<16;
      end
    end
  end

endmodule
