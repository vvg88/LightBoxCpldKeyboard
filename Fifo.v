module Fifo
#(
	parameter
		FIFO_EVENT_WIDTH = 8,
		FIFO_CAP_WIDTH = 3,
		FIFO_CAPACITY = 8
)
(
	input wire clk,
	input wire rst,
	input wire FifoClr,
	input wire [FIFO_EVENT_WIDTH - 1:0] FifoInput,
	input wire FifoWr,
	input wire FifoRd,
	
	output wire [3:0] tst,
	
	output reg [FIFO_EVENT_WIDTH - 1:0] FifoOutput
);

assign tst = {FifoWr, FifoRd, rdStrob, wrStrob};

reg [FIFO_EVENT_WIDTH - 1:0] FifoEventsQueue [FIFO_CAPACITY - 1:0];
reg [FIFO_CAP_WIDTH - 1:0] StartIndx;
reg [FIFO_CAP_WIDTH - 1:0] EndIndx;
reg FifoEmpty;

always @(posedge rst or posedge FifoClr or posedge clk) begin
	if (rst | FifoClr) begin
		StartIndx <= {FIFO_CAP_WIDTH{1'b0}};
		EndIndx <= {FIFO_CAP_WIDTH{1'b0}};
		FifoEmpty <= 1'b1;
	end
	else begin
		
		if (rdStrob) begin
			if (~FifoEmpty) begin
				FifoOutput <= FifoEventsQueue[StartIndx];
				StartIndx = StartIndx + 1;				//{{(FIFO_CAP_WIDTH - 1){1'b0}}, 1'b1};
				FifoEmpty <= (StartIndx == EndIndx) ? 1'b1 : 1'b0; //<= 
			end
			else begin
				FifoOutput <= {FIFO_EVENT_WIDTH{1'b0}};
			end
		end
		
		if (wrStrob) begin
				FifoEventsQueue[EndIndx] <= FifoInput;
				EndIndx = EndIndx + 1;
				FifoEmpty <= 1'b0; //FifoEmpty = 1'b0;
		end
		
	end
end

reg rdStrob, rdStrobEn;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		rdStrob <= 1'b0;
		rdStrobEn <= 1'b0;
	end
	else begin
		if (FifoRd) begin
			rdStrob = (~rdStrobEn) ? 1'b1 : 1'b0;
			rdStrobEn = 1'b1;
		end
		else begin
			rdStrobEn <= 1'b0;
		end
	end
end

reg wrStrob, wrStrobEn;
always @(posedge rst or posedge clk) begin
	if (rst) begin
		wrStrob <= 1'b0;
		wrStrobEn <= 1'b0;
	end
	else begin
		if (FifoWr) begin
			wrStrob = (~wrStrobEn) ? 1'b1 : 1'b0;
			wrStrobEn = 1'b1;
		end
		else begin
			wrStrobEn <= 1'b0;
		end
	end
end

endmodule
