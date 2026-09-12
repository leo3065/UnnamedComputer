`default_nettype none
module fifo_test;
timeunit 1ns/1ns;

logic CLK_sys, RST_n, RST_sync_n;
logic [7:0] data_i, data_o;
logic in_valid_i, in_ready_o;
logic out_valid_o, out_ready_i;
logic [3:0] count_o;
logic full_o, empty_o;

int test_data_sent_count = 0, test_data_recieved_count = 0;
logic [7:0] test_data_sent [$] = {};
logic [7:0] date_latest;

task automatic fifo_write(input [7:0] data);
begin
    @(posedge CLK_sys);
    data_i = data;
    in_valid_i = 1;
    @(posedge CLK_sys);
    while (!in_ready_o) begin
        @(posedge CLK_sys);
    end
    in_valid_i = 0;
    test_data_sent.push_back(data);
    test_data_sent_count++;
end
endtask

task automatic fifo_read(output [7:0] data);
begin
    @(posedge CLK_sys);
    out_ready_i = 1;
    while (!out_valid_o) begin
        @(posedge CLK_sys);
    end
    data = data_o;
    @(posedge CLK_sys);
    out_ready_i = 0;
    if (data != test_data_sent[test_data_recieved_count]) begin
        $error("Data mismatch: expected %02x, got %02x",
            test_data_sent[test_data_recieved_count], data);
    end
    test_data_recieved_count++;
end
endtask

localparam int CLK_HALF_DURATION = 5;
localparam int REPEAT_COUNT = 100;
initial begin
    CLK_sys = 0;
    RST_n = 1;

    #5 RST_n = 0;
    #5 RST_n = 1;
    #(CLK_HALF_DURATION*2*5);
    fork
        repeat (REPEAT_COUNT) begin
            fifo_write($urandom_range(0, 8'hFF));
            #(10 + $urandom_range(0, 10) + $urandom_range(0, 3)*10);
        end
        repeat (REPEAT_COUNT) begin
            fifo_read(date_latest);
            #(10 + $urandom_range(0, 10) + $urandom_range(0, 3)*10);
        end
    join
    $stop;
end

always #(CLK_HALF_DURATION) CLK_sys = ~CLK_sys;

reset_sync reset_sync_inst (
    .CLK_sys, .RST_n, .RST_sync_n
);

fifo #(.FIFO_DEPTH(16)) fifo_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    
    .data_i,
    .in_valid_i,
    .in_ready_o,

    .data_o,
    .out_valid_o,
    .out_ready_i,

    .count_o,
    .full_o,
    .empty_o
);

endmodule
