// Модуль ПЛИС блока клавиатуры

module keyboardMain
(
	input  wire SEL,
	input  wire SCK,
	input  wire SDI,
	output wire SDO,
	
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
	input wire EXT,
	//
	//input  wire E0IN,
	//output wire E0OUT,
	//
	//input  wire E1IN,
	//output wire E1OUT,
	
	output wire [7:0] LCD_D, //inout
	output wire LCD_RS,
	output wire LCD_RD,
	output wire LCD_WR,
	output wire LCD_CS,
	output wire LCD_RES,
	output wire LCD_BL,
	
	output wire LED_R,
	output wire LED_G,
	
	output wire [3:0] TST
);

localparam FIFO_EVENT_WIDTH = 8;		// Разрядность кода события
localparam COMM_DATA_WIDTH = 8;		// Разрядность шины данных команд
localparam COMM_ADDR_WIDTH = 3;		// Разрядность шины адреса команд

wire keyClk;						// Тактовая частота сканирования клавиатуры
wire KeyBoardEvent;				// Флаг события от клавиатуры
wire [7:0] KeyBoardEvCode;		// Код события от клавиатуры

// Модуль клавиатуры
/*KeyboardReader KeyBoardReadr
(
	//.clk(keyClk),
	.rst(EXT),
	.keysState(KEY),
	.joystKeys({JOYE, JOYD, JOYC, JOYB, JOYA}),
	.encKeys({ENC3K, ENC2K, ENC1K, ENC0K}),
	.encLinesA({ENC0S, ENC1S, ENC2S, ENC3S}),
	.encLinesB({ENC0C, ENC1C, ENC2C, ENC3C}),
	
	.tstWire(TST[3]),
	.keyEventReady(KeyBoardEvent),
	.keyEvent(KeyBoardEvCode)
);*/

wire [FIFO_EVENT_WIDTH - 1:0] FifoEvent;		// Код события
wire FifoReadEn;										// Флаг разрешения чтения события FIFO
wire [COMM_DATA_WIDTH - 1:0] CommDat;			// Данные команды
wire [COMM_ADDR_WIDTH - 1:0] CommAddr;			// Адрес команды
wire CommReady;

// Линия сигнала "Очистить FIFO"
/*wire FifoClr;
assign FifoClr = ((CommAddr == 1) && (CommDat == 0)) ? 1 : 0;*/

// Модуль интерфейса SPI
Spi #( .REPLY_WIDTH(FIFO_EVENT_WIDTH), .COMM_WIDTH(COMM_DATA_WIDTH), .ADR_WIDTH(COMM_ADDR_WIDTH)) SpiMod
(
	.rst(EXT), .sdi(SDI), .sck(SCK), .sel(SEL),
	.replyData(FifoEvent), .replyEn(FifoReadEn), .sdo(SDO),
	.commData(CommDat), .commAdr(CommAddr), .commReady(CommReady)
);

// Модуль дисплея
Display #( .DATA_W(COMM_DATA_WIDTH), .ADDR_W(COMM_ADDR_WIDTH)) MyDisp
(
	.clk(SCK), .rst(EXT), .commData(CommDat), .commAddr(CommAddr), .wrEn(CommReady),
	.dispData(LCD_D), .lcdRs(LCD_RS), .lcdWr(LCD_WR), .lcdRd(LCD_RD), .lcdCs(LCD_CS)
);

// Внешние линии
//wire [7:0] ExtLines;
//assign ExtLines = {4'h0, LED_R, LED_G, LCD_BL, LCD_RES};

// Регистр управления внешними дискретными сигналами
controlRegister #( .DATA_W(4), .ADDR_W(COMM_ADDR_WIDTH), .ADDR(4'h04)) ControlReg4
(
	.rst(EXT), .clk(SCK), .wrEnable(CommReady),
	.dBus(CommDat[3:0]), .aBus(CommAddr), .out({LED_R, LED_G, LCD_BL, LCD_RES})
);

// Делитель частоты для частоты сканирования клавиатуры
FreqDivider #( .DIVIDE_COEFF(5500), .CNTR_WIDTH(13)) FreqDevdr ( .enable(1), .clk(kbClk), .rst(EXT), .clk_out(keyClkScan));

wire kbClk;
wire keyClkScan;
intOsc InternOsc ( .oscena(1'b1), .osc(kbClk));

assign TST = {keyClkScan, 1'b0, 1'b0, 1'b0};

endmodule
