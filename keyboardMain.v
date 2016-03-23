// Модуль ПЛИС блока клавиатуры

module keyboardMain
(
	input  wire SEL,
	input  wire SCK,
	input  wire SDI,
	output wire SDO,
	
	input wire [0:22] KEY,
	
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
	
	input  wire E0IN,
	output wire E0OUT,
	
	input  wire E1IN,
	output wire E1OUT,
	
	inout  wire [0:7] LCD_D,
	output wire LCD_RS,
	output wire LCD_RD,
	output wire LCD_WR,
	output wire LCD_CS,
	output wire LCD_RES,
	output wire LCD_BL,
	
	output wire LED_R,
	output wire LED_G
);



endmodule