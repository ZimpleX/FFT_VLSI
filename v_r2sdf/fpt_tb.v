`include "sys_macro.vh"
module fpt_tb();
  fpt a;
  fpt b;
  fpt c;
  function fpt f_mul(fpt a, fpt b);
    fpt_mul temp;
    begin
      temp = a*b;
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
