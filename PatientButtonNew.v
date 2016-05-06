// Тактовая частота clk = 1 МГц
module PatientButtonNew
(
	input wire rst,					// Вход сброса
	input wire clk,					// Вход тактового сигнала
	input wire inLine0,				// Входная линия данных 1
	input wire inLine1,				// Входная линия данных 2
	
	output reg outLine0,			// Выходная линия данных 1
	output reg outLine1,			// Выходная линия данных 2
	output wire [3:0] tst,
	output reg eventFlag,			// Флаг события
	output reg [7:0] eventCode,	// Код события
	output reg [1:0] patientButtonState
);
assign tst = {1'b0, 1'b0, 1'b0, 1'b0};

reg [6:0] butPedCntr;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butPedCntr <= 7'h0;
	end
	else begin
		if (scanClk) begin
			butPedCntr <= &butPedCntr ? butPedCntr : butPedCntr + 7'h1;
		end
		else begin
			butPedCntr <= 7'h0;
		end
	end
end

always @(posedge rst or posedge clk) begin
	if (rst) begin
		outLine0 <= 1'b1;
		outLine1 <= 1'b1;
	end
	else begin
		if (scanClk) begin
			outLine0 <= (butPedCntr < 7'h8) ? 1'b0 : 1'b1;
			outLine1 <= (butPedCntr < 7'h3) ? 1'b0 : 1'b1;
		end
	end
end

reg [2:0] butEdgeCntr;
reg [2:0] pedEdgeCntr;
reg butEdgeCntSet, pedEdgeCntSet;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butEdgeCntr <= 3'h0;
		pedEdgeCntr <= 3'h0;
		butEdgeCntSet <= 1'b0;
		pedEdgeCntSet <= 1'b0;
	end
	else begin
		if (outLine0) begin
			if (~inLine0) begin
				butEdgeCntr <= butEdgeCntSet ? butEdgeCntr : butEdgeCntr + 3'h1;
				butEdgeCntSet <= 1'b1;
			end
			else begin
				butEdgeCntSet <= 1'b0;
			end
		end
		else begin
			butEdgeCntr <= 3'h0;
		end
		
		if (outLine1) begin
			if (~inLine1) begin
				pedEdgeCntr <= pedEdgeCntSet ? pedEdgeCntr : pedEdgeCntr + 3'h1;
				pedEdgeCntSet <= 1'b1;
			end
			else begin
				pedEdgeCntSet <= 1'b0;
			end
		end
		else begin
			pedEdgeCntr <= 3'h0;
		end
	end
end

reg [4:0] butBuff;
reg [4:0] pedBuff;
reg dataRdy, loadData;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butBuff <= 5'b11111;
		pedBuff <= 5'b11111;
		dataRdy <= 1'b0;
		loadData <= 1'b0;
	end
	else begin
		case (butPedCntr)
			7'd19: begin
				pedBuff[4] <= inLine1;
			end
			7'd22: begin
				butBuff[4] <= inLine0;
			end
			7'd30: begin
				pedBuff[3] <= inLine1;
			end
			7'd33: begin
				butBuff[3] <= inLine0;
			end
			7'd41: begin
				pedBuff[2] <= inLine1;
			end
			7'd44: begin
				butBuff[2] <= inLine0;
			end
			7'd52: begin
				pedBuff[1] <= inLine1;
			end
			7'd55: begin
				butBuff[1] <= inLine0;
			end
			7'd63: begin
				pedBuff[0] <= inLine1;
			end
			7'd66: begin
				butBuff[0] <= inLine0;
			end
			7'd67: begin
				loadData <= 1'b1;
			end
			7'd68: begin
				loadData <= 1'b0;
				dataRdy <= 1'b1;
			end
			7'd88: begin
				dataRdy <= 1'b0;
			end
		endcase
	end
end

reg [8:0] butPedState;
reg [8:0] butPedPrevState;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butPedState <= 9'h1FF;
		butPedPrevState <= 9'h1FF;
	end
	else begin
		if (loadData) begin
			butPedPrevState[7:4] <= butPedState[7:4];
			if ((butEdgeCntr == 3'h5) || ((butEdgeCntr == 3'h0) && (butBuff == 5'h1F))) begin
				butPedState[7:4] <= {butBuff[0], butBuff[1], butBuff[2], butBuff[4]};
			end
			
			butPedPrevState[3:0] <= butPedState[3:0];
			if ((pedEdgeCntr == 3'h5) || ((pedEdgeCntr == 3'h0) && (pedBuff == 5'h1F))) begin
				butPedState[3:0] <= {pedBuff[0], pedBuff[1], pedBuff[2], pedBuff[4]};
			end
			//butPedPrevState <= butPedState;
			//butPedState <= {butBuff[0], butBuff[1], butBuff[2], butBuff[4], pedBuff[0], pedBuff[1], pedBuff[2], pedBuff[4]};
		end
	end
end

reg [3:0] scanIndx;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		eventCode <= 8'h0;
		eventFlag <= 1'b0;
		scanIndx <= 4'h0;
	end
	else begin
		if (dataRdy) begin
			if (eventFlag) begin
				eventFlag <= 1'b0;
			end
			else begin
				if (butPedState[scanIndx] ^ butPedPrevState[scanIndx]) begin
					eventCode[7:6] <= (butPedState[scanIndx]) ? 2'b10 : 2'b01;
					eventCode[5:0] <= 6'd39 - scanIndx;
					eventFlag <= 1'b1;
					scanIndx <= scanIndx[3] ? scanIndx : scanIndx + 4'h1;
				end
				else begin
					scanIndx <= scanIndx[3] ? scanIndx : scanIndx + 4'h1;
				end
			end
		end
		else begin
			scanIndx <= dataRdy ? scanIndx : 4'h0;
		end
	end
end

always @(posedge rst or posedge clk) begin
	if (rst) begin
		patientButtonState <= 2'h0;
	end
	else begin
		if (dataRdy) begin
			if (butPedState[7:6] ^ butPedPrevState[7:6]) begin
				patientButtonState <= {~butPedState[6], ~butPedState[7]};
			end
		end
	end
end

wire scanClk;
FreqDivider #( .DIVIDE_COEFF(1000), .CNTR_WIDTH(10)) FreqDevdrScanClk ( .enable(1), .clk(clk), .rst(rst), .clk_out(scanClk));

endmodule
