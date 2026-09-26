`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// tb_morse_top.v  --  self-checking testbench for the whole design.
// Runs in Vivado xsim (set as sim top) or Verilator (--binary --timing).
//
// The DUT is built with CLK_HZ = 20 kHz so one "ms" is 20 clock cycles; all
// thresholds are still in milliseconds, so behaviour is identical to hardware.
// The button is driven like a human: random dot/dash lengths inside the spec
// windows, random gaps, and a few ms of contact bounce on every edge.
// A UART receiver model captures ja[0] and the result is compared to what
// was keyed.
// -----------------------------------------------------------------------------
module tb_morse_top;
    localparam integer CLK_HZ   = 20_000;
    localparam integer BAUD     = 2_000;
    localparam integer CLK_NS   = 50_000;              // 20 kHz
    localparam integer MS_NS    = 1_000_000;           // 1 ms of simulated time
    localparam integer BIT_NS   = 1_000_000_000 / BAUD;

    reg        sysclk = 1'b0;
    reg  [1:0] btn    = 2'b00;
    wire [3:0] led;
    wire       led5_r, led5_g, led5_b;
    wire [0:0] ja;

    always #(CLK_NS/2) sysclk = ~sysclk;

    morse_top #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (
        .sysclk(sysclk), .btn(btn), .led(led),
        .led5_r(led5_r), .led5_g(led5_g), .led5_b(led5_b), .ja(ja)
    );

    // ------------------------------------------------------------------ UART RX
    reg [8*64-1:0] rx_str = 0;
    integer        rx_cnt = 0;
    reg [7:0]      rx_byte;
    integer        b;
    initial begin
        forever begin
            @(negedge ja[0]);
            #(BIT_NS + BIT_NS/2);
            for (b = 0; b < 8; b = b + 1) begin
                rx_byte[b] = ja[0];
                #(BIT_NS);
            end
            rx_str = {rx_str[8*63-1:0], rx_byte};
            rx_cnt = rx_cnt + 1;
            $display("UART rx '%c'", rx_byte);
        end
    end

    // --------------------------------------------------------- stimulus helpers
    integer seed = 12345;

    function integer rnd(input integer lo, input integer hi);
        rnd = lo + ({$random(seed)} % (hi - lo + 1));
    endfunction

    // hold the key for `ms` milliseconds, with up to ~8 ms of contact bounce on both edges
    task press(input integer ms);
        integer i;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                btn[0] = ~btn[0];
                #(rnd(300_000, 2_000_000));
            end
            btn[0] = 1'b1;
            #(ms * MS_NS);
            for (i = 0; i < 4; i = i + 1) begin
                btn[0] = ~btn[0];
                #(rnd(300_000, 2_000_000));
            end
            btn[0] = 1'b0;
        end
    endtask

    task quiet(input integer ms);
        #(ms * MS_NS);
    endtask

    function [8*5-1:0] pattern(input [7:0] c);   // '.'/'-' string (right-aligned, NUL-padded)
        case (c)
        "A": pattern = ".-";    "B": pattern = "-...";  "C": pattern = "-.-.";
        "D": pattern = "-..";   "E": pattern = ".";     "F": pattern = "..-.";
        "G": pattern = "--.";   "H": pattern = "....";  "I": pattern = "..";
        "J": pattern = ".---";  "K": pattern = "-.-";   "L": pattern = ".-..";
        "M": pattern = "--";    "N": pattern = "-.";    "O": pattern = "---";
        "P": pattern = ".--.";  "Q": pattern = "--.-";  "R": pattern = ".-.";
        "S": pattern = "...";   "T": pattern = "-";     "U": pattern = "..-";
        "V": pattern = "...-";  "W": pattern = ".--";   "X": pattern = "-..-";
        "Y": pattern = "-.--";  "Z": pattern = "--..";
        "0": pattern = "-----"; "1": pattern = ".----"; "2": pattern = "..---";
        "3": pattern = "...--"; "4": pattern = "....-"; "5": pattern = ".....";
        "6": pattern = "-....";  "7": pattern = "--...";"8": pattern = "---..";
        "9": pattern = "----.";
        default: pattern = "";
        endcase
    endfunction

    // key one character: dots 50-150 ms, dashes 200-450 ms, element gap
    // 80-250 ms, then a 500-900 ms character gap
    task send_char(input [7:0] c);
        reg [8*5-1:0] p;
        integer k;
        begin
            p = pattern(c);
            for (k = 4; k >= 0; k = k - 1) begin
                if (p[8*k +: 8] == ".") begin press(rnd(50, 150));  quiet(rnd(80, 250)); end
                if (p[8*k +: 8] == "-") begin press(rnd(200, 450)); quiet(rnd(80, 250)); end
            end
            quiet(rnd(500, 900));
        end
    endtask

    // ------------------------------------------------------------------- test
    localparam [8*36-1:0] ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    reg [8*64-1:0] expected = 0;
    integer n_expected = 0;
    integer i, errors;

    task expect_char(input [7:0] c);
        begin
            expected   = {expected[8*63-1:0], c};
            n_expected = n_expected + 1;
        end
    endtask

    initial begin
        btn[1] = 1'b1;  quiet(5);  btn[1] = 1'b0;  quiet(20);

        // 1. pure bounce (3 ms blip) must be ignored by the debouncer
        btn[0] = 1'b1; #(3 * MS_NS); btn[0] = 1'b0; quiet(600);
        // 2. a 15 ms tap passes the debouncer but is below DOT_MIN_MS
        press(15); quiet(600);

        // 3. every letter and digit
        for (i = 35; i >= 0; i = i - 1) begin
            send_char(ALPHABET[8*i +: 8]);
            expect_char(ALPHABET[8*i +: 8]);
        end

        // 4. "SOS" keyed at the edges of the dot/dash windows
        press(50);  quiet(80);  press(50);  quiet(80);  press(150); quiet(600);
        press(450); quiet(80);  press(200); quiet(80);  press(450); quiet(600);
        press(150); quiet(250); press(150); quiet(250); press(50);  quiet(600);
        expect_char("S"); expect_char("O"); expect_char("S");

        // 5. a 1.5 s hold must still be a dash (press counter saturates, no wrap)
        press(1500); quiet(600);           expect_char("T");

        // 6. six dots is not a Morse character -> '?'
        for (i = 0; i < 6; i = i + 1) begin press(100); quiet(120); end
        quiet(600);                        expect_char("?");

        quiet(50);

        // ------------------------------------------------------------ check
        errors = 0;
        if (rx_cnt != n_expected) begin
            $display("FAIL: received %0d chars, expected %0d", rx_cnt, n_expected);
            errors = errors + 1;
        end
        for (i = 0; i < n_expected; i = i + 1)
            if (rx_str[8*i +: 8] !== expected[8*i +: 8]) begin
                $display("FAIL: char %0d from the end: got '%c' expected '%c'",
                         i, rx_str[8*i +: 8], expected[8*i +: 8]);
                errors = errors + 1;
            end
        if (errors == 0)
            $display("PASS: all %0d characters decoded correctly", n_expected);
        else
            $display("FAILED with %0d error(s)", errors);
        $finish;
    end
endmodule
