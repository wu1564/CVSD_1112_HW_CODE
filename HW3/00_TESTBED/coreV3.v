//Area:186026.870220
//Time:74786400ps = 74786ns
//Clock Period:3.4
//AT:13912205516.2729
module coreV3 (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	// core mode
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	// input feature map
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	// core output
	output        o_out_valid,
	output [13:0] o_out_data
);

localparam IDLE     = 15;
localparam LOAD_IMG =  0;
localparam RIGHT    =  1;
localparam LEFT     =  2;
localparam UP       =  3;
localparam DOWN     =  4;
localparam DETH_RED =  5;
localparam DETH_INC =  6;
localparam DISPLAY  =  7;
localparam CONV     =  8;
localparam CONV_OP  = 11;
localparam MID_FILT =  9;
localparam MID_COMP = 12;
localparam HA_TRANS = 10;
localparam HA_CAL   = 14;
localparam MID_MEM  = 13;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
// state machine
reg [3:0] ns, ps;
// SRAM
wire wen;
wire cen;
wire [7:0]  i_mem_data;
wire [7:0]  o_mem_data;
wire [11:0] o_mem_addr;
reg  wen_w, wen_r;
reg  cen_w, cen_r;
reg  p_wen_r, p_cen_r;
reg  [7:0]  o_mem_data_w, o_mem_data_r;
reg  [7:0]  o_p_mem_data_r;
reg  [11:0] o_mem_addr_w, o_mem_addr_r;
reg  [11:0] o_p_mem_addr_r;
// cnt
wire col_bound, image_bound;
reg  [2:0]  row_cnt_w, row_cnt_r;
reg  [3:0]  conv_cnt_w, conv_cnt_r;
reg  [3:0]  col_cnt_w ,col_cnt_r;
reg  [3:0]  conv_op_cnt_w, conv_op_cnt_r;
reg  [4:0]  shift_cnt_w, shift_cnt_r;
reg  [4:0]  dsiplay_cnt_w, display_cnt_r;
reg  [5:0]  depth_cnt_w, depth_cnt_r;
reg  [11:0] depth_shift; 
// flag
wire load_imge_done;
wire depth_change;
wire display_flag;
wire depth_done;
wire conv_next_stage;
wire conv_shift;
wire conv_depth_done;
wire conv_op_done;
wire conv_data_t;
wire conv_change;
wire conv_clear;
wire [3:0] conv_data_addr;
wire [3:0] conv_update_addr;
wire data_time_st;
wire mf_next_cmp;
wire mf_kernel_done;
wire mf_pad_jg;
wire mf_next_channel;
wire mf_done;
wire mf_mem_done;
wire trans_data_done;
wire trans_next_channel;
wire trans_done;
reg  pad_flag;
reg  mf_pad;
reg  pad_delay[0:2];
reg  [3:0] mf_next_num;
reg  [2:0] mf_cmp_num;
// core output
reg  o_op_ready_w, o_op_ready_r;
// display
wire up_bound, down_bound, left_bound, right_bound;
reg  [6:0] origin_w, origin_r;
// adder
wire [6:0]  add_out;
reg  [6:0]  add_in0, add_in1;
wire signed [11:0] add2_out;
reg  signed [11:0] add2_in0_w, add2_in1_w;
reg  signed [11:0] add2_in0_r, add2_in1_r;
wire signed [16:0] op_add_out;
reg  signed [16:0] op_add_in0_w, op_add_in1_w;
reg  signed [16:0] op_add_in0_r, op_add_in1_r;
// comparator
wire cmp1_out, cmp2_out, cmp3_out, cmp4_out;
reg  [7:0] cmp1_in0, cmp1_in1;
reg  [7:0] cmp2_in0, cmp2_in1;
reg  [7:0] cmp3_in0, cmp3_in1;
reg  [7:0] cmp4_in0, cmp4_in1;
// output
reg o_out_valid_w, o_out_valid_r;
reg [13:0] o_out_data_w, o_out_data_r;
//
integer i, j;
reg [13:0] op_temp_r[0:8], op_temp_w[0:8];
reg [7:0]  mf_temp_r[0:3], mf_temp_w[0:3];

sram_4096x8 sram_inst(
   .Q(i_mem_data),
   .CLK(i_clk),
   .CEN(cen),
   .WEN(wen),
   .A(o_mem_addr),
   .D(o_mem_data)
);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign cen                = cen_r;
assign wen                = wen_r;
assign o_mem_addr         = o_mem_addr_r;
assign o_mem_data         = o_mem_data_r;
assign col_bound          = (col_cnt_r == 4'd7);
assign image_bound        = (col_bound && row_cnt_r == 3'd7);
assign load_imge_done     = (image_bound && display_cnt_r == 5'd31);
assign o_in_ready         = 1'b1;
assign o_op_ready         = o_op_ready_r;
assign up_bound           = (!row_cnt_r);
assign down_bound         = (row_cnt_r == 3'd6);
assign left_bound         = (!col_cnt_r);
assign right_bound        = (col_cnt_r == 4'd6);
assign depth_change       = (shift_cnt_r == 5'd3);
assign display_flag       = (!depth_cnt_r && depth_change);
assign o_out_data         = o_out_data_r;
assign o_out_valid        = o_out_valid_r;
assign data_time_st       = (depth_cnt_r == 6'd3);
assign depth_done         = (depth_cnt_r[4:0] == display_cnt_r);
assign conv_next_stage    = (conv_shift && (shift_cnt_r == 5'd8 || shift_cnt_r == 5'd11 || shift_cnt_r == 5'd16 || shift_cnt_r == 5'd19));
assign conv_depth_done    = (depth_cnt_r == display_cnt_r);
assign conv_shift         = conv_depth_done | pad_flag;
assign conv_op_done       = (conv_op_cnt_r == 4'd12);
assign conv_data_addr     = mf_temp_r[0][6:3];
assign conv_update_addr   = mf_temp_r[1][3:0];
assign conv_data_t        = (mf_temp_r[0][2] && mf_temp_r[0][1:0] == 2'd3);
assign conv_clear         = (conv_op_done && conv_cnt_r == 4'd2);
assign conv_change        = (conv_op_cnt_r == 4'd4 && (conv_cnt_r == 4'd4 || conv_cnt_r == 4'd2));
assign mf_kernel_done     = (shift_cnt_r == 5'd8 || shift_cnt_r == 5'd13 || shift_cnt_r == 5'd18 || shift_cnt_r == 5'd23);
assign mf_next_cmp        = (conv_op_cnt_r == mf_next_num || (ps == MID_COMP && conv_cnt_r == 4'd4));
assign mf_pad_jg          = ~pad_delay[2];
assign mf_mem_done        = (conv_op_cnt_r == 4'd2);
assign mf_next_channel    = (mf_next_cmp && shift_cnt_r == 5'd24);
assign mf_done            = (depth_cnt_r == 6'd4);
assign trans_data_done    = (shift_cnt_r == 5'd6);
assign trans_next_channel = (conv_op_cnt_r == 4'd4);
assign trans_done         = mf_done;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// state machine
always @(*) begin
	case(ps)
		IDLE:     ns = (i_op_valid && ((i_op_mode[2:0] == 3'd7 || i_op_mode[3]) || i_op_mode == 4'd0)) ? i_op_mode : IDLE;
		LOAD_IMG: ns = (load_imge_done) ? IDLE : LOAD_IMG;
		DISPLAY:  ns = (display_flag & o_out_valid_r) ? IDLE : DISPLAY;
		CONV:     ns = (conv_next_stage) ? CONV_OP : CONV;
		CONV_OP:  begin
			if(conv_cnt_r == 4'd4 && conv_op_done) begin
				ns = IDLE;
			end else if(conv_op_done) begin
				ns = CONV;
			end else begin
				ns = CONV_OP;
			end
		end
		MID_FILT: ns = (mf_kernel_done) ? MID_MEM : MID_FILT;
		MID_COMP: begin
			case(1'b1)
				mf_done: ns = IDLE;
				mf_next_cmp: ns = MID_FILT;
				default: ns = MID_COMP;
			endcase
		end
		MID_MEM: ns = (mf_mem_done) ? MID_COMP : MID_MEM;
		HA_TRANS: begin
			case(1'b1)
				trans_done: ns = IDLE;
				trans_data_done: ns = HA_CAL;
				default: ns = HA_TRANS;
			endcase
		end
		HA_CAL:   ns = (trans_next_channel) ? HA_TRANS : HA_CAL;
		default:  ns = IDLE;
	endcase
end

//SRAM
always @(*) begin
	case(ps)
		LOAD_IMG: begin
			wen_w = ~i_in_valid;
			cen_w = 1'b0;
			if(i_in_valid) begin
				o_mem_data_w = i_in_data;
			end else begin
				o_mem_data_w = o_p_mem_data_r;
			end
			case(1'b1)
				i_op_valid:  o_mem_addr_w = o_p_mem_addr_r;
				image_bound: o_mem_addr_w = o_p_mem_addr_r + 12'd23;
				col_bound:   o_mem_addr_w = o_p_mem_addr_r + 12'd3;	
				i_in_valid:  o_mem_addr_w = o_p_mem_addr_r + 12'd1;
				default:     o_mem_addr_w = o_p_mem_addr_r;
			endcase
		end
		DISPLAY, CONV, CONV_OP, MID_FILT, MID_COMP, MID_MEM, HA_TRANS: begin
			wen_w = 1'b1;
			cen_w = 1'b0;
			o_mem_data_w = 8'd0;
			o_mem_addr_w = add2_out;
		end
		default: begin
			wen_w = 1'b1;
			cen_w = 1'b0;
			o_mem_data_w = 8'd0;
			o_mem_addr_w = 12'd10;
		end
	endcase
end

always @(*) begin
	case(ps)
		IDLE: begin
			if(i_op_valid) begin
				row_cnt_w     = row_cnt_r;
				col_cnt_w     = col_cnt_r;
				dsiplay_cnt_w = display_cnt_r;	
				case(i_op_mode) 
					LOAD_IMG: col_cnt_w = 4'hf;
					UP:       row_cnt_w = (up_bound)    ? row_cnt_r : row_cnt_r + 3'h7;
					DOWN:     row_cnt_w = (down_bound)  ? row_cnt_r : row_cnt_r + 3'd1;
					LEFT:     col_cnt_w = (left_bound)  ? col_cnt_r : col_cnt_r + 4'hf;
					RIGHT:    col_cnt_w = (right_bound) ? col_cnt_r : col_cnt_r + 4'd1;
					DETH_INC: begin
						case(1'b1)
							~display_cnt_r[3]: dsiplay_cnt_w = 5'd15;
							~display_cnt_r[4]: dsiplay_cnt_w = 5'd31;
							default:           dsiplay_cnt_w = display_cnt_r;
						endcase
					end
					DETH_RED: begin
						case(1'b1)
							display_cnt_r[4]: dsiplay_cnt_w = 5'd15;
							display_cnt_r[3]: dsiplay_cnt_w = 5'd7;
							default:          dsiplay_cnt_w = display_cnt_r;
						endcase
					end
					default: begin
						row_cnt_w     = row_cnt_r;
						col_cnt_w     = col_cnt_r;
						dsiplay_cnt_w = display_cnt_r;						
					end
				endcase
			end else begin
				row_cnt_w     = row_cnt_r;
				col_cnt_w     = col_cnt_r;
				dsiplay_cnt_w = display_cnt_r;
			end
		end
		LOAD_IMG: begin
			col_cnt_w = (col_bound) ? 0 : col_cnt_r + 3'd1;
			case(1'b1)
				image_bound: row_cnt_w = 3'd0;
				col_bound:   row_cnt_w = row_cnt_r + 3'd1;
				default:     row_cnt_w = row_cnt_r;
			endcase
			if(display_cnt_r == 5'd31) begin
				dsiplay_cnt_w = display_cnt_r;
			end else if(image_bound) begin
				dsiplay_cnt_w = display_cnt_r + 5'd1;
			end else begin
				dsiplay_cnt_w = display_cnt_r;
			end
		end
		default: begin
			row_cnt_w     = row_cnt_r;
			col_cnt_w     = col_cnt_r;
			dsiplay_cnt_w = display_cnt_r;	
		end
	endcase
end

always @(*) begin
	if(i_op_valid) begin
		case(i_op_mode)
			UP:      origin_w = (up_bound)    ? origin_r : add_out;
			DOWN:    origin_w = (down_bound)  ? origin_r : add_out;
			LEFT:    origin_w = (left_bound)  ? origin_r : add_out;
			RIGHT:   origin_w = (right_bound) ? origin_r : add_out;
			default: origin_w = origin_r;
		endcase
	end else begin
		origin_w = origin_r;
	end
end

always @(*) begin
	case(ps)
		IDLE:    o_op_ready_w = ~(o_op_ready_r | i_op_valid | i_in_valid);
		default: o_op_ready_w = 1'b0;
	endcase
end

always @(*) begin
	case(ps)
		DISPLAY: begin
			if(depth_done && depth_change) begin
				depth_cnt_w = 6'd0;
			end else if(depth_change) begin
				depth_cnt_w = depth_cnt_r + 6'd1;
			end else begin
				depth_cnt_w = depth_cnt_r;
			end
			shift_cnt_w = (depth_change) ? 5'd0 : shift_cnt_r + 5'd1;
		end
		CONV: begin
			depth_cnt_w = (conv_shift) ? 6'd0 : depth_cnt_r + 6'd1;
			shift_cnt_w = (conv_shift) ? shift_cnt_r + 5'd1 : shift_cnt_r;
		end
		CONV_OP: begin
			depth_cnt_w = depth_cnt_r;
			shift_cnt_w = shift_cnt_r;
		end
		MID_COMP: begin
			if(mf_next_channel) begin
				shift_cnt_w = 5'd0;
				depth_cnt_w = depth_cnt_r + 6'd1;
			end else begin
				shift_cnt_w = shift_cnt_r;
				depth_cnt_w = depth_cnt_r;
			end
		end
		MID_FILT: begin
			depth_cnt_w = depth_cnt_r;
			shift_cnt_w = shift_cnt_r + 5'd1;
		end
		MID_MEM: begin
			depth_cnt_w = depth_cnt_r;
			shift_cnt_w = shift_cnt_r;
		end
		HA_TRANS: begin
			shift_cnt_w = shift_cnt_r + 5'd1;
			depth_cnt_w = depth_cnt_r;
		end
		HA_CAL: begin
			depth_cnt_w = (trans_next_channel) ? depth_cnt_r + 6'd1 : depth_cnt_r;
			shift_cnt_w = 5'd0;
		end
		default: begin
			depth_cnt_w = 6'd0;
			shift_cnt_w = 5'd0;
		end
	endcase
end

assign add_out = add_in0 + add_in1;
always @(*) begin
	case(ps)
		IDLE: begin		
			add_in0 = origin_r;
			case(i_op_mode)
				UP:       add_in1 = -7'd10;
				DOWN:     add_in1 =  7'd10;
				LEFT:     add_in1 = -7'd1;
				RIGHT:    add_in1 =  7'd1;
				default:  add_in1 =  7'd0;
			endcase
		end
		DISPLAY: begin
			add_in0 = origin_r;
			case(shift_cnt_r)
				5'd1:    add_in1 = 7'd1;
				5'd2:    add_in1 = 7'd10;
				5'd3:    add_in1 = 7'd11;
				default: add_in1 = 7'd0;
			endcase
		end
		CONV, CONV_OP: begin
			add_in0 = origin_r;
			case(shift_cnt_r)
				5'd1:  add_in1 =  7'd1;  
				5'd2:  add_in1 =  7'd10;
				5'd3:  add_in1 =  7'd11; 
				5'd6:  add_in1 = -7'd11;
				5'd7:  add_in1 = -7'd10; 
				5'd8:  add_in1 = -7'd9;
				5'd9:  add_in1 = -7'd8;  
				5'd14: add_in1 =  7'd19;
				5'd15: add_in1 =  7'd20; 
				5'd16: add_in1 =  7'd21;
				5'd17: add_in1 =  7'd22; 
				5'd4,  5'd13: add_in1 =  7'd9;
				5'd5,  5'd12: add_in1 = -7'd1;  
				5'd10, 5'd19: add_in1 =  7'd2;
				5'd11, 5'd18: add_in1 =  7'd12; 
				default: add_in1 =  7'd0;
			endcase
		end
		MID_FILT, MID_MEM, HA_TRANS: begin
			add_in0 = origin_r;
			case(shift_cnt_r)
				5'd1:  add_in1 =  7'd10;  
				5'd2:  add_in1 =  7'd1;
				5'd3:  add_in1 =  7'd11;
				5'd6:  add_in1 = -7'd11;
				5'd11: add_in1 = -7'd8;  
				5'd16: add_in1 =  7'd19;
				5'd21: add_in1 =  7'd22;
				5'd4,  5'd15: add_in1 =  7'd9;
				5'd5,  5'd14: add_in1 = -7'd1;  
				5'd7,  5'd9:  add_in1 = -7'd10; 
				5'd8,  5'd10: add_in1 = -7'd9;
				5'd12, 5'd23: add_in1 =  7'd2;
				5'd13, 5'd22: add_in1 =  7'd12; 
				5'd17, 5'd19: add_in1 =  7'd20; 
				5'd18, 5'd20: add_in1 =  7'd21;
				default: add_in1 =  7'd0;
			endcase
		end
		default: begin
			add_in0 = 7'd0;	
			add_in1 = 7'd0;
		end
	endcase
end

assign add2_out = add2_in0_r + add2_in1_r;
always @(*) begin
	case(ps)
		DISPLAY, CONV, MID_FILT, MID_MEM, CONV_OP: begin
			add2_in0_w = add_out;
			add2_in1_w = depth_shift;
		end
		HA_TRANS: begin
			case(shift_cnt_r)
				5'd5: begin
					add2_in0_w = $signed({1'b0,i_mem_data}); // B
					add2_in1_w = add2_in1_r;
				end
				5'd6: begin
					add2_in0_w = add2_in0_r;
					add2_in1_w = $signed({1'b0,i_mem_data}); // D
				end
				default: begin
					add2_in0_w = add_out;
					add2_in1_w = depth_shift;
				end
			endcase
		end
		HA_CAL: begin
			case(conv_op_cnt_r)
				4'd0: begin
					add2_in0_w = add2_in0_r;
					add2_in1_w = $signed(~add2_in1_r + 1'b1); // -D  B-D=D2
				end
				4'd1: begin
					add2_in0_w = op_temp_r[1][11:0]; // C2 
					add2_in1_w = add2_out;// D2
				end
				4'd2: begin
					add2_in0_w = add2_in0_r;
					add2_in1_w = add2_in1_r;
				end
				4'd3: begin
					add2_in0_w = add2_in0_r;
					add2_in1_w = $signed(~add2_in1_r + 1'b1);
				end
				default: begin
					add2_in0_w = 12'd0;
					add2_in1_w = 12'd0;
				end
			endcase
		end
		default: begin
			add2_in0_w = 12'd0;
			add2_in1_w = 12'd0;
		end
	endcase
end

assign op_add_out = op_add_in0_r + op_add_in1_r;
always @(*) begin
	case(ps)
		CONV: begin
			op_add_in0_w = {1'b0,i_mem_data};
			op_add_in1_w = (data_time_st) ? 17'd0 : op_add_out;
		end
		CONV_OP: begin
			case(conv_op_cnt_r)
				4'd0, 4'd1, 4'd2: begin
					op_add_in0_w = {1'b0,i_mem_data};
					op_add_in1_w = (data_time_st) ? 17'd0 : op_add_out;
				end
				4'd3: begin
					case(conv_cnt_r)
						4'd1: begin
							op_add_in0_w = {1'b0,op_temp_r[0],{2{1'b0}}}; // 1/4
							op_add_in1_w = {1'b0,op_temp_r[1],{1{1'b0}}}; // 1/8
						end
						4'd2: begin
							op_add_in0_w = {1'b0,op_temp_r[0],{1{1'b0}}}; // 1/8
							op_add_in1_w = {1'b0,op_temp_r[1],{2{1'b0}}}; // 1/4
						end
						4'd3: begin
							op_add_in0_w = {1'b0,op_temp_r[0],{1{1'b0}}}; // 1/8
							op_add_in1_w = {1'b0,op_temp_r[1]};             // 1/16
						end
						4'd4: begin
							op_add_in0_w = {1'b0,op_temp_r[0]};       // 1/16
							op_add_in1_w = {1'b0,op_temp_r[1],{1{1'b0}}}; // 1/8
						end
						default: begin
							op_add_in0_w = 14'd0;
							op_add_in1_w = 14'd0;
						end
					endcase
				end
				4'd4: begin
					case(conv_cnt_r)
						4'd1: begin
							op_add_in0_w = op_add_out;
							op_add_in1_w = {1'b0,op_temp_r[2],{1{1'b0}}}; // 1/8
						end
						4'd2: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[2]}; // 1/16
						end
						4'd3: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[2],{2{1'b0}}}; // 1/4
						end
						4'd4: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[2],{1{1'b0}}}; // 1/8
						end
						default: begin
							op_add_in0_w = 14'd0;
							op_add_in1_w = 14'd0; 
						end
					endcase
				end
				4'd5: begin
					case(conv_cnt_r)
						4'd1: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[3]}; // 1/16
						end
						4'd2: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[3],{1{1'b0}}}; // 1/8
						end
						4'd3: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[3],{1{1'b0}}}; // 1/8
						end
						4'd4: begin
							op_add_in0_w = op_add_out; 
							op_add_in1_w = {1'b0,op_temp_r[3],{2{1'b0}}}; // 1/4
						end
						default: begin
							op_add_in0_w = 14'd0;
							op_add_in1_w = 14'd0; 
						end
					endcase
				end
				4'd6: begin
					op_add_in0_w = op_add_out;
					op_add_in1_w = {1'b0,op_temp_r[4]};
				end
				4'd7: begin
					op_add_in0_w = op_add_out;
					op_add_in1_w = {1'b0,op_temp_r[5],{1{1'b0}}};
				end
				4'd8: begin
					op_add_in0_w = op_add_out;
					op_add_in1_w = {1'b0,op_temp_r[6]};
				end
				4'd9: begin
					op_add_in0_w = op_add_out;
					op_add_in1_w = {1'b0,op_temp_r[7],{1{1'b0}}};
				end
				4'd10: begin
					op_add_in0_w = op_add_out;
					op_add_in1_w = {1'b0,op_temp_r[8]};
				end
				4'd11: begin
					op_add_in0_w = {1'b0,op_add_out[16:4]};
					op_add_in1_w = {1'b0,op_add_out[3]};
				end
				default: begin
					op_add_in0_w = 17'd0;
					op_add_in1_w = 17'd0;
				end
			endcase
		end
		HA_TRANS: begin
			op_add_in0_w = op_add_in0_r;
			op_add_in1_w = op_add_in1_r;
			case(shift_cnt_r)
				5'd3: op_add_in0_w = $signed({1'b0,i_mem_data}); // A
				5'd4: op_add_in1_w = $signed({1'b0,i_mem_data}); // C
				5'd5: op_add_in1_w = $signed(~op_add_in1_r + 1'b1);       //-C
				default: begin
					op_add_in0_w = 17'd0;
					op_add_in1_w = 17'd0;
				end
			endcase
		end
		HA_CAL: begin
			case(conv_op_cnt_r)
				4'd0: begin
					op_add_in0_w = op_temp_r[0]; // A+C=A2
					op_add_in1_w = $signed({add2_out[11],add2_out}); // B+D=B2
				end
				4'd1: begin
					op_add_in0_w = op_add_in0_r;
					op_add_in1_w = $signed(~op_add_in1_r + 1'b1); // A2-B2
				end
				default: begin
					op_add_in0_w = 17'd0;
					op_add_in1_w = 17'd0;
				end
			endcase
		end
		default: begin
			op_add_in0_w = 14'd0;
			op_add_in1_w = 14'd0;
		end
	endcase
end

always @(*) begin
	case(depth_cnt_r)
		6'd1:    depth_shift = 12'd100;  6'd2:  depth_shift = 12'd200; 	6'd3:  depth_shift = 12'd300;
		6'd4:    depth_shift = 12'd400;  6'd5:  depth_shift = 12'd500; 	6'd6:  depth_shift = 12'd600;
		6'd7:    depth_shift = 12'd700;  6'd8:  depth_shift = 12'd800; 	6'd9:  depth_shift = 12'd900;
		6'd10:   depth_shift = 12'd1000; 6'd11: depth_shift = 12'd1100;	6'd12: depth_shift = 12'd1200;
		6'd13:   depth_shift = 12'd1300; 6'd14: depth_shift = 12'd1400;	6'd15: depth_shift = 12'd1500;
		6'd16:   depth_shift = 12'd1600; 6'd17: depth_shift = 12'd1700;	6'd18: depth_shift = 12'd1800;
		6'd19:   depth_shift = 12'd1900; 6'd20: depth_shift = 12'd2000;	6'd21: depth_shift = 12'd2100;
		6'd22:   depth_shift = 12'd2200; 6'd23: depth_shift = 12'd2300;	6'd24: depth_shift = 12'd2400;
		6'd25:   depth_shift = 12'd2500; 6'd26: depth_shift = 12'd2600;	6'd27: depth_shift = 12'd2700;
		6'd28:   depth_shift = 12'd2800; 6'd29: depth_shift = 12'd2900;	6'd30: depth_shift = 12'd3000;
		6'd31:   depth_shift = 12'd3100;
		default: depth_shift = 12'd0;
	endcase
end

always @(*) begin
	case(ps)
		CONV: begin
			conv_cnt_w = (conv_next_stage) ? conv_cnt_r + 4'd1 : conv_cnt_r;
		    conv_op_cnt_w = conv_op_cnt_r;
		end
		CONV_OP: begin
			conv_op_cnt_w = (conv_op_done) ? 4'd0 : conv_op_cnt_r + 4'd1;
			conv_cnt_w = conv_cnt_r;
		end
		MID_FILT: begin
			conv_op_cnt_w = conv_op_cnt_r;
			case(shift_cnt_r)
				5'd9,  5'd14, 5'd19: conv_cnt_w = 4'd4;
				5'd0,  5'd1,  5'd2, 
				5'd10, 5'd11, 5'd15, 
				5'd16, 5'd20, 5'd21: conv_cnt_w = conv_cnt_r;
				default: begin
					if(mf_pad_jg) begin
						conv_cnt_w = conv_cnt_r + 4'd1;
					end else begin
						conv_cnt_w = conv_cnt_r;
					end
				end
			endcase
		end
		MID_COMP: begin
			conv_op_cnt_w = (mf_next_cmp) ? 4'd0 : conv_op_cnt_r + 4'd1;
			conv_cnt_w   = (mf_next_channel) ? 4'd0 : conv_cnt_r;
		end
		MID_MEM: begin
			if(mf_mem_done) begin
				conv_op_cnt_w = 4'd0;
			end else begin
				conv_op_cnt_w = conv_op_cnt_r + 4'd1;
			end
			conv_cnt_w = (mf_pad_jg) ? conv_cnt_r + 4'd1 : conv_cnt_r;
		end
		HA_CAL: begin
			conv_cnt_w = conv_cnt_r;
			conv_op_cnt_w = conv_op_cnt_r + 4'd1;
		end
		default: begin
			conv_cnt_w = 4'd0;
			conv_op_cnt_w = 4'd0;
		end
	endcase
end

always @(*) begin
	case(shift_cnt_r)
		5'd7, 5'd8:   pad_flag = (up_bound);
		5'd15, 5'd16: pad_flag = (down_bound);
		5'd4,  5'd5,  5'd12, 5'd13: pad_flag = (left_bound);
		5'd10, 5'd11, 5'd18, 5'd19: pad_flag = (right_bound);
		5'd6:  pad_flag = (up_bound    | left_bound);
		5'd9:  pad_flag = (up_bound    | right_bound);
		5'd14: pad_flag = (left_bound  | down_bound );
		5'd17: pad_flag = (right_bound | down_bound );
		default: pad_flag = 1'b0;
	endcase
	case(shift_cnt_r)
		5'd7,  5'd8,  5'd9,  5'd10: mf_pad = (up_bound);
		5'd17, 5'd18, 5'd19, 5'd20: mf_pad = (down_bound);
		5'd4,  5'd5,  5'd14, 5'd15: mf_pad = (left_bound);
		5'd12, 5'd13, 5'd22, 5'd23: mf_pad = (right_bound);
		5'd6:  mf_pad = (up_bound    | left_bound);
		5'd11: mf_pad = (up_bound    | right_bound);
		5'd16: mf_pad = (left_bound  | down_bound );
		5'd21: mf_pad = (right_bound | down_bound );
		default: mf_pad = 1'b0;
	endcase
	if(conv_cnt_r == 4'd9) begin
		mf_next_num = 4'd11;
		mf_cmp_num = 3'd4;
	end else begin
		mf_next_num = 4'd5;
		mf_cmp_num = 3'd1;
	end
end

// wire cmp1_out;
// reg  [7:0] cmp1_in0, cmp1_in1;
assign cmp1_out = (cmp1_in0 < cmp1_in1) ? 1'b1 : 1'b0;
assign cmp2_out = (cmp2_in0 < cmp2_in1) ? 1'b1 : 1'b0;
assign cmp3_out = (cmp3_in0 < cmp3_in1) ? 1'b1 : 1'b0;
assign cmp4_out = (cmp4_in0 < cmp4_in1) ? 1'b1 : 1'b0;
always @(*) begin
	case(conv_op_cnt_r)
		4'd0: begin
			cmp1_in0 = op_temp_r[0];
			cmp1_in1 = op_temp_r[1];
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0;
		end
		4'd1: begin
			cmp1_in0 = op_temp_r[1];
			cmp1_in1 = op_temp_r[2];
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0;
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0;
		end
		4'd2: begin
			cmp1_in0 = op_temp_r[2];
			cmp1_in1 = op_temp_r[3];
			cmp2_in0 = op_temp_r[0]; 
			cmp2_in1 = op_temp_r[1]; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
		4'd3: begin
			cmp1_in0 = op_temp_r[3];
			cmp1_in1 = op_temp_r[4];
			cmp2_in0 = op_temp_r[1]; 
			cmp2_in1 = op_temp_r[2]; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
		4'd4: begin
			cmp1_in0 = op_temp_r[4];
			cmp1_in1 = op_temp_r[5];
			cmp2_in0 = op_temp_r[2]; 
			cmp2_in1 = op_temp_r[3]; 
			cmp3_in0 = op_temp_r[0]; 
			cmp3_in1 = op_temp_r[1];
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
		4'd5: begin
			cmp1_in0 = op_temp_r[5];
			cmp1_in1 = op_temp_r[6];
			cmp2_in0 = op_temp_r[3]; 
			cmp2_in1 = op_temp_r[4]; 
			cmp3_in0 = op_temp_r[1]; 
			cmp3_in1 = op_temp_r[2];
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
		4'd6: begin
			cmp1_in0 = op_temp_r[6];
			cmp1_in1 = op_temp_r[7];
			cmp2_in0 = op_temp_r[4]; 
			cmp2_in1 = op_temp_r[5]; 
			cmp3_in0 = op_temp_r[2]; 
			cmp3_in1 = op_temp_r[3];
			cmp4_in0 = op_temp_r[0]; 
			cmp4_in1 = op_temp_r[1]; 
		end
		4'd7: begin
			cmp1_in0 = op_temp_r[7];
			cmp1_in1 = op_temp_r[8];
			cmp2_in0 = op_temp_r[5]; 
			cmp2_in1 = op_temp_r[6]; 
			cmp3_in0 = op_temp_r[3]; 
			cmp3_in1 = op_temp_r[4];
			cmp4_in0 = op_temp_r[1]; 
			cmp4_in1 = op_temp_r[2]; 
		end
		4'd8: begin
			cmp1_in0 = op_temp_r[0];
			cmp1_in1 = op_temp_r[1];
			cmp2_in0 = op_temp_r[6]; 
			cmp2_in1 = op_temp_r[7]; 
			cmp3_in0 = op_temp_r[4]; 
			cmp3_in1 = op_temp_r[5];
			cmp4_in0 = op_temp_r[2]; 
			cmp4_in1 = op_temp_r[3]; 
		end
		4'd9: begin
			cmp1_in0 = op_temp_r[1];
			cmp1_in1 = op_temp_r[2];
			cmp3_in0 = op_temp_r[5]; 
			cmp3_in1 = op_temp_r[6];
			cmp4_in0 = op_temp_r[3]; 
			cmp4_in1 = op_temp_r[4]; 
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0; 
		end
		4'd10: begin
			cmp1_in0 = op_temp_r[2];
			cmp1_in1 = op_temp_r[3];
			cmp4_in0 = op_temp_r[4]; 
			cmp4_in1 = op_temp_r[5]; 
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
		end
		4'd11: begin
			cmp1_in0 = op_temp_r[3];
			cmp1_in1 = op_temp_r[4];
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
		default: begin
			cmp1_in0 = 8'd0; cmp1_in1 = 8'd0;
			cmp2_in0 = 8'd0; cmp2_in1 = 8'd0; 
			cmp3_in0 = 8'd0; cmp3_in1 = 8'd0;
			cmp4_in0 = 8'd0; cmp4_in1 = 8'd0; 
		end
	endcase
end

always @(*) begin
	case(ps)
		CONV: begin
			if(conv_data_t) begin
				case(conv_update_addr)
					4'd0: begin
						op_temp_w[0] = op_add_out[16:0];
						for(i = 1; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
					4'd1: begin
						op_temp_w[1] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd2: begin
						op_temp_w[2] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd3: begin
						op_temp_w[3] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[2] = op_temp_r[2]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd4: begin
						op_temp_w[4] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[2] = op_temp_r[2];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd5: begin
						op_temp_w[5] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[2] = op_temp_r[2]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd6: begin
						op_temp_w[6] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[2] = op_temp_r[2]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd7: begin
						op_temp_w[7] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[2] = op_temp_r[2]; op_temp_w[8] = op_temp_r[8];
					end
					4'd8: begin
						op_temp_w[8] = op_add_out[16:0];
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[2] = op_temp_r[2];
					end					
					default: begin
						for(i = 0; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
				endcase
			end else begin
				for(i = 0; i < 9; i = i + 1) begin
					op_temp_w[i] = op_temp_r[i];
				end
			end
			mf_temp_w[0] = mf_temp_r[0];
			mf_temp_w[1] = mf_temp_r[1];
			if(conv_depth_done) begin
				mf_temp_w[0][2] = 1'b1;
			end else if(mf_temp_r[0][1:0] == 2'd3) begin
				mf_temp_w[0][2] = 1'b0;
			end else begin
				mf_temp_w[0][2] = mf_temp_r[0][2];
			end

			if(mf_temp_r[0][2]) begin
				mf_temp_w[0][1:0] = mf_temp_r[0][1:0] + 2'd1;
			end else begin
				mf_temp_w[0][1:0] = 2'd0;
			end

			if(conv_data_t || pad_flag) begin
				mf_temp_w[0][6:3] = mf_temp_r[0][6:3] + 4'd1;
			end else begin
				mf_temp_w[0][6:3] = mf_temp_r[0][6:3];
			end

			if(conv_depth_done) begin
				mf_temp_w[1][3:0] = conv_data_addr;
			end else begin
				mf_temp_w[1][3:0] = mf_temp_r[1][3:0];
			end

			for(i = 2; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		CONV_OP: begin
			op_temp_w[0] = op_temp_r[0]; 
			op_temp_w[1] = op_temp_r[1]; 
			op_temp_w[2] = op_temp_r[2];
			op_temp_w[3] = op_temp_r[3]; 
			if(conv_data_t) begin
				case(conv_update_addr)
					4'd4: begin
						op_temp_w[4] = op_add_out[16:0];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; 
						op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd5: begin
						op_temp_w[5] = op_add_out[16:0];
						op_temp_w[4] = op_temp_r[4]; op_temp_w[6] = op_temp_r[6]; 
						op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd6: begin
						op_temp_w[6] = op_add_out[16:0];
						op_temp_w[4] = op_temp_r[4]; op_temp_w[5] = op_temp_r[5]; 
						op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd7: begin
						op_temp_w[7] = op_add_out[16:0];
						op_temp_w[4] = op_temp_r[4]; op_temp_w[5] = op_temp_r[5]; 
						op_temp_w[6] = op_temp_r[6]; op_temp_w[8] = op_temp_r[8];
					end
					4'd8: begin
						op_temp_w[8] = op_add_out[16:0];
						op_temp_w[4] = op_temp_r[4]; op_temp_w[5] = op_temp_r[5]; 
						op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7];
					end					
					default: begin
						for(i = 4; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
				endcase
			end else begin
				if(conv_op_done) begin
					op_temp_w[6] = 14'd0;
				end else begin
					op_temp_w[6] = op_temp_r[6];
				end
				if(conv_op_done) begin
					op_temp_w[4] = 14'd0;
					op_temp_w[5] = 14'd0;
				end else begin
					op_temp_w[4] = op_temp_r[4];
					op_temp_w[5] = op_temp_r[5]; 
				end
				case(1'b1)
					conv_clear: begin
						op_temp_w[7] = 14'd0;
						op_temp_w[8] = 14'd0;
					end
					conv_change: begin
						op_temp_w[7] = op_temp_r[8];
						op_temp_w[8] = op_temp_r[7];
					end
					default: begin
						op_temp_w[7] = op_temp_r[7];
						op_temp_w[8] = op_temp_r[8];
					end
				endcase
			end
			mf_temp_w[0] = mf_temp_r[0];
			if(mf_temp_r[0][1:0] == 2'd3) begin
				mf_temp_w[0][2] = 1'b0;
			end else begin
				mf_temp_w[0][2] = mf_temp_r[0][2];
			end
			if(mf_temp_r[0][2]) begin
				mf_temp_w[0][1:0] = mf_temp_r[0][1:0] + 2'd1;
			end else begin
				mf_temp_w[0][1:0] = 2'd0;
			end
			if(conv_op_done) begin
				mf_temp_w[0][6:3] = 4'd4;
			end else begin
				mf_temp_w[0][6:3] = mf_temp_r[0][6:3];
			end
			for(i = 1; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		MID_FILT: begin
			case(shift_cnt_r)
				5'd0, 5'd9, 5'd14, 5'd19: begin
					for(i = 4; i < 9; i = i + 1) begin
						op_temp_w[i] = 14'd0;
					end
					for(i = 0; i < 4; i = i + 1) begin
						op_temp_w[i] = mf_temp_r[i];
					end
				end
				5'd1, 5'd2, 5'd10, 5'd11, 5'd15, 5'd16, 5'd20, 5'd21: begin
					for(i = 0; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				default: begin
					if(mf_pad_jg) begin
						case(conv_cnt_r)
							4'd0: begin
								op_temp_w[0] = i_mem_data;
								for(i = 1; i < 9; i = i + 1) begin
									op_temp_w[i] = op_temp_r[i];
								end
							end
							4'd1: begin
								op_temp_w[1] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd2: begin
								op_temp_w[2] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd3: begin
								op_temp_w[3] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[1] = op_temp_r[1]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd4: begin
								op_temp_w[4] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[1] = op_temp_r[1];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd5: begin
								op_temp_w[5] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[1] = op_temp_r[1]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd6: begin
								op_temp_w[6] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[1] = op_temp_r[1]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
							end
							4'd7: begin
								op_temp_w[7] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[1] = op_temp_r[1]; op_temp_w[8] = op_temp_r[8];
							end
							4'd8: begin
								op_temp_w[8] = i_mem_data;
								op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
								op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[1] = op_temp_r[1];
							end
							default: begin
								for(i = 0; i < 9; i = i + 1) begin
									op_temp_w[i] = op_temp_r[i];
								end
							end
						endcase
					end else begin
						for(i = 0; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
				end
			endcase
			if(shift_cnt_r == 5'd8) begin
				for(i = 0; i < 4; i = i + 1) begin
					mf_temp_w[i] = op_temp_r[i][7:0];
				end
			end else begin
				for(i = 0; i < 4; i = i + 1) begin
					mf_temp_w[i] = mf_temp_r[i];
				end
			end
		end
		MID_COMP: begin
			case(conv_op_cnt_r)
				4'd0: begin
					if(cmp1_out) begin
						op_temp_w[0] = op_temp_r[1];
						op_temp_w[1] = op_temp_r[0];
					end else begin
						op_temp_w[0] = op_temp_r[0];
						op_temp_w[1] = op_temp_r[1];
					end
					for(i = 2; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				4'd1: begin
					if(cmp1_out) begin
						op_temp_w[1] = op_temp_r[2];
						op_temp_w[2] = op_temp_r[1];
					end else begin
						op_temp_w[1] = op_temp_r[1];
						op_temp_w[2] = op_temp_r[2];
					end
					for(i = 3; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
					op_temp_w[0] = op_temp_r[0];
				end
				4'd2: begin
					if(cmp1_out) begin
						op_temp_w[2] = op_temp_r[3];
						op_temp_w[3] = op_temp_r[2];
					end else begin
						op_temp_w[2] = op_temp_r[2];
						op_temp_w[3] = op_temp_r[3];
					end
					if(cmp2_out) begin
						op_temp_w[0] = op_temp_r[1];
						op_temp_w[1] = op_temp_r[0];
					end else begin
						op_temp_w[0] = op_temp_r[0];
						op_temp_w[1] = op_temp_r[1];
					end
					for(i = 4; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				4'd3: begin
					if(cmp1_out) begin
						op_temp_w[3] = op_temp_r[4];
						op_temp_w[4] = op_temp_r[3];
					end else begin
						op_temp_w[3] = op_temp_r[3];
						op_temp_w[4] = op_temp_r[4];
					end
					if(cmp2_out) begin
						op_temp_w[1] = op_temp_r[2];
						op_temp_w[2] = op_temp_r[1];
					end else begin
						op_temp_w[1] = op_temp_r[1];
						op_temp_w[2] = op_temp_r[2];
					end
					for(i = 5; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
					op_temp_w[0] = op_temp_r[0];
				end
				4'd4: begin
					if(cmp1_out) begin
						op_temp_w[4] = op_temp_r[5];
						op_temp_w[5] = op_temp_r[4];
					end else begin
						op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5];
					end
					if(cmp2_out) begin
						op_temp_w[2] = op_temp_r[3];
						op_temp_w[3] = op_temp_r[2];
					end else begin
						op_temp_w[2] = op_temp_r[2];
						op_temp_w[3] = op_temp_r[3];
					end
					if(cmp3_out) begin
						op_temp_w[0] = op_temp_r[1];
						op_temp_w[1] = op_temp_r[0];
					end else begin
						op_temp_w[0] = op_temp_r[0];
						op_temp_w[1] = op_temp_r[1];
					end
					for(i = 6; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				4'd5: begin
					if(cmp1_out) begin
						op_temp_w[5] = op_temp_r[6];
						op_temp_w[6] = op_temp_r[5];
					end else begin
						op_temp_w[5] = op_temp_r[5];
						op_temp_w[6] = op_temp_r[6];
					end
					if(cmp2_out) begin
						op_temp_w[3] = op_temp_r[4];
						op_temp_w[4] = op_temp_r[3];
					end else begin
						op_temp_w[3] = op_temp_r[3];
						op_temp_w[4] = op_temp_r[4];
					end
					if(cmp3_out) begin
						op_temp_w[1] = op_temp_r[2];
						op_temp_w[2] = op_temp_r[1];
					end else begin
						op_temp_w[1] = op_temp_r[1];
						op_temp_w[2] = op_temp_r[2];
					end
					for(i = 7; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
					op_temp_w[0] = op_temp_r[0];
				end
				4'd6: begin
					if(cmp1_out) begin
						op_temp_w[6] = op_temp_r[7];
						op_temp_w[7] = op_temp_r[6];
					end else begin
						op_temp_w[6] = op_temp_r[6];
						op_temp_w[7] = op_temp_r[7];
					end
					if(cmp2_out) begin
						op_temp_w[4] = op_temp_r[5];
						op_temp_w[5] = op_temp_r[4];
					end else begin
						op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5];
					end
					if(cmp3_out) begin
						op_temp_w[2] = op_temp_r[3];
						op_temp_w[3] = op_temp_r[2];
					end else begin
						op_temp_w[2] = op_temp_r[2];
						op_temp_w[3] = op_temp_r[3];
					end
					if(cmp4_out) begin
						op_temp_w[0] = op_temp_r[1];
						op_temp_w[1] = op_temp_r[0];
					end else begin
						op_temp_w[0] = op_temp_r[0];
						op_temp_w[1] = op_temp_r[1];
					end
					op_temp_w[8] = op_temp_r[8];
				end
				4'd7: begin
					if(cmp1_out) begin
						op_temp_w[7] = op_temp_r[8];
						op_temp_w[8] = op_temp_r[7];
					end else begin
						op_temp_w[7] = op_temp_r[7];
						op_temp_w[8] = op_temp_r[8];
					end
					if(cmp2_out) begin
						op_temp_w[5] = op_temp_r[6];
						op_temp_w[6] = op_temp_r[5];
					end else begin
						op_temp_w[5] = op_temp_r[5];
						op_temp_w[6] = op_temp_r[6];
					end
					if(cmp3_out) begin
						op_temp_w[3] = op_temp_r[4];
						op_temp_w[4] = op_temp_r[3];
					end else begin
						op_temp_w[3] = op_temp_r[3];
						op_temp_w[4] = op_temp_r[4];
					end
					if(cmp4_out) begin
						op_temp_w[1] = op_temp_r[2];
						op_temp_w[2] = op_temp_r[1];
					end else begin
						op_temp_w[1] = op_temp_r[1];
						op_temp_w[2] = op_temp_r[2];
					end
					op_temp_w[0] = op_temp_r[0];
				end
				4'd8: begin
					if(cmp1_out) begin
						op_temp_w[0] = op_temp_r[1];
						op_temp_w[1] = op_temp_r[0];
					end else begin
						op_temp_w[0] = op_temp_r[0];
						op_temp_w[1] = op_temp_r[1];
					end
					if(cmp2_out) begin
						op_temp_w[6] = op_temp_r[7];
						op_temp_w[7] = op_temp_r[6];
					end else begin
						op_temp_w[6] = op_temp_r[6];
						op_temp_w[7] = op_temp_r[7];
					end
					if(cmp3_out) begin
						op_temp_w[4] = op_temp_r[5];
						op_temp_w[5] = op_temp_r[4];
					end else begin
						op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5];
					end
					if(cmp4_out) begin
						op_temp_w[2] = op_temp_r[3];
						op_temp_w[3] = op_temp_r[2];
					end else begin
						op_temp_w[2] = op_temp_r[2];
						op_temp_w[3] = op_temp_r[3];
					end
					op_temp_w[8] = op_temp_r[8];
				end
				4'd9: begin
					if(cmp1_out) begin
						op_temp_w[1] = op_temp_r[2];
						op_temp_w[2] = op_temp_r[1];
					end else begin
						op_temp_w[1] = op_temp_r[1];
						op_temp_w[2] = op_temp_r[2];
					end
					if(cmp3_out) begin
						op_temp_w[5] = op_temp_r[6];
						op_temp_w[6] = op_temp_r[5];
					end else begin
						op_temp_w[5] = op_temp_r[5];
						op_temp_w[6] = op_temp_r[6];
					end
					if(cmp4_out) begin
						op_temp_w[3] = op_temp_r[4];
						op_temp_w[4] = op_temp_r[3];
					end else begin
						op_temp_w[3] = op_temp_r[3];
						op_temp_w[4] = op_temp_r[4];
					end
					op_temp_w[0] = op_temp_r[0];
					op_temp_w[7] = op_temp_r[7];
					op_temp_w[8] = op_temp_r[8];
				end
				4'd10: begin
					if(cmp1_out) begin
						op_temp_w[2] = op_temp_r[3];
						op_temp_w[3] = op_temp_r[2];
					end else begin
						op_temp_w[2] = op_temp_r[2];
						op_temp_w[3] = op_temp_r[3];
					end
					if(cmp4_out) begin
						op_temp_w[4] = op_temp_r[5];
						op_temp_w[5] = op_temp_r[4];
					end else begin
						op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5];
					end
					op_temp_w[0] = op_temp_r[0];
					op_temp_w[1] = op_temp_r[1];
					op_temp_w[6] = op_temp_r[6];
					op_temp_w[7] = op_temp_r[7];
					op_temp_w[8] = op_temp_r[8];
				end
				4'd11: begin
					if(cmp1_out) begin
						op_temp_w[3] = op_temp_r[4];
						op_temp_w[4] = op_temp_r[3];
					end else begin
						op_temp_w[3] = op_temp_r[3];
						op_temp_w[4] = op_temp_r[4];
					end
					for(i = 0; i < 3; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
					for(i = 5; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				default: begin
					for(i = 0; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
			endcase
			for(i = 0; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		MID_MEM: begin
			if(mf_pad_jg) begin
				case(conv_cnt_r)
					4'd0: begin
						op_temp_w[0] = i_mem_data;
						for(i = 1; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
					4'd1: begin
						op_temp_w[1] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd2: begin
						op_temp_w[2] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[1] = op_temp_r[1]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd3: begin
						op_temp_w[3] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[1] = op_temp_r[1]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd4: begin
						op_temp_w[4] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[1] = op_temp_r[1];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd5: begin
						op_temp_w[5] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[1] = op_temp_r[1]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd6: begin
						op_temp_w[6] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[1] = op_temp_r[1]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
					end
					4'd7: begin
						op_temp_w[7] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[1] = op_temp_r[1]; op_temp_w[8] = op_temp_r[8];
					end
					4'd8: begin
						op_temp_w[8] = i_mem_data;
						op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
						op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[1] = op_temp_r[1];
					end
					default: begin
						for(i = 0; i < 9; i = i + 1) begin
							op_temp_w[i] = op_temp_r[i];
						end
					end
				endcase
			end else begin
				for(i = 0; i < 9; i = i + 1) begin
					op_temp_w[i] = op_temp_r[i];
				end
			end
			for(i = 0; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		HA_TRANS: begin
			case(shift_cnt_r)
				5'd5: begin
					op_temp_w[0] = op_add_out;
					for(i = 1; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
				5'd6: begin
					op_temp_w[1] = op_add_out;
					op_temp_w[0] = op_temp_r[0]; op_temp_w[2] = op_temp_r[2]; op_temp_w[3] = op_temp_r[3]; op_temp_w[4] = op_temp_r[4];
					op_temp_w[5] = op_temp_r[5]; op_temp_w[6] = op_temp_r[6]; op_temp_w[7] = op_temp_r[7]; op_temp_w[8] = op_temp_r[8];
				end
				default: begin
					for(i = 0; i < 9; i = i + 1) begin
						op_temp_w[i] = op_temp_r[i];
					end
				end
			endcase
			for(i = 0; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		HA_CAL: begin
			for(i = 0; i < 9; i = i + 1) begin
				op_temp_w[i] = op_temp_r[i];
			end
			for(i = 0; i < 4; i = i + 1) begin
				mf_temp_w[i] = mf_temp_r[i];
			end
		end
		default: begin
			for(i = 0; i < 9; i = i + 1) begin
				op_temp_w[i] = 14'd0;
			end
			for(i = 0; i < 4; i = i + 1) begin
				mf_temp_w[i] = 8'd0;
			end
		end
	endcase
end

always @(*) begin
	case(ps)
		DISPLAY: begin
			o_out_valid_w = (display_flag) ? ~o_out_valid_r : o_out_valid_r;
			o_out_data_w  = {{6{1'b0}},i_mem_data};
		end
		CONV_OP: begin
			if(conv_op_done) begin
				o_out_valid_w = 1'b1;
				o_out_data_w  = op_add_out[13:0];
			end else begin
				o_out_valid_w = 1'b0;
				o_out_data_w  = 14'd0;
			end
		end
		MID_FILT: begin
			o_out_data_w = op_temp_r[4];
			case(shift_cnt_r)
				5'd0: o_out_valid_w = (|depth_cnt_r && !shift_cnt_r) ? 1'b1 : 1'b0;
				5'd9, 5'd14, 5'd19: o_out_valid_w = 1'b1;
				default: o_out_valid_w = 1'b0;
			endcase
		end
		HA_CAL: begin
			o_out_valid_w = (|conv_op_cnt_r) ? 1'b1 : 1'b0;
			case(conv_op_cnt_r)
				4'd1, 4'd2: o_out_data_w = $signed({op_add_out[13],op_add_out[13:1] + op_add_out[0]});
				4'd3, 4'd4: o_out_data_w = $signed({add2_out[11],add2_out[11:1] + add2_out[0]});
				default:    o_out_data_w = 14'd0;
			endcase
		end
		default: begin
			o_out_data_w  = 14'd0;
			o_out_valid_w = 1'b0;
		end
	endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		ps <= IDLE;
	end else begin
		ps <= ns;
	end
end

// SRAM
always @(negedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		wen_r <= 1'b1;
		cen_r <= 1'b0;
		o_mem_addr_r <= 12'd10;
		o_mem_data_r <= 8'd0;
	end else begin
		wen_r <= p_wen_r;
		cen_r <= p_cen_r;
		o_mem_addr_r <= o_p_mem_addr_r;
		o_mem_data_r <= o_p_mem_data_r;
	end
end

//----------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		p_wen_r <= 1'b1;
		p_cen_r <= 1'b0;
		o_p_mem_addr_r <= 12'd0;
		o_p_mem_data_r <= 8'd0;
	end else begin
		p_wen_r <= wen_w;
		p_cen_r <= cen_w;
		o_p_mem_addr_r <= o_mem_addr_w;
		o_p_mem_data_r <= o_mem_data_w;
	end
end
//----------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		row_cnt_r     <= 3'd0;
		col_cnt_r     <= 4'd0;
		display_cnt_r <= 5'd0;
	end else begin
		row_cnt_r     <= row_cnt_w;
		col_cnt_r     <= col_cnt_w;
		display_cnt_r <= dsiplay_cnt_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		o_op_ready_r <= 1'b0;
	end else begin
		o_op_ready_r <= o_op_ready_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		origin_r <= 7'd11;
	end else begin
		origin_r <= origin_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		depth_cnt_r <= 6'd0;
		shift_cnt_r <= 5'd0;
		conv_cnt_r  <= 4'd0;
		conv_op_cnt_r <= 4'd0;
	end else begin
		depth_cnt_r <= depth_cnt_w;
		shift_cnt_r <= shift_cnt_w;
		conv_cnt_r  <= conv_cnt_w;
		conv_op_cnt_r <= conv_op_cnt_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		add2_in0_r <= 12'd0;
		add2_in1_r <= 12'd0;
		op_add_in0_r <= 17'd0;
		op_add_in1_r <= 17'd0;
	end else begin
		add2_in0_r <= add2_in0_w;
		add2_in1_r <= add2_in1_w;
		op_add_in0_r <= op_add_in0_w;
		op_add_in1_r <= op_add_in1_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i = 0; i < 9; i = i + 1) begin
			op_temp_r[i] <= 14'd0;
		end
		for(i = 0; i < 4; i = i + 1) begin
			mf_temp_r[i] <= 8'd0;
		end
	end else begin
		for(i = 0; i < 9; i = i + 1) begin
			op_temp_r[i] <= op_temp_w[i];
		end
		for(i = 0; i < 4; i = i + 1) begin
			mf_temp_r[i] <= mf_temp_w[i];
		end
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		o_out_data_r  <= 14'd0;
		o_out_valid_r <= 1'b0;
	end else begin
		o_out_data_r  <= o_out_data_w;
		o_out_valid_r <= o_out_valid_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		for(i = 0; i < 3; i = i + 1) begin
			pad_delay[i] <= 1'b0;
		end
	end else begin
		pad_delay[0] <= mf_pad;
		pad_delay[1] <= pad_delay[0];
		pad_delay[2] <= pad_delay[1];
	end
end

endmodule

