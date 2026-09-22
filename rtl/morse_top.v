module morse_top (
    input  wire       sys_clk,
    input  wire       rst_n,
    input  wire       btn_in,
    output wire [7:0] ascii_out,
    output wire       ready_flag
);
    wire btn_sync;
    wire tick_1ms;
    wire rst = 1'b0;
    wire sync_sig;
    wire tick_sig;
    wire [7:0] ascii_bus;

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
    assign led = ascii_bus[3:0];
    assign ascii_out  = 8'h00;
    assign ready_flag = 1'b0;
    
endmodule