// Делитель частоты
module FreqDivider
#(parameter
	DIVIDE_COEFF = 5,		// Коэффициент деления
	CNTR_WIDTH = 8			// Разрядность делителя
)
(
	input wire enable,			// Сигнал разрешения
	input wire clk,				// Тактовый сигнал
	input wire rst,				// Сигнал сброса
	output reg clk_out			// Выходной тактовый сигнал
);

reg [CNTR_WIDTH-1:0] cntr;

/*initial begin
	cntr = 8'b0;
	clk_out = 1'b1;
end*/

always @(posedge clk or posedge rst) begin
	if (rst) begin
		cntr <= {CNTR_WIDTH{1'b0}};
		clk_out <= 1'b1;
	end
	else begin
		if (enable) begin
			cntr = cntr + 1;
			if (cntr == DIVIDE_COEFF / 2) begin
				clk_out <= ~clk_out;
				cntr <= 0;
			end	
		end
	end
end

endmodule
