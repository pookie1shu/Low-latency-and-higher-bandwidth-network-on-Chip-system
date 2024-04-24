module arbiter_fifo (
    input wire clk,
    input wire master_req_write,
    input wire master_req_read,
    input wire [3:0] master_addr_write,
    input wire [3:0] master_addr_read,
    input wire [7:0] master_data_write,
    input wire [3:0] slave_addr,
    input wire slave_req,
    input wire slave_ack,
    output reg slave_req_write,
    output reg [7:0] slave_data_write,
    output reg slave_req_read,
    output reg [7:0] slave_data_read,
    output reg wclk, wrstn, wren,
    input wire [7:0] wdata,
    output reg wfull,
    output reg rclk, rrstn, rden,
    output reg [7:0] rdata,
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

always @(posedge clk or negedge wrstn or negedge wren) begin
    if (!wrstn)
        wbin <= 0;
    else
        wbin <= wbin + {{(aw){1'b0}}, (wren && wr_en_control)};
end

always @(posedge clk or negedge rrstn or negedge rden) begin
    if (!rrstn)
        rbin <= 0;
    else
        rbin <= rbin + {{(aw){1'b0}}, (rden && !rempty)};
end

assign waddrmem = wbin[aw-1:0];
assign raddrmem = rbin[aw-1:0];

assign wgray = (wbin >> 1) ^ wbin;
assign rgray = (rbin >> 1) ^ rbin;

always @(posedge clk) begin
    if (wren && wr_en_control && !wfull)
        mem[waddrmem] <= wdata;
end

always @(posedge clk) begin
    if (rden && !rempty)
        rdata <= mem[raddrmem];
end

// Condition to control write enable based on buffer status
assign wr_en_control = (wfull) ? 0 : 1;

// Arbiter logic
always @(posedge clk) begin
    if (master_req_write && !slave_req_write) begin
        slave_req_write <= 1'b0;
        wclk <= clk;
        wrstn <= 0;
        wren <= 1;
        wdata <= master_data_write;
        wfull <= 0;
    end else if (slave_req_write && slave_ack) begin
        wclk <= clk;
        wrstn <= 0;
        wren <= 0;
        wfull <= 1;
        slave_req_write <= 0;
    end else if (master_req_read && !slave_req_read) begin
        slave_req_read <= 1'b0;
        rclk <= clk;
        rrstn <= 0;
        rden <= 1;
    end else if (slave_req_read && slave_ack) begin
        rclk <= clk;