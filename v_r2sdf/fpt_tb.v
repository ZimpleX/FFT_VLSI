`include "sys_macro.vh"
module fpt_tb();
  fpt a;
  fpt b;
  fpt c;
  function fpt f_mul(fpt a, fpt b);
    fpt_mul temp;
    fpt_mul a_ext,b_ext;
    begin
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

  initial begin
    #(`CLK) a = 32'h0026_0000;
    b = 32'h0012_0000;
    #(`CLK) c = f_mul(a,b);
    #(`CLK*10) $finish;
  end

endmodule
