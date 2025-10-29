module ml_data_path #(
    parameter DATA_WIDTH = 20
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_trig,
    input [159:0] i_y_hat,
    input [319:0] i_r,
    output wire [159:0] o_y_hat,
    output wire [319:0] o_r,
    output wire [5:0] o_cnt,
    output wire o_cu_en
);

reg [159:0] y_hat_w, y_hat_r;
reg [319:0] r_w, r_r;
reg [5:0] cnt_w, cnt_r;
// gray code
wire [3:0] gray_bits;
reg [5:0] gray_st_w, gray_st_r;
reg en_w, en_r;

assign o_r     = r_r;
assign o_y_hat = y_hat_r;
assign o_cu_en = en_r;
assign o_cnt   = cnt_r;

always @(*) begin
    if(i_trig) begin
        y_hat_w = i_y_hat;
        r_w   = i_r;
    end else begin
        y_hat_w = y_hat_r;
        r_w   = r_r;
    end
end

always @(*) begin
    gray_st_w = cnt_r;

    if(i_trig) begin
        en_w = 1'b1;
    end else if(cnt_r == 6'b100000) begin
        en_w = 1'b0;
    end else begin
        en_w = en_r;
    end
end

genvar i;
generate
    for(i = 2; i < 6; i = i + 1) begin
        if(i == 5) begin
            assign gray_bits[i-2] = ((cnt_r[i] & (~|cnt_r[i-1:0])) || ((gray_st_r[i] == cnt_r[i]) & (cnt_r[i-1] & ~(|cnt_r[i-2:0])))) ? ~cnt_r[i] : cnt_r[i];
        end else begin
            assign gray_bits[i-2] = ((gray_st_r[i] == cnt_r[i]) & (cnt_r[i-1] & ~(|cnt_r[i-2:0]))) ? ~cnt_r[i] : cnt_r[i];
        end
    end
endgenerate

always @(*) begin
    if(en_r) begin
        cnt_w[0] = (cnt_r[0] == gray_st_r[0]) ? ~cnt_r[0] : cnt_r[0];
        cnt_w[1] = (cnt_r[0] & ~gray_st_r[0]) ? ~cnt_r[1] : cnt_r[1];
        cnt_w[5:2] = gray_bits;
    end else begin
        cnt_w = 6'd0;
    end
end

// ----------------------------------------------------------
// Sequential Logic Section
// ----------------------------------------------------------
always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        cnt_r     <= 6'd0;
        en_r      <= 1'b0;
        gray_st_r <= 6'b0;
    end else begin
        cnt_r     <= cnt_w;
        en_r      <= en_w;
        gray_st_r <= gray_st_w;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        y_hat_r <= 160'd0;
        r_r     <= 320'd0;
    end else begin
        y_hat_r <= y_hat_w;
        r_r     <= r_w;
    end
end

endmodule
