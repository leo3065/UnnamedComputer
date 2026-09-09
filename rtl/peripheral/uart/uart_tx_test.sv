`default_nettype none

import uart_pkg::*;

module uart_tx_test;
timeunit 1ns/1ns;

logic CLK_sys;
logic RST_n;
logic RST_sync_n;
logic uart_TX;

logic [7:0] data_send, data_latest;
logic valid;
logic ready;

parameter UART_BAUD = 9;
parameter CLK_FREQ = 50_000;
parameter real CLK_UART_RATIO = real'(CLK_FREQ) / real'(UART_BAUD);
parameter real CLK_UART_RATIO_ACTUAL = CLK_UART_RATIO * 0.98;
parameter CLK_HALF_DURATION = 5;
parameter BIT_DURATION = CLK_HALF_DURATION*2*CLK_UART_RATIO_ACTUAL;

task uart_tx_send_to (input logic [7:0] send_val);
begin
    @(posedge CLK_sys);
    data_send = send_val;
    valid = '1;
    do begin
        @(posedge CLK_sys);
    end while (~ready);
    $display("Sent");
    valid = '0;
end
endtask

parameter SEND_REPEAT_TIMES = 20;
always #(CLK_HALF_DURATION) CLK_sys = ~CLK_sys;
initial begin
    CLK_sys = 0;
    data_send = 0;
    valid = 0;
    
    #5 RST_n = 1'b0;
    #5 RST_n = 1'b1;
    #($urandom_range(BIT_DURATION, BIT_DURATION*2));
    
    for (int i_send=0; i_send<SEND_REPEAT_TIMES; i_send++) begin
        data_latest = $urandom_range('0, 'hff);
        $display("Sending (%0d/%0d): data = %02x",
            i_send, SEND_REPEAT_TIMES, data_latest);
        uart_tx_send_to(data_latest);
        if ($urandom_range(0, 9) < 8) begin
            $display("Wait for a while...");
            #($urandom_range(BIT_DURATION*8, BIT_DURATION*10));
        end
    end
    $stop;
end

reset_sync reset_sync_inst (
    .CLK_sys, .RST_n, .RST_sync_n
);

parameter CLK_DIV = calc_uart_clk_div(UART_BAUD, CLK_FREQ);
uart_tx #(.CLK_DIV(CLK_DIV)) uart_tx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_TX,
    .data_i(data_send),
    .valid_i(valid),
    .ready_o(ready)
);

endmodule

`default_nettype wire
