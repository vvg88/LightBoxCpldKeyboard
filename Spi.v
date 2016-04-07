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
	
	output reg replyEn,
	output reg sdo,
	output wire [COMM_WIDTH - 1:0] commData,
	output wire [ADR_WIDTH - 1:0] commAdr,
	output reg commReady
);

reg [3:0] state;
reg txEn;
reg [COMM_WIDTH - 1:0] commDatReg;
reg [ADR_WIDTH - 1:0] commAdrReg;

assign commData = commReady ? commDatReg : {COMM_WIDTH{1'b0}};
assign commAdr = commReady ? commAdrReg : {ADR_WIDTH{1'b0}};
//assign replyEn = txEnStrb ? 1'b0 : 1'b1;

always @(negedge sck or posedge rst) begin //negedge sck
	if (rst) begin
		state <= 4'h0;
		sdo <= 1'b0;
		txEn <= 1'b0;
		commReady <= 1'b0;
	end
	else begin
		if (~sel) begin
			state = state + 4'h1;
			case (state)
				4'd01: begin
				commReady <= 0;
				txEn <= sdi;
				replyEn <= (sdi) ? 1'b0 : 1'b1;
				//commAdrReg[3] = sdi;
				end
				4'd02: begin
				commAdrReg[2] <= sdi;
				end
				4'd03: begin
				commAdrReg[1] <= sdi;
				end
				4'd04: begin
				commAdrReg[0] <= sdi;
				replyEn <= 1'b0;
				sdo <= txEn ? 1'b0 : replyData[7];
				end
				4'd05: begin
				commDatReg[7] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[6];
				end
				4'd06: begin
				commDatReg[6] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[5];
				end
				4'd07: begin
				commDatReg[5] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[4];
				end
				4'd08: begin
				commDatReg[4] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[3];
				end
				4'd09: begin
				commDatReg[3] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[2];
				end
				4'd10: begin
				commDatReg[2] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[1];
				end
				4'd11: begin
				commDatReg[1] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[0];
				end
				4'd12: begin
				commDatReg[0] <= sdi;
				sdo <= 1'b0;
				commReady <= 1'b1;
				state <= 1'b0;
				end
				
			endcase
		end
		/*else begin
			
		end*/
	end
end

/*always @(posedge rst or negedge sck) begin
	if (rst) begin
		sdo <= 1'b0;
	end
	else begin
		if (~sel) begin
		
		end
	end
end*/

endmodule
