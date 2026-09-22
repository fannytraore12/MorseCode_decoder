`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2026 08:40:23 PM
// Design Name: 
// Module Name: morse_top
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


module morse_top (
    input  wire       sys_clk,
    input  wire       rst_n,
    input  wire       btn_in,
    output wire [7:0] ascii_out,
    output wire       ready_flag
);
    wire btn_sync;
    wire tick_1ms;

    synchronizer sync_inst (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .btn_in   (btn_in),
        .btn_sync (btn_sync)
    );

    tick_gen tick_inst (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .tick_1ms (tick_1ms)
    );

    assign ascii_out  = 8'h00;
    assign ready_flag = 1'b0;
endmodule
