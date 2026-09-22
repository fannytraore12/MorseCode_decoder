module synchronizer (
    input  wire sys_clk,
    input  wire rst_n,
    input  wire btn_in,
    output reg  btn_sync
);
    reg q1;
    always @(posedge sys_clk or negedge rst_n) begin
    //If reset is active (0), clear the registers
        if (!rst_n) begin
            q1       <= 1'b0;
            btn_sync <= 1'b0;
        end else begin
        //otherwise (reset is NOT active), run as normal clock-edge shifting
            q1       <= btn_in;
            btn_sync <= q1;
        end
    end
endmodule