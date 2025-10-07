module inst_decoder #(
    parameter INST_W = 32
)(
    input  [INST_W-1:0] i_i_inst,
    output reg type,
    output isBranch,
    output [4:0] s1,
    output [4:0] s2,
    output [4:0] s3,
    output signed [15:0] im,
    output [5:0] opcode
);

assign s1 = (type) ? s3 : i_i_inst[15:11];
assign s2 = i_i_inst[25:21];
assign s3 = i_i_inst[20:16];
assign im = i_i_inst[15:0];
assign opcode = i_i_inst[31:26];
assign isBranch = (opcode[5:4] == 2'b01 || opcode[3:0] == 4'd10 || opcode[3:0] == 4'd11 || opcode[3:0] == 4'd15);

always @(*) begin
    case(opcode)
        6'd0, 6'd1, 6'd2, 6'd3, 6'd7, 6'd8, 6'd9, 6'd12, 6'd13, 6'd14: type = 1'b0; // R type
        default: type = 1'b1;
    endcase
end

endmodule
