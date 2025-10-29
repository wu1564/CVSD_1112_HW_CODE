module mult2add_2 #(
    parameter DATA_WIDTH = 20,
    parameter FRAC = 16
)(
    input wire signed [DATA_WIDTH-1:0] a,
    input wire s,
    output wire signed [DATA_WIDTH-1:0] out
);

wire signed [DATA_WIDTH-1:0] add_out;

assign add_out = {{1{a[DATA_WIDTH-1]}},a[DATA_WIDTH-1:1]} + 
                 {{3{a[DATA_WIDTH-1]}},a[DATA_WIDTH-1:3]} +
                 {{4{a[DATA_WIDTH-1]}},a[DATA_WIDTH-1:4]};
assign out = (s) ? ~add_out : add_out;

endmodule
