// Модуль считывания энкодера
module EncoderReader
(
	input wire clk,					// Сигнал тактирования
	input wire rst,					// Сигнал сброса
	input wire encLineA,				// Сигнал линии А
	input wire encLineB,				// Сигнал линии В
	input wire [5:0] encNum,		// Номер энкодера
	
	output reg [1:0] encRotEvent,	// Флаг события поворота энкодера
	output wire [5:0] encCode 		// Код события
);

assign encCode = (encRotDir) ? (encNum + 6'h1) : (encNum);

wire encEventA;		// Флаг события с линии А
wire encEventB;		// Флаг события с линии В
reg encRotDir;			// Признак направления поворота экодера
reg evntRiseDetctFlg;// 

// Опрос линий энкодера
EncLineReader EncLineRdA ( .clk(clk), .rst(rst), .encLine(encLineA), .encEvent(encEventA));
EncLineReader EncLineRdB ( .clk(clk), .rst(rst), .encLine(encLineB), .encEvent(encEventB));

always @(encEventA or encEventB)  begin
	
	if (evntRiseDetctFlg & ~encEventA & ~encEventB) begin
		encRotEvent <= 2'b00;
		evntRiseDetctFlg <= 1'b0;
	end
	else begin
		if (encEventA & ~encEventB) begin		// Если фронт А,
			encRotDir <= 0;							// то направление положительное
			//encRotEvent <= 2'b11;					// установить флаг события
		end
		if (~encEventA & encEventB) begin		// Если фронт В,
			encRotDir <= 1;							// то направление отрицательное
			//encRotEvent <= 2'b11;					// установить флаг события
		end
		if (encEventA & encEventB) begin
			evntRiseDetctFlg <= 1'b1;
			encRotEvent <= 2'b11;					// установить флаг события
		end
	end
end

endmodule

// Модуль считывания состояния линии энкодера **************************************
module EncLineReader
(
	input wire clk,			// Сигнал тактирования
	input wire rst,			// Сигнал сброса
	input wire encLine,		// Линия энкодера
	
	output wire encEvent		// Флаг события энкодера
);

reg [3:0] chattCntr;		// Счетчик антидребезга
reg newEncLineState;		// Новое состояние линии энкодера
reg riseFlag;				// Флаг фронта на линии
reg fallFlag;				// Флаг спада на линии

assign encEvent = riseFlag & fallFlag;		// Установить флаг события энкодера

always @(posedge clk) begin
	if (rst) begin					// Сброс состояния
		newEncLineState <= 1;
		chattCntr <= 0;
		riseFlag <= 0;
		fallFlag <= 0;
	end
	else begin
		if (encLine != newEncLineState) begin		// Если состояние линии изменилось
			if (chattCntr) begin							// Если идет антидребезг-задержка
				chattCntr <= 0;							// Обнулить задержку
			end
			else begin
				chattCntr <= chattCntr + 4'h1;		// Иначе инкрементировать задержку
				newEncLineState <= encLine;			// и сохранить новое значение линии
				if (riseFlag & fallFlag) begin		// Если до этого было событие от энк-ра
					riseFlag <= 0;							// Обнулить флаги
					fallFlag <= 0;
				end
			end
		end
		else begin
			if (chattCntr) begin							// Если линии неизменна и идет задержка
				chattCntr = chattCntr + 4'h1;			// Инкрементировать задержку
				if (chattCntr[3]) begin					// Если отсчитана задержка 3 мс
					chattCntr <= 0;						// Обнулить задержку
					if (newEncLineState) begin			// Определить новое состояние
						riseFlag <= 1;						// Сохранить флаг фронта или спада
					end
					else begin
						fallFlag <= 1;
					end
				end
			end
		end
	end
end

endmodule
