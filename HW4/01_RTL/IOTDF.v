`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [3:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

localparam MAX  = 4'd1;
localparam MIN  = 4'd2;
localparam MAX2 = 4'd3;
localparam MIN2 = 4'd4;
localparam AVG  = 4'd5;
localparam EXT  = 4'd6;
localparam EXC  = 4'd7;
localparam PMAX = 4'd8;
localparam PMIN = 4'd9;

// interface
reg [130:0] iot_out_w, iot_out_r;
reg valid_w, valid_r;
//
wire data_done;
wire round_done;
reg  [2:0] data_cnt_w, data_cnt_r;
reg  [3:0] byte_cnt_w, byte_cnt_r;
reg  [127:0] temp_w, temp_r;
reg  [127:0] temp2_w, temp2_r;
// comparator
wire cmp1_out;
reg  cmp1_out_w, cmp1_out_r;
wire cmp2_out;
reg  cmp2_out_w, cmp2_out_r;
reg  [7:0] cmp1_in0, cmp1_in1;
reg  [7:0] cmp2_in0, cmp2_in1;
// equalizer
wire equal1_out;
reg  [7:0] equal1_in0, equal1_in1;
wire equal2_out;
reg  [7:0] equal2_in0, equal2_in1;
//adder
wire [33:0] adder;
reg  [32:0] add_in0, add_in1;
reg  cout;
// flag
wire init;
wire ext_jg;
wire n_cmp;
wire n_cmp2;
wire n_cmp_r;
wire n_cmp2_r;
wire max_time;
wire min_time;
wire max_data_t;
wire max_init;
wire min_data_t;
wire min_init;
wire max2_init;
wire max2_cmp1;
wire max2_cmp2;
wire max2_time;
wire min2_cmp1;
wire min2_cmp2;
wire min2_time;
reg  isLarge;
reg  isSmall;
reg  peak_w, peak_r;
reg  round_cnt;

//------------------------------------------------------------------------
assign busy        = 1'b0;
assign valid       = valid_r;
assign iot_out     = iot_out_r[127:0];
assign data_done   = (byte_cnt_r == 4'd15);
assign init        = (data_cnt_r == 3'd0);
assign round_done  = (data_done && data_cnt_r == 3'd7);
assign ext_jg      = (isLarge && isSmall);
assign n_cmp       = ~cmp1_out;
assign n_cmp2      = ~cmp2_out;
assign n_cmp_r     = ~cmp1_out_r;
assign n_cmp2_r    = ~cmp2_out_r;
assign max_time    = (cmp1_out || (equal1_out && cmp1_out_r));
assign max2_time   = (cmp2_out || (equal2_out && cmp2_out_r));
assign min_time    = (n_cmp  || (equal1_out && n_cmp_r));
assign min2_time   = (n_cmp2 || (equal2_out && n_cmp_r));
assign max_data_t  = (data_done && max_time);
assign max_init    = (init && !byte_cnt_r);
assign min_data_t  = (data_done && min_time);
assign min_init    = (max_init && temp_r[7:0] == 8'd0);
assign max2_init   = (init && byte_cnt_r == 4'd1);
assign max2_cmp1   = (max_time  && data_done);
assign max2_cmp2   = (max2_time && data_done);
assign min2_cmp1   = (min_time  && data_done);
assign min2_cmp2   = (min2_time && data_done);

//------------------------------------------------------------------------
always @(*) begin
    case(fn_sel)
        MAX, MIN, PMAX, PMIN, AVG, MAX2, MIN2: begin
            byte_cnt_w = (in_en) ? byte_cnt_r + 4'd1 : byte_cnt_r;
            data_cnt_w = (data_done) ? data_cnt_r + 3'd1 : data_cnt_r;
        end
        EXT, EXC: begin
            byte_cnt_w = (in_en) ? byte_cnt_r + 4'd1 : byte_cnt_r;
            data_cnt_w = data_cnt_r;
        end
        default: begin
            data_cnt_w = 3'd0;
            byte_cnt_w = 4'd0;
        end
    endcase
end

assign cmp1_out = (cmp1_in0 > cmp1_in1) ? 1'b1 : 1'b0;
assign equal1_out = (equal1_in0 == equal1_in1) ? 1'b1 : 1'b0;
always @(*) begin
    case(fn_sel)
        MAX, MIN, PMAX, PMIN, MAX2, MIN2: begin
            cmp1_in0   = iot_in;
            equal1_in0 = iot_in;
            case(byte_cnt_r)
                4'd0: begin
                    cmp1_in1   = iot_out_r[0+:8];
                    equal1_in1 = iot_out_r[0+:8];
                end
                4'd1: begin
                    cmp1_in1   = iot_out_r[8+:8];
                    equal1_in1 = iot_out_r[8+:8];
                end
                4'd2: begin    
                    cmp1_in1   = iot_out_r[16+:8];
                    equal1_in1 = iot_out_r[16+:8];
                end
                4'd3: begin
                    cmp1_in1   = iot_out_r[24+:8];
                    equal1_in1 = iot_out_r[24+:8];
                end
                4'd4: begin
                    cmp1_in1   = iot_out_r[32+:8];    
                    equal1_in1 = iot_out_r[32+:8];    
                end
                4'd5: begin
                    cmp1_in1   = iot_out_r[40+:8];
                    equal1_in1 = iot_out_r[40+:8];
                end
                4'd6: begin
                    cmp1_in1   = iot_out_r[48+:8];
                    equal1_in1 = iot_out_r[48+:8];
                end
                4'd7: begin
                    cmp1_in1   = iot_out_r[56+:8];
                    equal1_in1 = iot_out_r[56+:8];
                end
                4'd8: begin
                    cmp1_in1   = iot_out_r[56+:8];
                    equal1_in1 = iot_out_r[56+:8];
                end 
                4'd9: begin
                    cmp1_in1   = iot_out_r[72+:8];
                    equal1_in1 = iot_out_r[72+:8];
                end
                4'd10: begin
                    cmp1_in1   = iot_out_r[80+:8];
                    equal1_in1 = iot_out_r[80+:8];
                end
                4'd11: begin
                    cmp1_in1   = iot_out_r[88+:8];
                    equal1_in1 = iot_out_r[88+:8];
                end
                4'd12: begin
                    cmp1_in1   = iot_out_r[96+:8];
                    equal1_in1 = iot_out_r[96+:8];
                end
                4'd13: begin
                    cmp1_in1   = iot_out_r[104+:8];
                    equal1_in1 = iot_out_r[104+:8];
                end
                4'd14: begin
                    cmp1_in1   = iot_out_r[112+:8];
                    equal1_in1 = iot_out_r[112+:8];
                end
                4'd15: begin
                    cmp1_in1   = iot_out_r[120+:8];
                    equal1_in1 = iot_out_r[120+:8];
                end
                default: begin
                    cmp1_in1   = 8'd0;
                    equal1_in1 = 8'd0;
                end
            endcase
        end
        EXT: begin
            cmp1_in0   = iot_in;
            equal1_in0 = iot_in;
            if(data_done) begin
                cmp1_in1   = 8'h6f;
                equal1_in1 = 8'h6f;
            end else begin
                cmp1_in1   = 8'hff;
                equal1_in1 = 8'hff;
            end
        end
        EXC: begin
            cmp1_in0   = iot_in;
            equal1_in0 = iot_in;
            if(data_done) begin
                cmp1_in1   = 8'h7f;
                equal1_in1 = 8'h7f;
            end else begin
                cmp1_in1   = 8'hff;
                equal1_in1 = 8'hff;
            end
        end
        default: begin
            cmp1_in0 = 8'd0;
            cmp1_in1 = 8'd0;
            equal1_in0 = 8'd0;
            equal1_in1 = 8'd0;
        end
    endcase
end

assign cmp2_out   = (cmp2_in0 > cmp2_in1) ? 1'b1 : 1'b0;
assign equal2_out = (equal2_in0 == equal2_in1) ? 1'b1 : 1'b0;
always @(*) begin
    case(fn_sel)    
        MAX2, MIN2: begin
            cmp2_in0 = iot_in;
            equal2_in0 = iot_in;
            case(byte_cnt_r)
                4'd0: begin
                    cmp2_in1   = temp2_r[0+:8];
                    equal2_in1 = temp2_r[0+:8];
                end
                4'd1: begin
                    cmp2_in1   = temp2_r[8+:8];
                    equal2_in1 = temp2_r[8+:8];
                end
                4'd2: begin
                    cmp2_in1   = temp2_r[16+:8];
                    equal2_in1 = temp2_r[16+:8];
                end
                4'd3: begin
                    cmp2_in1   = temp2_r[24+:8];
                    equal2_in1 = temp2_r[24+:8];
                end
                4'd4: begin
                    cmp2_in1   = temp2_r[32+:8];
                    equal2_in1 = temp2_r[32+:8];
                end
                4'd5: begin
                    cmp2_in1   = temp2_r[40+:8];
                    equal2_in1 = temp2_r[40+:8];
                end
                4'd6: begin
                    cmp2_in1   = temp2_r[48+:8];
                    equal2_in1 = temp2_r[48+:8];
                end
                4'd7: begin
                    cmp2_in1   = temp2_r[56+:8];
                    equal2_in1 = temp2_r[56+:8];
                end
                4'd8: begin
                    cmp2_in1   = temp2_r[64+:8];
                    equal2_in1 = temp2_r[64+:8];
                end
                4'd9: begin
                    cmp2_in1   = temp2_r[72+:8];
                    equal2_in1 = temp2_r[72+:8];
                end
                4'd10: begin
                    cmp2_in1   = temp2_r[80+:8];
                    equal2_in1 = temp2_r[80+:8];
                end
                4'd11: begin
                    cmp2_in1   = temp2_r[88+:8];
                    equal2_in1 = temp2_r[88+:8];
                end
                4'd12: begin
                    cmp2_in1   = temp2_r[96+:8];
                    equal2_in1 = temp2_r[96+:8];
                end
                4'd13: begin
                    cmp2_in1   = temp2_r[104+:8];
                    equal2_in1 = temp2_r[104+:8];
                end
                4'd14: begin
                    cmp2_in1   = temp2_r[112+:8];
                    equal2_in1 = temp2_r[112+:8];
                end
                4'd15: begin
                    cmp2_in1   = temp2_r[120+:8];
                    equal2_in1 = temp2_r[120+:8];
                end
                default: begin
                    cmp2_in1   = 8'd0;
                    equal2_in1 = 8'd0;
                end
            endcase
        end
        EXT: begin
            cmp2_in1   = iot_in;
            equal2_in1 = iot_in;
            if(data_done) begin
                cmp2_in0   = 8'haf;
                equal2_in0 = 8'haf;
            end else begin
                cmp2_in0   = 8'hff;
                equal2_in0 = 8'hff;
            end
        end
        EXC: begin
            cmp2_in1   = iot_in;
            equal2_in1 = iot_in;
            if(data_done) begin
                cmp2_in0   = 8'hbf;
                equal2_in0 = 8'hbf;
            end else begin
                cmp2_in0   = 8'hff;
                equal2_in0 = 8'hff;
            end
        end
        default: begin
            cmp2_in0 = 8'd0;
            cmp2_in1 = 8'd0;
            equal2_in0 = 8'd0;
            equal2_in1 = 8'd0;
        end
    endcase
end

always @(*) begin
    case(1'b1)
        equal1_out: isLarge = cmp1_out_r;
        cmp1_out:   isLarge = 1'b1;
        default:    isLarge = 1'b0;
    endcase
    case(1'b1)
        equal2_out: isSmall = cmp2_out_r;
        cmp2_out:   isSmall = 1'b1;
        default:    isSmall = 1'b0;
    endcase
end

always @(*) begin
    case(fn_sel)
        MAX, MIN, PMAX, PMIN, MAX2, MIN2: begin
            cmp1_out_w = (equal1_out) ? cmp1_out_r : cmp1_out;
            cmp2_out_w = 1'b0;
        end
        EXT, EXC: begin
            cmp1_out_w = (equal1_out) ? cmp1_out_r : cmp1_out;
            cmp2_out_w = (equal2_out) ? cmp2_out_r : cmp2_out;
        end
        default: begin
            cmp1_out_w = 1'b0;
            cmp2_out_w = 1'b0;
        end
    endcase
end

always @(*) begin
    case(byte_cnt_r)
        4'd0:    temp_w[0+:8]   = iot_in;
        4'd1:    temp_w[8+:8]   = iot_in;
        4'd2:    temp_w[16+:8]  = iot_in;
        4'd3:    temp_w[24+:8]  = iot_in;
        4'd4:    temp_w[32+:8]  = iot_in;
        4'd5:    temp_w[40+:8]  = iot_in;
        4'd6:    temp_w[48+:8]  = iot_in;
        4'd7:    temp_w[56+:8]  = iot_in;
        4'd8:    temp_w[64+:8]  = iot_in;
        4'd9:    temp_w[72+:8]  = iot_in;
        4'd10:   temp_w[80+:8]  = iot_in;
        4'd11:   temp_w[88+:8]  = iot_in;
        4'd12:   temp_w[96+:8]  = iot_in;
        4'd13:   temp_w[104+:8] = iot_in;
        4'd14:   temp_w[112+:8] = iot_in;
        4'd15:   temp_w[120+:8] = iot_in;
        default: temp_w = 128'd0;
    endcase
end

always @(*) begin
    if(fn_sel == MAX2) begin
        case(1'b1) 
            max2_cmp1: temp2_w = iot_out_r;
            max2_cmp2: temp2_w = {iot_in,temp_r[119:0]};
            default:   temp2_w = temp2_r;
        endcase
    end else begin
        case(1'b1) 
            min2_cmp1: temp2_w = iot_out_r;
            min2_cmp2: temp2_w = {iot_in,temp_r[119:0]};
            default:   temp2_w = temp2_r;
        endcase
    end
end

always @(*) begin
    case(fn_sel)
        MAX: begin
            case(1'b1)
                max_init:   iot_out_w = 131'd0;
                max_data_t: iot_out_w = {iot_in,temp_r[119:0]};
                default:    iot_out_w = iot_out_r;
            endcase
        end
        MIN: begin
            case(1'b1)
                max_init:   iot_out_w = 131'h7_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
                min_data_t: iot_out_w = {iot_in,temp_r[119:0]};
                default:    iot_out_w = iot_out_r;
            endcase
        end
        PMAX: begin
            if(max_data_t) begin
                iot_out_w = {iot_in,temp_r[119:0]};
            end else begin
                iot_out_w = iot_out_r;
            end
        end
        PMIN: begin
            case(1'b1) 
                min_init:   iot_out_w = 131'h7_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
                min_data_t: iot_out_w = {iot_in,temp_r[119:0]};
                default:    iot_out_w = iot_out_r;
            endcase
        end
        EXT, EXC: iot_out_w = {iot_in,temp_r[119:0]};
        AVG: begin
            case(byte_cnt_r)
                4'd0:    iot_out_w = {iot_out_r[130:33],adder[32:0]};
                4'd1:    iot_out_w = {iot_out_r[130:66],adder[32:0],iot_out_r[32:0]};
                4'd2:    iot_out_w = {iot_out_r[130:99],adder[32:0],iot_out_r[65:0]};
                4'd3:    iot_out_w = (init) ? {adder[33:0],iot_out_r[98:3]} : {adder[31:0],iot_out_r[98:0]};
                4'd15:   iot_out_w = (init) ? {iot_in,temp_r[119:0]} : iot_out_r;
                default: iot_out_w = iot_out_r;
            endcase
        end
        MAX2: begin
            case(1'b1)
                max2_cmp1: iot_out_w = {iot_in,temp_r[119:0]};
                max_init:  iot_out_w = temp2_r;
                max2_init: iot_out_w = 131'd0; 
                default:   iot_out_w = iot_out_r;
            endcase
        end
        MIN2: begin
            case(1'b1)
                min2_cmp1: iot_out_w = {iot_in,temp_r[119:0]};
                max_init:  iot_out_w = temp2_r;
                max2_init: iot_out_w = 131'h7_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;
                default:   iot_out_w = iot_out_r;
            endcase
        end
        default:  iot_out_w = 131'd0;
    endcase
end

assign adder = add_in0 + add_in1;
always @(*) begin
    if(data_cnt_r == 3'd1) begin
        add_in0 = 33'd0;
    end else begin
        case(byte_cnt_r)
            4'd0:    add_in0 = iot_out_r[0+:33];
            4'd1:    add_in0 = iot_out_r[33+:33];
            4'd2:    add_in0 = iot_out_r[66+:33];
            4'd3:    add_in0 = iot_out_r[99+:32];
            default: add_in0 = 33'd0;
        endcase
    end
    case(byte_cnt_r)
        4'd0:    add_in1 = temp_r[0+:33];
        4'd1:    add_in1 = temp_r[33+:33] + cout;
        4'd2:    add_in1 = temp_r[66+:33] + cout;
        4'd3:    add_in1 = temp_r[127:99] + cout;
        default: add_in1 = 33'd0;
    endcase
end

always @(*) begin
    if(round_done) begin
        peak_w = 1'b0;
    end else if(data_done && ((fn_sel == PMAX && max_time) || (fn_sel == PMIN && min_time))) begin
        peak_w = 1'b1;
    end else begin
        peak_w = peak_r;
    end
end

always @(*) begin
    case(fn_sel)
        MAX, MIN: valid_w = (round_done) ? 1'b1 : 1'b0;
        MAX2, MIN2: valid_w = ((round_cnt && max_init) || round_done) ? 1'b1 : 1'b0;
        EXT:  valid_w = (data_done && ext_jg) ? 1'b1 : 1'b0;
        EXC:  valid_w = (data_done && ~ext_jg) ? 1'b1 : 1'b0;
        PMAX: valid_w = (round_done && (peak_r || max_time)) ? 1'b1 : 1'b0;
        PMIN: valid_w = (round_done && (peak_r || min_time)) ? 1'b1 : 1'b0;
        AVG:  valid_w = (round_cnt && byte_cnt_r == 4'd3 && !data_cnt_r) ? 1'b1 : 1'b0;
        default: valid_w = 1'b0;
    endcase
end

//------------------------------------------------------------------------
always @(posedge clk or posedge rst) begin
    if(rst) begin
        iot_out_r <= 128'd0;
        temp_r  <= 128'd0;
        temp2_r <= 128'd0;
    end else begin
        iot_out_r <= iot_out_w;
        temp_r  <= temp_w;
        temp2_r <= temp2_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        byte_cnt_r <= 4'd0;
        data_cnt_r <= 3'd0;
    end else begin
        byte_cnt_r <= byte_cnt_w;
        data_cnt_r <= data_cnt_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        cmp1_out_r <= 1'b0;
        cmp2_out_r <= 1'b0;
    end else begin
        cmp1_out_r <= cmp1_out_w;
        cmp2_out_r <= cmp2_out_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        valid_r <= 1'b0;
        peak_r  <= 1'b0;
        round_cnt <= 1'b0;
    end else begin
        valid_r <= valid_w;
        peak_r  <= peak_w;
        round_cnt <= (round_done) ? 1'b1 : round_cnt;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        cout <= 1'b0;
    end else begin
        cout <= adder[33];
    end
end

endmodule

