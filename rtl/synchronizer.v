module synchronizer (
    input  wire sys_clk,
    input  wire rst_n,
    input  wire btn_in,
    output reg  btn_sync
);
    reg sync0;// state 1 d flip-flop catching asynch btn_sync
    reg sync1; //stage 2 d flipflop registering a stable logic level with clk
    reg sync1_d;// delay flip flop
    always @(posedge sys_clk or negedge rst_n) begin
    //If reset is active (0), clear the registers
        if(!rst_n)begin
            sync0 <= 1'b0;
            sync1 <=1'b0;
            sync1_d <= 1'b0;
            btn_sync <= 1'b0;
        end 
        else begin
        //otherwise (reset is NOT active), run as normal clock-edge shifting
            sync0 <= btn_in;
            sync1 <=sync0;
            sync1_d <= sync1;
            btn_sync <= (sync1 && !sync1_d);
        end
    end
endmodule