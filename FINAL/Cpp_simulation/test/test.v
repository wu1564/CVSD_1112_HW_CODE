`timescale 1ns/10ps

module test;
// 4+16 
reg signed [39:0] target1;
reg signed [39:0] target2;
reg signed [39:0] mult1, mult2;
reg signed [19:0] result_r, result_i;
reg signed [19:0] result;
//[39:20][19:0]
initial begin
    target1 = 40'hfcb21_1fddc;
    target2 = 40'hfcb21_1fddc;
    //complexMult(target1, target2);
    complexNorm2(target1);
    sub(21'h0cfb7c, 21'h15e8d8);
    $display("sub:%x", mult1);
    // test
    mult1 = 40'sb110001110110101011100;
    $display("result:%x", mult1);
    mult1 = ~mult1 + 1'b1;
    $display("result:%x", mult1);
end

task complexNorm2;
input reg [39:0] tar1;
begin
    mult1 = tar1[0+:20] * tar1[0+:20];   // real * real
    mult2 = tar1[20+:20] * tar1[20+:20]; // imag * imag
    result_r = mult1[16+:20];
    $display("Real:%x", result_r); 
    result_i = mult2[16+:20];
    $display("Imag:%x", result_i);
    result = result_r + result_i;
    $display("ComplexNorm2:%x", result);
end
endtask

task sub;
input reg signed [20:0] tar1;
input reg signed [20:0] tar2;
begin
    mult1 = tar1 + ~tar2 + 1'b1;
end
endtask

task complexMult;
input reg signed [39:0] tar1;
input reg signed [39:0] tar2;
begin
    $display("Real:%x Imag:%x", tar1[0+:20], tar1[20+:20]);
    mult1 = tar1[19:0] * tar2[19:0]; // real * real
    result_r = mult1[16+:20];
    $display("mult1:%x", mult1[16+:20]);
    mult1 = tar1[20+:20] * tar2[20+:20]; // imag * imag
    $display("mult1:%x", mult1[16+:20]);
    result_r = result_r - mult1[16+:20];
    $display("Real:%x", result_r); 
    mult1 = tar1[0+:20] * tar2[20+:20]; // real * imag
    result_r = mult1[16+:20];
    $display("mult1:%x", mult1[16+:20]);
    mult1 = tar1[20+:20] * tar2[0+:20]; // imag * real
    $display("mult1:%x", mult1[16+:20]);
    result_r = result_r + mult1[16+:20];
    $display("Imag:%x", result_r);
end
endtask

endmodule

