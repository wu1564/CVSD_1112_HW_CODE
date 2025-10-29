// cd D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/01_RTL/simulation/
// vlog ml_demodulator_tb.v ./ml_demodulator.v ./ml_dataPath.v ./ml_x.v ./ml_cu.v ./mult.v ./mult_add.v
`timescale 1ns/1ps
`define CYCLE 10

module ml_demodulator_tb;

parameter DATA_WIDTH = 20;
parameter TEST_HB_LEN = 8000;
parameter GIVE_TIME = 1000;

// IO description
reg i_clk;
reg i_reset;
reg i_trig;
reg i_rd_rdy;
reg [159:0] i_y_hat;
reg [319:0] i_r;
// Test Data
reg [159:0] i_y_hat_arr[0:999];
reg [319:0] i_r_arr[0:999];
reg hb_gold[0:7999];
// ml output
wire o_hard_bit;
// testbench
reg [7:0] ml_hardbit;
reg [2:0] ml_cnt;
reg check_time;

//
integer i;

ml_demodulator ml_demo(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_trig(i_trig),
    .i_y_hat(i_y_hat),
    .i_r(i_r),

    .i_rd_rdy(i_rd_rdy),
    .o_rd_vld(o_rd_vld),
    .o_llr(),
    .o_hard_bit(o_hard_bit)
);


initial begin
    i_clk = 0;
    forever #(`CYCLE/2) i_clk = ~i_clk;
end

initial begin
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet6/SNR15dB_pat_r.dat", i_r_arr);
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet6/SNR15dB_pat_y_hat.dat", i_y_hat_arr);
    $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet6/SNR15dB_hb.dat", hb_gold);
    // $readmemh("D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/00_TESTBED/PATTERN/packet3/SNR10dB_llr.dat", llr_gold);
end

integer n;
initial begin
    i_trig = 1'b0;
    i_reset = 1'b0; #(`CYCLE*5);
    i_reset = 1'b1; #(`CYCLE*5);
    i_reset = 1'b0; #(`CYCLE*5);

    @(posedge i_clk);
    for(n = 0; n < GIVE_TIME; n = n + 1) begin
        sendData(n);
        repeat(63) @(posedge i_clk);
    end
end

initial begin
    @(posedge i_clk);
    rdy_pulse; // 640 cycles
    //
    // $display("%t start continuous delay 128+128", $time);
    rdy_pulse_num(512);
    // $display("%t start worst case", $time);
    rdy_pulse_num(0);
    // $display("%t end continuouse delay", $time);
    rdy_pulse_num(512);
    // $display("%t end worst case", $time);
    for(i = 0; i < 2000; i = i + 1) begin
        // rdy_pulse_num(0);
        // $display("%t end continuouse delay", $time);
        // rdy_pulse_num(512);
        rdy_pulse;
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
assign isWrong[0] = (ml_hardbit[0] !== hb_gold[index]);
assign isWrong[1] = (ml_hardbit[1] !== hb_gold[index+1]);
assign isWrong[2] = (ml_hardbit[2] !== hb_gold[index+2]);
assign isWrong[3] = (ml_hardbit[3] !== hb_gold[index+3]);
assign isWrong[4] = (ml_hardbit[4] !== hb_gold[index+4]);
assign isWrong[5] = (ml_hardbit[5] !== hb_gold[index+5]);
assign isWrong[6] = (ml_hardbit[6] !== hb_gold[index+6]);
assign isWrong[7] = (ml_hardbit[7] !== hb_gold[index+7]);

initial err_hb = 0;

initial begin
    wait(index == 8000);
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

integer er = 0;
integer temp = 0;
always @(posedge i_clk) begin
    if(o_rd_vld && i_rd_rdy) begin
        temp = index % 8;
        if(index < TEST_HB_LEN) begin
            if(o_hard_bit !== hb_gold[index]) begin
                er = 1;
            end
        end 
        if(temp == 7) begin
            if(er == 1) begin
                $display("Wrong ! No.%d Time:%t Your:%h, Golden:%h", index/8, $time, o_hard_bit, hb_gold[index]);
                err_hb = err_hb + 1;
            end
            er = 0;
        end
        index = index + 1;
    end
end

always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        ml_hardbit <= 0;
        ml_cnt <= 0;
        check_time <= 0;
    end else begin
        if(o_rd_vld && i_rd_rdy) begin
            ml_cnt <= ml_cnt + 1;
            ml_hardbit[ml_cnt] <= o_hard_bit;
        end
        if(check_time == 1 || check_time == 7) begin
            check_time = 0;
        end else if(check_time == 0 && ml_cnt == 7) begin
            check_time = 1;
        end 
    end
end

integer random_delay;
task rdy_pulse;
begin
    random_delay = ($random($realtime) & 32'h7FFFFFFF) % 513;
    // $display("delay num :%d", random_delay);
    #1 i_rd_rdy = 1'b0;
    repeat(random_delay) @(posedge i_clk);
    #1 i_rd_rdy = 1'b1;
    repeat(128) @(posedge i_clk);
    #1 i_rd_rdy = 1'b0;
    repeat(512 - random_delay) @(posedge i_clk);
end
endtask

task rdy_pulse_num;
input integer delay;
begin
    #1 i_rd_rdy = 1'b0;
    repeat(delay) @(posedge i_clk);
    #1 i_rd_rdy = 1'b1;
    repeat(128) @(posedge i_clk);
    #1 i_rd_rdy = 1'b0;
    repeat(512 - delay) @(posedge i_clk);
end
endtask

task sendData;
input integer i;
begin
    #1 i_trig  = 1'b1;
    #1 i_y_hat = i_y_hat_arr[i];
    #1 i_r     = i_r_arr[i];
    @(posedge i_clk);
    #1 i_trig = 1'b0;
end
endtask

endmodule
