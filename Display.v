module Display
#(
	parameter
		DATA_W = 8,
		ADDR_W = 3
)
(
	input wire clk,
	input wire rst,
	input wire [DATA_W - 1:0] commData,
	input wire [ADDR_W - 1:0] commAddr,
	input wire wrEn,
	
	output wire [7:0] dispData,
	output wire lcdRs,
	output wire lcdWr,
	output wire lcdRd,
	output wire lcdCs
);

assign lcdWr = (/*commAddr == 2 || commAddr == 3*/csMode) ? wrLine[1] : 1'b1;
assign dispData = (csMode) ? dispDataLatch : 8'h00;
assign lcdRs = (AddrThreeFlg) ? 1'b0 : 1'b1;
assign lcdRd = 1;
assign lcdCs = (csMode) ? csDelLine[2] : 1'b1;

reg csMode;
reg [7:0] dispDataLatch;
reg AddrThreeFlg;
reg [2:0] csDelLine;

always @(posedge rst or posedge wrEn) begin
	if (rst) begin
		//lcdCs <= 1;
		AddrThreeFlg <= 1'b0;
		csMode <= 1'b0;
	end
	else begin
		//lcdCs <= 0;
		csMode <= (commAddr == 2 || commAddr == 3) ? 1'b1 : 1'b0;
		dispDataLatch <= commData;
		AddrThreeFlg <= (commAddr == 3) ? 1'b1 : 1'b0;
	end
end

reg [1:0] wrLine;

always @(posedge clk) begin
	wrLine <= {wrLine[0], ~wrEn};
end

always @(posedge clk or posedge rst or posedge wrEn) begin
	if (rst)
		csDelLine <= 3'h7;
	else begin
		if (wrEn)
			csDelLine <= 3'h0;
		else
			csDelLine <= {csDelLine[1:0], 1'b1};
	end
end

endmodule
