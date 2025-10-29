`timescale 1ns/1ps
`define CYCLE 10

module FIFO_tb;
parameter DATA_WIDTH = 8;
parameter DEPTH = 16;

reg i_clk;
reg i_reset;
reg i_wen;
reg i_ren;
reg [DATA_WIDTH-1:0] i_wdata;
wire o_full;
wire o_empty;
wire o_valid;
wire [DATA_WIDTH-1:0] o_rdata;

FIFO #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
)FIFO_inst(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_wen(i_wen),
    .i_ren(i_ren),
    .i_wdata(i_wdata),
    .o_valid(o_valid),
    .o_full(o_full),
    .o_empty(o_empty),
    .o_rdata(o_rdata)
);

initial begin
    i_clk = 0;
    forever #(`CYCLE/2) i_clk = ~i_clk;
end

integer i;
initial begin
    i_wen = 0;
    i_ren = 0;
    i_reset = 1'b0; #(`CYCLE*5);
    i_reset = 1'b1; #(`CYCLE*5);
    i_reset = 1'b0; #(`CYCLE*5);

    @(posedge i_clk);
    // test 0 keep writing
    for(i = 0; i < DEPTH; i = i + 1) begin
        wrdata(i);
        if(i == 0) rdata();
    end
    for(i = 0; i < DEPTH; i = i + 1) begin
        wrdata(i);
    end
    repeat(10) @(posedge i_clk);
    flush();

    // test 1 keep reading
    for(i = 0; i < DEPTH; i = i + 1) wrdata(i+1);
    for(i = 0; i < DEPTH+5; i = i + 1) rdata();
    repeat(10) @(posedge i_clk);
    flush();

    // test 2 empty
    for(i = 0; i < 10; i = i + 1) wrdata(i+2);
    for(i = 0; i < 10; i = i + 1) rdata(); // empty now
    repeat(10) @(posedge i_clk);
    flush();

    // test 3 full
    for(i = 0; i < 10; i = i + 1) wrdata(i+3);
    for(i = 0; i < 5; i = i + 1) rdata(); 
    for(i = 0; i < 25; i = i + 1) wrdata(i+100); // full now
    repeat(10) @(posedge i_clk);
    flush();

    // test 4 ptr at the same position
    for(i = 0; i < 5; i = i + 1) wrdata(i+4);
    for(i = 0; i < 5; i = i + 1) rdata(); // empty
    for(i = 0; i < 5; i = i + 1) rdata(); // keep reading
    repeat(10) @(posedge i_clk);
    flush();
    
    // test 5 ptr at the same position
    for(i = 0; i < 5; i = i + 1) wrdata(i+5);
    for(i = 0; i < 5; i = i + 1) rdata(); // empty
    for(i = 0; i < DEPTH; i = i + 1) wrdata(i+1); // keep writing (full)
    for(i = 0; i < DEPTH; i = i + 1) wrdata(i+2); // keep writing
    repeat(10) @(posedge i_clk);
    flush();
end


task wrdata;
input reg[DATA_WIDTH-1:0] wdata;
begin
    @(posedge i_clk);
    i_wen = 1;
    i_wdata = wdata;
    @(posedge i_clk);
    i_wen = 0;
end
endtask

task rdata;
begin
    i_ren = 1;
    @(posedge i_clk);
    i_ren = 0;
end
endtask

task flush;
begin
    for(i = 0; i < DEPTH; i = i + 1) begin
        i_ren = 1;
        @(posedge i_clk);
        i_ren = 0;
    end
    #(`CYCLE * 10);
end
endtask

function integer clog2;
    input integer value;
    begin
        value = value - 1;
        for (clog2 = 0; value > 0; clog2 = clog2 + 1)
            value = value >> 1;
    end
endfunction

endmodule

