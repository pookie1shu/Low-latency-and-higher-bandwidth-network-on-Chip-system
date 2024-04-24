module apb_slave(
  input pclk, presetn,
  input psel, penable, pwrite,
  input [7:0] paddr, pwdata,
  output reg [7:0] prdata,
  output reg pready
);

  reg [7:0] addr;
  reg [7:0] mem [63:0];

  assign prdata = mem[addr];

  always @ (posedge pclk or negedge presetn) begin
    if (!presetn) begin
      pready <= 0;
    end else begin
      if (psel && !penable && !pwrite) begin
        pready <= 0;
      end else if (psel && penable && !pwrite) begin
        pready <= 1;
        addr <= paddr;
      end else if (psel && !penable && pwrite) begin
        pready <= 0;
      end else if (psel && penable && pwrite) begin
        pready <= 1;
        mem[addr] <= pwdata;
      end else begin
        pready <= 0;
      end
    end
  end
endmodule