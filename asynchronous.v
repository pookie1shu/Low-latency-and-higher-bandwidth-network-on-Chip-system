module afifo (
    input wire wclk, wrstn, wren,
    input wire [dsize-1:0] wdata,
    output reg wfull,
    input wire rclk, rrstn, rden,
    output reg [dsize-1:0] rdata,
    output reg rempty
);

parameter dsize = 8,
          asize = 4;
          
localparam dw = dsize,
           aw = asize;

wire [aw-1:0] waddrmem, raddrmem;
reg [aw-1:0] wbin, rbin;
wire [aw:0] wgray, rgray;
wire wr_en_control;

reg [dw-1:0] mem [0:((1<<aw)-1)];

initial begin
    wfull = 1'b0;
    rempty = 1'b1;
    wbin = 0;
    rbin = 0;
end

always @(posedge wclk or negedge wrstn or negedge wren) begin
    if (!wrstn)
        wbin <= 0;
    else
        wbin <= wbin + {{(aw){1'b0}}, (wren && wr_en_control)};
end

always @(posedge rclk or negedge rrstn or negedge rden) begin
    if (!rrstn)
        rbin <= 0;
    else
        rbin <= rbin + {{(aw){1'b0}}, (rden && !rempty)};
end

assign waddrmem = wbin[aw-1:0];
assign raddrmem = rbin[aw-1:0];

assign wgray = (wbin >> 1) ^ wbin;
assign rgray = (rbin >> 1) ^ rbin;

always @(posedge wclk) begin
    if (wren && wr_en_control && !wfull)
        mem[waddrmem] <= wdata;
end

always @(posedge rclk) begin
    if (rden && !rempty)
        rdata <= mem[raddrmem];
end

// Condition to control write enable based on buffer status
assign wr_en_control = (wfull) ? 0 : 1;

endmodule