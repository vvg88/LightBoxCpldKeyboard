// Тактовая частота clk = 1 МГц
module PatientButtonNew
(
	input wire rst,					// Вход сброса
	input wire clk,					// Вход тактового сигнала
	input wire inLine0,				// Входная линия данных 1
	input wire inLine1,				// Входная линия данных 2
	
	output reg outLine0,				// Выходная линия данных 1
	output reg outLine1,				// Выходная линия данных 2
	//output wire [3:0] tst,
	output reg eventFlag,			// Флаг события
	output reg [7:0] eventCode,	// Код события
	output reg [1:0] patientButtonState		// Состояние кнопок пациента
);
//assign tst = {1'b0, 1'b0, 1'b0, 1'b0};

reg [6:0] butPedCntr;		// Счетчик состояния.
									// Исп-ся для отсчета длительности сканирующих импульсов
									// и моментов считывания информационных бит
// Инкремент счетчика
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butPedCntr <= 7'h0;
	end
	else begin
		if (scanClk) begin
			butPedCntr <= &butPedCntr ? butPedCntr : butPedCntr + 7'h1;		// Инкремент до максимального значения
		end
		else begin
			butPedCntr <= 7'h0;		// Сброс счетчика
		end
	end
end

// Установка сканирующих сигналов на выходных линиях
always @(posedge rst or posedge clk) begin
	if (rst) begin
		outLine0 <= 1'b1;
		outLine1 <= 1'b1;
	end
	else begin
		if (scanClk) begin
			outLine0 <= (butPedCntr < 7'h8) ? 1'b0 : 1'b1;		// Для кнопки длительность сигнала 8 мкс
			outLine1 <= (butPedCntr < 7'h3) ? 1'b0 : 1'b1;		// Для педали длительность сигнала 3 мкс
		end
	end
end

// Счетчики спадов входного сигнала для кнопки и педали
// Исп-ся для исключения ложных событий при подключении устр-в
reg [2:0] butEdgeCntr;	
reg [2:0] pedEdgeCntr;
reg butEdgeCntSet, pedEdgeCntSet;	// Признаки инкремента счетчиков

// Отсчет фронтов на линиях
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butEdgeCntr <= 3'h0;
		pedEdgeCntr <= 3'h0;
		butEdgeCntSet <= 1'b0;
		pedEdgeCntSet <= 1'b0;
	end
	else begin
		if (outLine0) begin		// При 1 на выходе (нет сканирующего имп-са)
			if (~inLine0) begin	// При 0 на входе инкремент счетчика
				butEdgeCntr <= butEdgeCntSet ? butEdgeCntr : butEdgeCntr + 3'h1;
				butEdgeCntSet <= 1'b1;		// Установить признак инкремента
			end
			else begin
				butEdgeCntSet <= 1'b0;		// Сбросить признак инкремента
			end
		end
		else begin
			butEdgeCntr <= 3'h0;				// Сбросить счетчик на сканирующем импульсе
		end
		
		if (outLine1) begin		// Аналогично для педали
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

reg [4:0] butBuff;		// Данные от кнопки
reg [4:0] pedBuff;		// Данные от педали
reg dataRdy, loadData;	// Признаки готовности и загрузки данных

// Считать данные
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
				pedBuff[4] <= inLine1;		// Считать данные с педали
			end
			7'd22: begin
				butBuff[4] <= inLine0;		// Считать данные с кнопки
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
				loadData <= 1'b1;		// Установить признак загрузки данных
			end
			7'd68: begin
				loadData <= 1'b0;		// Сбросить признак загрузки данных
				dataRdy <= 1'b1;		// и установить признак готовности данных
			end
			7'd88: begin
				dataRdy <= 1'b0;		// Сбросить признак готовности данных
			end
		endcase
	end
end

// Текущее и предыдущее состояние кнопок и педалей
reg [8:0] butPedState;
reg [8:0] butPedPrevState;

// Загрузить новое состояние кнопок и педалей
always @(posedge rst or posedge clk) begin
	if (rst) begin
		butPedState <= 9'h1FF;
		butPedPrevState <= 9'h1FF;
	end
	else begin
		if (loadData) begin
			butPedPrevState[7:4] <= butPedState[7:4];		// Сохранить текущее состояние, чтобы избежать лишних событий при отключении устр-в
			if ((butEdgeCntr == 3'h5) || ((butEdgeCntr == 3'h0) && (butBuff == 5'h1F))) begin	// Если отсчитаны 5 фронтов или 0, но при условии считывания всех 1 (для идентификации отключения)
				butPedState[7:4] <= {butBuff[0], butBuff[1], butBuff[2], butBuff[4]};				// Считать новое состояние кнопки
			end
			
			butPedPrevState[3:0] <= butPedState[3:0];		// Аналогично для педали
			if ((pedEdgeCntr == 3'h5) || ((pedEdgeCntr == 3'h0) && (pedBuff == 5'h1F))) begin
				butPedState[3:0] <= {pedBuff[0], pedBuff[1], pedBuff[2], pedBuff[4]};
			end
			//butPedPrevState <= butPedState;
			//butPedState <= {butBuff[0], butBuff[1], butBuff[2], butBuff[4], pedBuff[0], pedBuff[1], pedBuff[2], pedBuff[4]};
		end
	end
end

reg [3:0] scanIndx;		// Индекс сканирования

// Сформировать событие
always @(posedge rst or posedge clk) begin
	if (rst) begin
		eventCode <= 8'h0;
		eventFlag <= 1'b0;
		scanIndx <= 4'h0;
	end
	else begin
		if (dataRdy) begin
			if (eventFlag) begin		// Если флаг установлен предыдущим событием, сбросить его
				eventFlag <= 1'b0;	// иначе текущее событие не попадет в FIFO
			end
			else begin
				if (butPedState[scanIndx] ^ butPedPrevState[scanIndx]) begin	// Если состояние изменилось, сформировать событие
					eventCode[7:6] <= (butPedState[scanIndx]) ? 2'b10 : 2'b01;
					eventCode[5:0] <= 6'd39 - scanIndx;
					eventFlag <= 1'b1;
					scanIndx <= scanIndx[3] ? scanIndx : scanIndx + 4'h1;
				end
				else begin
					scanIndx <= scanIndx[3] ? scanIndx : scanIndx + 4'h1;		// Инкремент индекса, если события не было
				end
			end
		end
		else begin
			scanIndx <= dataRdy ? scanIndx : 4'h0;		// Сброс индекса сканирования по спаду dataRdy
		end
	end
end

// Установить состояние кнопок пациента
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

wire scanClk;		// Частота сканирования внешних устройств 1 кГц
FreqDivider #( .DIVIDE_COEFF(1000), .CNTR_WIDTH(10)) FreqDevdrScanClk ( .enable(1), .clk(clk), .rst(rst), .clk_out(scanClk));

endmodule
