module Fifo
#(
	parameter
		FIFO_EVENT_WIDTH = 8,
		FIFO_CAP_WIDTH = 3,
		FIFO_CAPACITY = 8
)
(
	input wire rst,
	input wire FifoClr,
	input wire [FIFO_EVENT_WIDTH - 1:0] FifoInput,
	input wire FifoWr,
	input wire FifoRd,
	
	output reg [FIFO_EVENT_WIDTH - 1:0] FifoOutput
);

reg [FIFO_EVENT_WIDTH - 1:0] FifoEventsQueue [FIFO_CAPACITY - 1:0];
reg [FIFO_CAP_WIDTH - 1:0] StartIndx;
reg [FIFO_CAP_WIDTH - 1:0] EndIndx;
reg FifoEmpty;

always @(posedge rst or posedge FifoClr or posedge FifoWr or posedge FifoRd) begin
	if (rst | FifoClr) begin
		StartIndx <= FIFO_CAPACITY - 1;
		EndIndx <= FIFO_CAPACITY - 1;
		FifoEmpty <= 1'b1;
	end
	else begin
		if (FifoWr) begin
			FifoEventsQueue[EndIndx] = FifoInput;
			EndIndx = (EndIndx == 0) ? FIFO_CAPACITY - 1 : EndIndx - 1;
			FifoEmpty = 1'b0;
		end
		if (FifoRd) begin
			FifoOutput = (FifoEmpty) ? {FIFO_EVENT_WIDTH{1'b0}} : FifoEventsQueue[StartIndx];
			StartIndx = (StartIndx == 0) ? FIFO_CAPACITY - 1 : StartIndx - 1;
			FifoEmpty = (StartIndx == EndIndx) ? 1'b1 : 1'b0;
		end
	end
end

endmodule
