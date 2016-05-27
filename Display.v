module Display
#(
	parameter
		DATA_W = 8,		// Разрядность кода команды
		ADDR_W = 3		// Разрядность номера команды
)
(
	input wire clk,			// Сигнал тактирования
	input wire rst,			// Сброс
	input wire [DATA_W - 1:0] commData,		// Данные команды
	input wire [ADDR_W - 1:0] commAddr,		// Номер команды
	input wire wrEn,			// Сигнал разрешения записи
	input wire lcdPwr,		
	
	output wire [7:0] dispData,	// Шина данных дисплея
	output wire lcdRs,				// Сигнал команда/данные
	output wire lcdWr,				// Запись
	output wire lcdRd,				// Чтение
	output wire lcdCs					// Выбор микросхемы
);

assign lcdWr = lcdPwr ? ((csMode) ? wrLine[1] : 1'b1) : 1'b0;					// Сигнал записи задержать на 1 такт и только для команд 2 и 3, иначе - 1
assign dispData = lcdPwr ? ((csMode) ? dispDataLatch : 8'h00) : 8'h0;		// Установить шину данных дисплея
assign lcdRs = lcdPwr ? ((AddrThreeFlg) ? 1'b0 : 1'b1) : 1'b0;					// Для команды 3 сбросить сигнал RS
assign lcdRd = lcdPwr ? 1'b1 : 1'b0;													// RD всегда 1
assign lcdCs = lcdPwr ? ((csMode) ? csDelLine[2] : 1'b1) : 1'b0;				// Сигнал CS устанавливается в 0 по wrEn, а в 1 ставится с задержкой в 2 такта

reg csMode;						// Сигнал CS
reg [7:0] dispDataLatch;	// Данные дисплея
reg AddrThreeFlg;				// Признак, что номер команды 3
reg [2:0] csDelLine;			// Линия задержки сигнала CS

reg wrEnSet;	// Признак фиксации фронта сигнала wrEn
always @(posedge rst or posedge clk /*wrEn*/) begin
	if (rst) begin
		AddrThreeFlg <= 1'b0;
		csMode <= 1'b0;
		wrEnSet <= 1'b0;
	end
	else begin
		if (wrEn & (~wrEnSet)) begin												// По фронту wrEn
			csMode <= (commAddr == 2 || commAddr == 3) ? 1'b1 : 1'b0;	// Установить сигнал CS
			dispDataLatch <= commData;												// Загрузить данные дисплея
			AddrThreeFlg <= (commAddr == 3) ? 1'b1 : 1'b0;					// Установить признак команды 3
			wrEnSet <= 1'b1;
		end
		else begin
			wrEnSet <= (wrEn) ? wrEnSet : 1'b0;
		end
	end
end

// Линия задержки сигнала WR
reg [1:0] wrLine;
always @(posedge clk) begin
	wrLine <= {wrLine[0], ~wrEn};
end

// Сформировать сигнал CS
always @(posedge clk or posedge rst or posedge wrEn) begin
	if (rst)
		csDelLine <= 3'h7;
	else begin
		if (wrEn)					// Пока WR = 0, устанавливать 0
			csDelLine <= 3'h0;
		else							// Когда WR = 1, установить 1 с задержкой на 2 такта
			csDelLine <= {csDelLine[1:0], 1'b1};
	end
end

endmodule
