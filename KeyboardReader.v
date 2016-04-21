// Модуль опроса клавиатуры (23 кнопки, 4 энкодера, 1 джойстик)
module KeyboardReader
(
	input wire clk,					// Сигнал тактирования
	input wire rst,					// Сигнал сброса
	input wire [22:0] keysState,	// Состояние клавиш
	input wire [4:0] joystKeys,	// 
	input wire [3:0] encKeys,
	input wire [3:0] encLinesA,
	input wire [3:0] encLinesB,
	input wire e0in,					// Входы педали/кнопки пациента
	input wire e1in,
	
	//output wire [3:0] tstWire,
	output wire e0out,				// Выходы педали/кнопки пациента
	output wire e1out,
	output wire keyEventReady,		// Флаг события нажатия
	output wire [7:0] keyEvent		// Код события (клавиши)
);

wire kbClk;			// Тактовая частота клавиатуры (от внутреннего генератора)
wire keyClkScan;	// Частота опроса кнопок (~ 1 кГц)

reg [31:0] keysNewState;		// Новое состояние кнопок
reg [31:0] keysPrevState;		// Состояние кнопок на предыдущем такте
reg [32:0] keyBrdState;			// Текущее состояние клавиатуры
reg [32:0] keyBrdPrevState;	// Предыдущее состояние клавиатуры
reg [7:0] keyCode;				// Код нажатой клавиши
reg keyEvRdy;						// Флаг события от кнопок
reg [2:0] keyEvRdyDel;			// Линия задержки флага события

assign keyEventReady = keyEvRdyDel[2]; //keyEvRdy | encEventRdy | patButtEv;										// Установка флага события от клавиатуры
assign keyEvent = (keyEvRdy) ? keyCode : ((encEventRdy) ? encCode : (patButtEv ? butt1evCode : 8'h0));	// Установка кода события (код кнопки или энкодера)

// Сформировать сигнал события от клавиатуры с задержкой на 2 такта, чтобы не было потери событий
always @(posedge rst or posedge clk)  begin
	if (rst) begin
		keyEvRdyDel <= 3'h0;
	end
	else begin
		keyEvRdyDel <= {keyEvRdyDel[1:0], (keyEvRdy | encEventRdy | patButtEv)};
	end
end

///
///assign tstWire = {butt1evFlg, keyEventReady, |butt1evCode, |keyEvent};

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
		keysNewState <= {encKeys, joystKeys, keysState};	// Считать новое сост-ие
		keysPrevState <= keysNewState;							// Запомнить предыдущее
		if (keysNewState ^ keysPrevState) begin				// Если сост-ие изменилось
			if (waitCntEn)
				waitCntr <= 3'h0;		// Обнулить счетчик антидребезга, если он был запущен
			else
				waitCntEn <= 1'b1;	// Иначе, запустить сч-ик антидребезга
		end
		else begin
			waitCntr <= (waitCntEn) ? waitCntr + 3'h1 : 3'h0;					// Инкремент счетчика антидребезга, если он запущен
			waitCntEn <= (waitCntEn & (&waitCntr)) ? 1'b0 : waitCntEn;		// Остановить сч-ик, после отсчета ожидания
			keysScanEn <= (&waitCntr) ? 1'b1 : 1'b0;								// Установить флаг разрешения сканир-ия нового сост-ия клав-ры
		end
	end
end

// Загрузить новое сост-ие клав-ры
always @(posedge rst or posedge keysScanEn) begin
	if (rst) begin
		keyBrdState <= 33'h1FFFFFFFF;
		keyBrdPrevState <= 33'h1FFFFFFFF;
	end
	else begin
		if (keysScanEn) begin
			keyBrdState[31:0] <= keysNewState;	// Загрузить новое сост-ие
			keyBrdPrevState <= keyBrdState;		// Сохранить предыдущее
		end
	end
end

//assign encsKeysEn = keysScanEn | encEvent;

reg [5:0] scanIndx;		// Индекс сканируемого бита (кнопки)
// Сканирование изменившегося состояния кнопок
always @(posedge kbClk or posedge rst) begin
	if (rst) begin
		scanIndx <= 6'h0;
		keyEvRdy <= 1'b0;
	end
	else begin
		if (keysScanEn) begin		// Если флаг разрешения скан-ия установлен
			if (keyEvRdy) begin
				keyEvRdy <= 1'b0;		// Сбросить флаг события от кнопок, если установлен
			end
			else begin					
				if (keyBrdState[scanIndx] ^ keyBrdPrevState[scanIndx]) begin	// Если флаг события не установлен и состояние клав-ры изменилось
					keyCode[7:6] <= (keyBrdState[scanIndx]) ? 2'b10 : 2'b01;		// установить признак (нажатие/отпускание)
					keyCode[5:0] <= scanIndx;												// установить код кнопки
					keyEvRdy <= 1'b1;															// установить флаг события о нажатии кнопки
					scanIndx <= (scanIndx == 32) ? 6'd32 : scanIndx + 6'd1;		// инкр-т индекса, если он меньше 32. Иначе индекс сохранить 32, чтобы не сканировать по кругу
				end
				else begin
					scanIndx <= (scanIndx == 32) ? 6'd32 : scanIndx + 6'd1;		// инкр-т индекса, если он меньше 32. Иначе индекс сохранить 32, чтобы не сканировать по кругу
				end
			end
		end
		else begin
			scanIndx <= 6'd0;		// Обнулить индекс, когда флаг разрешения скан-ия сброшен
		end
	end
end

reg [5:0] encLinesNewSt;	// Новое состояние линий энкодера
reg [5:0] encLinesPrevSt;	// Предыдущее состояние линий энкодера
reg encCntEn;					// флаг разрешения счетчика антидребезга контактов энкодеров
reg encScanEn;					// флаг разрешения сканирования измененного сост-ия энк-ов
reg [2:0] encCntr;			// Счетчик антидребезга контактов энкодеров


// Определить изменение состояния линий энкодеров
always @(posedge encClkScan or posedge rst) begin
	if (rst) begin
		encCntr <= 3'h4;
		encCntEn <= 1'b0;
		encScanEn <= 1'b0;
		encLinesNewSt <= {encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};	// Уст-ть начальное состояние
		encLinesPrevSt <= {encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};
	end
	else begin
		encLinesNewSt <= {encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};	// Считать новое состояние
		encLinesPrevSt <= encLinesNewSt;																									// Сохранить предыдущее
		if (encLinesNewSt ^ encLinesPrevSt) begin		// Если сост-ие изменилось
			if (encCntEn)
				encCntr <= 3'h4;								// Если счетчик запущен, обнулить его
			else
				encCntEn <= 1'b1;								// Разрешить счетчик
		end
		else begin
			encCntr <= (encCntEn) ? encCntr - 3'h1 : 3'h4;					// Декр-т счетчика, если он запущен
			encCntEn <= (encCntEn & (~(|encCntr))) ? 1'b0 : encCntEn;	// Запретить счетчик, когда он обнулится
			encScanEn <= (~(|encCntr)) ? 1'b1 : 1'b0;							// Установить флаг разрешения сканирования измененного сост-ия энк-ов
		end
		
	end
end

//
reg [7:0] encCode, encCodeNew;	// код события энкодера, новый код события энкодера
reg [5:0] encsNewState;				// Новое состояние энкодеров
reg [5:0] encsPrevState;			// Предыдущее состояние энкодеров
reg encEvent;	// Событие об изменении состояния энк-ров

always @(posedge rst or posedge encClkScan) begin
	if (rst) begin
		//encsPrevState <= {encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};
		encsNewState <= {encLinesB[2], encLinesA[2], encLinesB[1], encLinesA[1], encLinesB[0], encLinesA[0]};		// Сохранить текущее состояние
		encEvent <= 1'b0;
	end
	else begin
		if (encScanEn | ampEncScan) begin	// Если событие от энкодеров
			encsPrevState = encsNewState;		// Сохранить предыдущее сост-ие
			encsNewState = encLinesNewSt;		// Считать новое сост-ие
			
			// Если текущее состояние линий для одного энк-ра одинаковое, а предыдущее разное, то был поворот на один щелчок
			// Определить наличие поворота для энк-ра Marker
			if ((encsPrevState[0] ^ encsPrevState[1]) & (~(encsNewState[0] ^ encsNewState[1]))) begin
				encCodeNew[7:0] <= {2'b11, ((encsNewState[1] ^ encsPrevState[1]) ? 6'h0 : 6'h1)};	// Установить код в зависимости от направления поворота
				encEvent <= 1'b1;																							// Установить флаг события
			end
			
			// Определить наличие поворота для энк-ра Curve
			if ((encsPrevState[2] ^ encsPrevState[3]) & (~(encsNewState[2] ^ encsNewState[3]))) begin
				encCodeNew[7:0] <= {2'b11, ((encsNewState[3] ^ encsPrevState[3]) ? 6'h2 : 6'h3)};	// см выше
				encEvent <= 1'b1;
			end
			
			// Определить наличие поворота для энк-ра Duration
			if ((encsPrevState[4] ^ encsPrevState[5]) & (~(encsNewState[4] ^ encsNewState[5]))) begin
				encCodeNew[7:0] <= {2'b11, ((encsNewState[5] ^ encsPrevState[5]) ? 6'h4 : 6'h5)}; // {7'b1100001, (encsNewState[2] ^ encsPrevState[2])};
				encEvent <= 1'b1;
			end
			
			// Определить наличие поворота для энк-ра Amplitude
			if (ampEncScan) begin
				encCodeNew[7:0] <= {2'b11, (ampEncQ2 ? 6'h7 : 6'h6)};
				encEvent <= 1'b1;
			end
			
		end
		else begin
			encEvent <= 1'b0;		// Сбросить флаг события
		end
		
	end
end

reg encEventRdy, encEvRdySet;		// Флаг события от энк-ра, флаг установки события (нужен, чтобы флаг события был длительностью 1 такт)
always @(posedge rst or posedge kbClk) begin
	if (rst) begin
		encEventRdy <= 1'b0;
		encEvRdySet <= 1'b0;
		encCode <= 8'h0;
	end
	else begin
		if (encEvent) begin
			encEventRdy <= (~encEvRdySet) ? 1'b1 : 1'b0;		// Установить флаг события
			encCode <= encCodeNew;	// Сохранить код энкодера
			encEvRdySet <= 1'b1;		// Установить признак, что флаг события установлен
		end
		else
			encEvRdySet <= 1'b0;
	end
end

// Описание алгоритма для этих линий дано http://www.eng.utah.edu/~cs3710/xilinx-docs/examples/s3esk_rotary_encoder_interface.pdf
/*wire ampEncQ1;
wire ampEncQ2;
assign ampEncQ1 = (encLinesA[3] == encLinesB[3]) ? (encLinesA[3] & encLinesB[3]) : ampEncQ1;
assign ampEncQ2 = (encLinesA[3] != encLinesB[3]) ? encLinesB[3] : ampEncQ2;*/

reg ampEncQ1;
reg ampEncQ2;
always @(posedge rst or posedge kbClk) begin
	if (rst) begin
		ampEncQ1 <= 1'b0;
		ampEncQ2 <= 1'b0;
	end
	else begin
		ampEncQ1 <= (encLinesA[3] == encLinesB[3]) ? (encLinesA[3] & encLinesB[3]) : ampEncQ1;
		ampEncQ2 <= (encLinesA[3] != encLinesB[3]) ? encLinesB[3] : ampEncQ2;
	end
end

// Признак установки флага события от энк-ра Amplitude
// Флаг регистрации спада на линии ampEncQ1
// Флаг события от энк-ра Amplitude
reg ampEncSet, isNegQ1, ampEncScan;

// Регистрация поворота энк-ра Amplitude
always @(posedge rst or posedge encClkScan) begin
	if (rst) begin
		ampEncSet <= 1'b0;
		isNegQ1 <= 1'b0;
		ampEncScan <= 1'b0;
	end
	else begin
		if (ampEncQ1) begin													// Если зарегистрирован фронт
			ampEncScan <= (~ampEncSet & isNegQ1) ? 1'b1 : 1'b0;	// Установить Флаг события на 1 такт
			ampEncSet <= isNegQ1 ? 1'b1 : ampEncSet;					// Уст-ть признак, что событие энк-ра установлено
			isNegQ1 <= 1'b0;													// Сбросить флаг регистрации спада на линии ampEncQ1
		end
		else begin					// Если зарегестрирован спад
			ampEncSet <= 1'b0;	// Сбросить признак установки события от энк-ра Amplitude
			isNegQ1 <= 1'b1;		// Установить Флаг регистрации спада на линии ampEncQ1
		end
	end
end

wire butt1evFlg /*butt2evFlg*/;		// Событие от кнопки пациента
wire [7:0] butt1evCode;					// Код события кнопки пациента

// Модуль кнопки пациента
PatientButton PatientButt1
(
	.rst(rst), .clk(patButtClk), .inLine0(e0in), .inLine1(e1in),
	.outLine0(e0out), .outLine1(e1out),
	//.tst(tstWire),
	.eventFlag(butt1evFlg), .eventCode(butt1evCode)

);

// Флаг события от кнопки пациента
reg patButtEv, patButtEvSet;
always @(posedge rst or posedge kbClk) begin
	if (rst) begin
		patButtEv <= 1'b0;
		patButtEvSet <= 1'b0;
	end
	else begin
		if (butt1evFlg /*| butt2evFlg*/) begin		// Если пришло событие от педали/кнопки пациента
			patButtEvSet <= 1'b1;						// Установить флаг события
			patButtEv <= patButtEvSet ? 1'b0 : 1'b1;
		end
		else begin
			patButtEvSet <= 1'b0;
		end
	end
end

// Тактовая частота кнопки пациента (1 Мгц)
wire patButtClk;
FreqDivider #( .DIVIDE_COEFF(48), .CNTR_WIDTH(6)) FreqDevdr4patButt ( .enable(1), .clk(clk), .rst(rst), .clk_out(patButtClk));

// Внутренний R-C генератор
intOsc InternOsc ( .oscena(1'b1), .osc(kbClk));

// Делитель частоты для частоты сканирования клавиатуры
FreqDivider #( .DIVIDE_COEFF(8), .CNTR_WIDTH(3)) FreqDevdr2 ( .enable(1), .clk(encClkScan), .rst(rst), .clk_out(keyClkScan));

wire encClkScan;		// Тактовая частота опроса энк-ов
// Делитель частоты для частоты сканирования энк-ов
FreqDivider #( .DIVIDE_COEFF(688), .CNTR_WIDTH(10)) FreqDevdr ( .enable(1), .clk(kbClk), .rst(rst), .clk_out(encClkScan));

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
