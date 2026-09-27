module morse_top (
    input  wire       sys_clk,
    input  wire       btn_rst,     // BTN0, active-high: idle=0, pressed=1
    input  wire       btn_in,
    output wire [7:0] ascii_out,
    output wire       ready_flag
);
    wire       btn_sync;
    wire       tick_1ms;
    wire       rst_n = ~btn_rst;   // synchronizer/tick_gen want active-low async reset
    wire       rst   =  btn_rst;   // morse_fsm wants active-high reset - same raw signal, no double inversion
    wire [7:0] raw_code;
    wire       char_ready;

    synchronizer sync_inst (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .btn_in   (btn_in),
        .tick_1ms (tick_1ms),
        .btn_sync (btn_sync)
    );

    tick_gen tick_inst (
        .sys_clk  (sys_clk),
        .rst_n    (rst_n),
        .tick_1ms (tick_1ms)
    );

    morse_fsm fsm_inst (
        .clk        (sys_clk),
        .rst        (rst),
        .btn_sync   (btn_sync),
        .tick_1ms   (tick_1ms),
        .raw_code   (raw_code),
        .char_ready (char_ready)
    );

    morse_decoder dec_inst (
        .raw_code      (raw_code),
        .char_ready_in (char_ready),
        .ascii_out     (ascii_out),
        .ready_flag    (ready_flag)
    );

endmodule