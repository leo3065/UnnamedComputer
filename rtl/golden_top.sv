`default_nettype none
module golden_top(
    ///////// CLOCK /////////
    input   wire CLOCK0_50,
    input   wire CLOCK1_50,

    ///////// KEY /////////
    input   wire [ 3: 0] KEY, //BUTTON is Low-Active

    ///////// SW /////////
    input   wire [ 9: 0] SW,

    ///////// LED /////////
    output  wire [ 9: 0] LEDR, //LED is Low-Active

    ///////// Seg7 /////////
    output  wire [ 6: 0] HEX0,
    output  wire [ 6: 0] HEX1,
    output  wire [ 6: 0] HEX2,
    output  wire [ 6: 0] HEX3,
    output  wire [ 6: 0] HEX4,
    output  wire [ 6: 0] HEX5,

    ///////// SDRAM /////////
    output  wire DRAM_CLK,
    output  wire DRAM_CKE,
    output  wire [12: 0] DRAM_ADDR,
    output  wire [ 1: 0] DRAM_BA,
    inout   wire [31: 0] DRAM_DQ,
    output  wire DRAM_CS_n,
    output  wire DRAM_WE_n,
    output  wire DRAM_CAS_n,
    output  wire DRAM_RAS_n,
    output  wire [ 3: 0] DRAM_DQM,

    ///////// HDMI /////////
    output  wire HDMI_TX_CLK,
    output  wire HDMI_TX_HS,
    output  wire HDMI_TX_VS,
    output  wire [23: 0] HDMI_TX_D,
    output  wire HDMI_TX_DE,
    input   wire HDMI_TX_INT,
    inout   wire HDMI_LRCLK,
    inout   wire HDMI_MCLK,
    inout   wire HDMI_SCLK,
    inout   wire HDMI_I2S0,

    ///////// UART /////////
    output  wire UART_TX,
    input   wire UART_RX,

    ///////// I2C for HDMI and ADC /////////
    inout   wire I2C_SCL,
    inout   wire I2C_SDA,

    ///////// GPIO /////////
    inout   wire [35: 0] GPIO_D
);

logic CLK_sys;
assign CLK_sys = CLOCK0_50;
localparam int CLK_FREQ = 'd50_000_000;

logic INIT_DONE_n, RST_sync_n, RST_n_ext;

reset_release reset_release_inst (.ninit_done(INIT_DONE_n));
reset_sync reset_sync_inst  (.CLK_sys, .RST_n(~INIT_DONE_n & RST_n_ext), .RST_sync_n);

localparam int UART_BAUD = 'd115200;
localparam int CLK_DIV_INIT = uart_pkg::calc_uart_clk_div(UART_BAUD, CLK_FREQ);
localparam int CLK_DIV_ALT = uart_pkg::calc_uart_clk_div('d9600, CLK_FREQ);

localparam int FIFO_DEPTH = 1<<7;

logic wr_almost_full_thres;
logic [7:0] almost_full_tres_q, almost_full_tres_i;
always_ff @(posedge CLK_sys or negedge RST_sync_n) begin
    if (!RST_sync_n) begin
        almost_full_tres_q <= FIFO_DEPTH-1;
    end else begin
        if (wr_almost_full_thres) begin
            almost_full_tres_q <= almost_full_tres_i;
        end
    end
end

wire baud_sel = SW[8];
wire [15:0] clk_div_i = baud_sel ? CLK_DIV_ALT : CLK_DIV_INIT;

logic [7:0] data_recv, data_fifo, data_send;
logic rx_valid_recv, rx_ready_recv, err, err_clr, overrun, overrun_clr;
logic fifo_rx_full, fifo_rx_empty, fifo_tx_full, fifo_tx_empty;
logic [7:0] fifo_rx_count, fifo_tx_count;
logic fifo_valid, fifo_ready, send_trigger, send_en;
logic tx_valid_send, tx_ready_send;

uart_rx #(.CLK_DIV_INIT(CLK_DIV_INIT)) uart_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_RX(UART_RX),
    .data_o(data_recv),
    .valid_o(rx_valid_recv),
    .ready_i(rx_ready_recv),
    .err_o(err),
    .err_clr_i(err_clr),
    .overrun_o(overrun),
    .overrun_clr_i(overrun_clr),
    .clk_div_i(clk_div_i)
);

logic fifo_almost_full;

fifo #(.DATA_WIDTH(8), .FIFO_DEPTH(FIFO_DEPTH)) fifo_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .data_i(data_recv),
    .in_valid_i(rx_valid_recv),
    .in_ready_o(rx_ready_recv),
    .data_o(data_fifo),
    .out_valid_o(fifo_valid),
    .out_ready_i(fifo_ready & send_en),
    .count_o(fifo_rx_count),
    .full_o(fifo_rx_full),
    .empty_o(fifo_rx_empty),

    .almost_full_o(fifo_almost_full),
    .almost_full_thres_i(almost_full_tres_q)
);

always_ff @(posedge CLK_sys or negedge RST_sync_n) begin : send_control
    if (!RST_sync_n) begin
        send_en <= 1'b0;
    end else begin
        if (fifo_almost_full) begin
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
    .count_o(fifo_tx_count),
    .full_o(fifo_tx_full),
    .empty_o(fifo_tx_empty)
);

uart_tx #(.CLK_DIV_INIT(CLK_DIV_INIT)) uart_tx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_TX(UART_TX),
    .data_i(data_send),
    .valid_i(tx_valid_send),
    .ready_o(tx_ready_send),
    .clk_div_i(clk_div_i)
);

lut_7seg lut_7seg_inst0 (.val_i(fifo_rx_count[3:0]), .hex_o(HEX0));
lut_7seg lut_7seg_inst1 (.val_i(fifo_rx_count[7:4]), .hex_o(HEX1));
lut_7seg lut_7seg_inst2 (.val_i(almost_full_tres_q[3:0]), .hex_o(HEX2));
lut_7seg lut_7seg_inst3 (.val_i(almost_full_tres_q[7:4]), .hex_o(HEX3));
lut_7seg lut_7seg_inst4 (.val_i(fifo_tx_count[3:0]), .hex_o(HEX4));
lut_7seg lut_7seg_inst5 (.val_i(fifo_tx_count[7:4]), .hex_o(HEX5));

assign LEDR = ~{
    fifo_tx_full, fifo_tx_empty, send_en, fifo_rx_full, fifo_rx_empty,
    1'b0, overrun, err, ~UART_RX, ~UART_TX};

assign almost_full_tres_i = SW[6:0]+1;

assign RST_n_ext = KEY[0];
assign wr_almost_full_thres = ~KEY[1];
assign err_clr = ~KEY[2];
assign overrun_clr = ~KEY[3];

endmodule
