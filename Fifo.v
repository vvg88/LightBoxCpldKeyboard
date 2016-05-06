module Fifo
#(
	parameter
		FIFO_EVENT_WIDTH = 8,		// Разрядность событий
		FIFO_CAP_WIDTH = 3,			// Разрядность емкости очереди
		FIFO_CAPACITY = 8				// Ёмкость очереди
)
(
	input wire clk,			// Тактовый сигнал
	input wire rst,			// Сброс
	//input wire FifoClr,		// Очистить очередь
	input wire [FIFO_EVENT_WIDTH - 1:0] FifoInput,	// Вход фифо
	input wire FifoWr,		// Сигнал записи в фифо
	input wire FifoRd,		// Сигнал чтения в фифо
	
	///output wire [3:0] tst,
	
	output reg [FIFO_EVENT_WIDTH - 1:0] FifoOutput	// Выход фифо
);

//assign tst = {FifoWr, FifoRd, rdStrob, wrStrob};

reg [FIFO_EVENT_WIDTH - 1:0] FifoEventsQueue [FIFO_CAPACITY - 1:0];	// Очередь событий фифо
reg [FIFO_CAP_WIDTH - 1:0] StartIndx;											// Индекс начала очереди
reg [FIFO_CAP_WIDTH - 1:0] EndIndx;												// Индекс конца очереди
reg FifoEmpty;																			// Признак пустого фифо

// Запись/чтение
always @(posedge rst  or posedge clk/*or posedge FifoClr*/) begin
	if (rst /*| FifoClr*/) begin
		StartIndx <= {FIFO_CAP_WIDTH{1'b0}};
		EndIndx <= {FIFO_CAP_WIDTH{1'b0}};
		FifoEmpty <= 1'b1;
	end
	else begin
		
		/*if (rdStrob & wrStrob & (~FifoEmpty)) begin
			FifoOutput <= FifoInput;
		end
		else begin*/
			if (rdStrob) begin			// По стробу чтения
				if (~FifoEmpty) begin	// Если фифо не пусто, считать событие
					FifoOutput <= FifoEventsQueue[StartIndx];
					StartIndx = (StartIndx == (FIFO_CAPACITY - 1)) ? {FIFO_CAP_WIDTH{1'b0}} : StartIndx + {{(FIFO_CAP_WIDTH - 1){1'b0}}, 1'b1};				//{{(FIFO_CAP_WIDTH - 1){1'b0}}, 1'b1};
					FifoEmpty <= (StartIndx == EndIndx) ? 1'b1 : 1'b0;
				end
				else begin					// Если фифо пусто, выставить 0
					FifoOutput <= {FIFO_EVENT_WIDTH{1'b0}};
				end
			end
			
			if (wrStrob) begin									// По стробу записи записать событие в фифо
				FifoEventsQueue[EndIndx] <= FifoInput;
				EndIndx = (EndIndx == (FIFO_CAPACITY - 1)) ? {FIFO_CAP_WIDTH{1'b0}} : EndIndx + {{(FIFO_CAP_WIDTH - 1){1'b0}}, 1'b1};
				FifoEmpty <= 1'b0; //FifoEmpty = 1'b0;
			end
		//end
	end
end

// Строб чтения, признак установки строба чтения
reg rdStrob, rdStrobEn;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		rdStrob <= 1'b0;
		rdStrobEn <= 1'b0;
	end
	else begin
		if (FifoRd) begin		// По фронту сигнала чтения установить строб чтения, длительностью 1 такт
			rdStrob = (~rdStrobEn) ? 1'b1 : 1'b0;
			rdStrobEn = 1'b1;
		end
		else begin
			rdStrobEn <= 1'b0;
		end
	end
end

// Строб записи, признак установки строба записи
reg wrStrob, wrStrobEn;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		wrStrob <= 1'b0;
		wrStrobEn <= 1'b0;
	end
	else begin
		if (FifoWr) begin		// По фронту сигнала записи установить строб записи, длительностью 1 такт
			wrStrob = (~wrStrobEn) ? 1'b1 : 1'b0;
			wrStrobEn = 1'b1;
		end
		else begin
			wrStrobEn <= 1'b0;
		end
	end
end

endmodule
