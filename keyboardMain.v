// Модуль ПЛИС блока клавиатуры

module keyboardMain
(
	//input  wire SEL,
	input  wire SCK,
	//input  wire SDI,
	//output wire SDO,
	
	input wire [22:0] KEY,
	
	input wire ENC0S,
	input wire ENC0C,
	input wire ENC0K,
	
	input wire ENC1S,
	input wire ENC1C,
	input wire ENC1K,
	
	input wire ENC2S,
	input wire ENC2C,
	input wire ENC2K,
	
	input wire ENC3S,
	input wire ENC3C,
	input wire ENC3K,
	
	input wire JOYA,
	input wire JOYB,
	input wire JOYC,
	input wire JOYD,
	input wire JOYE,
	
	input wire INT,
	//input wire EXT,
	//
	//input  wire E0IN,
	//output wire E0OUT,
	//
	//input  wire E1IN,
	//output wire E1OUT,
	//
	//inout  wire [7:0] LCD_D,
	//output wire LCD_RS,
	//output wire LCD_RD,
	//output wire LCD_WR,
	//output wire LCD_CS,
	//output wire LCD_RES,
	output reg LCD_BL
	//
	//output wire LED_R,
	//output wire LED_G
);

wire keyClk;
wire KeyBoardEvent;

wire KeyBoardEvCode;

initial begin
	LCD_BL = 0;
end

// Модуль клавиатуры
KeyboardReader KeyBoardReadr
(
	. clk(keyClk),
	.rst(INT),
	.keysState(KEY),
	.joystKeys({JOYA, JOYB, JOYC, JOYD, JOYE}),
	.encKeys({ENC0K, ENC1K, ENC2K, ENC3K}),
	.encLinesA({ENC0S, ENC1S, ENC2S, ENC3S}),
	.encLinesB({ENC0C, ENC1C, ENC2C, ENC3C}),
	
	.keyEventReady(KeyBoardEvent),
	.keyEvent(KeyBoardEvCode)
);

// Делитель частоты для частоты сканирования клавиатуры
FreqDivider #( .DIVIDE_COEFF(48000), .CNTR_WIDTH(16)) FreqDevdr ( .enable(1), .clk(SCK), .rst(INT), .clk_out(keyClk));

endmodule
