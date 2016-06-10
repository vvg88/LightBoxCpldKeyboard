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
	
	//input wire INT,
	input wire EXT,
	
	input  wire E0IN,
	output wire E0OUT,
	
	input  wire E1IN,
	output wire E1OUT,
	
	output wire [7:0] LCD_D, //inout
	output wire LCD_RS,
	output wire LCD_RD,
	output wire LCD_WR,
	output wire LCD_CS,
	output wire LCD_RES,
	output wire LCD_BL,
	output wire LCD_PWR,
	
	output wire LED_R,
	output wire LED_G,
	
	output wire [3:0] TST
);

localparam FIFO_EVENT_WIDTH = 8;		// Разрядность кода события
localparam COMM_DATA_WIDTH = 8;		// Разрядность шины данных команд
localparam COMM_ADDR_WIDTH = 3;		// Разрядность шины адреса команд
localparam CPLD_VERSION = 8'h1;

wire keyClk;						// Тактовая частота сканирования клавиатуры
wire KeyBoardEvent;				// Флаг события от клавиатуры
wire [7:0] KeyBoardEvCode;		// Код события от клавиатуры
wire LcdPwrLine;					// 

assign LCD_PWR = LcdPwrLine;

// Модуль клавиатуры
KeyboardReader KeyBoardReadr
(
	.clk(SCK),
	.rst(EXT),
	.keysState(KEY),
	.joystKeys({JOYE, JOYD, JOYC, JOYB, JOYA}),
	.encKeys({ENC3K, ENC2K, ENC1K, ENC0K}),
	.encLinesA({ENC3S, ENC2S, ENC1S, ENC0S}),
	.encLinesB({ENC3C, ENC2C, ENC1C, ENC0C}),
	.e0in(E0IN),
	.e1in(E1IN),
	
	//.tstWire(TST),
	.e0out(E0OUT),
	.e1out(E1OUT),
	.keyEventReady(KeyBoardEvent),
	.keyEvent(KeyBoardEvCode),
	.patButtons(patButtonsState)
);

wire [FIFO_EVENT_WIDTH - 1:0] FifoEvent;		// Код события
wire FifoReadEn;										// Флаг разрешения чтения события FIFO
wire [COMM_DATA_WIDTH - 1:0] CommDat;			// Данные команды
wire [COMM_ADDR_WIDTH - 1:0] CommAddr;			// Адрес команды
wire CommReady;
wire [1:0] patButtonsState;

// Линия сигнала "Очистить FIFO"
reg FifoClr;
reg [1:0] fifoClrCntr;
reg cpldVerFlg;
reg [7:0] cpldVerCode;
always @(posedge EXT or posedge SCK /*CommReady*/) begin
	if (EXT) begin
		FifoClr <= 1'b0;
		fifoClrCntr <= 2'h0;
		cpldVerCode <= 8'h0;
		cpldVerFlg <= 1'b0;
	end
	else begin
		if (CommReady && (CommAddr == 1) && (CommDat == 0)) begin
			fifoClrCntr <= fifoClrCntr + 2'h1;
			case (fifoClrCntr)
				/*2'h0: begin
					fifoClrCntr <= 2'h3;
				end*/
				2'h0: begin
					FifoClr <= 1'b1;
				end
				2'h1: begin
					FifoClr <= 1'b0;
					cpldVerFlg <= 1'b1;
					cpldVerCode <= CPLD_VERSION;
				end
				2'h2: begin
					cpldVerFlg <= 1'b1;
					cpldVerCode <= CPLD_VERSION;
				end
				2'h3: begin
					cpldVerFlg <= 1'b0;
					cpldVerCode <= 8'h0;
					fifoClrCntr <= 2'h3;
				end
				
			endcase
		end
		else begin
			fifoClrCntr <= 2'h0;
		end
	end
end
//assign FifoClr = ((CommAddr == 1) && (CommDat == 0)) ? 1 : 0;

wire fifoWrEv;
wire [FIFO_EVENT_WIDTH - 1:0] fifoWrCode;
assign fifoWrEv = cpldVerFlg ? cpldVerFlg : KeyBoardEvent;
assign fifoWrCode = cpldVerFlg ? cpldVerCode : KeyBoardEvCode;

Fifo #( .FIFO_EVENT_WIDTH(8), .FIFO_CAP_WIDTH(3), .FIFO_CAPACITY(7)) MyFifo
(
	.clk(SCK), .rst(EXT | FifoClr), /*.FifoClr(FifoClr),*/ .FifoInput(fifoWrCode),
	.FifoWr(fifoWrEv), .FifoRd(FifoReadEn), /*.tst(TST),*/ .FifoOutput(FifoEvent)
);

// Модуль интерфейса SPI
Spi #( .REPLY_WIDTH(FIFO_EVENT_WIDTH), .COMM_WIDTH(COMM_DATA_WIDTH), .ADR_WIDTH(COMM_ADDR_WIDTH)) SpiMod
(
	.rst(EXT), .sdi(SDI), .sck(SCK), .sel(SEL),
	.replyData(FifoEvent), .replyEn(FifoReadEn), .sdo(SDO),
	.commData(CommDat), .commAdr(CommAddr), .commReady(CommReady),
	.patientButtns(patButtonsState)
	//.cpldVer(8'h1)
);

// Модуль дисплея
Display #( .DATA_W(COMM_DATA_WIDTH), .ADDR_W(COMM_ADDR_WIDTH)) MyDisp
(
	.clk(SCK), .rst(EXT), .commData(CommDat), .commAddr(CommAddr), .wrEn(CommReady), .lcdPwr(LcdPwrLine),
	.dispData(LCD_D), .lcdRs(LCD_RS), .lcdWr(LCD_WR), .lcdRd(LCD_RD), .lcdCs(LCD_CS)
);

wire LedRedLine, LedGreenLine;
assign LED_R = ~LedRedLine;
assign LED_G = ~LedGreenLine;
// Регистр управления внешними дискретными сигналами
controlRegister #( .DATA_W(5), .ADDR_W(COMM_ADDR_WIDTH), .ADDR(4'h04)) ControlReg4
(
	.rst(EXT), .clk(SCK), .wrEnable(CommReady),
	.dBus(CommDat[4:0]), .aBus(CommAddr), .out({LcdPwrLine, LedRedLine, LedGreenLine, LCD_BL, LCD_RES})
);

assign TST = {cpldVerFlg, cpldVerCode[0], fifoWrEv, 1'b0};
//assign TST[3] = KeyBoardEvent;

endmodule
