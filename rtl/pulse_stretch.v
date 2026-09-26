// -----------------------------------------------------------------------------
// pulse_stretch.v
// Multi-cycle pulse conditioning for the debug LEDs: a single 8 ns strobe is
// invisible, so each trigger holds the output high for HOLD_MS milliseconds.
// Re-triggering restarts the hold time.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
`default_nettype none

module pulse_stretch #(
    parameter integer HOLD_MS = 150
) (
    input  wire clk,
    input  wire rst,
    input  wire tick_1ms,
    input  wire pulse_in,
    output reg  pulse_out
);
    localparam integer CW = $clog2(HOLD_MS + 1);
    reg [CW-1:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt       <= {CW{1'b0}};
            pulse_out <= 1'b0;
        end else if (pulse_in) begin
            cnt       <= HOLD_MS[CW-1:0];
            pulse_out <= 1'b1;
        end else if (tick_1ms && cnt != {CW{1'b0}}) begin
            cnt <= cnt - 1'b1;
            if (cnt == {{(CW-1){1'b0}}, 1'b1})
                pulse_out <= 1'b0;
        end
    end
endmodule

`default_nettype wire
