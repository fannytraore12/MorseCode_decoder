`timescale 1ns / 1ps
// 4-state Morse parser.
//   IDLE         : wait for a press
//   PRESS_ACTIVE : count 1 ms ticks while btn_sync is held
//   RELEASE_EVAL : classify the press
//                    < DOT_MIN_MS             -> ignored (too short to be deliberate)
//                    DOT_MIN_MS..DASH_MIN_MS-1 -> dot  (0)
//                    >= DASH_MIN_MS           -> dash (1)
//   GAP_WAIT     : count key-up time; a new press continues the character,
//                  CHAR_GAP_MS of silence commits it.
//
// code_out = {symbol_count[2:0], symbol_bits[4:0]}: elements right-aligned,
// first element in the MSB of the used bits. e.g. K (-.-) = {3'd3, 5'b00101}.
// morse_decoder turns this into ASCII.
module morse_fsm #(
    parameter integer DOT_MIN_MS  = 30,
    parameter integer DASH_MIN_MS = 175,
    parameter integer CHAR_GAP_MS = 400
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_sync,     // debounced LEVEL from synchronizer
    input  wire       tick_1ms,
    output reg  [7:0] code_out,     // latched {count, bits} of the last character
    output reg        code_valid,   // 1-cycle pulse when code_out updates
    output reg        overflow,     // last character had more than 5 elements
    output reg        sym_valid,    // 1-cycle pulse per accepted dot/dash
    output reg        sym_is_dash,
    output reg  [1:0] state
);
    localparam IDLE         = 2'b00;
    localparam PRESS_ACTIVE = 2'b01;
    localparam RELEASE_EVAL = 2'b10;
    localparam GAP_WAIT     = 2'b11;

    reg [9:0] press_ms;      // active button-hold stopwatch (saturates at 1023)
    reg [9:0] gap_ms;        // silent gap stopwatch
    reg [4:0] symbol_bits;   // shift register, 5 bits so digits fit
    reg [2:0] symbol_count;  // elements packed so far (0..5)
    reg       too_long;      // a 6th element arrived

    wire       is_dash  = (press_ms >= DASH_MIN_MS[9:0]);
    wire       too_short = (press_ms <  DOT_MIN_MS[9:0]);
    wire [9:0] gap_next = gap_ms + 10'd1;

    always @(posedge clk) begin
        code_valid <= 1'b0;
        sym_valid  <= 1'b0;

        if (rst) begin
            state        <= IDLE;
            press_ms     <= 10'd0;
            gap_ms       <= 10'd0;
            symbol_bits  <= 5'b0;
            symbol_count <= 3'b0;
            too_long     <= 1'b0;
            code_out     <= 8'b0;
            overflow     <= 1'b0;
            sym_is_dash  <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (btn_sync) begin
                        state    <= PRESS_ACTIVE;
                        press_ms <= 10'd0;
                    end
                end

                PRESS_ACTIVE: begin
                    if (!btn_sync)
                        state <= RELEASE_EVAL;
                    else if (tick_1ms && press_ms != 10'd1023)
                        press_ms <= press_ms + 10'd1;
                end

                RELEASE_EVAL: begin
                    if (!too_short) begin
                        sym_valid   <= 1'b1;
                        sym_is_dash <= is_dash;
                        if (symbol_count == 3'd5) begin
                            too_long <= 1'b1;
                        end else begin
                            symbol_bits  <= {symbol_bits[3:0], is_dash};
                            symbol_count <= symbol_count + 3'd1;
                        end
                    end
                    gap_ms <= 10'd0;           // start timing the silence now
                    // a rejected tap with nothing captured goes straight back to IDLE
                    if (too_short && symbol_count == 3'd0 && !too_long)
                        state <= IDLE;
                    else
                        state <= GAP_WAIT;
                end

                GAP_WAIT: begin
                    if (btn_sync) begin
                        press_ms <= 10'd0;
                        state    <= PRESS_ACTIVE;
                    end
                    else if (tick_1ms) begin
                        gap_ms <= gap_next;
                        if (gap_next >= CHAR_GAP_MS[9:0]) begin
                            code_out     <= {symbol_count, symbol_bits};
                            overflow     <= too_long;
                            code_valid   <= 1'b1;
                            symbol_count <= 3'b0;
                            symbol_bits  <= 5'b0;
                            too_long     <= 1'b0;
                            state        <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule
