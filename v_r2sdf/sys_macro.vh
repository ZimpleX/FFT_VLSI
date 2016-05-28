`ifndef _data_type_vh_
`define _data_type_vh_

`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
`define DTYPE_FIXED_POINT
`ifdef DTYPE_FIXED_POINT
  typedef integer t_ip_raw;
  typedef reg [15:-16] fpt;
  typedef reg [63:0] fpt_mul;
`else
  typedef real t_ip_raw;
  typedef real fpt;
`endif

`define N_ 4
typedef fpt cpx [1:0];
typedef fpt cpx_buf [1:0][1:0]; //lower dim: [1]: real; [0]: img
                                //higher dim: [1]: shifted out; [0]: shifted in
typedef fpt t_trig_arr[1<<(`N_-1)];
typedef reg [`N_-1:0] t_shuffle_idx [(1<<`N_)-1:0];

`endif
