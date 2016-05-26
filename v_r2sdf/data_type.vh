/*
typedef reg [15:-16] fpt;
typedef reg [62:0] fpt_mul;
*/
`ifndef _data_type_vh_
`define _data_type_vh_
typedef real fpt;
typedef fpt cpx [1:0];
typedef fpt t_trig_arr[$];//[1<<(N-1)];

`endif
