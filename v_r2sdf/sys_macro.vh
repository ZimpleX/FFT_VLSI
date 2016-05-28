`ifndef _data_type_vh_
`define _data_type_vh_

`define CLK 20
`define CLKH (`CLK/2)
`timescale 1ns/100ps
typedef integer t_ip_raw;
typedef reg [15:-16] fpt;
typedef reg [63:0] fpt_mul;

`define N_ 5
typedef fpt cpx [1:0];
typedef fpt t_trig_arr[1<<(`N_-1)];
typedef reg [`N_-1:0] t_shuffle_idx [(1<<`N_)-1:0];

`endif
