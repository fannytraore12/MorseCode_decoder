`timescale 1ns / 1ps
// PYNQ-Z2 top level (pure fabric, no PS)
//   BTN0  : Morse key               BTN1 : reset
//   ja[0] : UART TX 115200 8N1 -> RX pin of a 3.3 V USB-serial adapter (+ GND)
//   LD0   : key held (debounced)    LD1  : dot accepted
//   LD2   : dash accepted           LD3  : character committed
//   LD5   : FSM state  red = PRESS_ACTIVE, blue = GAP_WAIT,
//                      green flash = RELEASE_EVAL accepted an element, off = IDLE
module morse_top #(
    parameter integer CLK_HZ      = 125_000_000,
    parameter integer BAUD        = 115_200,
    parameter integer DEBOUNCE_MS = 10,
    parameter integer DOT_MIN_MS  = 30,
    parameter integer DASH_MIN_MS = 175,
    parameter integer CHAR_GAP_MS = 400
)(
    input  wire       sysclk,
    input  wire [1:0] btn,
    output wire [3:0] led,
    output wire       led5_r,
    output wire       led5_g,
    output wire       led5_b,
    output wire [0:0] ja
);
    wire clk = sysclk;

    // ---- reset: power-on pulse + BTN1, synchronised to clk ------------------
    reg [3:0] por = 4'hF;
    (* ASYNC_REG = "TRUE" *) reg [1:0] rst_meta = 2'b11;
    reg rst = 1'b1;
    always @(posedge clk) begin
        por      <= {por[2:0], 1'b0};
        rst_meta <= {rst_meta[0], btn[1]};
        rst      <= por[3] | rst_meta[1];
    end
    wire rst_n = ~rst;   // for the modules that use active-low reset

    // ---- 1 ms tick ------------------------------------------------------------
    wire tick_1ms;
    tick_gen #(.CLK_HZ(CLK_HZ)) tick_inst (
        .sys_clk  (clk),
        .rst_n    (rst_n),
        .tick_1ms (tick_1ms)
    );

    // ---- button sync + debounce ----------------------------------------------
    wire btn_sync, btn_rise, btn_fall;
    synchronizer #(.DEBOUNCE_MS(DEBOUNCE_MS)) sync_inst (
        .sys_clk  (clk),
        .rst_n    (rst_n),
        .tick_1ms (tick_1ms),
        .btn_in   (btn[0]),
        .btn_sync (btn_sync),
        .btn_rise (btn_rise),
        .btn_fall (btn_fall)
    );

    // ---- FSM ------------------------------------------------------------------
    wire [7:0] code;
    wire       code_valid, overflow, sym_valid, sym_is_dash;
    wire [1:0] state;
    morse_fsm #(
        .DOT_MIN_MS(DOT_MIN_MS), .DASH_MIN_MS(DASH_MIN_MS), .CHAR_GAP_MS(CHAR_GAP_MS)
    ) fsm_inst (
        .clk        (clk),
        .rst        (rst),
        .btn_sync   (btn_sync),
        .tick_1ms   (tick_1ms),
        .code_out   (code),
        .code_valid (code_valid),
        .overflow   (overflow),
        .sym_valid  (sym_valid),
        .sym_is_dash(sym_is_dash),
        .state      (state)
    );

    // ---- decode to ASCII -------------------------------------------------------
    wire [7:0] ascii;
    wire [5:0] index;          // A=1..Z=26, 0..9=27..36, 0=unknown
    morse_decoder dec_inst (
        .len      (code[7:5]),
        .bits     (code[4:0]),
        .overflow (overflow),
        .ascii    (ascii),
        .index    (index)
    );

    // ---- UART out on ja[0] ------------------------------------------------------
    // code_out is registered in the same cycle code_valid pulses, so the
    // decoded ascii is valid one clock later: send on the delayed strobe.
    reg code_valid_d = 1'b0;
    always @(posedge clk) code_valid_d <= code_valid;

    wire uart_busy;
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) uart_inst (
        .clk  (clk),
        .rst  (rst),
        .send (code_valid_d),
        .data (ascii),
        .tx   (ja[0]),
        .busy (uart_busy)
    );

    // ---- debug LEDs: stretch 8 ns strobes so they're visible -------------------
    wire dot_led, dash_led, char_led, eval_led;
    pulse_stretch #(.HOLD_MS(120)) ps_dot  (.clk(clk), .rst(rst), .tick_1ms(tick_1ms),
        .pulse_in(sym_valid & ~sym_is_dash), .pulse_out(dot_led));
    pulse_stretch #(.HOLD_MS(120)) ps_dash (.clk(clk), .rst(rst), .tick_1ms(tick_1ms),
        .pulse_in(sym_valid &  sym_is_dash), .pulse_out(dash_led));
    pulse_stretch #(.HOLD_MS(250)) ps_char (.clk(clk), .rst(rst), .tick_1ms(tick_1ms),
        .pulse_in(code_valid), .pulse_out(char_led));
    pulse_stretch #(.HOLD_MS(60))  ps_eval (.clk(clk), .rst(rst), .tick_1ms(tick_1ms),
        .pulse_in(sym_valid), .pulse_out(eval_led));

    assign led = {char_led, dash_led, dot_led, btn_sync};

    // RGB LEDs are very bright at 100 %: run LD5 at 1/8 duty
    reg [2:0] pwm = 3'd0;
    always @(posedge clk) pwm <= pwm + 3'd1;
    wire dim = (pwm == 3'd0);

    assign led5_r = dim & ~eval_led & (state == 2'b01);   // PRESS_ACTIVE
    assign led5_b = dim & ~eval_led & (state == 2'b11);   // GAP_WAIT
    assign led5_g = dim &  eval_led;                      // RELEASE_EVAL hit
endmodule
