module ml_demodulator(
    i_clk,
    i_reset,
    i_trig,
    i_y_hat,
    i_r,
    i_rd_rdy,
    o_rd_vld,
    o_llr,
    o_hard_bit
);

localparam FRAC = 16;
localparam REAL =  4;
localparam DATA_WIDTH = FRAC + REAL;

// IO description
input wire i_clk;
input wire i_reset;
input wire i_trig;
input wire [159:0] i_y_hat;
input wire [319:0] i_r;
input wire i_rd_rdy;
output wire o_rd_vld;
output wire [7:0] o_llr;
output wire o_hard_bit;

// data path output
wire [159:0] o_dp_y_hat;
wire [319:0] o_dp_r;
wire [5:0]   o_dp_cnt;
wire         o_dp_cu_en;
// X output
wire o_x_valid;
wire [7:0] o_x_hardbit;
//

ml_data_path #(
    .DATA_WIDTH(DATA_WIDTH)
)data_path(
    .i_clk  (i_clk),
    .i_reset(i_reset),
    .i_trig (i_trig),
    .i_y_hat(i_y_hat),
    .i_r    (i_r),
    .o_y_hat(o_dp_y_hat),
    .o_r    (o_dp_r),
    .o_cnt  (o_dp_cnt),
    .o_cu_en(o_dp_cu_en)
);

ml_x #(
    .DATA_WIDTH(DATA_WIDTH)
)ml_x_inst(
    .i_clk   (i_clk),
    .i_reset (i_reset),
    .i_y_hat (o_dp_y_hat),
    .i_r     (o_dp_r),
    .cnt     (o_dp_cnt),
    .i_enable(o_dp_cu_en),
    // LLR output
    .o_valid (o_x_valid),
    .o_x_hardbit(o_x_hardbit)
);

ml_controller #(
    .DATA_WIDTH(8),
    .DEPTH(16)
)ml_controller_ins(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_rd_rdy(i_rd_rdy),
    // x output
    .i_x_valid(o_x_valid),
    .i_x_hard_bit(o_x_hardbit),
    .o_rd_vld(o_rd_vld),
    .o_hard_bit(o_hard_bit)
);

endmodule