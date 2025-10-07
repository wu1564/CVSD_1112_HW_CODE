`timescale 1ns/100ps
`include "../00_TESTBED/define.v"

`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000
`define DATA_MEM_DEPTH 64
`define RST_DELAY   2
`define SDF_FILE "./Netlist/core_syn.sdf"

`ifdef p0
    `define Inst   "../00_TESTBED/PATTERN/p0/inst.dat"
	`define DATA   "../00_TESTBED/PATTERN/p0/data.dat"
	`define STATUS "../00_TESTBED/PATTERN/p0/status.dat"
	`define STATUS_PATT_NUM 80 
`elsif p1
	`define Inst   "../00_TESTBED/PATTERN/p1/inst.dat"
	`define DATA   "../00_TESTBED/PATTERN/p1/data.dat"
	`define STATUS "../00_TESTBED/PATTERN/p1/status.dat"
	`define STATUS_PATT_NUM 11
`endif

module testbed;

reg clk = 0;
reg rst_n = 1;
// instruction memory
wire [ 31 : 0 ] imem_addr;
wire [ 31 : 0 ] imem_inst;
// data memory
wire            dmem_we;
wire [ 31 : 0 ] dmem_addr;
wire [ 31 : 0 ] dmem_wdata;
wire [ 31 : 0 ] dmem_rdata;
// core output
wire [  1 : 0 ] mips_status;
wire            mips_status_valid;
//
integer  i, error, status_error, checkIndex;
reg  [31:0] golden_data[0:`DATA_MEM_DEPTH-1];
reg  [1:0]  golden_status[0:`STATUS_PATT_NUM-1];

`ifdef SDF
	initial sdf_annotate(`SDF_FILE, u_core);
`endif 

initial begin
	$fsdbDumpfile("core.fsdb");
	$fsdbDumpvars(0, testbed, "+mda");
end

initial begin
	$readmemb(`Inst, u_inst_mem.mem_r);
	$readmemb(`DATA, golden_data);
	$readmemb(`STATUS, golden_status);
end


core u_core (
	.i_clk(clk),
	.i_rst_n(rst_n),
	// instruction memory
	.o_i_addr(imem_addr),
	.i_i_inst(imem_inst),
	// data memory
	.o_d_we(dmem_we),
	.o_d_addr(dmem_addr),
	.o_d_wdata(dmem_wdata),
	.i_d_rdata(dmem_rdata),
	// core output
	.o_status(mips_status),
	.o_status_valid(mips_status_valid)
);

inst_mem  u_inst_mem (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_addr(imem_addr),
	.o_inst(imem_inst)
);

data_mem  u_data_mem (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_we(dmem_we),
	.i_addr(dmem_addr),
	.i_wdata(dmem_wdata),
	.o_rdata(dmem_rdata)
);

initial clk = 0;
always #(`HCYCLE) clk = ~clk;

initial begin
	status_error = 0;
	checkIndex = 0;
	rst_n = 1;
	reset;
	$display("-------------------------------------------------------------");
	$display("                       Status Check                          ");
	$display("-------------------------------------------------------------");
	while(checkIndex < `STATUS_PATT_NUM) begin
		@(negedge clk);
		if(mips_status_valid == 1'b1) begin
			if(mips_status != golden_status[checkIndex]) begin
				$display("[%d]: Error! Time: %4d Golden Status=%b, Yours=%b", checkIndex, $time, golden_status[checkIndex], mips_status);
				status_error = status_error + 1;
			end
			checkIndex = checkIndex + 1;
		end
	end
	if(status_error == 0) begin
		$display("----------------------------------------------");
		$display("  Bingo! All Status are correct !             ");
		$display("----------------------------------------------");	
	end else begin
		$display("----------------------------------------------");
		$display("  Wrong! Total status error: %d               ", status_error);
		$display("----------------------------------------------");
	end
end

// check data memory
initial begin
	error = 0;
	wait(mips_status_valid == 1'b1 && (mips_status == `MIPS_OVERFLOW || mips_status == `MIPS_END));
	#(`CYCLE);
	checkDataMem;
	$finish;
end

// MAX CYCLE
initial begin
	#(`CYCLE * `MAX_CYCLE);
	$display("----------------------------------------------");
	$display("Latency of your design is over 120000 cycles!!");
	$display("----------------------------------------------");
	checkDataMem;
	$finish;
end

//----------------------------------------------------------------------------

task reset;
begin
	# ( 0.25 * `CYCLE);
	rst_n = 0;
	#((`RST_DELAY) * `CYCLE);
	rst_n = 1;
end
endtask

task checkDataMem;
begin
	$display("-------------------------------------------------------------");
	$display("                   Data Memory Check                         ");
	$display("-------------------------------------------------------------");
	for(i = 0; i < `DATA_MEM_DEPTH; i = i + 1) begin
		if(u_data_mem.mem_r[i] != golden_data[i]) begin
			$display("[%d]: Error! Golden Data=%b, Yours=%b", i, golden_data[i], u_data_mem.mem_r[i]);
			error = error + 1;
		end 
	end
	if(error == 0) begin
		$display("----------------------------------------------");
		$display("  Bingo! All data are correct !               ");
		$display("----------------------------------------------");		
	end else begin
		$display("----------------------------------------------");
		$display("  Wrong! Total error: %d                      ", error);
		$display("----------------------------------------------");
	end
end
endtask

endmodule
