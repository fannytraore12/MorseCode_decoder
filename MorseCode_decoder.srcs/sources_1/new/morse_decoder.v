`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// morse_decoder : combinational lookup from morse_fsm's raw_code to ASCII.
// raw_code = {symbol_count[2:0], symbol_bits[4:0]}, where symbol_bits packs
// each element as (prev << 1) | bit, dot=0 dash=1 - i.e. the FIRST element
// ends up as the most-significant valid bit. symbol_bits is 5 bits wide,
// covering every standard letter (<=4 elements) and digit (exactly 5).
//------------------------------------------------------------------------------
module morse_decoder(
    input  wire [7:0] raw_code,
    input  wire       char_ready_in,
    output reg  [7:0] ascii_out,
    output reg        ready_flag
);
    wire [2:0] cnt  = raw_code[7:5];
    wire [4:0] bits = raw_code[4:0];

    always @(*) begin
        ready_flag = char_ready_in;
        case ({cnt, bits})
            // count=1
            {3'd1, 5'b00000}: ascii_out = "E"; // .
            {3'd1, 5'b00001}: ascii_out = "T"; // -
            // count=2
            {3'd2, 5'b00000}: ascii_out = "I"; // ..
            {3'd2, 5'b00001}: ascii_out = "A"; // .-
            {3'd2, 5'b00010}: ascii_out = "N"; // -.
            {3'd2, 5'b00011}: ascii_out = "M"; // --
            // count=3
            {3'd3, 5'b00000}: ascii_out = "S"; // ...
            {3'd3, 5'b00001}: ascii_out = "U"; // ..-
            {3'd3, 5'b00010}: ascii_out = "R"; // .-.
            {3'd3, 5'b00011}: ascii_out = "W"; // .--
            {3'd3, 5'b00100}: ascii_out = "D"; // -..
            {3'd3, 5'b00101}: ascii_out = "K"; // -.-
            {3'd3, 5'b00110}: ascii_out = "G"; // --.
            {3'd3, 5'b00111}: ascii_out = "O"; // ---
            // count=4
            {3'd4, 5'b00000}: ascii_out = "H"; // ....
            {3'd4, 5'b00001}: ascii_out = "V"; // ...-
            {3'd4, 5'b00010}: ascii_out = "F"; // ..-.
            {3'd4, 5'b00100}: ascii_out = "L"; // .-..
            {3'd4, 5'b00110}: ascii_out = "P"; // .--.
            {3'd4, 5'b00111}: ascii_out = "J"; // .---
            {3'd4, 5'b01000}: ascii_out = "B"; // -...
            {3'd4, 5'b01001}: ascii_out = "X"; // -..-
            {3'd4, 5'b01010}: ascii_out = "C"; // -.-.
            {3'd4, 5'b01011}: ascii_out = "Y"; // -.--
            {3'd4, 5'b01100}: ascii_out = "Z"; // --..
            {3'd4, 5'b01101}: ascii_out = "Q"; // --.-
            // count=5 (digits)
            {3'd5, 5'b00000}: ascii_out = "5"; // .....
            {3'd5, 5'b00001}: ascii_out = "4"; // ....-
            {3'd5, 5'b00011}: ascii_out = "3"; // ...--
            {3'd5, 5'b00111}: ascii_out = "2"; // ..---
            {3'd5, 5'b01111}: ascii_out = "1"; // .----
            {3'd5, 5'b10000}: ascii_out = "6"; // -....
            {3'd5, 5'b11000}: ascii_out = "7"; // --...
            {3'd5, 5'b11100}: ascii_out = "8"; // ---..
            {3'd5, 5'b11110}: ascii_out = "9"; // ----.
            {3'd5, 5'b11111}: ascii_out = "0"; // -----
            default:          ascii_out = "?"; // unrecognized pattern
        endcase
    end
endmodule