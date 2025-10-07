module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	// instruction memory
	output [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	// data memory
	output                  o_d_we,
	output [ ADDR_W-1 : 0 ] o_d_addr,
	output [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	// core output
	output [        1 : 0 ] o_status,
	output                  o_status_valid
);

// state machine
localparam IDLE     = 3'd0;
localparam FETCH    = 3'd1;
localparam EXEC     = 3'd2;
localparam DATA_MEM = 3'd3;
localparam PC_GEN   = 3'd4;
localparam NOP      = 3'd5;

// operation
localparam OP_ADD  = 6'd0;
localparam OP_SUB  = 6'd1;
localparam OP_ADDU = 6'd2;
localparam OP_SUBU = 6'd3;
localparam OP_ADDI = 6'd4;
localparam OP_LW   = 6'd5;
localparam OP_SW   = 6'd6;
localparam OP_AND  = 6'd7;
localparam OP_OR   = 6'd8;
localparam OP_XOR  = 6'd9;
localparam OP_BEQ  = 6'd10;
localparam OP_BNE  = 6'd11;
localparam OP_SLT  = 6'd12;
localparam OP_SLL  = 6'd13;
localparam OP_SRL  = 6'd14;
localparam OP_BLT  = 6'd15;
localparam OP_BGE  = 6'd16;
localparam OP_BLTU = 6'd17;
localparam OP_BGEU = 6'd18;
localparam OP_EOF  = 6'd19;

// MIPS status definition
localparam R_TYPE_SUCCESS = 0;
localparam I_TYPE_SUCCESS = 1;
localparam MIPS_OVERFLOW  = 2;
localparam MIPS_END       = 3;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
reg [2:0] ns, ps;
reg [1:0] cnt_r, cnt_w;
// program counter for instruction memory 
reg [ADDR_W-1:0] pc_w, pc_r;
// instruction decoder
wire type;
wire isBranch;
wire [5:0] opcode;
wire [4:0] s1, s2, s3;
wire signed [15:0] im;
// register file
// connect module
wire we;
wire [log2(DATA_W)-1:0] rf_addr0, rf_addr1;
wire [DATA_W-1:0] rf_writeData;
wire [DATA_W-1:0] rf_dataOut0, rf_dataOut1;
// wire part
reg  we_w;
reg  [log2(DATA_W)-1:0] rf_addr0_w, rf_addr1_w;
reg  [DATA_W-1:0] rf_writeData_w;
// sequencial part
reg  we_r;
reg  [log2(DATA_W)-1:0] rf_addr0_r, rf_addr1_r;
reg  [DATA_W-1:0] rf_writeData_r;
// flag
wire fetch_done;
wire exec_done;
wire jump_DM_state;
wire pc_gen_done;
wire eof_state;
wire branchJump;
// adder 
wire [DATA_W-1:0] neg_add_in1;
wire signed [DATA_W:0] add_out;
reg  signed [DATA_W:0] add_in0_w, add_in1_w;
reg  signed [DATA_W:0] add_in0_r, add_in1_r;
//comparator
wire compare_out;
wire equal;
reg  [DATA_W-1:0] compare_in0, compare_in1;
// data memory
reg o_d_we_w;
reg [ADDR_W-1:0] o_d_addr_w;
reg [DATA_W-1:0] o_d_wdata_w;
// core output
reg [1:0] o_status_w;
reg o_status_valid_w;
// overflow
wire overflow;
wire overflow_DM, overflow_IM;
reg  overflow_w, overflow_r;

// ---------------------------------------------------------------------------
// module
// ---------------------------------------------------------------------------
inst_decoder #(
	.INST_W(INST_W)
)decoder (
	.i_i_inst(i_i_inst),
	.type(type),
	.s1(s1),
	.s2(s2),
	.s3(s3),
	.im(im),
	.opcode(opcode),
	.isBranch(isBranch)
);

registerFile #(
    .DATA_W(DATA_W),
    .DEPTH(32)
)RF(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.we(we), // read: we == 0, write: we == 1
	.addr0(rf_addr0),
	.addr1(rf_addr1),
	.writeData_i(rf_writeData),
	.dataOut0(rf_dataOut0),
	.dataOut1(rf_dataOut1)
);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign we = we_r;
assign rf_addr0 = rf_addr0_r;
assign rf_addr1 = rf_addr1_r;
assign rf_writeData = rf_writeData_r;
assign fetch_done  = (cnt_r == 2'd1);
assign exec_done   = fetch_done;
assign pc_gen_done = fetch_done;
assign branchJump  = isBranch & fetch_done;
assign jump_DM_state = ((opcode == 6'd5 || opcode == 6'd6) && exec_done);
assign equal = (rf_dataOut0 == rf_dataOut1);
assign eof_state = (opcode == 6'd19);
assign o_d_addr  = o_d_addr_w;
assign o_d_wdata = o_d_wdata_w;
assign o_d_we    = o_d_we_w;
assign o_status  = o_status_w;
assign o_status_valid = o_status_valid_w;
assign overflow_DM = (|add_out[10:8])  | overflow_IM;
assign overflow_IM = |add_out[32:12];
assign overflow    = overflow_w | overflow_r;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// state machine
always @(*) begin
	case(ps)
		IDLE: ns = FETCH;
		FETCH: begin
			case(1'b1)
				eof_state:  ns = NOP;
				branchJump: ns = PC_GEN;
				fetch_done: ns = EXEC;
				default:    ns = FETCH;
			endcase
		end
		EXEC: begin
			case(1'b1)
				jump_DM_state: ns = DATA_MEM;
				exec_done:     ns = PC_GEN;
				default:       ns = EXEC;
			endcase
		end
		DATA_MEM: ns = PC_GEN;
		PC_GEN:   begin
			case(1'b1)
				overflow:    ns = NOP;
				pc_gen_done: ns =FETCH;
				default:     ns = PC_GEN;
			endcase
		end
		NOP:      ns = NOP;
		default:  ns = IDLE;			
	endcase
end

always @(*) begin
	case(ps)
		FETCH, EXEC, PC_GEN:   cnt_w = (fetch_done) ? 2'd0 : cnt_r + 2'd1;
		default: cnt_w = 2'd0;
	endcase
end

// instruction memory
assign o_i_addr = pc_r;
always @(*) begin
	if(ps == PC_GEN && pc_gen_done) begin
		pc_w = $unsigned(add_out[DATA_W-1:0]);
	end else begin
		pc_w = pc_r;
	end
end

// register file
always @(*) begin
	case(ps)
		FETCH: begin
			we_w = we_r;
			rf_writeData_w = rf_writeData_r;
			if(fetch_done) begin
				if(type == 1'b1) begin // I type
					rf_addr0_w = s1;
					rf_addr1_w = s2;
				end else begin		   // R type
						rf_addr0_w = s2;
						rf_addr1_w = s3;
				end
			end else begin
				rf_addr0_w = rf_addr0_r;
				rf_addr1_w = rf_addr0_r;
			end
		end
		EXEC: begin
			case(opcode)
				OP_ADD, OP_SUB, 
				OP_ADDU, OP_SUBU, OP_ADDI: rf_writeData_w = add_out[DATA_W-1:0];
				OP_AND:  rf_writeData_w = rf_dataOut0 & rf_dataOut1;
				OP_OR:   rf_writeData_w = rf_dataOut0 | rf_dataOut1;
				OP_XOR:  rf_writeData_w = rf_dataOut0 ^ rf_dataOut1;
				OP_SLL:  rf_writeData_w = rf_dataOut0 << rf_dataOut1;
				OP_SRL:  rf_writeData_w = rf_dataOut0 >> rf_dataOut1;
				OP_SLT:  rf_writeData_w = (compare_out) ? 32'd1 : 32'd0;
				default: rf_writeData_w = 32'd0;
			endcase
			rf_addr0_w = (exec_done) ? s1 : s2;
			rf_addr1_w = rf_addr1_r;
			if(exec_done && opcode != OP_SW && opcode != OP_LW && ~isBranch) begin
				we_w = 1'b1;
			end else begin
				we_w = 1'b0;
			end			
		end
		DATA_MEM: begin
			we_w = opcode[0];
			rf_addr0_w = s1;
			rf_addr1_w = rf_addr1_r;
			rf_writeData_w = i_d_rdata;
		end
		default: begin
			we_w = 1'b0;
			rf_addr0_w = rf_addr0_r;
			rf_addr1_w = rf_addr1_r;
			rf_writeData_w = rf_writeData_r;
		end
	endcase
end

// adder
assign neg_add_in1 = ~rf_dataOut1 + 1'b1;
assign add_out = $signed(add_in0_r) + $signed(add_in1_r);
always @(*) begin
	if(ps != PC_GEN) begin
		case(opcode)
			// arthematic
			OP_ADD: begin
				add_in0_w = $signed(rf_dataOut0);
				add_in1_w = $signed(rf_dataOut1);
			end
			OP_SUB: begin
				add_in0_w = $signed(rf_dataOut0);
				add_in1_w = $signed(neg_add_in1);
			end
			OP_ADDU: begin
				add_in0_w = $signed({1'b0,rf_dataOut0});
				add_in1_w = $signed({1'b0,rf_dataOut1});
			end
			OP_SUBU: begin
				add_in0_w = $signed({1'b0,rf_dataOut0});
				add_in1_w = $signed({1'b0,neg_add_in1});
			end
			OP_ADDI, OP_LW, OP_SW: begin //load $s1 = Mem[$s2 + im] 
				add_in0_w = $signed(rf_dataOut1);
				add_in1_w = im;
			end
			default: begin
				add_in0_w = 32'd0;
				add_in1_w = 32'd0;
			end
		endcase
	end else begin
		case(opcode)
			OP_BEQ: begin
				add_in0_w = $signed({1'b0, pc_r});
				if(equal) begin
					add_in1_w = $signed({1'b0, im});
				end else begin
					add_in1_w = 32'sd4;
				end
			end
			OP_BNE: begin
				add_in0_w = $signed({1'b0, pc_r});
				if(equal) begin
					add_in1_w = 32'sd4;
				end else begin
					add_in1_w = $signed({1'b0, im});
				end
			end
			OP_BLT: begin
				add_in0_w = $signed(pc_r);
				if(compare_out) begin
					add_in1_w = $signed(im);
				end else begin
					add_in1_w = 32'sd4;
				end				
			end
			OP_BLTU: begin
				add_in0_w = $signed({1'b0, pc_r});
				if(compare_out) begin
					add_in1_w = $signed({1'b0, im});
				end else begin
					add_in1_w = 32'sd4;
				end		
			end
			OP_BGE: begin
				add_in0_w = $signed(pc_r);
				if(compare_out) begin
					add_in1_w = 32'sd4;
				end else begin
					add_in1_w = $signed(im);
				end							
			end
			OP_BGEU: begin
				add_in0_w = $signed({1'b0, pc_r});
				if(compare_out) begin
					add_in1_w = 32'sd4;
				end else begin
					add_in1_w = $signed({1'b0, im});
				end		
			end
			default: begin
				add_in0_w = $signed(pc_r);
				add_in1_w = 32'sd4;
			end
		endcase
	end
end

// comparator
assign compare_out = ($signed(compare_in0) > $signed(compare_in1));
always @(*) begin
	compare_in0 = rf_dataOut1;
	compare_in1 = rf_dataOut0;
end

// data memory
always @(*) begin
	o_d_we_w    = (ps == DATA_MEM && opcode == OP_SW) ? 1'b1 : 1'b0;
	o_d_addr_w  = add_out[DATA_W-1:0];
	o_d_wdata_w = rf_dataOut0;
end

//core output
always @(*) begin
	case(ps)
		PC_GEN: begin
			if(pc_gen_done) begin
				o_status_w = {1'b0, type};
				o_status_valid_w = 1'b1;
			end else begin
				o_status_w = 2'd0;
				o_status_valid_w = 1'b0;
			end
		end
		NOP: begin
			o_status_valid_w = 1'b1;
			o_status_w = (overflow_r) ? 2'b10 : 2'b11;
		end
		default: begin
			o_status_w = 2'd0;
			o_status_valid_w = 1'b0;
		end
	endcase
end

always @(*) begin
	// three conditions 
	// 1. arthemetic overflow 
	// add, sub, addi, addu, subu, 
	// exec_done
	// 2. data memory overflow         o_d_addr[7:2]
	// time to judge
	// exec_done
	// 3. instruction memory overflow  o_i_addr[11:2]
	// pc_gen_done

	// time to judge
	overflow_w = overflow_r;
	if(exec_done && ps == EXEC) begin
		case(opcode)
			OP_LW, OP_SW: overflow_w = overflow_DM;
			OP_ADD, OP_ADDI, OP_SUB: overflow_w = add_out[DATA_W] ^ add_out[DATA_W-1];
			OP_ADDU: overflow_w = add_out[DATA_W];
			OP_SUBU: overflow_w = ~add_out[DATA_W];
			default: overflow_w = overflow_r;
		endcase
	end else if(isBranch && ps == PC_GEN && pc_gen_done) begin
		overflow_w = overflow_IM;
	end 
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

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		cnt_r <= 2'd0;
	end else begin
		cnt_r <= cnt_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		pc_r <= 32'd0;
	end else begin
		pc_r <= pc_w;
	end
end

//adder 
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		add_in0_r <= 33'd0;
		add_in1_r <= 33'd0;
	end else begin
		add_in0_r <= add_in0_w;
		add_in1_r <= add_in1_w;
	end
end

// RF
always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		we_r <= 1'b0;
		rf_addr0_r <= {log2(DATA_W){1'b0}};
		rf_addr1_r <= {log2(DATA_W){1'b0}};
		rf_writeData_r <= 32'd0;
	end else begin
		we_r <= we_w;
		rf_addr0_r <= rf_addr0_w;
		rf_addr1_r <= rf_addr1_w;
		rf_writeData_r <= rf_writeData_w;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		overflow_r <= 1'b0;
	end else begin
		overflow_r <= overflow_w;
	end
end

//----------------------------------------------------------------

function integer log2;
   input integer value;
   begin
     value = value-1;
     for (log2=0; value>0; log2=log2+1)
       value = value>>1;
   end
 endfunction

endmodule
