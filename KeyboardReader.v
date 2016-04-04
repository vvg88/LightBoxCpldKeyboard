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
	
	output wire tstWire,
	output wire keyEventReady,		// Флаг события нажатия
	output wire [7:0] keyEvent		// Код события (клавиши)
);

wire kbClk;
wire keyClkScan;

reg [31:0] keysNewState;
reg [31:0] keysPrevState;
reg [32:0] keyBrdState;
reg [32:0] keyBrdPrevState;
reg [7:0] keyCode;
reg keyEvRdy;
reg encEvRdy;

assign keyEventReady = keyEvRdy;
assign keyEvent = keyCode;
///
assign tstWire = kbClk;

reg waitCntEn;
reg [2:0] waitCntr;
reg keysScanEn;

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
			waitCntEn <= (&waitCntr) ? 1'b0 : 1'b1;
			keysScanEn <= (&waitCntr) ? 1'b1 : 1'b0;
		end
	end
end

always @(posedge rst or posedge keysScanEn) begin
	if (rst) begin
		keyBrdState <= 33'h1FFFFFFFF;
		keyBrdPrevState <= 33'h1FFFFFFFF;
	end
	else begin
		if (keysScanEn) begin
			keyBrdState[31:0] <= keysNewState;
			keyBrdPrevState <= keyBrdState;
		end
	end
end


reg [5:0] scanIndx;
always @(posedge kbClk or posedge rst or posedge keysScanEn) begin
	if (rst) begin
		//keyBrdState <= 30'h3FFFFFFF;
		//keyBrdPrevState <= 30'h3FFFFFFF;
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

intOsc InternOsc ( .oscena(1'b1), .osc(kbClk));

// Делитель частоты для частоты сканирования клавиатуры
FreqDivider #( .DIVIDE_COEFF(5500), .CNTR_WIDTH(13)) FreqDevdr ( .enable(1), .clk(kbClk), .rst(rst), .clk_out(keyClkScan));

endmodule

//assign keyEventReady = keyEvent[6] | keyEvent[7];		// Установка флага события
// Опрос клавиатуры
/*ButtonReader Key0 ( .rst(rst), .clk(clk), .keyState(keysState[0]), .keyNum(0), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key1 ( .rst(rst), .clk(clk), .keyState(keysState[1]), .keyNum(1), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key2 ( .rst(rst), .clk(clk), .keyState(keysState[2]), .keyNum(2), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key3 ( .rst(rst), .clk(clk), .keyState(keysState[3]), .keyNum(3), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key4 ( .rst(rst), .clk(clk), .keyState(keysState[4]), .keyNum(4), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key5 ( .rst(rst), .clk(clk), .keyState(keysState[5]), .keyNum(5), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key6 ( .rst(rst), .clk(clk), .keyState(keysState[6]), .keyNum(6), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key7 ( .rst(rst), .clk(clk), .keyState(keysState[7]), .keyNum(7), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key8 ( .rst(rst), .clk(clk), .keyState(keysState[8]), .keyNum(8), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key9 ( .rst(rst), .clk(clk), .keyState(keysState[9]), .keyNum(9), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));

ButtonReader Key10 ( .rst(rst), .clk(clk), .keyState(keysState[10]), .keyNum(10), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key11 ( .rst(rst), .clk(clk), .keyState(keysState[11]), .keyNum(11), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key12 ( .rst(rst), .clk(clk), .keyState(keysState[12]), .keyNum(12), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key13 ( .rst(rst), .clk(clk), .keyState(keysState[13]), .keyNum(13), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key14 ( .rst(rst), .clk(clk), .keyState(keysState[14]), .keyNum(14), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key15 ( .rst(rst), .clk(clk), .keyState(keysState[15]), .keyNum(15), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key16 ( .rst(rst), .clk(clk), .keyState(keysState[16]), .keyNum(16), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key17 ( .rst(rst), .clk(clk), .keyState(keysState[17]), .keyNum(17), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key18 ( .rst(rst), .clk(clk), .keyState(keysState[18]), .keyNum(18), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key19 ( .rst(rst), .clk(clk), .keyState(keysState[19]), .keyNum(19), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));

ButtonReader Key20 ( .rst(rst), .clk(clk), .keyState(keysState[20]), .keyNum(20), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key21 ( .rst(rst), .clk(clk), .keyState(keysState[21]), .keyNum(21), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader Key22 ( .rst(rst), .clk(clk), .keyState(keysState[22]), .keyNum(22), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));

ButtonReader EncKey0 ( .rst(rst), .clk(clk), .keyState(encKeys[0]), .keyNum(23), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
EncoderReader Enc0 ( .clk(clk), .rst(rst), .encLineA(encLinesA[0]), .encLineB(encLinesB[0]), .encNum(0), .encRotEvent({keyEvent[7], keyEvent[6]}), .encCode(keyEvent[5:0]));

ButtonReader EncKey1 ( .rst(rst), .clk(clk), .keyState(encKeys[1]), .keyNum(24), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
EncoderReader Enc1 ( .clk(clk), .rst(rst), .encLineA(encLinesA[1]), .encLineB(encLinesB[1]), .encNum(2), .encRotEvent({keyEvent[7], keyEvent[6]}), .encCode(keyEvent[5:0]));

ButtonReader EncKey2 ( .rst(rst), .clk(clk), .keyState(encKeys[2]), .keyNum(25), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
EncoderReader Enc2 ( .clk(clk), .rst(rst), .encLineA(encLinesA[2]), .encLineB(encLinesB[2]), .encNum(4), .encRotEvent({keyEvent[7], keyEvent[6]}), .encCode(keyEvent[5:0]));

ButtonReader EncKey3 ( .rst(rst), .clk(clk), .keyState(encKeys[3]), .keyNum(26), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
EncoderReader Enc3 ( .clk(clk), .rst(rst), .encLineA(encLinesA[3]), .encLineB(encLinesB[3]), .encNum(6), .encRotEvent({keyEvent[7], keyEvent[6]}), .encCode(keyEvent[5:0]));

ButtonReader JoystKeyA ( .rst(rst), .clk(clk), .keyState(joystKeys[0]), .keyNum(27), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader JoystKeyB ( .rst(rst), .clk(clk), .keyState(joystKeys[1]), .keyNum(28), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader JoystKeyC ( .rst(rst), .clk(clk), .keyState(joystKeys[2]), .keyNum(29), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader JoystKeyD ( .rst(rst), .clk(clk), .keyState(joystKeys[3]), .keyNum(30), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
ButtonReader JoystKeyE ( .rst(rst), .clk(clk), .keyState(joystKeys[4]), .keyNum(31), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));*/

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
