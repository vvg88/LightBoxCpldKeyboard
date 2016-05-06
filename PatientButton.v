// Тактовая частота clk = 1 МГц
module PatientButton
(
	input wire rst,					// Вход сброса
	input wire clk,					// Вход тактового сигнала
	input wire inLine0,				// Входная линия данных 1
	input wire inLine1,				// Входная линия данных 2
	
	output wire outLine0,			// Выходная линия данных 1
	output wire outLine1,			// Выходная линия данных 2
	output wire [3:0] tst,
	output reg eventFlag,			// Флаг события
	output reg [7:0] eventCode,	// Код события
	output reg [1:0] patientButtonState
);
assign tst = {1'b0, buttConctdFlg, bitsReady, 1'b0};

assign outLine0 = (buttCntr) ? 1'b0 : 1'b1;	// Установить выходные линии
assign outLine1 = (buttCntr) ? 1'b0 : 1'b1;

reg [9:0] scanCntr;	// Счетчик для частоты сканиования 1 кГц
reg [4:0] buttCntr;	// Счетчик сканирующих импульсов для кнопки (8 мкс) и педали (3 мкс)
reg isButtScan;		// Признак сканирования кноппки (1) или педали (0)

// Формирование сканирующих импульсов на выходных линиях
always @(posedge rst or posedge clk) begin
	if (rst) begin
		scanCntr <= 10'd1000;
		buttCntr <= 4'h3;
		isButtScan <= 1'b1;
		//pedalCntr <= 3'h7;
	end
	else begin
		scanCntr = (scanCntr == 0) ? 10'd1000 : scanCntr - 10'h1;	// Отсчет 1 мс
		buttCntr <= (buttCntr) ? buttCntr - 4'h1 : buttCntr;			// Отсчет сканирующего импульса (3 мкс или 8 мкс)
		if (scanCntr == 0) begin
			buttCntr <= isButtScan ? 4'h3 : 4'h8;	// Установить счетчик сканир-его имп-са 
			isButtScan <= ~isButtScan;					// Уст-ть признак
		end
	end
end

wire readEn;
assign readEn = (readEnCntr < 70) ? 1'b1 : 1'b0;

reg [6:0] readEnCntr;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		readEnCntr <= 7'h0;
	end
	else begin
		if (outLine0 & outLine1) begin
			readEnCntr <= (readEnCntr == 70) ? readEnCntr : readEnCntr + 7'h1;
		end
		else begin
			readEnCntr <= 7'h0;
		end
	end
end

reg bitWaitEn;		// Флаг разршения ожидания бита
always @(posedge clk or posedge rst) begin
	if (rst) begin
		bitWaitEn <= 1'h0;
	end
	else begin		// Установить флаг по спаду на входной линии при 1 на выходной
		bitWaitEn <= readEn & ((~inLine0 & outLine0) | (~inLine1 & outLine1));
	end
end

/*wire bitWaitEn;
assign bitWaitEn = ~inLine0 & outLine0;*/
//wire bitWaitCntrEn;
//assign bitWaitCntrEn = bitWaitEn ? 1'b1 : (~(|bitWaitCntr) ? 1'b0 : 1'b1);

reg bitWaitCntrEn;		// Флаг разрешения счет-ка ожидания бита
reg [2:0] bitWaitCntr;	// Сч-ик ожидания бита (5 мкс)
// Отсчет ожидания информационного бита
// Флаг разрешения счет-ка уст-ся по фронту bitWaitEn,
// а сбрасывается по спаду bitWaitEn или по окончании счета в зависимости от того, что наступит раньше
always @(posedge rst or posedge clk) begin
	if (rst) begin
		bitWaitCntr <= 3'h0;
		bitWaitCntrEn <= 1'b0;
	end
	else begin
		if (bitWaitEn) begin
			bitWaitCntrEn = bitWaitCntr == 0 ? 1'b1 : (bitWaitCntr == 3'h3 ? 1'b0 : bitWaitCntrEn);
		end
		else begin
			bitWaitCntrEn = bitWaitCntr == 3'h3 ? 1'b0 : bitWaitCntrEn;
		end
		bitWaitCntr = bitWaitCntrEn ? (bitWaitCntr + 3'h1) : (bitWaitEn ? bitWaitCntr : 3'h0);
		
	end
end

wire rdBitStrb;		// Строб чтения инф-ого бита (инверсия bitWaitCntrEn)
assign rdBitStrb = ~bitWaitCntrEn;

reg [4:0] bitsBuff;		// Буфер для линии inLine0
reg [4:0] bitsBuff1;		// Буфер для линии inLine1
// Считать 5 инф-ых бит
always @(posedge rst or posedge rdBitStrb) begin
	if (rst) begin
		bitsBuff[4:0] <= 5'h0;
		bitsBuff1[4:0] <= 5'h0;
	end
	else begin
		if (rdBitStrb) begin
			bitsBuff[4:0] <= {bitsBuff[3:0], inLine0};
			bitsBuff1[4:0] <= {bitsBuff1[3:0], inLine1};
		end
	end
end

/*always @(posedge rst or posedge clk) begin
	if (rst) begin
		bitsBuff[4:0] <= 5'h0;
		bitsBuff1[4:0] <= 5'h0;
		rdBitStrbCntr <= 2'h0;
		isBadData <= 1'b0;
		isBadData1 <= 1'b0;
		bitBuff <= 1'h0;
		bitBuff1 <= 1'h0;
		rdBitStrbNegSet <= 1'b0;
		//rdBitStrbCntrEn <= 1'b0;
		isDataLoaded <= 1'b0;
	end
	else begin
		if (rdBitStrb & rdBitStrbNegSet) begin
			rdBitStrbCntr = rdBitStrbCntr[1] ? rdBitStrbCntr : rdBitStrbCntr + 2'h1;
			//rdBitStrbCntrEn = rdBitStrbCntr[1] ? 1'b0 : rdBitStrbCntrEn;
			if (rdBitStrbCntr[1] & ~isDataLoaded) begin
				bitsBuff[4:0] <= {bitsBuff[3:0], bitBuff};
				bitsBuff1[4:0] <= {bitsBuff1[3:0], bitBuff1};
				isBadData <= bitBuff ^ inLine0;
				isBadData1 <= bitBuff1 ^ inLine1;
				isDataLoaded <= 1'b1;
				//rdBitStrbCntrEn <= 1'b0;
				//rdBitStrbCntr <= 2'h0;
			end
			else begin
				bitBuff <= inLine0;
				bitBuff1 <= inLine1;
			end
			
			if (~outLines) begin
				isBadData <= 1'b0;
				isBadData1 <= 1'b0;
			end
		end
		else begin
			rdBitStrbNegSet <= 1'b1;
			isDataLoaded <= 1'b0;
			//rdBitStrbCntrEn <= 1'b1;
			rdBitStrbCntr <= 2'h0;
		end
	end
end*/

//reg [1:0] rdBitStrbCntr;
//reg isBadData, isBadData1;
//reg /*[1:0]*/ bitBuff;
//reg /*[1:0]*/ bitBuff1;
//reg rdBitStrbNegSet/*, rdBitStrbCntrEn*/;
//reg isDataLoaded;

reg [2:0] bitCntr;		// Сч-ик считанных инф-ых бит
reg bitCntrSet;			// Флаг инкр-та счет-ка
wire localRst;				// Сброс счет-ка бит формируется по сигналу rst или по 0 на линии outLine0, т.е. при импульсе сканирования
assign localRst = rst | (~outLine0);
// Отсчет инф-ых бит
always @(posedge localRst or posedge clk) begin
	if (localRst) begin
		bitCntr <= 3'h0;
		bitCntrSet <= 1'b1;
	end
	else begin
		if (rdBitStrb) begin
			bitCntr <= bitCntrSet ? bitCntr : bitCntr + 3'h1;
			bitCntrSet <= 1'b1;
		end
		else begin
			bitCntrSet <= 1'b0;
			bitCntr <= (bitCntr == 3'h5) ? 3'h0 : bitCntr;
		end
	end
end

// При считывании инф-ых бит bitsCs = 0;
wire bitsCs;
assign bitsCs = (bitCntr == 3'h5) ? 1'b1 : 1'b0;

reg bitsReady, bitsReadySet;	// Флаг готовности считанных инф-ых битов
always @(posedge rst or posedge clk) begin
	if (rst) begin
		bitsReady <= 1'b0;
	end
	else begin
		if (bitsCs) begin
			bitsReady <= bitsReadySet ? 1'b0 : 1'b1;	// Установить на 1 такт флаг готовности считанных инф-ых битов
			bitsReadySet <= 1'b1;
		end
		else begin
			bitsReadySet <= 1'b0;
		end
	end
end

/* Определение подключения/отключения кнопки или педали */
wire outLines;
assign outLines = outLine0 & outLine1;
reg [1:0] outLinesBuff;			// Буфер выходных линий (исп-ся для определения фронта сигнала)
reg [1:0] disconCntr;			// Счетчик фронтов для определения отключения
reg buttConctdFlg;				// Признак подключения кнопки/педали
// Установка/сброс признака подключения
always @(posedge rst or posedge clk) begin
	if (rst) begin
		outLinesBuff <= 2'b11;
		buttConctdFlg <= 1'b0;
		disconCntr <= 2'h0;
	end
	else begin
		outLinesBuff = {outLinesBuff[0], outLines};	// Сдвинуть буфер
		if (bitsReady) begin
			//if (~bitsBuff[4]) begin			// Если биты считаны
				buttConctdFlg <= 1'b1;		// Установить признак и сбросить счетчик
				disconCntr <= 2'h0;
			//end
		end
		else begin
			if (~outLinesBuff[0] & outLinesBuff[1]) begin				// Если биты не считывались и был фронт на outLines
				disconCntr <= disconCntr + 2'h1;								// Инкр-т счетчика
				buttConctdFlg <= &disconCntr ? 1'b0 : buttConctdFlg;	// Сброс признака подключения, если 3 фронта подряд не приходили данные
			end
		end
	end
end

/*reg [1:0] outLinesBuff1;			// Буфер выходных линий (исп-ся для определения фронта сигнала)
reg [1:0] disconCntr1;			// Счетчик фронтов для определения отключения
reg buttConctdFlg1;				// Признак подключения кнопки/педали
// Установка/сброс признака подключения
always @(posedge rst or posedge clk) begin
	if (rst) begin
		outLinesBuff1 <= 2'b11;
		buttConctdFlg1 <= 1'b0;
		disconCntr1 <= 2'h0;
	end
	else begin
		outLinesBuff1 = {outLinesBuff1[0], outLine1};	// Сдвинуть буфер
		if (bitsReady) begin
			if (~bitsBuff1[4]) begin			// Если биты считаны
				buttConctdFlg1 <= 1'b1;		// Установить признак и сбросить счетчик
				disconCntr1 <= 2'h0;
			end
		end
		else begin
			if (~outLinesBuff1[0] & outLinesBuff1[1]) begin				// Если биты не считывались и был фронт на outLines
				disconCntr1 <= disconCntr1 + 2'h1;								// Инкр-т счетчика
				buttConctdFlg1 <= &disconCntr1 ? 1'b0 : buttConctdFlg1;	// Сброс признака подключения, если 3 фронта подряд не приходили данные
			end
		end
	end
end*/

reg [2:0] patButtState;			// Состояние кнопки пациента линии 0
reg [2:0] patButtPrevState;	// Предыдущее состояние кнопки пациента линии 0
reg [2:0] patButtState1;		// Состояние кнопки пациента линии 1
reg [2:0] patButtPrevState1;	// Предыдущее состояние кнопки пациента линии 1
/*reg [2:0] PedalState;
reg [2:0] PedalPrevState;*/
reg isButtnConct, isButtnConct1;		// Признак подключения кнопки к линии 0 и 1
always @(posedge rst or posedge clk) begin
	if (rst) begin
		eventFlag <= 1'b0;
		patButtPrevState <= 3'h7;
		patButtState <= 3'h7;
		//PedalPrevState <= 3'h7;
		//PedalState <= 3'h7;
		patButtState1 <= 3'h7;
		patButtPrevState1 <= 3'h7;
		isButtnConct <= 1'b1;
		isButtnConct1 <= 1'b1;
		patientButtonState <= 2'b00;
	end
	else begin
		if (bitsReady) begin										// По стробу bitsReady
			if (~bitsBuff[4] /*& ~isBadData*/) begin		// Если по линии 0 считаны данные
				patButtPrevState = patButtState;				// Сохранить новое состояние
				patButtState = bitsBuff[2:0];
				if (bitsBuff[3]) begin							// Если данные пришли от кнопки
					isButtnConct <= 1'b1;						// Уст-ть флаг
					if (patButtState[0] ^ patButtPrevState[0]) begin			// Если состояние кнопок изменилось, сформировать соответствующее событие
						eventCode[7:6] <= patButtState[0] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd32;
						eventFlag <= 1'b1;
						patientButtonState[0] <= ~patButtState[0];
					end
					if (patButtState[1] ^ patButtPrevState[1]) begin
						eventCode[7:6] <= patButtState[1] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd33;
						eventFlag <= 1'b1;
						patientButtonState[1] <= ~patButtState[1];
					end
					/*if (patButtState[1:0] ^ patButtPrevState[1:0]) begin			// Если состояние кнопок изменилось, сформировать соответствующее событие
						patientButtonState <= ~patButtState[1:0];
					end*/
				end
				else begin											// Если данные пришли от педали
					//PedalPrevState = PedalState;
					//PedalState = bitsBuff[2:0];
					isButtnConct <= 1'b0;						// Сбросить флаг подключения педали
					if (isButtnConct) begin						// Если до этого была подключена педаль,
						patButtPrevState = patButtState;		// Стереть предыдущее состояние
					end
					if (patButtState[0] ^ patButtPrevState[0]) begin			// Если состояние педалей изменилось, сформировать соответствующее событие
						eventCode[7:6] <= patButtState[0] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd36;
						eventFlag <= 1'b1;
					end
					if (patButtState[1] ^ patButtPrevState[1]) begin
						eventCode[7:6] <= patButtState[1] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd37;
						eventFlag <= 1'b1;
					end
					if (patButtState[2] ^ patButtPrevState[2]) begin
						eventCode[7:6] <= patButtState[2] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd38;
						eventFlag <= 1'b1;
					end
				end
			end
			/*else begin
				patButtPrevState <= 3'h7;
				patButtState <= 3'h7;
			end*/
			
			if (~bitsBuff1[4]) begin						// Если по линии 1 считаны данные
				patButtPrevState1 = patButtState1;		// Сохранить новое состояние
				patButtState1 = bitsBuff1[2:0];
				if (bitsBuff1[3]) begin
					isButtnConct1 <= 1'b1;
					if (patButtState1[0] ^ patButtPrevState1[0]) begin
						eventCode[7:6] <= patButtState1[0] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd32;
						eventFlag <= 1'b1;
						patientButtonState[0] <= ~patButtState[0];
					end
					if (patButtState1[1] ^ patButtPrevState1[1]) begin
						eventCode[7:6] <= patButtState1[1] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd33;
						eventFlag <= 1'b1;
						patientButtonState[1] <= ~patButtState[1];
					end
					/*if (patButtState1[1:0] ^ patButtPrevState1[1:0]) begin			// Если состояние кнопок изменилось, сформировать соответствующее событие
						patientButtonState <= ~patButtState1[1:0];
					end*/
				end
				else begin
					//PedalPrevState = PedalState;
					//PedalState = bitsBuff1[2:0];
					isButtnConct1 <= 1'b0;
					if (isButtnConct1) begin
						patButtPrevState1 = patButtState1;
					end
					if (patButtState1[0] ^ patButtPrevState1[0]) begin
						eventCode[7:6] <= patButtState1[0] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd36;
						eventFlag <= 1'b1;
					end
					if (patButtState1[1] ^ patButtPrevState1[1]) begin
						eventCode[7:6] <= patButtState1[1] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd37;
						eventFlag <= 1'b1;
					end
					if (patButtState1[2] ^ patButtPrevState1[2]) begin
						eventCode[7:6] <= patButtState1[2] ? 2'b10 : 2'b01;
						eventCode[5:0] <= 6'd38;
						eventFlag <= 1'b1;
					end
				end
			end
			/*else begin
				patButtState1 <= 3'h7;
				patButtPrevState1 <= 3'h7;
			end*/
		end
		else begin
			eventFlag <= eventFlag ? 1'b0 : eventFlag;		// Сбросить флаг события
			if (~buttConctdFlg) begin
				patButtPrevState <=  3'h7;
				patButtState <= 3'h7;
				patButtState1 <= 3'h7;
				patButtPrevState1 <= 3'h7;
			end
		end
	end
end

endmodule
