// vlog ml_demodulator_tb.v ./ml_demodulator.v ./ml_dataPath.v ./ml_x.v ./ml_cu.v ./mult.v ./mult_add.v ml_controller.v mult2add_2.v mult2add_4.v
// cd D:/Hardware/IC/NTU_CVSD/CVSD_111_2/111-2_HW/FINAL/final_project/01_RTL/simulation
`timescale 1ns/1ps
`define CYCLE 10

module ml_controller_tb;

parameter DATA_WIDTH = 8;
parameter DEPTH = 16;
parameter GIVE_TIME = 10;

// IO description
reg i_clk;
reg i_reset;
reg i_trig;
reg [159:0] i_y_hat;
reg [319:0] i_r;
// ml output
wire ml_llr_valid;
wire [7:0] ml_hardbit;
//
integer i;
reg [5:0] cnt;

reg i_rd_rdy;
reg i_x_valid;
reg [7:0] i_x_hard_bit;

ml_controller #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
)ml_controller_inst(
    .i_clk(i_clk),             
    .i_reset(i_reset),
    .i_rd_rdy(i_rd_rdy),
    .i_x_valid(i_x_valid),             // x output
    .i_x_hard_bit(i_x_hard_bit),
    .o_rd_vld(o_rd_vld),
    .o_hard_bit(o_hard_bit)
);


initial begin
    i_clk = 0;
    forever #(`CYCLE/2) i_clk = ~i_clk;
end


// 10010101


integer n;

reg [7:0] testdata[0:9];
reg [7:0] testdata2[0:9];
initial begin
    i_rd_rdy = 0;
    i_x_valid = 0;
    for(i = 0; i < 10; i = i + 1) begin
        testdata2[i] = i;
    end
    testdata[0] = 8'b10010101;
    testdata[1] = 8'b10101110;
    testdata[2] = 8'b11010101;
    testdata[3] = 8'b10011110;
    testdata[4] = 8'b11111110;
    testdata[5] = 8'b00000010;
    testdata[6] = 8'b11010111;
    testdata[7] = 8'b10011100;
    testdata[8] = 8'b10011101;
    testdata[9] = 8'b10010110;
    i_reset = 1'b0; #(`CYCLE*5);
    i_reset = 1'b1; #(`CYCLE*5);
    i_reset = 1'b0; #(`CYCLE*5);

    @(posedge i_clk);
    for(n = 0; n < GIVE_TIME; n = n + 1) begin
        sendData(testdata[n]);
        repeat(63) @(posedge i_clk);
    end

    repeat(200) @(posedge i_clk);
    for(n = 0; n < GIVE_TIME; n = n + 1) begin
        sendData(testdata2[n]);
        repeat(63) @(posedge i_clk);
    end
end

initial begin
    @(posedge i_clk);
    rdy_pulse;
    repeat(1024) @(posedge i_clk);
    rdy_pulse;
    repeat($random()%1024) @(posedge i_clk);
    rdy_pulse;
    repeat($random()%1024) @(posedge i_clk);
    rdy_pulse;
    repeat($random()%1024) @(posedge i_clk);
    rdy_pulse;
end

task sendData;
input reg[7:0] x_input;
begin
    i_x_valid = 1'b1;
    i_x_hard_bit = x_input;
    @(posedge i_clk);
    i_x_valid = 1'b0;
end
endtask


task rdy_pulse;
begin
    i_rd_rdy = 1'b1;
    repeat(128) @(posedge i_clk);
    i_rd_rdy = 1'b0;
end
endtask

reg cnt_valid;
wire cnt_valid_w = i_x_valid | cnt_valid;
reg [7:0] ml_data;
reg [2:0] ml_cnt;
always @(posedge i_clk or posedge i_reset) begin
    if(i_reset) begin
        cnt <= 0;
        cnt_valid <= 0;
        ml_data <= 0;
        ml_cnt <= 0;
    end else begin
        cnt <= (cnt_valid_w) ? cnt + 1 : cnt;
        if(i_x_valid) begin
            cnt_valid <= 1;
        end else if(cnt == 63) begin
            cnt_valid <= 0;
        end

        if(o_rd_vld && i_rd_rdy) begin
            ml_cnt <= ml_cnt + 1;
            ml_data[ml_cnt] <= o_hard_bit;
        end
    end
end




endmodule
