module uart_rx #(
    parameter int UART_BAUD = 'd9600,
    parameter int CLK_FREQ = 'd50_000_000
)(
    input   CLK_sys,
    input   RST_n,

    input   uart_RX,

    output  reg [7:0] data_o,
    output  reg recv_o,
    input   err_clr_i,
    output  reg err_o
);

typedef enum logic [2:0] {
    IDLE, TRIGGERED, START, READ, DONE, STOP, ERR_HOLD
} uart_state_t;

logic rx_sample, rx_sync_0, rx_sync_1;
uart_state_t state, state_next;

localparam int CLK_DIV = (CLK_FREQ + UART_BAUD/2) / UART_BAUD;
localparam int CLK_DIV_WIDTH = $clog2(CLK_DIV);
logic [CLK_DIV_WIDTH:0] count_sample, count_sample_next;
localparam logic [CLK_DIV_WIDTH:0]
    COUNT_SAMPLE_MAX = CLK_DIV - 1,
    COUNT_SAMPLE_SAMPLE = CLK_DIV / 2,
    COUNT_SAMPLE_STOP_LO = (CLK_DIV * 3) / 8,
    COUNT_SAMPLE_STOP_HI = (CLK_DIV * 5) / 8;

logic [3:0] count_bit, count_bit_next;
localparam logic [3:0] COUNT_BIT_DONE = 8;

logic [7:0] data_recv;

always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (RST_n == '0) begin
        rx_sync_0 <= 1;
        rx_sync_1 <= 1;
    end else begin
        rx_sync_0 <= uart_RX;
        rx_sync_1 <= rx_sync_0;
    end
end

always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (RST_n == '0) begin
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
    if (RST_n == '0) begin
        state <= IDLE;
        count_sample <= 0;
        count_bit <= 0;
        rx_sample <= 1;
        data_recv <= 0;
        
        data_o <= 0;
        recv_o <= 0;
    end else begin
        state <= state_next;
        count_sample <= count_sample_next;
        count_bit <= count_bit_next;
        rx_sample <= rx_sync_1;
        if (count_sample_next == COUNT_SAMPLE_SAMPLE && state_next == READ) begin
            // LSB first
            data_recv <= {rx_sample, data_recv[7:1]};
        end else begin
            data_recv <= data_recv;
        end
        
        if (state == STOP && state_next == DONE) begin
            data_o <= data_recv;
            recv_o <= 1;
        end else begin
            data_o <= data_o;
            recv_o <= 0;
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
            if (count_sample == COUNT_SAMPLE_SAMPLE) begin
                state_next = START;
            end else begin
                state_next = TRIGGERED;
            end
            count_sample_next = count_sample + 1;
            count_bit_next = 0;
        end
    end
    START: begin
        if (count_sample == COUNT_SAMPLE_MAX) begin
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
        if (count_sample < COUNT_SAMPLE_MAX) begin
            count_sample_next = count_sample + 1;
        end else begin
            count_sample_next = 0;
        end
        
        if (count_sample == COUNT_SAMPLE_MAX) begin
            if (count_bit == COUNT_BIT_DONE) begin
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
        if (count_sample >= COUNT_SAMPLE_STOP_LO
                && count_sample <= COUNT_SAMPLE_STOP_HI) begin
            if (rx_sample == '0) begin
                // Framing error
                state_next = ERR_HOLD;
                count_sample_next = 0;
            end else if (count_sample == COUNT_SAMPLE_STOP_HI) begin
                state_next = DONE;
                count_sample_next = 0;
            end
        end
    end
    ERR_HOLD: begin
        if (rx_sample == '1) begin
            if (count_sample == COUNT_SAMPLE_MAX) begin
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
    DONE: begin
        state_next = IDLE;
        count_sample_next = 0;
        count_bit_next = 0;
    end
    endcase
end

endmodule
