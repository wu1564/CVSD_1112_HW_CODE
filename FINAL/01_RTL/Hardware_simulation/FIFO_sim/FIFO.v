module FIFO #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire i_clk,
    input wire i_reset,
    input wire i_wen,
    input wire i_ren,
    input wire [DATA_WIDTH-1:0] i_wdata,
    output wire o_full,
    output wire o_empty,
    output wire o_valid,
    output wire [DATA_WIDTH-1:0] o_rdata
);

wire write, read;
wire full, empty;
reg valid_w, valid_r;
reg [clog2(DEPTH):0] w_ptr_r, w_ptr_w;
reg [clog2(DEPTH):0] r_ptr_r, r_ptr_w;
reg [DATA_WIDTH-1:0] mem_w[0:DEPTH-1], mem_r[0:DEPTH-1];
reg [DATA_WIDTH-1:0] o_rdata_w, o_rdata_r;
integer i;

assign write = ~full & i_wen;
assign read  = ~empty & i_ren;
assign full = ({~w_ptr_r[clog2(DEPTH)], w_ptr_r[clog2(DEPTH)-1:0]} == r_ptr_r);
assign empty = (w_ptr_r == r_ptr_r);
// output
assign o_valid = valid_r;
assign o_full = full;
assign o_empty = empty;
assign o_rdata = o_rdata_r;

always @(*) begin
    for(i = 0; i < DEPTH; i = i + 1) mem_w[i] = mem_r[i];
    if(write) begin
        mem_w[w_ptr_r[clog2(DEPTH)-1:0]] = i_wdata;
    end
    if(read) begin
        o_rdata_w = mem_r[r_ptr_r[clog2(DEPTH)-1:0]];
    end else begin
        o_rdata_w = 0;
    end
end

always @(*) begin
    if(write) begin
        w_ptr_w = w_ptr_r + 1;
    end else begin
        w_ptr_w = w_ptr_r;
    end
    if(read) begin
        valid_w = 1'b1;
        r_ptr_w = r_ptr_r + 1;
    end else begin
        valid_w = 1'b0;
        r_ptr_w = r_ptr_r;
    end

end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        for(i = 0; i < DEPTH; i = i + 1) mem_r[i] = 0;
        valid_r <= 1'b0;
        w_ptr_r <= 0;
        r_ptr_r <= 0;
        o_rdata_r <= 0;
    end else begin
        for(i = 0; i < DEPTH; i = i + 1) mem_r[i] = mem_w[i];
        valid_r <= valid_w;
        w_ptr_r <= w_ptr_w;
        r_ptr_r <= r_ptr_w;
        o_rdata_r <= o_rdata_w;
    end
end

function integer clog2;
    input integer value;
    begin
        value = value - 1;
        for (clog2 = 0; value > 0; clog2 = clog2 + 1)
            value = value >> 1;
    end
endfunction

endmodule

