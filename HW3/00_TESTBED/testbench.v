`timescale 1ns/100ps
`define CYCLE       10.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   2


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
    `define OP_LEN 41
    `define GOLD_LEN 80
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
    `define OP_LEN 41
    `define GOLD_LEN 320
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERN/indata3.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
    `define OP_LEN 41
    `define GOLD_LEN 320
`elsif tb4
    `define INFILE "../00_TESTBED/PATTERN/indata4.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode4.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden4.dat"
    `define OP_LEN 121
    `define GOLD_LEN 708
`elsif tbh
    `define INFILE "../00_TESTBED/PATTERN/indatah.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmodeh.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/goldenh.dat"
    `define OP_LEN 501
    `define GOLD_LEN 2848
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
    `define OP_LEN 41
    `define GOLD_LEN 1984
`endif

`define SDFFILE "./Netlist/core_syn.sdf"  // Modify your sdf file name


module testbed;

reg         clk, rst_n;
reg         op_valid;
reg  [ 3:0] op_mode;
wire        op_ready;
reg         in_valid;
reg  [ 7:0] in_data;
wire        in_ready;
wire        out_valid;
wire [13:0] out_data;

reg  [ 7:0] indata_mem [0:2047];
reg  [ 3:0] opmode_mem [0:1023];
reg  [13:0] golden_mem [0:4095];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
integer i, index, j, error;
reg signed [13:0] s_golden_mem;
reg signed [13:0] s_out_data;

// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_core);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("core.fsdb");
  $fsdbDumpvars(3, "+mda");
end


core u_core (
	.i_clk       (clk),
	.i_rst_n     (rst_n),
	.i_op_valid  (op_valid),
	.i_op_mode   (op_mode),
    .o_op_ready  (op_ready),
	.i_in_valid  (in_valid),
	.i_in_data   (in_data),
	.o_in_ready  (in_ready),
	.o_out_valid (out_valid),
	.o_out_data  (out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

// Clock generation
initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

// Reset generation
initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

// ==============================================
// TODO: Check pattern after process finish
// ==============================================
initial begin
    in_data  = 8'd0;
    op_mode  = 4'd0;
    in_valid = 1'b0;
    op_valid = 1'b0;
    for(i = 0; i < `OP_LEN; i = i + 1) begin
        op_mode = 4'd0;
        wait(op_ready == 1'b1);
        #(`CYCLE) @(negedge clk);
        op_valid = 1'b1;
        op_mode = opmode_mem[i];
        #(`CYCLE); 
        #1 op_valid = 1'b0;
        if(op_mode == 4'd0) begin
            load_image_data;
        end
    end
end

initial begin
    j = 0;
    error = 0;
    while(j < `GOLD_LEN) begin
        @(negedge clk);
        if(out_valid == 1'b1) begin
            if(out_data != golden_mem[j]) begin
                s_golden_mem = golden_mem[j];
                s_out_data = out_data;
                $display("[%d]: Error! Time:%d Golden=%b[%d], Yours=%b[%d]  Signed Golden=[%d], Signed Yours=[%d]", j, $time, golden_mem[j], golden_mem[j], out_data, out_data, s_golden_mem, s_out_data);
                error = error + 1;
            end
            j = j + 1;
        end
    end
    if(error == 0) begin
        $display("----------------------------------------------");
        $display("-                 ALL PASS!                  -");
        $display("----------------------------------------------");
    end else begin
        $display("----------------------------------------------");
        $display("  Wrong! Total error: %d                      ", error);
        $display("----------------------------------------------");
    end
    $finish;
end

initial begin
    wait((in_valid && out_valid) || 
         (op_valid && out_valid) || 
         (in_valid && op_ready)  || 
         (op_valid && op_ready));
    $display("-------------------------------------------------");
    $display("There's some error here, so the process finished");
    $display("-------------------------------------------------");
    $finish;
end

//-----------------------------------------

task load_image_data;
begin
    index = 0;
    in_valid = 1'b1;
    for(index = 0; index < 2048; index = index + 1) begin
        if(in_ready == 1'b1) begin
            in_data = indata_mem[index];
        end else begin
            index = index - 1;
        end
        @(negedge clk);
    end
    in_valid = 1'b0;
    in_data  = 8'd0;
end
endtask




// always @(u_core.mf_temp_r[0][2]) begin
//     if(u_core.ps == 8)
//         $display("1 %4t, mf_temp_r[0][2] = %d", $time, u_core.mf_temp_r[0][2]);
// end

// always @(u_core.mf_temp_r[2][0]) begin
//     if(u_core.ps == 8)
//         $display("2 %4t, mf_temp_r[2][0] = %d", $time, u_core.mf_temp_r[2][0]);
// end

endmodule
