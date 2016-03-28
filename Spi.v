module Spi
#(
	parameter
		REPLY_WIDTH = 8,
		COMM_WIDTH = 8,
		ADR_WIDTH = 3
)
(
	input wire rst,
	input wire sdi,
	input wire sck,
	input wire sel,
	
	input wire [REPLY_WIDTH - 1:0] replyData,
	
	output wire replyEn,
	output reg sdo,
	output wire [COMM_WIDTH - 1:0] commData,
	output wire [ADR_WIDTH - 1:0] commAdr,
	output reg commReady
);

assign commData = commReady ? commDatReg : {COMM_WIDTH{1'b0}};
assign commAdr = commReady ? commAdrReg : {ADR_WIDTH{1'b0}};
assign replyEn = txEn ? 1'b1 : 1'b0;

reg [3:0] state;
reg txEn;
reg [COMM_WIDTH - 1:0] commDatReg;
reg [ADR_WIDTH - 1:0] commAdrReg;

always @(posedge sck or posedge rst) begin
	if (rst) begin
		state <= 0;
		sdo <= 0;
		txEn <= 0;
		commReady <= 0;
	end
	else begin
		if (~sel) begin
			state = state + 4'h1;
			case (state)
				4'd00: begin
				commReady = 0;
				txEn = sdi;
				//commAdrReg[3] = sdi;
				end
				4'd01: begin
				commAdrReg[2] = sdi;
				end
				4'd02: begin
				commAdrReg[1] = sdi;
				end
				4'd03: begin
				commAdrReg[0] = sdi;
				end
				4'd04: begin
				commDatReg[7] = sdi;
				sdo = txEn ? replyData[7] : 1'b0;
				end
				4'd05: begin
				commDatReg[6] = sdi;
				sdo = txEn ? replyData[6] : 1'b0;
				end
				4'd06: begin
				commDatReg[5] = sdi;
				sdo = txEn ? replyData[5] : 1'b0;
				end
				4'd07: begin
				commDatReg[4] = sdi;
				sdo = txEn ? replyData[4] : 1'b0;
				end
				4'd08: begin
				commDatReg[3] = sdi;
				sdo = txEn ? replyData[3] : 1'b0;
				end
				4'd09: begin
				commDatReg[2] = sdi;
				sdo = txEn ? replyData[2] : 1'b0;
				end
				4'd10: begin
				commDatReg[1] = sdi;
				sdo = txEn ? replyData[1] : 1'b0;
				end
				4'd11: begin
				commDatReg[0] = sdi;
				sdo = txEn ? replyData[0] : 1'b0;
				commReady = 1;
				state = 0;
				end
				
			endcase
		end
	end
end

endmodule
