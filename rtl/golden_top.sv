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

assign UART_TX = '1;
assign I2C_SCL = '1;
assign I2C_SDA = '1;

logic CLK_sys;
assign CLK_sys = CLOCK0_50;

logic INIT_DONE_n, RST_sync_n;

reset_release reset_release_inst (
    .ninit_done(INIT_DONE_n)
);

reset_sync (.CLK_sys, .RST_n(~INIT_DONE_n), .RST_sync_n);

logic [7:0] data;
logic recv, err;
parameter UART_BAUD = 115200;

assign LEDR = ~{9'b0, err};

uart_rx #(.UART_BAUD(UART_BAUD)) uart_rx_inst (
    .CLK_sys,
    .RST_n(RST_sync_n),
    .uart_RX(UART_RX),
    .data_o(data),
    .recv_o(recv),
    .err_clr_i(~KEY[0]),
    .err_o(err)
);

logic [7:0] data_latched0, data_latched1, data_latched2;

always_ff @(posedge CLK_sys or negedge RST_sync_n) begin
    if (RST_sync_n == '0) begin
        data_latched0 <= '0;
        data_latched1 <= '0;
        data_latched2 <= '0;
    end else begin
        if (recv) begin
            data_latched0 <= data;
            data_latched1 <= data_latched0;
            data_latched2 <= data_latched1;
        end
    end
end

lut_7seg (.val_i(data_latched2[7:4]), .disp_n_o(HEX5));
lut_7seg (.val_i(data_latched2[3:0]), .disp_n_o(HEX4));
lut_7seg (.val_i(data_latched1[7:4]), .disp_n_o(HEX3));
lut_7seg (.val_i(data_latched1[3:0]), .disp_n_o(HEX2));
lut_7seg (.val_i(data_latched0[7:4]), .disp_n_o(HEX1));
lut_7seg (.val_i(data_latched0[3:0]), .disp_n_o(HEX0));

endmodule
