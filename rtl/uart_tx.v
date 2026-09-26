// -----------------------------------------------------------------------------
// uart_tx.v
// Minimal 8N1 UART transmitter. Used to stream decoded characters out of a PMOD
// pin to a USB-serial adapter (the PYNQ-Z2's own USB-UART is wired to the PS,
// not the PL, so the fabric can't reach it without a Zynq block design).
// Characters arrive >= 400 ms apart and a byte takes ~87 us at 115200, so no
// FIFO is needed; a request that arrives while busy is dropped.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
`default_nettype none

module uart_tx #(
    parameter integer CLK_HZ = 125_000_000,
    parameter integer BAUD   = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       send,      // 1-cycle request
    input  wire [7:0] data,
    output reg        tx,        // idles high
    output wire       busy
);
    localparam integer CPB = CLK_HZ / BAUD;       // 1085 on hardware
    localparam integer CW  = $clog2(CPB);

    reg [CW-1:0] baud_cnt;
    reg [3:0]    bit_idx;        // 0 = start, 1..8 = data, 9 = stop
    reg [7:0]    shreg;
    reg          active;

    assign busy = active;

    always @(posedge clk) begin
        if (rst) begin
            tx       <= 1'b1;
            active   <= 1'b0;
            baud_cnt <= {CW{1'b0}};
            bit_idx  <= 4'd0;
            shreg    <= 8'd0;
        end else if (!active) begin
            tx <= 1'b1;
            if (send) begin
                shreg    <= data;
                active   <= 1'b1;
                bit_idx  <= 4'd0;
                baud_cnt <= {CW{1'b0}};
                tx       <= 1'b0;               // start bit
            end
        end else if (baud_cnt == CPB[CW-1:0] - 1'b1) begin
            baud_cnt <= {CW{1'b0}};
            bit_idx  <= bit_idx + 1'b1;
            case (bit_idx)
            4'd8:    tx <= 1'b1;                // stop bit
            4'd9:    active <= 1'b0;            // stop bit finished
            default: begin                      // data bits, LSB first
                tx    <= shreg[0];
                shreg <= {1'b0, shreg[7:1]};
            end
            endcase
        end else begin
            baud_cnt <= baud_cnt + 1'b1;
        end
    end
endmodule

`default_nettype wire
