module tick_gen (
    input  wire sys_clk,
    input  wire rst_n,
    output reg  tick_1ms
);
    reg [16:0] count;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= 17'd0;
            tick_1ms <= 1'b0;
        end else if (count == 17'd99999) begin
            count    <= 17'd0;
            tick_1ms <= 1'b1;
        end else begin
            count    <= count + 1'b1;
            tick_1ms <= 1'b0;
        end
    end
endmodule