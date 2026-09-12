`default_nettype none
module uart_rx #(
    parameter int CLK_DIV_INIT,
    parameter int CLK_DIV_WIDTH = 13
)(
    input   wire CLK_sys,
    input   wire RST_n,

    input   wire uart_RX,

    output  reg [7:0] data_o,
    output  reg valid_o,
    input   wire ready_i,

    output  reg err_o,
    input   wire err_clr_i,

    output  reg overrun_o,
    input   wire overrun_clr_i,

    input   wire [CLK_DIV_WIDTH-1:0] clk_div_i
);

typedef enum logic [2:0] {
    IDLE, TRIGGERED, START, READ, STOP, DONE, ERR_HOLD
} uart_rx_state_t;
uart_rx_state_t state, state_next;

logic [CLK_DIV_WIDTH-1:0] count_sample, count_sample_next;
logic [CLK_DIV_WIDTH-1:0] count_div_cur, count_div_cfg;
logic [CLK_DIV_WIDTH-1:0]
    count_sample_max, count_sample_sample,
    count_sample_stop_lo, count_sample_stop_hi;
assign count_sample_max = count_div_cur - 1;
assign count_sample_sample = count_div_cur >> 1;
assign count_sample_stop_lo = count_sample_sample - (count_div_cur >> 3);
assign count_sample_stop_hi = count_sample_sample + (count_div_cur >> 3);

always_ff @(posedge CLK_sys or negedge RST_n) begin : clk_div_cfg
    if (~RST_n) begin
        count_div_cfg <= CLK_DIV_INIT;
        count_div_cur <= CLK_DIV_INIT;
    end else begin
        count_div_cfg <= clk_div_i;
        if (state_next == TRIGGERED) begin
            count_div_cur <= count_div_cfg;
        end
    end
end

logic [3:0] count_bit, count_bit_next;
localparam logic [3:0] COUNT_BIT_DONE = 8;

logic [7:0] data_recv;

logic rx_sample, rx_sync_0, rx_sync_1;

always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (~RST_n) begin
        rx_sync_0 <= 1;
        rx_sync_1 <= 1;
    end else begin
        rx_sync_0 <= uart_RX;
        rx_sync_1 <= rx_sync_0;
    end
end

always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (~RST_n) begin
        err_o <= 0;
    end else begin
        if (state_next == ERR_HOLD && state != ERR_HOLD) begin
            err_o <= 1;
        end else if (err_clr_i) begin
            err_o <= 0;
        end
    end
end

always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (~RST_n) begin
        state <= IDLE;
        count_sample <= 0;
        count_bit <= 0;
        rx_sample <= 1;
        data_recv <= 0;
        
        data_o <= 0;
        valid_o <= 0;
        overrun_o <= 0;
    end else begin
        state <= state_next;
        count_sample <= count_sample_next;
        count_bit <= count_bit_next;
        rx_sample <= rx_sync_1;
        if (count_sample_next == count_sample_sample && state_next == READ) begin
            // LSB first
            data_recv <= {rx_sample, data_recv[7:1]};
        end else begin
            data_recv <= data_recv;
        end
        
        if (state == STOP && state_next == DONE) begin
            // New byte coming in
            if (valid_o == 0 || ready_i == 1) begin
                // Either consumed or ready to be consumed
                data_o <= data_recv;
                valid_o <= 1;
                if (overrun_clr_i) begin
                    overrun_o <= 1;
                end
            end else begin
                // Holding the old byte, new byte got dropped
                data_o <= data_o;
                valid_o <= valid_o;
                overrun_o <= 1;
            end
        end else begin
            if (ready_i == 1) begin
                // Consumed
                data_o <= data_o;
                valid_o <= 0;
            end else begin
                data_o <= data_o;
                valid_o <= valid_o;
            end
            if (overrun_clr_i) begin
                overrun_o <= 0;
            end else begin
                overrun_o <= overrun_o;
            end
        end
    end
end

always_comb begin
    state_next = state;
    count_sample_next = count_sample;
    count_bit_next = count_bit;
    unique case(state)
    default: begin
        state_next = IDLE;
        count_sample_next = 0;
        count_bit_next = 0;
    end
    IDLE: begin
        if (rx_sample == '0) begin
            // Start bit detected
            state_next = TRIGGERED;
            count_sample_next = count_sample + 1;
        end else begin
            state_next = IDLE;
            count_sample_next = 0;
        end
        count_bit_next = 0;
    end
    TRIGGERED: begin
        if (rx_sample == '1) begin
            // Start bit not completed
            state_next = IDLE;
            count_sample_next = 0;
            count_bit_next = 0;
        end else begin
            // Start bit stays for long enough, ready to receive
            if (count_sample == count_sample_sample) begin
                state_next = START;
            end else begin
                state_next = TRIGGERED;
            end
            count_sample_next = count_sample + 1;
            count_bit_next = 0;
        end
    end
    START: begin
        if (count_sample >= count_sample_max) begin
            state_next = READ;
            count_sample_next = 0;
            count_bit_next = 1;
        end else begin
            state_next = START;
            count_sample_next = count_sample + 1;
            count_bit_next = 0;
        end
    end
    READ: begin
        if (count_sample < count_sample_max) begin
            count_sample_next = count_sample + 1;
        end else begin
            count_sample_next = 0;
        end
        
        if (count_sample >= count_sample_max) begin
            if (count_bit >= COUNT_BIT_DONE) begin
                state_next = STOP;
            end else begin
                state_next = READ;
            end
            count_bit_next = count_bit + 1;
        end else begin
            state_next = READ;
            count_bit_next = count_bit;
        end
    end
    STOP: begin
        count_sample_next = count_sample + 1;
        count_bit_next    = count_bit;
        state_next        = STOP;
        if (count_sample >= count_sample_stop_lo
                && count_sample < count_sample_stop_hi) begin
            if (rx_sample == '0) begin
                // Framing error
                state_next = ERR_HOLD;
                count_sample_next = 0;
            end
        end else if (count_sample >= count_sample_stop_hi) begin
            state_next = DONE;
            count_sample_next = 0;
        end
    end
    DONE: begin
        state_next = IDLE;
        count_sample_next = 0;
        count_bit_next = 0;
    end
    ERR_HOLD: begin
        if (rx_sample == '1) begin
            if (count_sample >= count_sample_max) begin
                state_next = IDLE;
                count_sample_next = 0;
            end else begin
                state_next = ERR_HOLD;
                count_sample_next = count_sample + 1;
            end
        end else begin
            state_next = ERR_HOLD;
            count_sample_next = 0;
        end
        count_bit_next = 0;
    end
    endcase
end

endmodule
