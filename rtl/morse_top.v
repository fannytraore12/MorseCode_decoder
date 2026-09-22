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
    morse_fsm fsm_inst (
        .clk(clk),
        .rst(rst),
        .btn_sync(sync_sig),    
        .tick_1ms(tick_sig),
        .ascii_out(ascii_out)
    );

    assign ascii_out  = 8'h00;
    assign ready_flag = 1'b0;
    
endmodule