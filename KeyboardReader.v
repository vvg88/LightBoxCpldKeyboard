// Модуль опроса клавиатуры (23 кнопки, 4 энкодера, 1 джойстик)
module KeyboardReader
(
	//input wire clk,					// Сигнал тактирования
	input wire rst,					// Сигнал сброса
	input wire [22:0] keysState,	// Состояние клавиш
	input wire [4:0] joystKeys,
	input wire [3:0] encKeys,
	input wire [3:0] encLinesA,
	input wire [3:0] encLinesB,
	
	///output wire [3:0] tstWire,
	output wire keyEventReady,		// Флаг события нажатия
	output wire [7:0] keyEvent		// Код события (клавиши)
);

wire kbClk;
wire keyClkScan;

reg [31:0] keysNewState;		// Новое состояние кнопок
reg [31:0] keysPrevState;		// Состояние кнопок на предыдущем такте
reg [32:0] keyBrdState;			// Текущее состояние клавиатуры
reg [32:0] keyBrdPrevState;	// Предыдущее состояние клавиатуры
reg [7:0] keyCode;				// Код нажатой клавиши
reg keyEvRdy;						// Флаг события от кнопок
reg encEvRdy;

assign keyEventReady = keyEvRdy;
assign keyEvent = keyCode;
///
///assign tstWire = {waitCntEn, keyEvRdy, keyCode[7], keyCode[6]};

reg waitCntEn;			// Разрешение счетчика антидребезга
reg [2:0] waitCntr;	// Счетчик антидребезга
reg keysScanEn;		// Флаг резрешения сканирования состояния кнопок

// Считывание состояния кнопок
always @(posedge keyClkScan or posedge rst) begin
	if (rst) begin
		waitCntr <= 3'h0;
		waitCntEn <= 1'b0;
		keysScanEn <= 1'b0;
		keysNewState <= 32'hFFFFFFFF;
		keysPrevState <= 32'hFFFFFFFF;
	end
	else begin
		keysNewState <= {encKeys, joystKeys, keysState};
		keysPrevState <= keysNewState;
		if (keysNewState ^ keysPrevState) begin
			if (waitCntEn)
				waitCntr <= 3'h0;
			else
				waitCntEn <= 1'b1;
		end
		else begin
			waitCntr <= (waitCntEn) ? waitCntr + 3'h1 : 3'h0;
			waitCntEn <= (waitCntEn & (&waitCntr)) ? 1'b0 : waitCntEn;
			keysScanEn <= (&waitCntr) ? 1'b1 : 1'b0;
		end
	end
end

reg newKbdLoad; // Флаг однократной загрузки нового состояния кнопок
always @(posedge kbClk or posedge rst or posedge keysScanEn) begin
	if (rst) begin
		keyBrdState <= 33'h1FFFFFFFF;
		keyBrdPrevState <= 33'h1FFFFFFFF;
		newKbdLoad <= 1'b1;
	end
	else begin
		if (keysScanEn) begin
			if (newKbdLoad) begin
				keyBrdState[31:0] <= keysNewState;
				newKbdLoad <= 1'b0;
			end
		end
		else begin
			newKbdLoad <= 1'b1;
			keyBrdPrevState <= keyBrdState;
		end
	end
end


reg [5:0] scanIndx;
// Сканирование изменившегося состояния кнопок
always @(posedge kbClk or posedge rst) begin
	if (rst) begin
		scanIndx <= 6'h0;
		keyEvRdy <= 1'b0;
	end
	else begin
		if (keysScanEn) begin
			if (keyEvRdy) begin
				keyEvRdy <= 1'b0;
			end
			else begin
				if (keyBrdState[scanIndx] ^ keyBrdPrevState[scanIndx]) begin
					keyCode[7:6] <= (keyBrdState[scanIndx]) ? 2'b10 : 2'b01;
					keyCode[5:0] <= scanIndx;
					keyEvRdy <= 1'b1;
					scanIndx <= (scanIndx == 32) ? 6'd32 : scanIndx + 6'd1;
				end
				else begin
					scanIndx <= (scanIndx == 32) ? 6'd32 : scanIndx + 6'd1;
				end
			end
		end
		else begin
			scanIndx <= 6'd0;
		end
	end
end

reg [7:0] encLinesNewSt;
reg [7:0] encLinesPrevSt;

reg encCntEn;
reg encScanEn;		
reg [1:0] encCntr;

always @(posedge keyClkScan or posedge rst) begin
	if (rst) begin
		encCntr <= 2'h0;
		encCntEn <= 1'b0;
		encScanEn <= 1'b0;
		encLinesNewSt <= 8'hFF;
		encLinesPrevSt <= 8'hFF;
	end
	else begin
		encLinesNewSt <= {encLinesB[3], encLinesA[3], encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};
		encLinesPrevSt <= encLinesNewSt;
		if (encLinesNewSt ^ encLinesPrevSt) begin
			if (encCntEn)
				encCntr <= 3'h0;
			else
				encCntEn <= 1'b1;
		end
		else begin
			encCntr <= (encCntEn) ? encCntr + 3'h1 : 3'h0;
			encCntEn <= (encCntEn & (&encCntr)) ? 1'b0 : encCntEn;
			encScanEn <= (&encCntr) ? 1'b1 : 1'b0;
		end
	end
end

/*always @(posedge rst or posedge encScanEn) begin
	
end*/

intOsc InternOsc ( .oscena(1'b1), .osc(kbClk));

// Делитель частоты для частоты сканирования клавиатуры
FreqDivider #( .DIVIDE_COEFF(5500), .CNTR_WIDTH(13)) FreqDevdr ( .enable(1), .clk(kbClk), .rst(rst), .clk_out(keyClkScan));

endmodule

// Считыватель состояния кнопки
/*module ButtonReader
(
	input wire rst,			// Сигнал сброса
	input wire clk,			// Тактовый сигнал
	input wire keyState,		// Состояние кнопки
	input wire [5:0] keyNum,			//	
	
	output wire  keyPressed,	// Флаг: кнопка нажата
	output wire  keyReleased,	// Флаг: кнопка отпущена
	output wire [5:0] keyCode		
);

assign keyCode = (keyPrsd | keyRlsd) ? keyNum : 6'bzzzzzz;
assign keyPressed = keyPrsd ? keyPrsd : 1'bz;
assign keyReleased = keyRlsd ? keyRlsd : 1'bz;

reg [9:0] keyBuff;			// Антидребезговый буфер
reg keyScanRun = 0;			// Признак антидребезгового опроса кнопки 
reg keyPrsd;
reg keyRlsd;

always @(posedge clk) begin
	if (rst) begin				// Сброс модуля
		keyBuff <= 10'b1;
		keyScanRun <= 0;
		keyPrsd <= 0;
		keyRlsd <= 0;
		//keyPressed <= 0;
		//keyReleased <= 0;
	end
	else begin
		if (keyState != keyBuff[0]) begin		// Если состояние кнопки изменилось
			if (keyScanRun) begin					// и идет процесс антидреб. опроса
				keyScanRun <= 0;						// Сбросить флаг и очистить буфер
				keyBuff <= keyState ? 10'b0 : 10'b1;
			end
			else begin					// В противном случае установить флаг
				keyScanRun <= 1;
			end
		end
	
		if (keyScanRun) begin		// Если идет процесс антидреб опроса
			keyBuff <= {keyBuff[9:1], keyState};		// Сохранить новое состояние
			if (~|keyBuff) begin		// Если в буффере все 0
				keyPrsd <= 1;		// Установить признак нажатия кнопки keyPressed
				keyScanRun <= 0;		// и сбросить флаг опроса
			end
			if (&keyBuff) begin		// Если в буффере все 1
				keyRlsd <= 1;		// Установить признак отпускания кнопки
				keyScanRun <= 0;
			end
		end
		
		if (keyPressed | keyReleased) begin		// Если было нажатие,
			keyPrsd <= 0;							// обнулить признаки нажатия/отпусканияkeyPressed
			keyRlsd <= 0;
		end
	end
end

endmodule*/
