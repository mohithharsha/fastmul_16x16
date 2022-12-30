// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

fastmul_16x16 dut(a,b,y);

endmodule

module fastmul_16x16(a,b,y);
input [15:0]a,b;
output [31:0]y;
wire[255:0]p;
  wire [125:8]s,c; 
wire[41:0]s1,c1,Cout;
wire [5:0]O0,O1,O2,O3;

mul_8x8 u31(a[7:0],b[7:0],p[63:0]);
mul_8x8 u32(a[15:8],b[7:0],p[127:64]);
mul_8x8 u33(a[7:0],b[15:8],p[191:128]);
mul_8x8 u34(a[15:8],b[15:8],p[255:192]);

//first stage//
//4//
ha u35(p[4],p[19],s[8],c[8]);
//5//
counter53 u36(p[5],p[19],p[34],p[49],c[8],s1[0],c1[0],Cout[0]);
//6//
counter53 u37(p[6],p[20],p[35],p[50],c1[0],s1[1],c1[1],Cout[1]);
//7//
counter53 u38(p[7],p[21],p[36],p[51],Cout[0],s1[2],c1[2],Cout[2]);
fa u39(c1[1],p[67],p[82],s[9],c[9]);
//8//
counter53 u40(p[8],p[22],p[37],p[52],Cout[1],s1[3],c1[3],Cout[3]);
counter53 u41(c1[2],c[9],p[68],p[83],p[98],s1[4],c1[4],Cout[4]);
//9//
counter53 u42(p[9],p[23],p[38],p[53],Cout[2],s1[5],c1[5],Cout[5]);
counter53 u43(c1[3],c1[4],p[69],p[84],p[99],s1[6],c1[6],Cout[6]);
//10//
counter53 u44(p[10],p[24],p[39],p[54],Cout[3],s1[7],c1[7],Cout[7]);
counter53 u45(Cout[4],c1[5],c1[6],p[70],p[85],s1[8],c1[8],Cout[8]);
ha u46(p[100],p[115],s[10],c[10]);
//11//
counter53 u47(p[11],p[25],p[40],p[55],Cout[5],s1[9],c1[9],Cout[9]);
counter53 u48(Cout[6],c1[7],c1[8],c[10],p[71],s1[10],c1[10],Cout[10]);
fa u49(p[86],p[101],p[116],s[11],c[11]);
//12//
counter154 u50(p[12],p[26],p[41],p[56],p[71],p[86],p[101],p[116],p[131],p[146],p[161],p[176],p[191],Cout[7],Cout[8],O0[0],O1[0],O2[0],O3[0]);
//13//
counter154 u51(p[13],p[27],p[42],p[57],p[72],p[87],p[102],p[117],p[132],p[147],p[162],p[177],p[192],p[207],O1[0],O0[1],O1[1],O2[1],O3[1]);
//14//
counter154 u52(p[14],p[28],p[43],p[58],p[73],p[88],p[103],p[118],p[133],p[148],p[163],p[178],p[193],p[208],p[223],O0[2],O1[2],O2[2],O3[2]);
//15//
counter154 u53(p[15],p[29],p[44],p[59],p[74],p[89],p[104],p[119],p[134],p[149],p[164],p[179],p[194],p[209],p[224],O0[3],O1[3],O2[3],O3[3]);
ha u54(O3[0],p[240],s[12],c[12]);
//16//
counter154 u55(p[31],p[46],p[61],p[76],p[91],p[106],p[121],p[136],p[151],p[166],p[181],p[196],p[211],p[226],p[241],O0[4],O1[4],O2[4],O3[4]);
ha u56(O3[1],O2[2],s[13],c[13]);
//17//
counter154 u57(p[47],p[62],p[77],p[92],p[107],p[122],p[137],p[152],p[167],p[182],p[197],p[212],p[227],p[242],O3[2],O0[5],O1[5],O2[5],O3[5]);
ha u58(O2[3],O1[4],s[14],c[14]);
//18//
counter53 u59(p[63],p[78],p[93],p[108],O3[3],s1[11],c1[11],Cout[11]);
counter53 u60(p[123],p[138],p[153],p[168],O2[4],s1[12],c1[12],Cout[12]);
counter53 u61(p[183],p[198],p[213],p[228],O1[5],s1[13],c1[13],Cout[13]);
ha u62(c[14],p[243],s[15],c[15]);
//19//
counter53 u63(p[79],p[94],p[109],p[124],O3[4],s1[14],c1[14],Cout[14]);
counter53 u64(p[139],p[154],p[169],p[174],O2[5],s1[15],c1[15],Cout[15]);
counter53 u65(p[199],p[214],p[229],p[244],c1[11],s1[16],c1[16],Cout[16]);
ha u66(c1[12],c1[13],s[16],c[16]);
//20//
counter53 u67(p[95],p[110],p[125],p[140],O3[5],s1[17],c1[17],Cout[17]);
counter53 u68(p[155],p[170],p[185],p[200],Cout[11],s1[18],c1[18],Cout[18]);
fa u69(p[215],p[230],p[245],s[17],c[17]);
ha u70(Cout[12],Cout[13],s[18],c[18]);
//21//
counter53 u71(p[111],p[126],p[141],p[156],Cout[14],s1[19],c1[19],Cout[19]);
counter53 u72(p[171],p[186],p[201],p[216],Cout[15],s1[20],c1[20],Cout[20]);
ha u73(p[231],p[246],s[19],c[19]);
fa u74(Cout[16],c1[17],c1[18],s[20],c[20]);
//22//
counter53 u75(p[127],p[142],p[157],p[172],Cout[17],s1[21],c1[21],Cout[21]);
ha u76(p[187],p[192],s[21],c[21]);
fa u77(p[217],p[232],p[247],s[22],c[22]);
fa u78(Cout[18],c1[19],c1[20],s[23],c[23]);
//23//
counter53 u79(p[143],p[158],p[173],p[188],Cout[19],s1[22],c1[22],Cout[22]);
ha u80(p[203],p[218],s[24],c[24]);
fa u81(p[233],p[248],Cout[20],s[25],c[25]);
fa u82(c1[21],c[21],c[22],s[26],c[26]);
//24//
counter53 u83(p[159],p[174],p[189],p[204],Cout[21],s1[23],c1[23],Cout[23]);
fa u84(p[219],p[234],p[249],s[27],c[27]);
ha u85(c1[22],c[24],s[28],c[28]);
//25//
counter53 u86(p[175],p[190],p[205],p[220],Cout[22],s1[24],c1[24],Cout[24]);
ha u87(c1[23],c[27],s[29],c[29]);
//26//
fa u88(p[191],p[206],p[221],s[30],c[30]);
ha u89(Cout[23],c1[24],s[31],c[31]);
//27//
ha u90(p[207],p[222],s[32],c[32]);
fa u91(Cout[24],c[30],c[31],s[33],c[33]);
//28//
ha u92(p[208],c[32],s[34],c[34]);
//29//
ha u93(p[224],c[34],s[35],c[35]);
//30//
ha u94(p[240],c[35],s[36],c[36]);

//Second stage

//0//
ha u95(p[0],c[36],y[0],c[37]);
//1//
ha u96(p[1],c[37],s[38],c[38]);
//2//
fa u97(p[2],p[17],c[38],s[39],c[39]);
//3//
fa u98(p[3],p[18],p[32],s[40],c[40]);
//4//
fa u99(s[8],p[34],p[49],s[41],c[41]);
//5//
ha u100(s1[0],p[65],s[42],c[42]);
//6//
counter53 u101(s1[1],p[66],p[81],p[96],c[42],s1[25],c1[25],Cout[25]);
//7//
counter53 u102(s1[2],s[9],p[97],p[112],c1[25],s1[26],c1[26],Cout[26]);
//8//
counter53 u103(s1[3],s1[4],p[113],p[128],Cout[25],s1[27],c1[27],Cout[27]);
//9//
counter53 u104(s1[5],s1[6],p[114],p[129],p[134],s1[28],c1[28],Cout[28]);
//10//
counter53 u105(s1[7],s1[8],s[10],p[130],Cout[27],s1[29],c1[29],Cout[29]);
ha u106(p[145],p[160],s[43],c[43]);
//11//
counter53 u107(s1[9],s1[10],s[11],p[131],Cout[28],s1[30],c1[30],Cout[30]);
fa u108(p[145],p[161],p[176],s[44],c[44]);
//12//
counter53 u109(O0[0],c1[9],c1[10],c[11],Cout[29],s1[31],c1[31],Cout[31]);
ha u110(c1[30],c[44],s[45],c[45]);
//13//
fa u111(O0[1],Cout[9],Cout[10],s[46],c[46]);
ha u112(Cout[30],c1[31],s[47],c[47]);
//14//
fa u113(O0[2],O2[0],O1[1],s[48],c[48]);
ha u114(Cout[31],c[46],s[49],c[49]);
//15//
fa u115(O0[3],s[12],O2[1],s[50],c[50]);
ha u116(O1[2],c[48],s[51],c[51]);
//16//
fa u117(O0[4],s[13],O1[3],s[52],c[52]);
ha u118(c[12],c[50],s[53],c[53]);
//17//
fa u119(O0[5],s[14],c[8],s[54],c[54]);
//18//
fa u120(s1[11],s1[12],s1[13],s[55],c[55]);
//19//
counter53 u121(c[10],s1[14],s1[15],s1[16],c[55],s1[32],c1[32],Cout[32]);
//20//
counter53 u122(c1[14],c1[15],c1[16],c[16],c1[32],s1[33],c1[33],Cout[33]);
fa u123(s1[17],s1[18],s[17],s[56],c[56]);
//21//
counter53 u124(c[17],c[18],s1[19],s1[20],Cout[32],s1[34],c1[34],Cout[34]);
fa u125(s[19],s[20],c1[33],s[57],c[57]);
//22//
counter53 u126(c[19],c[20],s1[21],s[21],Cout[33],s1[35],c1[35],Cout[35]);
fa u127(s[22],s[23],c1[34],s[58],c[58]);
//23//
counter53 u128(c[23],s1[22],s[24],s[25],Cout[34],s1[36],c1[36],Cout[36]);
//24//
counter53 u129(c[25],c[26],s1[23],s[27],Cout[35],s1[37],c1[37],Cout[37]);
//25//
counter53 u130(c[27],s1[24],s[29],p[235],Cout[36],s1[38],c1[38],Cout[38]);
//26//
counter53 u131(c[29],s[30],s[31],p[236],Cout[37],s1[39],c1[39],Cout[39]);
//27//
fa u132(s[32],s[33],p[237],s[59],c[59]);
ha u133(p[252],Cout[38],s[60],c[60]);
//28//
counter53 u134(p[223],p[238],p[244],c[26],c[27],s1[40],c1[40],Cout[40]);
ha u135(Cout[39],c[53],s[61],c[61]);
//29//
ha u136(p[239],c1[40],s[62],c[62]);


//third stage
//3//
ha u137(s[40],c[39],s[63],c[63]);
//4//
fa u138(s[41],c[40],p[64],s[64],c[64]);
//5//
fa u139(s[42],c[41],p[80],s[65],c[65]);
//6//
ha u140(s1[25],c[65],s[66],c[66]);
//7//
ha u141(s1[26],c[66],y[7],c[67]);
//8//
fa u142(s1[27],c1[26],c[9],y[8],c[68]);
//9//
fa u143(s1[28],Cout[26],c1[27],s[69],c[69]);
//10//
fa u144(s1[29],s[43],c1[28],s[70],c[70]);
//11//
counter53 u145(s1[30],s[44],c1[29],c[37],c[70],s1[41],c1[41],Cout[41]);
//12//
fa u146(s1[31],s[45],c1[41],s[71],c[71]);
//13//
fa u147(s[46],s[47],Cout[41],s[72],c[72]);
ha u148(c[45],c[71],s[73],c[73]);
//14//
fa u149(s[48],s[49],c[72],s[74],c[74]);
ha u150(c[47],c[72],s[75],c[75]);
//15//
fa u151(s[50],s[51],c[74],s[76],c[76]);
ha u152(c[48],c[75],s[77],c[77]);
//16//
fa u153(s[52],s[53],c[76],s[78],c[78]);
ha u154(c[50],c[77],s[79],c[79]);
//17//
fa u155(s[54],c[52],c[78],s[80],c[80]);
ha u156(c[53],c[79],s[81],c[81]);
//18//
fa u157(s[55],c[54],c[80],s[82],c[82]);
ha u158(s[15],c[81],s[83],c[83]);
//19//
fa u159(s1[32],s[16],c[82],s[84],c[84]);
//20//
fa u160(s1[33],s[56],s[18],s[84],c[85]);
//21//
fa u161(s1[34],s[57],c[56],s[86],c[86]);
//22//
fa u162(s1[35],s[58],c[57],s[87],c[87]);
//23//
fa u163(s1[36],c1[35],c[58],s[88],c[88]);
//24//
fa u164(s1[37],c1[36],s[28],s[89],c[89]);
//25//
fa u165(s1[38],c1[37],p[250],s[90],c[90]);
//26//
fa u166(s1[39],c1[38],p[251],s[91],c[91]);
//27//
fa u167(s[59],s[60],c1[39],s[92],c[92]);
//28//
fa u168(s1[40],s[61],c[59],s[93],c[93]);
//29//
fa u169(s[62],c[61],p[254],s[94],c[94]);
//30//
fa u170(p[255],c[62],c[94],s[95],c[95]);

//final stage
//1
ha u171(p[16],s[38],y[1],c[96]);
//2
fa u172(s[39],p[32],c[96],y[2],c[97]);
//3
fa u173(s[63],p[48],c[97],y[3],c[98]);
//4
fa u174(s[64],c[63],c[98],y[4],c[99]);
//5
fa u175(s[65],c[64],c[99],y[5],c[100]);
//6
ha u176(s[66],c[100],y[6],c[101]);
//7
ha u177(s[67],c[101],y[7],c[102]);
//8
ha u178(s[68],c[102],y[8],c[103]);
//9
fa u179(s[69],c[68],c[103],y[9],c[104]);
//10
fa u180(s[70],c[69],c[104],y[10],c[105]);
//11
ha u181(s1[41],c[105],y[11],c[106]);
//12
ha u182(s[71],c[106],y[12],c[107]);
//13
fa u183(s[72],s[73],c[107],y[13],c[108]);
//14
fa u184(s[74],s[75],c[108],y[14],c[109]);
//15
fa u185(s[76],s[77],c[109],y[15],c[110]);
//16
fa u186(s[78],s[79],c[110],y[16],c[111]);
//17
fa u187(s[80],s[81],c[111],y[17],c[112]);
//18
fa u188(s[82],s[83],c[112],y[18],c[113]);
//19
fa u189(s[84],c[83],c[113],y[19],c[114]);
//20
fa u190(s[85],c[84],c[114],y[20],c[115]);
//21
fa u191(s[86],c[85],c[115],y[21],c[116]);
//22
fa u192(s[87],c[86],c[116],y[22],c[117]);
//23
fa u193(s[88],c[87],c[117],y[23],c[118]);
//24
fa u194(s[89],c[88],c[118],y[24],c[119]);
//25
fa u195(s[90],c[89],c[119],y[25],c[120]);
//26
fa u196(s[91],c[90],c[120],y[26],c[121]);
//27
fa u197(s[92],c[91],c[121],y[27],c[122]);
//28
fa u198(s[93],c[92],c[122],y[28],c[123]);
//29
fa u199(s[94],c[93],c[123],y[29],c[124]);
//30
fa u200(s[95],c[94],c[124],y[30],c[125]);
assign c[125] = y[31];



endmodule

module counter154(Z0,Z1,Z2,Z3,Z4,Z5,Z6,Z7,Z8,Z9,Z10,Z11,Z12,Z13,Z14,O0,O1,O2,O3);
input Z0,Z1,Z2,Z3,Z4,Z5,Z6,Z7,Z8,Z9,Z10,Z11,Z12,Z13,Z14;
output O0,O1,O2,O3;
wire s[7:0];
wire c[7:0];
wire [1:0]s1,c1,Cout;


fa u1(Z0,Z1,Z2,s[0],c[0]);
fa u2(Z3,Z4,Z5,s[1],c[1]);
fa u3(Z6,Z7,Z8,s[2],c[2]);
fa u4(Z9,Z10,Z11,s[3],c[3]);
fa u5(Z12,Z13,Z14,s[4],c[4]);

counter53 u6(s[0],s[1],s[2],s[3],s[4],s1[0],c1[0],Cout[0]);
counter53 u7(c[0],c[1],c[2],c[3],c[4],s1[1],c1[1],Cout[1]);

assign s1[0]=O0;
ha u8(c1[0],s1[1],s[5],c[5]);
fa u9(Cout[0],c1[1],c[0],s[6],c[6]);
ha u10(Cout[1],c[1],s[7],c[7]);
assign s[5] = O1;
assign s[6] = O2;
assign s[7] = O3;
endmodule

module counter53(X0,X1,X2,X3,X4,s1,c1,Cout);
input X0,X1,X2,X3,X4;
output s1,c1,Cout;
wire Y[4:0],P,R;
wire R1,R2,P1,P2;
wire t1,t2,t3;

assign Y[0] = X3 | X4;
assign Y[1] = X3 & X4;
assign Y[2] = X1 | X2;
assign Y[3] = X1 & X2;
assign Y[4] = X0;
assign R1 = Y[0] & ~Y[1];
assign R2 = Y[2] & ~Y[3];
assign R = R1 ^ R2 ;
assign P1 = ~R & Y[3];
assign P2 = R & Y[4];
assign P = P1 | P2;
assign t1 = Y[1] | Y[2];
assign t2 = Y[0] & t1;
assign Cout = t2 & P;
assign t3 = Y[0] & t1;
assign c1 = t3 ^ P; 
assign s1 = R ^ Y[4];

endmodule

module fa(a,b,c,s,co);
input a,b,c;
output s,co;
assign s = a ^ b ^ c;
assign co = (a & b) | (b & c) | (c & a);
endmodule

module ha(a,b,s,c);
input a,b;
output s,c;
assign s = a ^ b;
assign c = a & b;
endmodule 

module mul_8x8(a,b,p);
input [7:0]a,b;
output [63:0]p;

mul_4x4 u27(a[3:0],b[3:0],p[15:0]);
mul_4x4 u28(a[7:4],b[3:0],p[31:16]);
mul_4x4 u29(a[3:0],b[7:4],p[47:32]);
mul_4x4 u30(a[7:4],b[7:4],p[63:48]);

endmodule


module mul_4x4(a,b,p);
input [3:0]a,b;
output [15:0]p;

and u11(p[0],a[0],b[0]);
and u12(p[1],a[1],b[0]);
and u13(p[2],a[2],b[0]);
and u14(p[3],a[3],b[0]);
and u15(p[4],a[0],b[1]);
and u16(p[5],a[1],b[1]);
and u17(p[6],a[2],b[1]);
and u18(p[7],a[3],b[1]);
and u19(p[8],a[0],b[2]);
and u20(p[9],a[1],b[2]);
and u21(p[10],a[2],b[2]);
and u22(p[11],a[3],b[2]);
and u23(p[12],a[0],b[3]);
and u24(p[13],a[1],b[3]);
and u25(p[14],a[2],b[3]);
and u26(p[15],a[3],b[3]);

endmodule



`default_nettype wire
