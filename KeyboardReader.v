// Модуль опроса клавиатуры (23 кнопки, 4 энкодера, 1 джойстик)
module KeyboardReader
(
	input wire clk,					// Сигнал тактирования
	input wire rst,					// Сигнал сброса
	input wire [22:0] keysState,	// Состояние клавиш
	input wire [4:0] joystKeys,
	input wire [3:0] encKeys,
	input wire [3:0] encLinesA,
	input wire [3:0] encLinesB,
	
	output wire keyEventReady,		// Флаг события нажатия
	output wire [7:0] keyEvent		// Код события (клавиши)
);

//reg [22:0] keysPressed;		// Флаги нажатия клавиш
//reg [22:0] keysReleased;	// Флаги отпускания клавиш

assign keyEventReady = keyEvent[6] | keyEvent[7];		// Установка флага события

// Опрос клавиатуры
ButtonReader Key0 ( .rst(rst), .clk(clk), .keyState(keysState[0]), .keyNum(0), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));
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
ButtonReader JoystKeyE ( .rst(rst), .clk(clk), .keyState(joystKeys[4]), .keyNum(31), .keyPressed(keyEvent[6]), .keyReleased(keyEvent[7]), .keyCode(keyEvent[5:0]));

endmodule

// Считыватель состояния кнопки
module ButtonReader
(
	input wire rst,			// Сигнал сброса
	input wire clk,			// Тактовый сигнал
	input wire keyState,		// Состояние кнопки
	input wire [5:0] keyNum,			//	
	
	output reg keyPressed,	// Флаг: кнопка нажата
	output reg keyReleased,	// Флаг: кнопка отпущена
	output wire [5:0] keyCode		
);

assign keyCode = keyNum;

reg [9:0] keyBuff;			// Антидребезговый буфер
reg keyScanRun = 0;			// Признак антидребезгового опроса кнопки 

always @(posedge clk) begin
	if (rst) begin				// Сброс модуля
		keyBuff <= 10'b1;
		keyScanRun <= 0;
		keyPressed <= 0;
		keyReleased <= 0;
	end
	else begin
		if (keyState != keyBuff[0]) begin		// Если состояние кнопки изменилось
			if (keyScanRun) begin					// и идет процесс антидреб. опроса
				keyScanRun <= 0;						// Сбросить флаг и очистить буфер
				keyBuff <= keyState ? 10'b0 : 10'b1;
			end
			else begin					// В противном случае установить флаг
				keyScanRun <= 1;
				keyPressed <= 0;		// И обнулить признаки нажатия/отпускания
				keyReleased <= 0;
			end
		end
	
		if (keyScanRun) begin		// Если идет процесс антидреб опроса
			keyBuff <= {keyBuff[9:1], keyState};		// Сохранить новое состояние
			if (~|keyBuff) begin		// Если в буффере все 0
				keyPressed <= 1;		// Установить признак нажатия кнопки
				keyScanRun <= 0;		// и сбросить флаг опроса
			end
			if (&keyBuff) begin		// Если в буффере все 1
				keyReleased <= 1;		// Установить признак отпускания кнопки
				keyScanRun <= 0;
			end
		end
	end
end

endmodule
