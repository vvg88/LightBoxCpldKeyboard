module Spi
#(
	parameter
		REPLY_WIDTH = 8,		// Разрядность ответа
		COMM_WIDTH = 8,		// Разрядность команд
		ADR_WIDTH = 3			// Разрядность номера команды
)
(
	input wire rst,		// Сброс
	input wire sdi,		// Вход данных
	input wire sck,		// Вход тактовой частоты
	input wire sel,		// Вход CS
	
	input wire [REPLY_WIDTH - 1:0] replyData,		// Данные ответа
	
	output reg replyEn,			// Строб разрешения передачи ответа
	output reg sdo,				// Выходная линия данных
	output wire [COMM_WIDTH - 1:0] commData,		// Код команды
	output wire [ADR_WIDTH - 1:0] commAdr,			// Номер команды
	output reg commReady									// Строб готовности команды
);

reg [3:0] state;		// Состояние
reg txEn;				// Флаг разрешения передачи ответа
reg [COMM_WIDTH - 1:0] commDatReg;		// Регистр данных команды
reg [ADR_WIDTH - 1:0] commAdrReg;		// Рег-р номера команды

// Установить данные и номер команды
assign commData = commReady ? commDatReg : {COMM_WIDTH{1'b0}};
assign commAdr = commReady ? commAdrReg : {ADR_WIDTH{1'b0}};
//assign replyEn = txEnStrb ? 1'b0 : 1'b1;

// Считывание данных и передача ответа
always @(negedge sck or posedge rst) begin //negedge sck
	if (rst) begin
		state <= 4'h0;
		sdo <= 1'b0;
		txEn <= 1'b0;
		commReady <= 1'b0;
	end
	else begin
		if (~sel) begin				// Если CS = 0
			state = state + 4'h1;	// Изменить состояние
			case (state)
				4'd01: begin			// Принять первый бит (флаг разрешения ответа)
				commReady <= 0;
				txEn <= sdi;
				replyEn <= (sdi) ? 1'b0 : 1'b1;
				//commAdrReg[3] = sdi;
				end
				4'd02: begin				// Принять номер команды в след-их 3-х битах
				commAdrReg[2] <= sdi;
				end
				4'd03: begin
				commAdrReg[1] <= sdi;
				end
				4'd04: begin
				commAdrReg[0] <= sdi;					// Принять последний байт 
				replyEn <= 1'b0;
				sdo <= txEn ? 1'b0 : replyData[7];	// Начать передачу ответа
				end
				4'd05: begin
				commDatReg[7] <= sdi;					// Начать прием кода команды
				sdo <= txEn ? 1'b0 : replyData[6];
				end
				4'd06: begin
				commDatReg[6] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[5];
				end
				4'd07: begin
				commDatReg[5] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[4];
				end
				4'd08: begin
				commDatReg[4] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[3];
				end
				4'd09: begin
				commDatReg[3] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[2];
				end
				4'd10: begin
				commDatReg[2] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[1];
				end
				4'd11: begin
				commDatReg[1] <= sdi;
				sdo <= txEn ? 1'b0 : replyData[0];	// Передать последний бит ответа
				end
				4'd12: begin
				commDatReg[0] <= sdi;		// Принять последний бит команды
				sdo <= 1'b0;
				commReady <= 1'b1;			// Выставить флаг готовности команды
				state <= 1'b0;
				end
				
			endcase
		end
	end
end

/*always @(posedge rst or negedge sck) begin
	if (rst) begin
		sdo <= 1'b0;
	end
	else begin
		if (~sel) begin
		
		end
	end
end*/

endmodule
