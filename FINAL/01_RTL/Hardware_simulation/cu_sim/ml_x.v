// cd D:\\Hardware\\IC\\NTU_CVSD\\CVSD_111_2\\111-2_HW\\FINAL\\final_project\\01_RTL\\simulation\
// vlog -reportprogress 300 ./cu_tb.v ./ml_cu.v ./mult.v ./mult_add.v ./mult_sub.v ./x1.v
module ml_x #(
    parameter DATA_WIDTH = 20
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_enable,
    input [159:0] i_y_hat;
    input [319:0] i_r;
    input wire [5:0] cnt,
    // LLR output
    output wire o_valid,
    output wire [DATA_WIDTH+1:0] o_llr_x11,
    output wire [DATA_WIDTH+1:0] o_llr_x12,
    output wire [DATA_WIDTH+1:0] o_llr_x21,
    output wire [DATA_WIDTH+1:0] o_llr_x22,
    output wire [DATA_WIDTH+1:0] o_llr_x31,
    output wire [DATA_WIDTH+1:0] o_llr_x32,
    output wire [DATA_WIDTH+1:0] o_llr_x41,
    output wire [DATA_WIDTH+1:0] o_llr_x42
);

// cu input
// y_hat
wire [DATA_WIDTH-1:0] y1_real;
wire [DATA_WIDTH-1:0] y1_imag;
wire [DATA_WIDTH-1:0] y2_real;
wire [DATA_WIDTH-1:0] y2_imag;
wire [DATA_WIDTH-1:0] y3_real;
wire [DATA_WIDTH-1:0] y3_imag;
wire [DATA_WIDTH-1:0] y4_real;
wire [DATA_WIDTH-1:0] y4_imag;
// r parameters
wire [DATA_WIDTH-1:0] r11_real;
wire [DATA_WIDTH-1:0] r12_real;
wire [DATA_WIDTH-1:0] r12_imag;
wire [DATA_WIDTH-1:0] r22_real;
wire [DATA_WIDTH-1:0] r13_real;
wire [DATA_WIDTH-1:0] r13_imag;
wire [DATA_WIDTH-1:0] r23_real;
wire [DATA_WIDTH-1:0] r23_imag;
wire [DATA_WIDTH-1:0] r33_real;
wire [DATA_WIDTH-1:0] r14_real;
wire [DATA_WIDTH-1:0] r14_imag;
wire [DATA_WIDTH-1:0] r24_real;
wire [DATA_WIDTH-1:0] r24_imag;
wire [DATA_WIDTH-1:0] r34_real;
wire [DATA_WIDTH-1:0] r34_imag;
wire [DATA_WIDTH-1:0] r44_real;
wire signed [DATA_WIDTH-1:0] quadrant_real[0:3];
wire signed [DATA_WIDTH-1:0] quadrant_imag[0:3];
// cu output
wire o_cu_valid;
wire [5:0] o_cu_cnt;
wire signed [DATA_WIDTH+1:0] o_cu_llr[0:3];
// x output
wire signed [DATA_WIDTH+1:0] o_llr_1[0:3];
wire signed [DATA_WIDTH+1:0] o_llr_2[0:3];
// control signal
reg [5:0] done_dy_w, done_dy_r;
wire [1:0] s2_cnt;
wire [1:0] s3_cnt;
wire [1:0] s4_cnt;
// comparotors
reg [DATA_WIDTH+1:0] comp_x00_01_w, comp_x11_10_w, comp_min_w;

// Cu input
assign y1_real = i_y_hat[19:0];
assign y1_imag = i_y_hat[39:20];
assign y2_real = i_y_hat[59:40];
assign y2_imag = i_y_hat[79:60];
assign y3_real = i_y_hat[99:80];
assign y3_imag = i_y_hat[119:100];
assign y4_real = i_y_hat[139:120];
assign y4_imag = i_y_hat[159:140];
assign // r parameters
assign r11_real = i_r[19:0];
assign r12_real = i_r[39:20];
assign r12_imag = i_r[59:40];
assign r22_real = i_r[79:60];
assign r13_real = i_r[99:80];
assign r13_imag = i_r[119:100];
assign r23_real = i_r[139:120];
assign r23_imag = i_r[159:140];
assign r33_real = i_r[179:160];
assign r14_real = i_r[199:180];
assign r14_imag = i_r[219:200];
assign r24_real = i_r[239:220];
assign r24_imag = i_r[259:240];
assign r34_real = i_r[279:260];
assign r34_imag = i_r[299:280];
assign r44_real = i_r[319:300];
assign quadrant_real[0] =  20'd46341; // (0,0)
assign quadrant_imag[0] =  20'd46341; 
assign quadrant_real[1] =  20'd46341; // (0,1)
assign quadrant_imag[1] = -20'd46341;
assign quadrant_real[2] = -20'd46341; // (1,0)
assign quadrant_imag[2] =  20'd46341; 
assign quadrant_real[3] = -20'd46341; // (1,1)
assign quadrant_imag[3] = -20'd46341; 
//
assign s4_cnt = cnt[1:0];
assign s3_cnt = cnt[3:2];
assign s2_cnt = cnt[5:4];
//
assign o_valid = done_dy_r[4];
// X output
assign o_llr_x11 = o_llr_1[0];
assign o_llr_x12 = o_llr_2[0];
assign o_llr_x21 = o_llr_1[1];
assign o_llr_x22 = o_llr_2[1];
assign o_llr_x31 = o_llr_1[2];
assign o_llr_x32 = o_llr_2[2];
assign o_llr_x41 = o_llr_1[3];
assign o_llr_x42 = o_llr_2[3];

genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin:x
        wire [1:0] cnt_t;
        wire comp_out0_x;
        wire comp_out1_x;
        wire comp_out2_x;
        wire comp_out3_x;
        wire [DATA_WIDTH+1:0] minLLR_final_x11;
        wire [DATA_WIDTH+1:0] minLLR_final_x10;
        wire [DATA_WIDTH+1:0] minLLR_final_x21;
        wire [DATA_WIDTH+1:0] minLLR_final_x20;
        reg  [DATA_WIDTH+1:0] minLLR_x11_w, minLLR_x11_r;
        reg  [DATA_WIDTH+1:0] minLLR_x10_w, minLLR_x10_r;
        reg  [DATA_WIDTH+1:0] minLLR_x01_w, minLLR_x01_r;
        reg  [DATA_WIDTH+1:0] minLLR_x00_w, minLLR_x00_r;

        // x1 - bit1
        assign minLLR_final_x11 = ($unsigned(minLLR_x10_r) < $unsigned(minLLR_x11_r)) ? minLLR_x10_r : minLLR_x11_r;
        assign minLLR_final_x10 = ($unsigned(minLLR_x00_r) < $unsigned(minLLR_x01_r)) ? minLLR_x00_r : minLLR_x01_r;
        assign o_llr_1[i] = (o_valid) ? ($signed({1'b0, minLLR_final_x11}) - $signed({1'b0, minLLR_final_x10})) : {DATA_WIDTH+1{1'b0}};

        assign minLLR_final_x21 = ($unsigned(minLLR_x01_r) < $unsigned(minLLR_x11_r)) ? minLLR_x01_r : minLLR_x11_r;
        assign minLLR_final_x20 = ($unsigned(minLLR_x00_r) < $unsigned(minLLR_x10_r)) ? minLLR_x00_r : minLLR_x10_r;
        assign o_llr_2[i] = (o_valid) ? ($signed({1'b0, minLLR_final_x21}) - $signed({1'b0, minLLR_final_x20})) : {DATA_WIDTH+1{1'b0}};

        if(i == 0) begin
            assign comp_out0_x = ($unsigned(o_cu_llr[0]) < $unsigned(minLLR_x00_r));
            assign comp_out1_x = ($unsigned(o_cu_llr[1]) < $unsigned(minLLR_x01_r));
            assign comp_out2_x = ($unsigned(o_cu_llr[2]) < $unsigned(minLLR_x10_r));
            assign comp_out3_x = ($unsigned(o_cu_llr[3]) < $unsigned(minLLR_x11_r));
            always @(*) begin
                if(done_dy_r[4]) begin
                    minLLR_x11_w = o_cu_llr[3];
                    minLLR_x10_w = o_cu_llr[2];
                    minLLR_x01_w = o_cu_llr[1];
                    minLLR_x00_w = o_cu_llr[0];
                end else begin
                    minLLR_x11_w = (o_cu_valid & comp_out3_x) ? o_cu_llr[3] : minLLR_x11_r;
                    minLLR_x10_w = (o_cu_valid & comp_out2_x) ? o_cu_llr[2] : minLLR_x10_r;
                    minLLR_x01_w = (o_cu_valid & comp_out1_x) ? o_cu_llr[1] : minLLR_x01_r;
                    minLLR_x00_w = (o_cu_valid & comp_out0_x) ? o_cu_llr[0] : minLLR_x00_r;
                end
            end
        end else begin
            assign cnt_t = o_cu_cnt[(5-2*(i-1)):(4-2*(i-1))];
            assign comp_out0_x = ($unsigned(comp_min_w) < $unsigned(minLLR_x00_r));
            assign comp_out1_x = ($unsigned(comp_min_w) < $unsigned(minLLR_x01_r));
            assign comp_out2_x = ($unsigned(comp_min_w) < $unsigned(minLLR_x10_r));
            assign comp_out3_x = ($unsigned(comp_min_w) < $unsigned(minLLR_x11_r));
            always @(*) begin
                if(done_dy_r[4]) begin
                    minLLR_x11_w = {1'b0, {DATA_WIDTH+1{1'b1}}};
                    minLLR_x10_w = {1'b0, {DATA_WIDTH+1{1'b1}}};
                    minLLR_x01_w = {1'b0, {DATA_WIDTH+1{1'b1}}};
                    minLLR_x00_w = comp_min_w;
                end else begin
                    minLLR_x11_w = (o_cu_valid && cnt_t == 2'd3 && comp_out3_x) ? comp_min_w : minLLR_x11_r;
                    minLLR_x10_w = (o_cu_valid && cnt_t == 2'd2 && comp_out2_x) ? comp_min_w : minLLR_x10_r;
                    minLLR_x01_w = (o_cu_valid && cnt_t == 2'd1 && comp_out1_x) ? comp_min_w : minLLR_x01_r;
                    minLLR_x00_w = (o_cu_valid && cnt_t == 2'd0 && comp_out0_x) ? comp_min_w : minLLR_x00_r;
                end
            end
        end
        always @(posedge i_clk or posedge i_reset) begin
            if(i_reset) begin
                minLLR_x11_r <= {1'b0,{DATA_WIDTH+1{1'b1}}};
                minLLR_x10_r <= {1'b0,{DATA_WIDTH+1{1'b1}}};
                minLLR_x00_r <= {1'b0,{DATA_WIDTH+1{1'b1}}};
                minLLR_x01_r <= {1'b0,{DATA_WIDTH+1{1'b1}}};
            end else begin
                minLLR_x11_r <= minLLR_x11_w;
                minLLR_x10_r <= minLLR_x10_w;
                minLLR_x00_r <= minLLR_x00_w;
                minLLR_x01_r <= minLLR_x01_w;
            end
        end
    end
endgenerate

//-------------------------------------------------------------------------------------------
ml_cu_valid #(
    .DATA_WIDTH(DATA_WIDTH)
)cu_x11_11(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_enable(i_enable),
    .i_cnt(cnt),
    // y_hat
    .y1_real(y1_real),
    .y1_imag(y1_imag),
    .y2_real(y2_real),
    .y2_imag(y2_imag),
    .y3_real(y3_real),
    .y3_imag(y3_imag),
    .y4_real(y4_real),
    .y4_imag(y4_imag),
    // r parameters
    .r11_real(r11_real),
    .r12_real(r12_real),
    .r12_imag(r12_imag),
    .r22_real(r22_real),
    .r13_real(r13_real),
    .r13_imag(r13_imag),
    .r23_real(r23_real),
    .r23_imag(r23_imag),
    .r33_real(r33_real),
    .r14_real(r14_real),
    .r14_imag(r14_imag),
    .r24_real(r24_real),
    .r24_imag(r24_imag),
    .r34_real(r34_real),
    .r34_imag(r34_imag),
    .r44_real(r44_real),
    .o_valid(o_cu_valid),
    .o_llr(o_cu_llr[3]),
    .o_cnt(o_cu_cnt),
    // r
    .s1_real(quadrant_real[3]),
    .s1_imag(quadrant_imag[3]),
    .s2_real(quadrant_real[s2_cnt]),
    .s2_imag(quadrant_imag[s2_cnt]),
    .s3_real(quadrant_real[s3_cnt]),
    .s3_imag(quadrant_imag[s3_cnt]),
    .s4_real(quadrant_real[s4_cnt]),
    .s4_imag(quadrant_imag[s4_cnt])
);

genvar j;
generate
    for(j = 0; j < 3; j = j + 1) begin:ml_cu
        ml_cu #(
            .DATA_WIDTH(DATA_WIDTH)
        )cu_inst(
            .i_clk(i_clk),
            .i_reset(i_reset),
            // y_hat
            .y1_real(y1_real),
            .y1_imag(y1_imag),
            .y2_real(y2_real),
            .y2_imag(y2_imag),
            .y3_real(y3_real),
            .y3_imag(y3_imag),
            .y4_real(y4_real),
            .y4_imag(y4_imag),
            // r parameters
            .r11_real(r11_real),
            .r12_real(r12_real),
            .r12_imag(r12_imag),
            .r22_real(r22_real),
            .r13_real(r13_real),
            .r13_imag(r13_imag),
            .r23_real(r23_real),
            .r23_imag(r23_imag),
            .r33_real(r33_real),
            .r14_real(r14_real),
            .r14_imag(r14_imag),
            .r24_real(r24_real),
            .r24_imag(r24_imag),
            .r34_real(r34_real),
            .r34_imag(r34_imag),
            .r44_real(r44_real),
            .o_llr(o_cu_llr[j]),
            // r
            .s1_real(quadrant_real[j]),
            .s1_imag(quadrant_imag[j]),
            .s2_real(quadrant_real[s2_cnt]),
            .s2_imag(quadrant_imag[s2_cnt]),
            .s3_real(quadrant_real[s3_cnt]),
            .s3_imag(quadrant_imag[s3_cnt]),
            .s4_real(quadrant_real[s4_cnt]),
            .s4_imag(quadrant_imag[s4_cnt])
        );
    end
endgenerate

//-------------------------------------------------------------------------------------------

always @(*) begin
    done_dy_w = {done_dy_r, (cnt == 6'd63)};
    comp_x00_01_w = ($unsigned(o_cu_llr[0]) < $unsigned(o_cu_llr[1])) ? o_cu_llr[0] : o_cu_llr[1];
    comp_x11_10_w = ($unsigned(o_cu_llr[3]) < $unsigned(o_cu_llr[2])) ? o_cu_llr[3] : o_cu_llr[2];
    comp_min_w    = ($unsigned(comp_x00_01_w) < $unsigned(comp_x11_10_w)) ? comp_x00_01_w : comp_x11_10_w;
end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        done_dy_r <= 5'd0;
    end else begin
        done_dy_r <= done_dy_w;
    end
end

endmodule
