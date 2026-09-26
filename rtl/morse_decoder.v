// -----------------------------------------------------------------------------
// morse_decoder.v
// Combinational lookup: (char_len, char_bits) -> ASCII + a compact 6-bit index.
//   index  1..26 = 'A'..'Z'
//   index 27..36 = '0'..'9'
//   index  0     = unknown / overflow  (ascii = '?')
// Bits: 0 = dot, 1 = dash, right-aligned, first element is the MSB of the
// used bits (matches morse_fsm).
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
`default_nettype none

module morse_decoder (
    input  wire [2:0] len,
    input  wire [4:0] bits,
    input  wire       overflow,
    output reg  [7:0] ascii,
    output reg  [5:0] index
);
    always @* begin
        ascii = "?";
        if (!overflow) begin
            case ({len, bits})
            // 1 element
            {3'd1, 5'b00000}: ascii = "E";   // .
            {3'd1, 5'b00001}: ascii = "T";   // -
            // 2 elements
            {3'd2, 5'b00000}: ascii = "I";   // ..
            {3'd2, 5'b00001}: ascii = "A";   // .-
            {3'd2, 5'b00010}: ascii = "N";   // -.
            {3'd2, 5'b00011}: ascii = "M";   // --
            // 3 elements
            {3'd3, 5'b00000}: ascii = "S";   // ...
            {3'd3, 5'b00001}: ascii = "U";   // ..-
            {3'd3, 5'b00010}: ascii = "R";   // .-.
            {3'd3, 5'b00011}: ascii = "W";   // .--
            {3'd3, 5'b00100}: ascii = "D";   // -..
            {3'd3, 5'b00101}: ascii = "K";   // -.-
            {3'd3, 5'b00110}: ascii = "G";   // --.
            {3'd3, 5'b00111}: ascii = "O";   // ---
            // 4 elements
            {3'd4, 5'b00000}: ascii = "H";   // ....
            {3'd4, 5'b00001}: ascii = "V";   // ...-
            {3'd4, 5'b00010}: ascii = "F";   // ..-.
            {3'd4, 5'b00100}: ascii = "L";   // .-..
            {3'd4, 5'b00110}: ascii = "P";   // .--.
            {3'd4, 5'b00111}: ascii = "J";   // .---
            {3'd4, 5'b01000}: ascii = "B";   // -...
            {3'd4, 5'b01001}: ascii = "X";   // -..-
            {3'd4, 5'b01010}: ascii = "C";   // -.-.
            {3'd4, 5'b01011}: ascii = "Y";   // -.--
            {3'd4, 5'b01100}: ascii = "Z";   // --..
            {3'd4, 5'b01101}: ascii = "Q";   // --.-
            // 5 elements (digits)
            {3'd5, 5'b01111}: ascii = "1";   // .----
            {3'd5, 5'b00111}: ascii = "2";   // ..---
            {3'd5, 5'b00011}: ascii = "3";   // ...--
            {3'd5, 5'b00001}: ascii = "4";   // ....-
            {3'd5, 5'b00000}: ascii = "5";   // .....
            {3'd5, 5'b10000}: ascii = "6";   // -....
            {3'd5, 5'b11000}: ascii = "7";   // --...
            {3'd5, 5'b11100}: ascii = "8";   // ---..
            {3'd5, 5'b11110}: ascii = "9";   // ----.
            {3'd5, 5'b11111}: ascii = "0";   // -----
            default:          ascii = "?";
            endcase
        end

        if (ascii >= "A" && ascii <= "Z")
            index = ascii[5:0];                // 'A' = 0x41 -> low 6 bits = 1
        else if (ascii >= "0" && ascii <= "9")
            index = ascii[5:0] - 6'd21;         // '0' = 0x30 -> 48-21 = 27
        else
            index = 6'd0;
    end
endmodule

`default_nettype wire
