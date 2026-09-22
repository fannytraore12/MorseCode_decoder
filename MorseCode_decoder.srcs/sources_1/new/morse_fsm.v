`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/22/2026 02:47:20 PM
// Design Name: 
// Module Name: morse_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module morse_fsm(
    input wire clk,
    input wire rst,
    input wire btn_sync,
    input wire tick_1ms,
    output reg[7:0] ascii_out
    );
    localparam IDLE = 2'b00;
    localparam PRESS_ACTIVE = 2'b01;
    localparam RELEASE_EVAL = 2'b10;
    localparam GAP_WAIT = 2'b11;
    reg [1:0] state;
    reg [9:0] press_ms;
    reg [9:0] gap_ms;
    reg [3:0] symbol_bits;
    reg [2:0] symbol_count;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; //holds current phase of the lifecycle FSM
            press_ms <= 10'd0; // active button-hold stopwatch
            gap_ms <= 10'b0; // silent gap stopwatch
            symbol_bits <= 4'b0;// shift register (packing do() and dash())
            symbol_count <= 3'b0; //counts how many symbols have been packed so far
            ascii_out <= 8'b0;//output bus holding latched character byte for external logic
        end
        else begin
            case(state)        
                IDLE: begin
                    if (btn_sync) begin
                        state <= PRESS_ACTIVE;
                        press_ms <= 10'd0;
                    end
                end
                PRESS_ACTIVE: begin
                     if(tick_1ms) press_ms <= press_ms + 10'd1;
                     if(!btn_sync) state <= RELEASE_EVAL;
                 end
                RELEASE_EVAL: begin
                    if(press_ms >= 10'd50 && press_ms <= 10'd150)begin 
                        symbol_bits <= (symbol_bits << 1) | 4'b0;
                        symbol_count <= symbol_count + 3'b1;
                    end
                    if(press_ms >= 10'd200 && press_ms <= 10'd450)begin 
                        symbol_bits <= (symbol_bits << 1) | 4'b1;
                        symbol_count <=  symbol_count + 3'b1;
                    end
                    state <=GAP_WAIT;
                 end
                 GAP_WAIT:begin
                    if(btn_sync)begin
                        gap_ms <= 10'b0;
                        press_ms <= 10'd0;
                        state <= PRESS_ACTIVE;
                     end
                     if(tick_1ms)begin
                        gap_ms <= gap_ms + 10'b1;
                     end
                     if(gap_ms > 10'd400)begin
                         ascii_out <= {symbol_count, symbol_bits};
                         symbol_count <= 3'b0;
                         symbol_bits <= 4'b0;
                         state <= IDLE;
                     end                                           
                end
            endcase
         end
      end
endmodule              
