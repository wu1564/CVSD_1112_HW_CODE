module alu #(
    parameter INT_W  = 4,
    parameter FRAC_W = 6,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input                     i_valid,
    input signed [DATA_W-1:0] i_data_a, // 10bits 4bits integer and 6 bits fraction
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output       [DATA_W-1:0] o_data
); // Do not modify

localparam IDLE =  0;
localparam ADD  =  1;
localparam SUB  =  2;
localparam MULT =  3;
localparam MAC  =  4;
localparam TANH =  5;
localparam ORN  =  6;
localparam CLZ  =  7;
localparam CTZ  =  8;
localparam CPOP =  9;
localparam ROL  = 10;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg [DATA_W-1:0] o_data_w, o_data_r;
reg              o_valid_w, o_valid_r;
// ---- Add your own wires and registers here if needed ---- //
// adder
wire signed [DATA_W-1:0] neg_i_data_b;
wire signed [DATA_W+INT_W-1:0] add;
reg  signed [DATA_W+INT_W-1:0] add_in0, add_in1;
reg  signed [DATA_W+INT_W-1:0] add_out;
// multiplier
wire signed [DATA_W*2-1:0] mult;
reg  signed [DATA_W-1:0] mult_in0, mult_in1;
reg  signed [DATA_W+INT_W-1:0] mult_out;
wire negative;
// comparison
wire compare;
wire compare2;
reg  signed [DATA_W+INT_W-1:0] compare_in0, compare_in1;
// overflow flag
wire overflow_w;
reg  overflow_r;
reg  adder_overflow;
// counter
reg  [3:0] cnt_r, cnt_w;
// state machine
reg  [4:0] ns, ps;
//
reg  [1:0] count_num;
reg  count_done;
integer i;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// output signal
assign o_valid = o_valid_r;
assign o_data = o_data_r;
// ---- Add your own wire data assignments here if needed ---- //

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
assign overflow_w = (i_valid && i_inst < 4'd4) ? compare | adder_overflow : o_data_r;

// adder
assign neg_i_data_b = ~i_data_b + 1'b1;
assign add = add_in0 + add_in1;
always @(*) begin
    adder_overflow = 0;
    if(i_inst == 4'd1) begin // subtract
        add_in0 = {{INT_W{i_data_a[DATA_W-1]}}, i_data_a};
        add_in1 = {{INT_W{neg_i_data_b[DATA_W-1]}},neg_i_data_b};
        if(i_data_a[DATA_W-1] && !i_data_b[DATA_W-1] && !add[DATA_W-1]) begin
            add_out = 10'b10_0000_0000;
            adder_overflow = 1'b1;
        end else if(!i_data_a[DATA_W-1] && i_data_b[DATA_W-1] && add[DATA_W-1]) begin
            add_out = 10'b01_1111_1111;
            adder_overflow = 1'b1;
        end else begin
            add_out = add;
        end
    end else begin
        if(i_inst == 4'd3) begin
            add_in0 = mult_out;
            add_in1 = $signed({{4{o_data_r[DATA_W-1]}}, o_data_r});
        end else if(i_inst == 4'd4) begin
            add_in0 = mult_out;
            add_in1 = (cnt_r == 4'd2) ? $signed({5'd0,1'b1,4'd0}) : $signed({{6{1'b1}},4'd0});
        end else begin
            add_in0 = {{INT_W{i_data_a[DATA_W-1]}}, i_data_a};
            add_in1 = {{INT_W{i_data_b[DATA_W-1]}}, i_data_b};
        end
        if(!add_in0[DATA_W+INT_W-1] && !add_in1[DATA_W+INT_W-1] && add[DATA_W-1]) begin
            add_out = 10'b01_1111_1111;
            adder_overflow = 1'b1;
        end else if(add_in0[DATA_W+INT_W-1] && add_in1[DATA_W+INT_W-1] && !add[DATA_W-1]) begin
            add_out = 10'b10_0000_0000;
            adder_overflow = 1'b1;
        end else begin
            add_out = add;
        end
    end
end

// Comparator
assign compare = (compare_in0 > compare_in1) ? 1'b1 : 1'b0;
assign compare2 = ($signed(add) < $signed(14'sb1111_1000_0000_00));
always @(*) begin
    case(i_inst)
        4'd2: begin
            if(negative) begin
                compare_in0 = 10'sb10_0000_0000;
                compare_in1 = $signed(mult[19:6]);
            end else begin
                compare_in0 = $signed(mult[19:6]);
                compare_in1 = 10'sb01_1111_1111;
            end  
        end
        4'd4: begin
            compare_in0 = i_data_a;
            case(cnt_r)
                4'd0: compare_in1 = 10'sb0001_100000;
                4'd2: compare_in1 = $signed({{4{1'b0}},1'b1,{5{1'b0}}});
                4'd4: compare_in1 = $signed({{5{1'b1}},{5{1'b0}}});
                4'd6: compare_in1 = $signed({{3{1'b1}},2'b01,{5{1'b0}}});
                default: begin
                    compare_in1 = 14'd0;
                end
            endcase
        end
        default: begin
            compare_in0 = add;
            compare_in1 = 14'sb00_0001_1111_1111;
        end
    endcase
end

// multiplier
assign mult = $signed(mult_in0) * $signed(mult_in1);
assign negative = i_data_a[9] ^ i_data_b[9];
always @(*) begin
    if(compare && i_inst != 4'd3 && i_inst != 4'd4) begin
        mult_out = (negative) ? 14'sb1111_10_0000_0000 : 14'sb0000_01_1111_1111;
    end else begin
        mult_out = $signed(mult[19:6] + mult[5]);
    end
end

always @(*) begin
    mult_in0 = i_data_a;
    if(i_inst != 4'd4) begin
        mult_in1 = i_data_b;
    end else begin
        mult_in1 = $signed({{4{1'b0}},1'b1,{5{1'b0}}}); // 0.5
    end
end

//counter
always @(*) begin
    case(ps)
        CLZ, CTZ, CPOP, TANH: cnt_w = (cnt_r == 4'd8 || count_done) ? 4'd0 : cnt_r + 4'd2;
        default:   cnt_w = 4'd0;
    endcase
end

// output data
always@(*) begin
    if(i_valid) begin
        case(i_inst)
            4'd6, 4'd7, 4'd8: begin
                o_data_w = 10'd0; // count bits
                o_valid_w = 1'b0;
            end
            default: begin
                o_data_w = o_data_r;
                o_valid_w = 1'b0;
            end
        endcase
    end else begin
        case(ps)
            ADD, SUB: begin
                o_data_w = $unsigned(add_out);
                o_valid_w = 1'b1;
            end
            MULT: begin
                o_data_w = $unsigned(mult_out);
                o_valid_w = 1'b1;
            end
            MAC: begin
                o_valid_w = 1'b1;
                case(1'b1)
                    compare:  o_data_w = 10'b01_1111_1111;
                    compare2: o_data_w = 10'b10_0000_0000;
                    default:  o_data_w = add[DATA_W-1:0];
                endcase
            end
            TANH: begin
                if(count_done) begin 
                    o_valid_w = 1'b1;
                    case(cnt_r)
                        4'd0:    o_data_w = $signed({{3{1'b0}}, 1'b1, {6{1'b0}}});
                        4'd2, 4'd6: o_data_w = add[9:0];
                        4'd4:    o_data_w = i_data_a;
                        4'd8:    o_data_w = $signed({{4{1'b1}},{6{1'b0}}});
                        default: o_data_w = 10'd0;
                    endcase
                end else begin
                    o_valid_w = 1'b0;
                    o_data_w = 10'd0;                    
                end
            end
            ORN: begin
                o_data_w = i_data_a | (~i_data_b);
                o_valid_w = 1'b1;
            end
            CLZ, CTZ, CPOP: begin
                o_data_w = o_data_r + count_num;
                o_valid_w = count_done;
            end
            ROL: begin
                for(i = DATA_W-1; i >= i_data_b; i = i - 1) begin
                    o_data_w[i] = i_data_a[i-i_data_b];
                end
                for(i = 0; i < i_data_b; i = i + 1) begin
                    o_data_w[i_data_b-i-1] = i_data_a[DATA_W-1-i];
                end
                o_valid_w = 1'b1;
            end
            default: begin
                o_valid_w = 1'b0;
                o_data_w = o_data_r;
            end
        endcase
    end
end

always @(*) begin
    case(ps)
        CLZ: begin
            case({i_data_a[9-cnt_r], i_data_a[8-cnt_r]})
                2'd0: begin
                    count_num = 2'd2;
                    count_done = 1'b0;
                end
                2'd1: begin
                    count_num = 2'd1;
                    count_done = 1'b1;
                end
                2'd2: begin
                    count_num = 2'd0;
                    count_done = 1'b1;
                end
                default: begin
                    count_num = 2'd0;
                    count_done = 1'b1;
                end
            endcase
        end
        CTZ: begin
            case({i_data_a[cnt_r+1], i_data_a[cnt_r]})
                2'd0: begin
                    count_done = 1'd0;
                    count_num = 2'd2;
                end
                2'd1: begin
                    count_done = 1'd1;
                    count_num = 2'd0;
                end
                2'd2: begin
                    count_done = 1'd1;
                    count_num = 2'd1;
                end
                default: begin
                    count_done = 1'b1;
                    count_num = 2'd0;
                end
            endcase 
        end
        CPOP: begin
            count_done = (cnt_r == 4'd8);
            case({i_data_a[cnt_r], i_data_a[cnt_r+1]})
                2'b00:    count_num = 2'd0;
                2'b01, 2'b10: count_num = 2'd1;
                2'b11:    count_num = 2'd2;
                default:  count_num = 2'd0;
            endcase
        end
        TANH: begin
            count_num = 2'd0;
            count_done = (compare || (cnt_r == 4'd8));
        end
        default: begin
            count_num = 2'd0;
            count_done = 1'b0;
        end
    endcase
end

// state machine
always @(*) begin
    case (ps)
        IDLE: begin
            if(i_valid) begin
                ns = i_inst + 1'b1;
            end else begin
                ns = IDLE;
            end
        end
        CTZ, CLZ, CPOP, TANH: ns = (count_done) ? IDLE : ps;
        default: ns = IDLE;
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        cnt_r <= 4'd0;
    end else begin
        cnt_r <= cnt_w;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        overflow_r <= 1'b0;
    end else begin
        overflow_r <= overflow_w;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ps <= IDLE;
    end else begin
        ps <= ns;
    end
end

always@(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_data_r <= 0;
        o_valid_r <= 0;
    end else begin
        o_data_r <= o_data_w;
        o_valid_r <= o_valid_w;
    end
end

endmodule
