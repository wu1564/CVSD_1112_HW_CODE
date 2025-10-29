`timescale 1ns/1ps
`define CYCLE 10

module ml_x_tb;

parameter DATA_WIDTH = 20;
parameter STORE_DATA = 64000;
parameter TEST_LLR_LEN = STORE_DATA;
parameter TEST_HB_LEN = 8000;
parameter GIVE_TIME = 1000;

// IO description
reg o_valid;
reg [5:0] o_valid_pulse;
wire o_x1_valid;

// tb signals
reg i_clk;
reg i_reset;
reg i_rd_rdy;
reg i_trig;
reg i_enable;
reg [5:0] cnt;
reg hb_gold[0:7999];
reg [159:0] i_y_hat[0:999];
reg [319:0] i_r[0:999];
reg [7:0] llr_gold[0:7999];
reg [DATA_WIDTH+1:0] LLR_x11_gold[0:STORE_DATA-1];
reg [DATA_WIDTH+1:0] LLR_x10_gold[0:STORE_DATA-1];
reg [DATA_WIDTH+1:0] LLR_x01_gold[0:STORE_DATA-1];
reg [DATA_WIDTH+1:0] LLR_x00_gold[0:STORE_DATA-1];
integer i;

// y_hat
reg [DATA_WIDTH-1:0] y1_real;
reg [DATA_WIDTH-1:0] y1_imag;
reg [DATA_WIDTH-1:0] y2_real;
reg [DATA_WIDTH-1:0] y2_imag;
reg [DATA_WIDTH-1:0] y3_real;
reg [DATA_WIDTH-1:0] y3_imag;
reg [DATA_WIDTH-1:0] y4_real;
reg [DATA_WIDTH-1:0] y4_imag;
// r parameters
reg [DATA_WIDTH-1:0] r11_real;
reg [DATA_WIDTH-1:0] r12_real;
reg [DATA_WIDTH-1:0] r12_imag;
reg [DATA_WIDTH-1:0] r22_real;
reg [DATA_WIDTH-1:0] r13_real;
reg [DATA_WIDTH-1:0] r13_imag;
reg [DATA_WIDTH-1:0] r23_real;
reg [DATA_WIDTH-1:0] r23_imag;
reg [DATA_WIDTH-1:0] r33_real;
reg [DATA_WIDTH-1:0] r14_real;
reg [DATA_WIDTH-1:0] r14_imag;
reg [DATA_WIDTH-1:0] r24_real;
reg [DATA_WIDTH-1:0] r24_imag;
reg [DATA_WIDTH-1:0] r34_real;
reg [DATA_WIDTH-1:0] r34_imag;
reg [DATA_WIDTH-1:0] r44_real;
wire [DATA_WIDTH+1:0] o_llr_x11;
wire [DATA_WIDTH+1:0] o_llr_x12;
wire [DATA_WIDTH+1:0] o_llr_x21;
wire [DATA_WIDTH+1:0] o_llr_x22;
wire [DATA_WIDTH+1:0] o_llr_x31;
wire [DATA_WIDTH+1:0] o_llr_x32;
wire [DATA_WIDTH+1:0] o_llr_x41;
wire [DATA_WIDTH+1:0] o_llr_x42;

reg [DATA_WIDTH-1:0] s1_real;
reg [DATA_WIDTH-1:0] s1_imag;
reg [DATA_WIDTH-1:0] s12_real;
reg [DATA_WIDTH-1:0] s12_imag;
reg [DATA_WIDTH-1:0] s2_real;
reg [DATA_WIDTH-1:0] s2_imag;
reg [DATA_WIDTH-1:0] s3_real;
reg [DATA_WIDTH-1:0] s3_imag;
reg [DATA_WIDTH-1:0] s4_real;
reg [DATA_WIDTH-1:0] s4_imag;
reg valid;

//0.707106781186547524405886264338327
// 46341=  0_000_1011010100000101 
// -46341= 1_111_0100101011111011 
//     bin:1_111_0100101011111011
x1 #(
    .DATA_WIDTH(DATA_WIDTH)
)x1_inst(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_enable(i_enable),
    .cnt(cnt),
    .i_y_hat(i_y_hat),
    .i_r(i_r),
    // LLR output
    .o_valid(o_x1_valid),
    .o_llr_x11(o_llr_x11),
    .o_llr_x12(o_llr_x12),
    .o_llr_x21(o_llr_x21),
    .o_llr_x22(o_llr_x22),
    .o_llr_x31(o_llr_x31),
    .o_llr_x32(o_llr_x32),
    .o_llr_x41(o_llr_x41),
    .o_llr_x42(o_llr_x42)
);

wire cnt_done;
assign cnt_done = (cnt == 6'd63);
wire cnt_start;
reg cnt_start_r;

assign cnt_start = i_trig | cnt_start_r;

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        cnt <= 7'b0;
        valid <= 1'b0;
        o_valid_pulse <= 5'd0;
        o_valid <= 1'b0;
        cnt_start_r <= 1'b0;
    end else begin
        o_valid_pulse <= {o_valid_pulse,cnt_done};
        if(i_trig) begin
            cnt_start_r <= 1'b1;
        end else begin
            cnt_start_r <= (cnt == 6'd63) ? 1'b0 : cnt_start;
        end
        if(o_valid_pulse[5]) begin
            o_valid <= ~o_valid;
        end else begin
            o_valid <= o_valid;
        end
        if(cnt_start) begin
            cnt <= cnt + 1;
        end else begin
            cnt <= 0;
        end
    end
end

initial begin
    i_clk = 0;
    forever #(`CYCLE/2) i_clk = ~i_clk;
end

initial begin
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet3/SNR10dB_pat_r.dat", i_r);
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet3/SNR10dB_pat_y_hat.dat", i_y_hat);
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet3/SNR10dB_hb.dat", hb_gold);
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet3/SNR10dB_llr.dat", llr_gold);
    $readmemh("./LLR_dat_x11_500.txt", LLR_x11_gold);
    $readmemh("./LLR_dat_x10_500.txt", LLR_x10_gold);
    $readmemh("./LLR_dat_x01_500.txt", LLR_x01_gold);
    $readmemh("./LLR_dat_x00_500.txt", LLR_x00_gold);
end

integer k;
initial begin
    i_enable = 1'b0;
    i_trig = 1'b0;
    valid = 1'b0;
    y1_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y1_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y2_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y2_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y3_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y3_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y4_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    y4_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    // y1_real = 0;
    // y1_imag = 0;
    // y2_real = 0;
    // y2_imag = 0;
    // y3_real = 0;
    // y3_imag = 0;
    // y4_real = 0;
    // y4_imag = 0;
    // r parameters
    r11_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r12_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r12_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r22_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r13_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r13_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r23_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r23_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r33_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r14_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r14_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r24_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r24_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r34_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r34_imag = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r44_real = {1'b0,{DATA_WIDTH-1{1'b1}}};
    r11_real = 0;
    r12_real = 0;
    r12_imag = 0;
    r22_real = 0;
    r13_real = 0;
    r13_imag = 0;
    r23_real = 0;
    r23_imag = 0;
    r33_real = 0;
    r14_real = 0;
    r14_imag = 0;
    r24_real = 0;
    r24_imag = 0;
    r34_real = 0;
    r34_imag = 0;
    r44_real = 0;
    i_reset = 1'b0; #(`CYCLE*5);
    i_reset = 1'b1; #(`CYCLE*5);
    i_reset = 1'b0; #(`CYCLE*5);

    for(k = 0; k < GIVE_TIME; k = k + 1) begin
        sendData(k);
        wait(cnt == 6'd63);
    end
end

// check if the LLR of each branch is correct 
integer error;
integer j, t, a;
integer shift, shift_cnt;
integer err_x00, err_x01, err_x10, err_x11;
initial begin
    error = 0;
    t = 0;
    err_x00 = 0;
    err_x01 = 0;
    err_x10 = 0;
    err_x11 = 0;
    for(a = 0; a < TEST_LLR_LEN; a = a + 1) begin
        wait(x1_inst.o_cu_valid);
        @(posedge i_clk);
        // if(x1_inst.done_dy_r[5]) begin
        if(x1_inst.o_cu_valid) begin
            if(x1_inst.o_cu_llr[3] !== LLR_x11_gold[a]) err_x00 = 1;
            if(x1_inst.o_cu_llr[2] !== LLR_x10_gold[a]) err_x01 = 1;
            if(x1_inst.o_cu_llr[1] !== LLR_x01_gold[a]) err_x10 = 1;
            if(x1_inst.o_cu_llr[0] !== LLR_x00_gold[a]) err_x11 = 1;
            if(err_x00 | err_x01 | err_x10 | err_x11) error = error + 1;
            if(err_x00) begin
                $display("------------------------------------------------");
                $display("Soft Bits:");
                $display("Wrong ! No.%d time:%t o_llr_x00:%h, o_llr_x00_gold:%h", a, $time, x1_inst.o_cu_llr[0], LLR_x00_gold[a]);
                $display("------------------------------------------------");
            end
            if(err_x01) begin
                $display("------------------------------------------------");
                $display("Soft Bits:");
                $display("Wrong ! No.%d time:%t o_llr_x01:%h, o_llr_x01_gold:%h", a, $time, x1_inst.o_cu_llr[1], LLR_x01_gold[a]);
                $display("------------------------------------------------");
            end
            if(err_x10) begin
                $display("------------------------------------------------");
                $display("Soft Bits:");
                $display("Wrong ! No.%d time:%t o_llr_x10:%h, o_llr_x10_gold:%h", a, $time, x1_inst.o_cu_llr[2], LLR_x10_gold[a]);
                $display("------------------------------------------------");
            end
            if(err_x11) begin
                $display("------------------------------------------------");
                $display("Soft Bits:");
                $display("Wrong ! No.%d time:%t o_llr_x11:%h, o_llr_x11_gold:%h", a, $time, x1_inst.o_cu_llr[3], LLR_x11_gold[a]);
                $display("------------------------------------------------");
            end
        end
    end
    if(error == 0) begin
        $display("------------------------------------------------");
        $display("All LLR data matched!");
        $display("------------------------------------------------");
    end else begin
        $display("------------------------------------------------");
        $display("Total %d errors found!", error);
        $display("------------------------------------------------");
    end
end


// // write file
// integer llr_fl;
// initial begin
//     llr_fl = $fopen("myLLR.txt", "w");
// end

integer err_hb;
integer o_err_x[0:7];
integer index = 0;
wire isWrong[0:7];
assign isWrong[0] = (o_llr_x11[DATA_WIDTH-1] !== hb_gold[index]);
assign isWrong[1] = (o_llr_x12[DATA_WIDTH-1] !== hb_gold[index+1]);
assign isWrong[2] = (o_llr_x21[DATA_WIDTH-1] !== hb_gold[index+2]);
assign isWrong[3] = (o_llr_x22[DATA_WIDTH-1] !== hb_gold[index+3]);
assign isWrong[4] = (o_llr_x31[DATA_WIDTH-1] !== hb_gold[index+4]);
assign isWrong[5] = (o_llr_x32[DATA_WIDTH-1] !== hb_gold[index+5]);
assign isWrong[6] = (o_llr_x41[DATA_WIDTH-1] !== hb_gold[index+6]);
assign isWrong[7] = (o_llr_x42[DATA_WIDTH-1] !== hb_gold[index+7]);

initial begin
    err_hb = 0;
    while (index < TEST_HB_LEN) begin
        wait(o_x1_valid === 1'b1);
        @(posedge i_clk);
        if(o_x1_valid) begin
            case(1'b1)
                isWrong[0]:  begin
                    $display("Wrong ! No.%d Time:%t Your x11:%h, Golden:%h", index/8, $time, o_llr_x11[DATA_WIDTH-1], hb_gold[index]);
                    err_hb = err_hb + 1;
                end
                isWrong[1]:  begin
                    $display("Wrong ! No.%d Time:%t Your x12:%h, Golden:%h", index/8, $time, o_llr_x12[DATA_WIDTH-1], hb_gold[index+1]);
                    err_hb = err_hb + 1;
                end
                isWrong[2]:  begin
                    $display("Wrong ! No.%d Time:%t Your x21:%h, Golden:%h", index/8, $time, o_llr_x21[DATA_WIDTH-1], hb_gold[index+2]);
                    err_hb = err_hb + 1;
                end
                isWrong[3]:  begin
                    $display("Wrong ! No.%d Time:%t Your x22:%h, Golden:%h", index/8, $time, o_llr_x22[DATA_WIDTH-1], hb_gold[index+3]);
                    err_hb = err_hb + 1;
                end
                isWrong[4]:  begin
                    $display("Wrong ! No.%d Time:%t Your x31:%h, Golden:%h", index/8, $time, o_llr_x31[DATA_WIDTH-1], hb_gold[index+4]);
                    err_hb = err_hb + 1;
                end
                isWrong[5]:  begin
                    $display("Wrong ! No.%d Time:%t Your x32:%h, Golden:%h", index/8, $time, o_llr_x32[DATA_WIDTH-1], hb_gold[index+5]);
                    err_hb = err_hb + 1;
                end
                isWrong[6]:  begin
                    $display("Wrong ! No.%d Time:%t Your x41:%h, Golden:%h", index/8, $time, o_llr_x41[DATA_WIDTH-1], hb_gold[index+6]);
                    err_hb = err_hb + 1;
                end
                isWrong[7]:  begin
                    $display("Wrong ! No.%d Time:%t Your x42:%h, Golden:%h", index/8, $time, o_llr_x42[DATA_WIDTH-1], hb_gold[index+7]);
                    err_hb = err_hb + 1;
                end
                default: begin
                end
            endcase
        end
        index = index + 8;
        #1;
    end
    if(err_hb == 0) begin
        $display("------------------------------------------------");
        $display("Congradulations ! ALL DATA PASS !");
        $display("------------------------------------------------");
    end else begin
        $display("------------------------------------------------");
        $display("Total Wrong: %d Found !", err_hb);
        $display("------------------------------------------------");
    end
    $stop;
end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        i_enable <= 1'b0;
    end else begin
        i_enable <= (!i_trig && cnt == 0 && i_enable == 0) ? 1'b0 : 1'b1;
    end
end

task sendData;
input integer i;
begin
    @(posedge i_clk);
    i_trig = 1'b1;
    // @(posedge i_clk);
    // Continuous Assignments
    y1_real = i_y_hat[i][19:0];
    y1_imag = i_y_hat[i][39:20];
    y2_real = i_y_hat[i][59:40];
    y2_imag = i_y_hat[i][79:60];
    y3_real = i_y_hat[i][99:80];
    y3_imag = i_y_hat[i][119:100];
    y4_real = i_y_hat[i][139:120];
    y4_imag = i_y_hat[i][159:140];
    // r parameters
    r11_real = i_r[i][19:0];
    r12_real = i_r[i][39:20];
    r12_imag = i_r[i][59:40];
    r22_real = i_r[i][79:60];
    r13_real = i_r[i][99:80];
    r13_imag = i_r[i][119:100];
    r23_real = i_r[i][139:120];
    r23_imag = i_r[i][159:140];
    r33_real = i_r[i][179:160];
    r14_real = i_r[i][199:180];
    r14_imag = i_r[i][219:200];
    r24_real = i_r[i][239:220];
    r24_imag = i_r[i][259:240];
    r34_real = i_r[i][279:260];
    r34_imag = i_r[i][299:280];
    r44_real = i_r[i][319:300];
    @(posedge i_clk);
    i_trig = 1'b0;
end
endtask

endmodule
