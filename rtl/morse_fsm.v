`timescale 1ns / 1ps

module morse_fsm(
    input wire clk,
    input wire rst,
    input wire btn_sync,
    input wire tick_1ms,
    output reg [7:0] raw_code,   // {1'b0, symbol_count[2:0], symbol_bits[3:0]} - NOT ascii, decode separately
    output reg        char_ready // 1-clk pulse when raw_code is freshly valid
);
    localparam IDLE = 2'b00;
    localparam PRESS_ACTIVE = 2'b01;
    localparam RELEASE_EVAL = 2'b10;
    localparam GAP_WAIT = 2'b11;
    
    reg [1:0] state;
    reg [9:0] press_ms;
    reg [9:0] gap_ms;
    reg [4:0] symbol_bits;   // widened 4->5 bits: digits need 5 elements, letters need <=4
    reg [2:0] symbol_count;
    
    always @(posedge clk) begin
        char_ready <= 1'b0;   // default every cycle; only pulses high in the commit branch below

        if (rst) begin
            state        <= IDLE;
            press_ms     <= 10'd0;
            gap_ms       <= 10'd0;
            symbol_bits  <= 5'b0;
            symbol_count <= 3'b0;
            raw_code     <= 8'b0;
        end
        else begin
            case(state)        
                IDLE: begin
                    if (btn_sync) begin
                        state    <= PRESS_ACTIVE;
                        press_ms <= 10'd0;
                    end
                end
                
                PRESS_ACTIVE: begin
                    if (tick_1ms) press_ms <= press_ms + 10'd1;
                    if (!btn_sync) state <= RELEASE_EVAL;
                end
                
                RELEASE_EVAL: begin
                    if (press_ms >= 10'd50 && press_ms <= 10'd150) begin    
                        symbol_bits  <= (symbol_bits << 1) | 5'b0;
                        symbol_count <= symbol_count + 3'b1;
                    end
                    if (press_ms >= 10'd200 && press_ms <= 10'd450) begin    
                       symbol_bits  <= (symbol_bits << 1) | 5'b1;
                       symbol_count <= symbol_count + 3'b1;
                    end
                    state <= GAP_WAIT;
                end
                
                GAP_WAIT: begin
                    if (btn_sync) begin
                        gap_ms   <= 10'd0;
                        press_ms <= 10'd0;
                        state    <= PRESS_ACTIVE;
                    end
                    if (tick_1ms) begin
                        gap_ms <= gap_ms + 10'd1;
                    end
                    if (gap_ms > 10'd400) begin
                        raw_code     <= {symbol_count, symbol_bits};   // 3+5 = 8 bits, no padding needed
                        char_ready   <= 1'b1;   // pulses high for exactly 1 clk
                        symbol_count <= 3'b0;
                        symbol_bits  <= 5'b0;
                        state        <= IDLE;
                    end                                            
                end
            endcase
        end
    end
endmodule