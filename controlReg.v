// Модуль параметризуемого управляющего регистра
// Параметрами задается ширина регистра, ширина шины адреса и сам адрес на шине
// Содержимое регистра изменяется по фронту clk
// при установленом стробе записи wrEnable и равенстве кода на шине адреса адресу регистра
module controlRegister 
#(
	parameter 
		DATA_W = 8,							// Размер регистра, по умолчанию 8
		ADDR_W = 4,							// Размер шины адреса, по умолчанию 4
		ADDR	 = 4'b0						// Адрес регистра на шине
)
(
	input wire rst, 						// асинхронный вход сброса
	input wire clk,						// тактовый сигнал
	input wire wrEnable,					// строб записи в регистр
	input [DATA_W-1:0] dBus,			// Шина данных
	input [ADDR_W-1:0] aBus,			// Шина адреса
	output reg[DATA_W-1:0] out			// Состояние регистра
);

always @(posedge clk) begin
	if(rst) begin
		out = 0;
	end
	else begin
		if((aBus[ADDR_W-1:0] == ADDR) && wrEnable) begin
			out = dBus;
		end
	end
end

endmodule

