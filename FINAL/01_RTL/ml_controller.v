module ml_controller #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    i_clk,
    i_reset,
    i_rd_rdy,
    // x output
    i_x_valid,
    i_x_hard_bit,
    o_rd_vld,
    o_hard_bit
);

input wire i_clk;
input wire i_reset;
input wire i_rd_rdy;
// x outp
input wire i_x_valid;
input wire [7:0] i_x_hard_bit;
output wire o_rd_vld;
output wire o_hard_bit;

// fifo w/r
wire o_fifo_full;
wire o_fifo_empty;
reg wen_r, wen_w;
reg ren_r, ren_w;
// output
wire next_bit;
wire next_harbit;
wire [7:0] o_fifo_rdata;
reg o_rd_vld_w, o_rd_vld_r;
reg [7:0] o_hard_bit_w, o_hard_bit_r;
reg [2:0] cnt_w, cnt_r;

assign next_bit = i_rd_rdy & o_rd_vld;
assign next_harbit = (next_bit && (cnt_r == 3'd7));
// ml output
assign o_rd_vld = o_rd_vld_r;
assign o_hard_bit = o_hard_bit_r[0];

FIFO #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
)ml_output_fifo(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_wen(wen_r),
    .i_ren(ren_w),
    .i_wdata(i_x_hard_bit),
    .o_full(o_fifo_full),
    .o_empty(o_fifo_empty),
    .o_rdata(o_fifo_rdata)
);

// fifo control
always @(*) begin
    // the present is sending data and there's new data coming up
    if(i_x_valid & o_rd_vld & ~o_fifo_full) begin
        wen_w = 1'b1;
    end else begin
        wen_w = 1'b0;
    end

    // next hardbit => the present is sending data
    //(i_rd_rdy && ~o_rd_vld) => the time is done sending data but there's data in FIFO 
    if((i_rd_rdy && ((o_rd_vld && cnt_r == 3'd7) || ~o_rd_vld)) & ~o_fifo_empty) begin
        ren_w = 1'b1;
    end else begin
        ren_w = 1'b0;
    end

    if(next_bit) begin
        cnt_w = cnt_r + 3'd1;
    end else begin
        cnt_w = cnt_r;
    end
end

always @(*) begin
    // if fifo is empy and there's new data output uses x's output
    // if fifo is not emty and ready to pop data, then output uses fifo rdata
    if(o_fifo_empty & i_x_valid & ~o_rd_vld) begin
        o_hard_bit_w = i_x_hard_bit;
    end else if(ren_w) begin
        o_hard_bit_w = o_fifo_rdata;
    end else if(next_bit) begin
        o_hard_bit_w = {1'b0,o_hard_bit_r[7:1]};
    end else begin
        o_hard_bit_w = o_hard_bit_r;
    end

    // next_harbit & o_fifo_empty => if it's done sending data and there's no data in fifo then stop. wait for new data
    // i_x_valid || ren_w || !o_fifo_empty => if new data coming up or fifo has data or ready to read next data
    if(next_harbit & o_fifo_empty) begin
        o_rd_vld_w = 1'b0;
    end else if(i_x_valid | ren_w) begin
        o_rd_vld_w = 1'b1;
    end else begin
        o_rd_vld_w = o_rd_vld_r;
    end
end

// ----------------------------------------------------------
// Sequential Logic Section
// ----------------------------------------------------------
always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        ren_r <= 1'b0;
        wen_r <= 1'b0;
    end else begin
        ren_r <= ren_w;
        wen_r <= wen_w;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        cnt_r        <= 3'd0;
        o_rd_vld_r   <= 1'b0;
        o_hard_bit_r <= 8'd0;
    end else begin
        cnt_r        <= cnt_w;
        o_rd_vld_r   <= o_rd_vld_w;
        o_hard_bit_r <= o_hard_bit_w;
    end
end

endmodule
