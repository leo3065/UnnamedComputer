module golden_top(
    ///////// CLOCK /////////
    input              CLOCK0_50,
    input              CLOCK1_50,

    ///////// KEY /////////
    input    [ 3: 0]   KEY, //BUTTON is Low-Active

    ///////// SW /////////
    input    [ 9: 0]   SW,

    ///////// LED /////////
    output   [ 9: 0]   LEDR, //LED is Low-Active

    ///////// Seg7 /////////
    output   [ 6: 0]   HEX0,
    output   [ 6: 0]   HEX1,
    output   [ 6: 0]   HEX2,
    output   [ 6: 0]   HEX3,
    output   [ 6: 0]   HEX4,
    output   [ 6: 0]   HEX5,

    ///////// SDRAM /////////
    output             DRAM_CLK,
    output             DRAM_CKE,
    output   [12: 0]   DRAM_ADDR,
    output   [ 1: 0]   DRAM_BA,
    inout    [31: 0]   DRAM_DQ,
    output             DRAM_CS_n,
    output             DRAM_WE_n,
    output             DRAM_CAS_n,
    output             DRAM_RAS_n,
    output   [ 3: 0]   DRAM_DQM,

    ///////// HDMI /////////
    output             HDMI_TX_CLK,
    output             HDMI_TX_HS,
    output             HDMI_TX_VS,
    output   [23: 0]   HDMI_TX_D,
    output             HDMI_TX_DE,
    input              HDMI_TX_INT,
    inout              HDMI_LRCLK,
    inout              HDMI_MCLK,
    inout              HDMI_SCLK,
    inout              HDMI_I2S0,

    ///////// UART /////////
    output             UART_TX,
    input              UART_RX,

    ///////// I2C for HDMI and ADC /////////
    inout              I2C_SCL,
    inout              I2C_SDA,

    ///////// GPIO /////////
    inout    [35: 0]   GPIO_D
);

// assign UART_TX = '1;

logic CLK_sys;
assign CLK_sys = CLOCK0_50;
localparam int CLK_FREQ = 'd50_000_000;

logic INIT_DONE_n, RST_sync_n, RST_n_ext;

reset_release reset_release_inst (.ninit_done(INIT_DONE_n));
reset_sync reset_sync_inst  (.CLK_sys, .RST_n(~INIT_DONE_n & RST_n_ext), .RST_sync_n);

localparam int UART_BAUD = 'd115200;
localparam int CLK_DIV = uart_pkg::calc_uart_clk_div(UART_BAUD, CLK_FREQ);

logic [7:0] data_recv, data_fifo, data_send;
logic rx_valid_recv, rx_ready_recv, err, err_clr, overrun, overrun_clr;
logic fifo_rx_full, fifo_rx_empty, fifo_tx_full, fifo_tx_empty;
logic [7:0] fifo_rx_count, fifo_tx_count;
logic fifo_valid, fifo_ready, send_trigger, send_en;
logic tx_valid_send, tx_ready_send;

localparam int FIFO_DEPTH = 1<<7;
uart_rx #(.CLK_DIV(CLK_DIV)) uart_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_RX(UART_RX),
    .data_o(data_recv),
    .valid_o(rx_valid_recv),
    .ready_i(rx_ready_recv),
    .err_o(err),
    .err_clr_i(err_clr),
    .overrun_o(overrun),
    .overrun_clr_i(overrun_clr)
);

fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) fifo_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .data_i(data_recv),
    .in_valid_i(rx_valid_recv),
    .in_ready_o(rx_ready_recv),
    .data_o(data_fifo),
    .out_valid_o(fifo_valid),
    .out_ready_i(fifo_ready & send_en),
    .fifo_count_o(fifo_rx_count),
    .fifo_full_o(fifo_rx_full),
    .fifo_empty_o(fifo_rx_empty)
);

localparam [7:0] SEND_TRIGGER_PATTERN = 8'hAA;
logic rx_beat, rx_trigger;
assign rx_beat = rx_valid_recv && rx_ready_recv;
assign rx_trigger = rx_beat && (data_recv == SEND_TRIGGER_PATTERN);
always_ff @(posedge CLK_sys or negedge RST_sync_n) begin : send_control
    if (!RST_sync_n) begin
        send_en <= 1'b0;
    end else begin
        if (rx_trigger) begin
            send_en <= 1'b1;
        end else if (fifo_rx_empty) begin
            send_en <= 1'b0;
        end
    end
end

fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) fifo_tx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .data_i(data_fifo),
    .in_valid_i(fifo_valid & send_en),
    .in_ready_o(fifo_ready),
    .data_o(data_send),
    .out_valid_o(tx_valid_send),
    .out_ready_i(tx_ready_send),
    .fifo_count_o(fifo_tx_count),
    .fifo_full_o(fifo_tx_full),
    .fifo_empty_o(fifo_tx_empty)
);

uart_tx #(.CLK_DIV(CLK_DIV)) uart_tx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_TX(UART_TX),
    .data_i(data_send),
    .valid_i(tx_valid_send),
    .ready_o(tx_ready_send)
);

lut_7seg lut_7seg_inst0 (.val_i(fifo_rx_count[3:0]), .hex_o(HEX0));
lut_7seg lut_7seg_inst1 (.val_i(fifo_rx_count[7:4]), .hex_o(HEX1));
assign HEX2 = '1;
assign HEX3 = '1;
lut_7seg lut_7seg_inst4 (.val_i(fifo_tx_count[3:0]), .hex_o(HEX4));
lut_7seg lut_7seg_inst5 (.val_i(fifo_tx_count[7:4]), .hex_o(HEX5));

assign LEDR = ~{
    fifo_tx_full, fifo_tx_empty, send_en, fifo_rx_full, fifo_rx_empty,
    1'b0, overrun, err, ~UART_RX, ~UART_TX};

assign RST_n_ext = KEY[0];
assign err_clr = ~KEY[2];
assign overrun_clr = ~KEY[3];

endmodule
