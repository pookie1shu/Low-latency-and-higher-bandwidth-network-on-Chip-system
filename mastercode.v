module master (
    input           clk,
    input           resetn,
    input  [7:0]    apb_write_paddr,
    input  [7:0]    apb_read_paddr,
    input  [7:0]    apb_write_data,
    input           presetn,
    input           write,
    input           transfer,
    input           pready,
    output          psel1,
    output reg      penable,
    output reg  [8:0] paddr,
    output reg      pwrite,
    output reg  [7:0] pwdata,
    output reg  [7:0] apb_read_data_out,
    output          pslverr
);

    reg [2:0] present_state, next_state;
    reg invalid_setup_error;
    reg setup_error;
    reg invalid_read_paddr;
    reg invalid_write_paddr;
    reg invalid_write_data;

    parameter IDLE   = 3'b000,
              SETUP  = 3'b001,
              ENABLE = 3'b010;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            present_state <= IDLE;
        end else begin
            present_state <= next_state;
        end
    end

    always @(present_state or transfer or pready) begin
        pwrite = write;
        case (present_state)
            IDLE: begin
                penable = 1'b0;
                if (!transfer) begin
                    next_state = IDLE;
                end else begin
                    next_state = SETUP;
                end
            end
            SETUP: begin
                penable = 1'b0;
                if (read && !write) begin
                    paddr = apb_read_paddr;
                end else if (!read && write) begin
                    paddr = apb_write_paddr;
                    pwdata = apb_write_data;
                end
                next_state = ENABLE;
            end
            ENABLE: begin
                if (psel1) begin
                    penable = 1'b1;
                end
                if (transfer && !pslverr) begin
                    if (pready) begin
                        if (read && write) begin 
                            next_state = SETUP;
                            apb_read_data_out = prdata;
                        end 
                    end
                    next_state = ENABLE;
                end
                next_state = IDLE;
            end
        endcase
    end
endmodule