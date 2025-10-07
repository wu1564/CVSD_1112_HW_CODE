module registerFile #(
    parameter DATA_W = 32,
    parameter DEPTH  = 32
)(
    input i_clk,
	input i_rst_n,
    input we, // read: we == 0, write: we == 1
    input [DATA_W-1:0] writeData_i,
    input [log2(DATA_W)-1:0] addr0,
    input [log2(DATA_W)-1:0] addr1,
    output [DATA_W-1:0] dataOut0,
    output [DATA_W-1:0] dataOut1
);

integer i;
reg [DATA_W-1:0] writeData;
reg [DATA_W-1:0] memory[0:DEPTH-1];

assign dataOut0 = (~we) ? memory[addr0] : 32'd0;
assign dataOut1 = (~we) ? memory[addr1] : 32'd0;

always @(*) begin
    if(we) begin // read: we == 0, write: we == 1
        writeData = writeData_i;
    end else begin
        writeData = memory[addr0];
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        for(i = 0; i < DEPTH; i = i + 1) begin
            memory[i] <= 32'd0;
        end
    end else begin
        memory[addr0] <= writeData;
    end
end

function integer log2;
   input integer value;
   begin
     value = value-1;
     for (log2=0; value>0; log2=log2+1)
       value = value>>1;
   end
 endfunction

endmodule
