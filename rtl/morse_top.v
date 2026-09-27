module synchronizer #(
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire sys_clk,
    input  wire rst_n,       // active-low, async
    input  wire btn_in,      // raw pin, active-high: idle=0, pressed=1
    input  wire tick_1ms,
    output reg  btn_sync     // debounced LEVEL: 1 while pressed, 0 while released
);
    localparam integer W = $clog2(DEBOUNCE_MS + 1);

    reg sync0, sync1;        // 2-stage metastability synchronizer
    reg [W-1:0] cnt;

    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync0    <= 1'b0;
            sync1    <= 1'b0;
            cnt      <= {W{1'b0}};
            btn_sync <= 1'b0;
        end
        else begin
            sync0 <= btn_in;
            sync1 <= sync0;

            if (tick_1ms) begin
                if (sync1 == btn_sync) begin
                    cnt <= {W{1'b0}};              // agrees with current output: no bounce in progress
                end
                else if (cnt == DEBOUNCE_MS - 1) begin
                    cnt      <= {W{1'b0}};
                    btn_sync <= sync1;              // disagreement held for DEBOUNCE_MS ticks: accept it
                end
                else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end
endmodule