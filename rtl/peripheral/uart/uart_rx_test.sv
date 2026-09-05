`default_nettype none
module uart_rx_test();
timeunit 1ns/1ns;

logic CLK_sys;
logic RST_n;
logic RST_sync_n;
logic uart_RX;
logic err_clr;
logic [7:0] data;
logic recv;
logic err;

logic [7:0] data_lastest;
int byte_sent, byte_recieved;

enum {
    IDLE, NORMAL, ERR_START, ERR_END
} send_case;

parameter UART_BAUD = 9;
parameter CLK_FREQ = 50_000;
parameter real CLK_UART_RATIO = real'(CLK_FREQ) / real'(UART_BAUD);
parameter real CLK_UART_RATIO_ACTUAL = CLK_UART_RATIO * 0.98;
parameter CLK_HALF_DURATION = 5;
parameter BIT_DURATION = CLK_HALF_DURATION*2*CLK_UART_RATIO_ACTUAL;

task automatic uart_send_to(input [7:0] send_val, ref logic uart_rx);
begin
    $display("Sending: data = %02x", send_val);
    uart_rx = 0; #BIT_DURATION // Start bit
    for (int b=0; b<8; b++) begin
        // LSB first
        uart_rx = send_val[b]; #BIT_DURATION;
    end
    uart_rx = 1; #BIT_DURATION; // Stop bit
end
endtask

task automatic uart_broken_stop_to(input [7:0] send_val, ref logic uart_rx);
begin
    $display("Sending with broken stop bit: data = %02x", send_val);
    uart_rx = 0; #BIT_DURATION // Start bit
    for (int b=0; b<8; b++) begin
        // LSB first
        uart_rx = send_val[b]; #BIT_DURATION;
    end
    uart_rx = 1; #(BIT_DURATION/4); // looks like a stop bit briefly
    uart_rx = 0; #(BIT_DURATION);   // low across the entire check window
    uart_rx = 1;
end
endtask

task automatic uart_noise_to (ref logic uart_rx);
    $display("Inject noise");
    uart_rx = 0;
    #($urandom_range(1, BIT_DURATION/3)) // Not long enough
    uart_rx = 1;
endtask

initial begin
    CLK_sys = 1'b0;
    RST_n = 1'b1;
    uart_RX = 1'b1;
    byte_sent = 0;
    byte_recieved = 0;
    send_case = IDLE;
    err_clr = 0;

    #5 RST_n = 1'b0;
    #5 RST_n = 1'b1;
    #($urandom_range(BIT_DURATION, BIT_DURATION*2));
    
    repeat (100) begin
        if ($urandom_range(0, 9) < 9) begin
            send_case = NORMAL;
            data_lastest = $urandom_range('0, 'hff);
            byte_sent++;
            uart_send_to (
                .send_val(data_lastest),
                .uart_rx(uart_RX)
            );
            #($urandom_range(0, BIT_DURATION*2));
        end else begin
            if ($urandom_range(0, 9) < 5) begin
                send_case = ERR_START;
                uart_noise_to(
                    .uart_rx(uart_RX)
                );
                #($urandom_range(BIT_DURATION, BIT_DURATION*2));
            end else begin
                send_case = ERR_END;
                data_lastest = $urandom_range('0, 'hff);
                uart_broken_stop_to (
                    .send_val(data_lastest),
                    .uart_rx(uart_RX)
                );
                #(BIT_DURATION)
                if (err != 1) begin
                    $error("EXPECTED ERROR NOT RISEN");
                end
                err_clr = 1;
                #(BIT_DURATION);
                if (err != 0) begin
                    $error("ERROR NOT CLEARED");
                end
                err_clr = 0;
                #(BIT_DURATION * 2 + $urandom_range(0, BIT_DURATION));
            end
        end
        send_case = IDLE;
    end
    $stop;
end

always #(CLK_HALF_DURATION) CLK_sys = ~CLK_sys;

always @(posedge CLK_sys) begin
    if (recv) begin
        byte_recieved++;
        $display("Receive: data = %02x", data);
        if (data != data_lastest) begin
            $error("DATA MISMATCH, data = %02x, expected = %02x", data, data_lastest);
        end
        if (byte_sent > byte_recieved) begin
            $error("MISSING BYTE");
        end else if (byte_sent < byte_recieved) begin
            $error("EXTRA BYTE");
        end
    end
end

reset_sync reset_sync_inst (
    .CLK_sys, .RST_n, .RST_sync_n
);

uart_rx #(
    .UART_BAUD(UART_BAUD), .CLK_FREQ(CLK_FREQ)
) uart_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_RX,
    .data_o(data),
    .recv_o(recv),
    .err_clr_i(err_clr),
    .err_o(err)
);

endmodule
`default_nettype wire
