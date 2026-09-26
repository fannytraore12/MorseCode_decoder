`timescale 1ns / 1ps
// Brings the asynchronous push-button into the sysclk domain.
//   sync0 -> sync1 : 2-flop metastability chain
//   debounce       : sync1 must disagree with btn_sync for DEBOUNCE_MS
//                    consecutive 1 ms ticks before btn_sync changes
//   btn_rise/fall  : one-cycle strobes on each debounced edge
// btn_sync is a LEVEL (1 while held) -- morse_fsm times how long it stays high.
// Both edges get the same debounce delay, so measured durations are unchanged.
module synchronizer #(
    parameter integer DEBOUNCE_MS = 10
)(
    input  wire sys_clk,
    input  wire rst_n,
    input  wire tick_1ms,
    input  wire btn_in,
    output reg  btn_sync,   // debounced level
    output reg  btn_rise,
    output reg  btn_fall
);
    (* ASYNC_REG = "TRUE" *) reg sync0; // stage 1 d flip-flop catching async btn_in
    (* ASYNC_REG = "TRUE" *) reg sync1; // stage 2 d flip-flop, stable level on clk

    localparam integer CW = $clog2(DEBOUNCE_MS + 1);
    reg [CW-1:0] stable_ms;             // how long sync1 has disagreed with btn_sync

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync0     <= 1'b0;
            sync1     <= 1'b0;
            btn_sync  <= 1'b0;
            btn_rise  <= 1'b0;
            btn_fall  <= 1'b0;
            stable_ms <= {CW{1'b0}};
        end else begin
            sync0    <= btn_in;
            sync1    <= sync0;
            btn_rise <= 1'b0;
            btn_fall <= 1'b0;

            if (sync1 == btn_sync) begin
                stable_ms <= {CW{1'b0}};            // bounce back: restart window
            end else if (tick_1ms) begin
                if (stable_ms == DEBOUNCE_MS[CW-1:0] - 1'b1) begin
                    btn_sync  <= sync1;             // held long enough: accept
                    btn_rise  <=  sync1;
                    btn_fall  <= ~sync1;
                    stable_ms <= {CW{1'b0}};
                end else begin
                    stable_ms <= stable_ms + 1'b1;
                end
            end
        end
    end
endmodule
