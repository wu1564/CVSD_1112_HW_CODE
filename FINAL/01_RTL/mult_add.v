module mult_add #(
    parameter ADD = 1,
    parameter DATA_WIDTH = 20,
    parameter FRAC = 16
)(
    input wire signed [DATA_WIDTH-1:0] a1,
    input wire signed [DATA_WIDTH-1:0] a2,
    input wire signed [DATA_WIDTH-1:0] b1,
    input wire signed [DATA_WIDTH-1:0] b2,
    output wire signed [DATA_WIDTH-1:0] out
);

wire signed [DATA_WIDTH*2-1:0] mult_out0;
wire signed [DATA_WIDTH*2-1:0] mult_out1;

assign mult_out0 = $signed(a1) * $signed(a2);
assign mult_out1 = $signed(b1) * $signed(b2);

generate
    if(ADD) begin
        assign out = mult_out0[FRAC+:DATA_WIDTH] + mult_out1[FRAC+:DATA_WIDTH];
    end else begin
        assign out = mult_out0[FRAC+:DATA_WIDTH] + ~mult_out1[FRAC+:DATA_WIDTH];
    end
endgenerate

endmodule
