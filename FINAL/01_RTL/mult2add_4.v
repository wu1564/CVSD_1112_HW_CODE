module mult2add_4 #(
    parameter ADD = 1,
    parameter DATA_WIDTH = 20,
    parameter FRAC = 16
)(
    input wire signed [DATA_WIDTH-1:0] a1,
    input wire s1, // s
    input wire signed [DATA_WIDTH-1:0] b1,
    input wire s2, // s
    output wire signed [DATA_WIDTH-1:0] out
);

wire signed [DATA_WIDTH-1:0] add_out_a;
wire signed [DATA_WIDTH-1:0] sign_a;
wire signed [DATA_WIDTH-1:0] add_out_b;
wire signed [DATA_WIDTH-1:0] sign_b;

assign add_out_a = ({{1{a1[DATA_WIDTH-1]}},a1[DATA_WIDTH-1:1]} + 
                   {{3{a1[DATA_WIDTH-1]}},a1[DATA_WIDTH-1:3]}) +
                   {{4{a1[DATA_WIDTH-1]}},a1[DATA_WIDTH-1:4]};
assign sign_a = (s1) ? ~add_out_a : add_out_a;

assign add_out_b = ({{1{b1[DATA_WIDTH-1]}},b1[DATA_WIDTH-1:1]} + 
                   {{3{b1[DATA_WIDTH-1]}},b1[DATA_WIDTH-1:3]}) +
                   {{4{b1[DATA_WIDTH-1]}},b1[DATA_WIDTH-1:4]};
assign sign_b = (s2) ? ~add_out_b : add_out_b;

generate
    if(ADD) begin
        assign out = sign_a + sign_b;
    end else begin
        assign out = sign_a + ~sign_b;
    end
endgenerate

endmodule













// 310]

// 397]

// 544

// 755]


