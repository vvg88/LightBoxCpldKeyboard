module Display
#(
	parameter
		DATA_W = 8,
		ADDR_W = 3
)
(
	//input wire clk,
	input wire rst,
	input wire [DATA_W - 1:0] commData,
	input wire [ADDR_W - 1:0] commAddr,
	input wire wrEn,
	
	output wire [7:0] dispData,
	output wire lcdRs,
	output wire lcdWr,
	output wire lcdRd,
	output reg lcdCs
);

assign lcdWr = (commAddr == 2 || commAddr == 3) ? ~wrEn : 1'b1;
assign dispData = (commAddr == 2 || commAddr == 3) ? commData : 8'h00;
assign lcdRs = (commAddr == 3) ? 1'b0 : 1'b1;
assign lcdRd = 1;

always @(posedge rst or posedge wrEn) begin
	if (rst)
		lcdCs <= 1;
	else
		lcdCs <= 0;
end

endmodule
