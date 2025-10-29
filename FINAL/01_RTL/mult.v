module mult #(
    parameter DATA_WIDTH = 20,
    parameter FRAC = 16
)(
    input wire signed [DATA_WIDTH-1:0] a,
    input wire signed [DATA_WIDTH-1:0] b,
    output wire signed [DATA_WIDTH-1:0] out
);

wire signed [DATA_WIDTH*2-1:0] mult_out;

assign mult_out = $signed(a) * $signed(b);
assign out = mult_out[FRAC+:DATA_WIDTH];

endmodule
