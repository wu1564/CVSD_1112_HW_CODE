// cd D:\\Hardware\\IC\\NTU_CVSD\\CVSD_111_2\\111-2_HW\\FINAL\\final_project\\01_RTL\\simulation\
// vlog -reportprogress 300 ./cu_tb.v ./ml_cu.v ./mult.v ./mult_add.v ./mult_sub.v 
module ml_cu_valid #(
    parameter DATA_WIDTH = 20
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_enable,
    input wire [5:0] i_cnt,
    // y_hat
    input wire [DATA_WIDTH-1:0] y1_real,
    input wire [DATA_WIDTH-1:0] y1_imag,
    input wire [DATA_WIDTH-1:0] y2_real,
    input wire [DATA_WIDTH-1:0] y2_imag,
    input wire [DATA_WIDTH-1:0] y3_real,
    input wire [DATA_WIDTH-1:0] y3_imag,
    input wire [DATA_WIDTH-1:0] y4_real,
    input wire [DATA_WIDTH-1:0] y4_imag,
    // r parameters
    input wire [DATA_WIDTH-1:0] r11_real,
    input wire [DATA_WIDTH-1:0] r12_real,
    input wire [DATA_WIDTH-1:0] r12_imag,
    input wire [DATA_WIDTH-1:0] r22_real,
    input wire [DATA_WIDTH-1:0] r13_real,
    input wire [DATA_WIDTH-1:0] r13_imag,
    input wire [DATA_WIDTH-1:0] r23_real,
    input wire [DATA_WIDTH-1:0] r23_imag,
    input wire [DATA_WIDTH-1:0] r33_real,
    input wire [DATA_WIDTH-1:0] r14_real,
    input wire [DATA_WIDTH-1:0] r14_imag,
    input wire [DATA_WIDTH-1:0] r24_real,
    input wire [DATA_WIDTH-1:0] r24_imag,
    input wire [DATA_WIDTH-1:0] r34_real,
    input wire [DATA_WIDTH-1:0] r34_imag,
    input wire [DATA_WIDTH-1:0] r44_real,
    // r
    input wire [DATA_WIDTH-1:0] s1_real,
    input wire [DATA_WIDTH-1:0] s1_imag,
    input wire [DATA_WIDTH-1:0] s2_real,
    input wire [DATA_WIDTH-1:0] s2_imag,
    input wire [DATA_WIDTH-1:0] s3_real,
    input wire [DATA_WIDTH-1:0] s3_imag,
    input wire [DATA_WIDTH-1:0] s4_real,
    input wire [DATA_WIDTH-1:0] s4_imag,
    // LLR output
    output wire [5:0] o_cnt,
    output wire o_valid,
    output wire [DATA_WIDTH+1:0] o_llr
);

localparam FRAC = 16;

integer i;
reg  [DATA_WIDTH-1:0] y_sg1_r[0:7], y_sg1_w[0:7]; 
reg  [DATA_WIDTH-1:0] y_sg2_r[0:1], y_sg2_w[0:1]; 
wire [DATA_WIDTH-1:0] ps_sg1_w[0:19];
reg  [DATA_WIDTH-1:0] ps_sg1_r[0:19];
reg  [DATA_WIDTH-1:0] ps_sg2_r[0:7], ps_sg2_w[0:7];
wire [DATA_WIDTH-1:0] ps_sg3_w[0:4];
reg  [DATA_WIDTH-1:0] ps_sg3_r[0:4]; 
reg  [DATA_WIDTH+1:0] ps_sg4_r, ps_sg4_w;
reg [2:0] valid_sg_dy_r, valid_sg_dy_w;
reg [5:0] cnt_reg_w[0:3], cnt_reg_r[0:3];
reg [DATA_WIDTH-1:0] y4_sub_real, y4_sub_imag;

//---------------------------------------------------------------------
// Output Signal
//---------------------------------------------------------------------
assign o_llr = ps_sg4_r;
assign o_valid = valid_sg_dy_r[2];
assign o_cnt = cnt_reg_r[3];

mult #(DATA_WIDTH, FRAC)mult0(r44_real, s4_real, ps_sg1_w[0]);
mult #(DATA_WIDTH, FRAC)mult1(r44_real, s4_imag, ps_sg1_w[1]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub0(r34_real, s4_real, r34_imag ,s4_imag, ps_sg1_w[2]);
mult_add #(DATA_WIDTH, FRAC)mult_add0(r34_real, s4_imag, r34_imag ,s4_real, ps_sg1_w[3]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub1(r24_real, s4_real, r24_imag ,s4_imag, ps_sg1_w[4]);
mult_add #(DATA_WIDTH, FRAC)mult_add1(r24_real, s4_imag, r24_imag ,s4_real, ps_sg1_w[5]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub2(r14_real, s4_real, r14_imag ,s4_imag, ps_sg1_w[6]);
mult_add #(DATA_WIDTH, FRAC)mult_add2(r14_real, s4_imag, r14_imag ,s4_real, ps_sg1_w[7]);
mult #(DATA_WIDTH, FRAC)mult2(r33_real, s3_real, ps_sg1_w[8]);
mult #(DATA_WIDTH, FRAC)mult3(r33_real, s3_imag, ps_sg1_w[9]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub3(r23_real, s3_real, r23_imag ,s3_imag, ps_sg1_w[10]);
mult_add #(DATA_WIDTH, FRAC)mult_add3(r23_real, s3_imag, r23_imag ,s3_real, ps_sg1_w[11]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub4(r13_real, s3_real, r13_imag ,s3_imag, ps_sg1_w[12]);
mult_add #(DATA_WIDTH, FRAC)mult_add4(r13_real, s3_imag, r13_imag ,s3_real, ps_sg1_w[13]);
mult #(DATA_WIDTH, FRAC)mult4(r22_real, s2_real, ps_sg1_w[14]);
mult #(DATA_WIDTH, FRAC)mult5(r22_real, s2_imag, ps_sg1_w[15]);
mult_sub #(DATA_WIDTH, FRAC)mult_sub5(r12_real, s2_real, r12_imag ,s2_imag, ps_sg1_w[16]);
mult_add #(DATA_WIDTH, FRAC)mult_add5(r12_real, s2_imag, r12_imag ,s2_real, ps_sg1_w[17]);
mult #(DATA_WIDTH, FRAC)mult6(r11_real, s1_real, ps_sg1_w[18]);
mult #(DATA_WIDTH, FRAC)mult7(r11_real, s1_imag, ps_sg1_w[19]);

always @(*) begin
    ps_sg2_w[0] = y_sg1_r[6] - ps_sg1_r[0]; // y4 - r44*s4 (done)
    ps_sg2_w[1] = y_sg1_r[7] - ps_sg1_r[1];
    ps_sg2_w[2] = y_sg1_r[4] - (ps_sg1_r[2] + ps_sg1_r[8]); // y3 - r34*s4 + r33*s3(done)
    ps_sg2_w[3] = y_sg1_r[5] - (ps_sg1_r[3] + ps_sg1_r[9]);
    ps_sg2_w[4] = (y_sg1_r[2] - ps_sg1_r[14]) - (ps_sg1_r[10] + ps_sg1_r[4]); // y2 - r22*s2 - (r23*s3 + r24*s4) (done)
    ps_sg2_w[5] = (y_sg1_r[3] - ps_sg1_r[15]) - (ps_sg1_r[11] + ps_sg1_r[5]);
    ps_sg2_w[6] = (ps_sg1_r[18] + ps_sg1_r[16]) + (ps_sg1_r[12] + ps_sg1_r[6]); // (r11*s1+r12*s2 + r13*s3 + r14*s4)
    ps_sg2_w[7] = (ps_sg1_r[19] + ps_sg1_r[17]) + (ps_sg1_r[13] + ps_sg1_r[7]); 
end

always @(*) begin
    y4_sub_real = y_sg2_r[0] - ps_sg2_r[6];
    y4_sub_imag = y_sg2_r[1] - ps_sg2_r[7];
end


always @(*) begin
    cnt_reg_w[0] = i_cnt;
    for(i = 1; i < 4; i=i+1) begin
        cnt_reg_w[i] = cnt_reg_r[i-1];
    end
end

wire [DATA_WIDTH-1:0] add_out;
mult_add #(DATA_WIDTH, FRAC)mult_add6(ps_sg2_r[0], ps_sg2_r[0], ps_sg2_r[1], ps_sg2_r[1], ps_sg3_w[0]);
mult_add #(DATA_WIDTH, FRAC)mult_add7(ps_sg2_r[2], ps_sg2_r[2], ps_sg2_r[3], ps_sg2_r[3], ps_sg3_w[1]);
mult_add #(DATA_WIDTH, FRAC)mult_add8(ps_sg2_r[4], ps_sg2_r[4], ps_sg2_r[5], ps_sg2_r[5], ps_sg3_w[2]);
mult #(DATA_WIDTH, FRAC)mult8(y4_sub_real, y4_sub_real, ps_sg3_w[3]);
mult #(DATA_WIDTH, FRAC)mult9(y4_sub_imag, y4_sub_imag, ps_sg3_w[4]);
assign add_out = ps_sg3_r[3] + ps_sg3_r[4];

always @(*) begin
    valid_sg_dy_w = {valid_sg_dy_r,i_enable};
    ps_sg4_w = ({2'd0,ps_sg3_r[0]} + {2'd0,ps_sg3_r[1]})+ ({2'd0,add_out} + {2'd0,ps_sg3_r[2]});
end



always @(*) begin
    y_sg1_w[0] = y1_real;
    y_sg1_w[1] = y1_imag;
    y_sg1_w[2] = y2_real;
    y_sg1_w[3] = y2_imag;
    y_sg1_w[4] = y3_real;
    y_sg1_w[5] = y3_imag;
    y_sg1_w[6] = y4_real;
    y_sg1_w[7] = y4_imag;
    y_sg2_w[0] = y_sg1_r[0];
    y_sg2_w[1] = y_sg1_r[1];
end

always @(posedge i_clk or posedge i_reset) begin
    if (i_reset) begin
        for(i = 0; i < 20; i = i + 1) ps_sg1_r[i] <= {DATA_WIDTH{1'b0}};
        for(i = 0; i < 8; i = i + 1)  ps_sg2_r[i] <= {DATA_WIDTH{1'b0}};
        for(i = 0; i < 5; i = i + 1)  ps_sg3_r[i] <= {DATA_WIDTH{1'b0}};
        for(i = 0; i < 8; i = i + 1) y_sg1_r[i] <= {DATA_WIDTH{1'b0}};
        for(i = 0; i < 2; i = i + 1) y_sg2_r[i] <= {DATA_WIDTH{1'b0}};
        for(i = 0; i < 4; i = i + 1) cnt_reg_r[i] <= {6{1'b0}};
        ps_sg4_r <= {1'b0,{DATA_WIDTH+1{1'b1}}};
        valid_sg_dy_r <= 3'd0;
    end else begin
        for(i = 0; i < 20; i = i + 1) ps_sg1_r[i] <= ps_sg1_w[i];
        for(i = 0; i < 8; i = i + 1)  ps_sg2_r[i] <= ps_sg2_w[i];
        for(i = 0; i < 5; i = i + 1)  ps_sg3_r[i] <= ps_sg3_w[i];
        for(i = 0; i < 8; i = i + 1)  y_sg1_r[i] <= y_sg1_w[i];
        for(i = 0; i < 2; i = i + 1)  y_sg2_r[i] <= y_sg2_w[i];
        for(i = 0; i < 4; i = i + 1) cnt_reg_r[i] <= cnt_reg_w[i];
        ps_sg4_r <= ps_sg4_w;
        valid_sg_dy_r <= valid_sg_dy_w;
    end
end

endmodule
