`timescale 1ns / 1ps
// Divides the 125 MHz sysclk down to a one-cycle strobe every 1 ms.
// DIV = 125_000 -> 17-bit counter. CLK_HZ is a parameter so the testbench
// can run with a tiny divisor instead of simulating 125k cycles per ms.
module tick_gen #(
    parameter integer CLK_HZ = 125_000_000
)(
    input  wire sys_clk,
    input  wire rst_n,
    output reg  tick_1ms
);
    localparam integer DIV = CLK_HZ / 1000;
    localparam integer W   = (DIV > 1) ? $clog2(DIV) : 1;

    reg [W-1:0] count;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
        //if reset IS active (0), clear all registers
            count    <= {W{1'b0}};
            tick_1ms <= 1'b0;
        end else if (count == DIV[W-1:0] - 1'b1) begin
            count    <= {W{1'b0}};
            tick_1ms <= 1'b1;
        end else begin
            count    <= count + 1'b1;
            tick_1ms <= 1'b0;
        end
    end
endmodule
