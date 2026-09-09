module uart_tx #(
    parameter int CLK_DIV
)(
    input   CLK_sys,
    input   RST_n,

    output  uart_TX,

    input   [7:0] data_i,
    input   valid_i,
    output  ready_o
);

localparam int CLK_DIV_WIDTH = $clog2(CLK_DIV);
logic [CLK_DIV_WIDTH:0] count_sample;
localparam logic [CLK_DIV_WIDTH:0] COUNT_SAMPLE_MAX = CLK_DIV - 1;

logic [3:0] count_bit;
localparam logic [3:0] COUNT_BIT_DONE = 10;

logic [9:0] shift_out;
logic [7:0] data_reg;
logic has_data;
logic read_next;
logic ready;

assign uart_TX = shift_out[0];
assign read_next = has_data & (count_bit == '0);
assign ready = valid_i & (read_next | ~has_data);
assign ready_o = ready;

// Data register
always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (~RST_n) begin
        data_reg <= '0;
        has_data <= '0;
    end else begin
        if (ready) begin
            data_reg <= data_i;
            has_data <= '1;
        end else if (read_next) begin
                data_reg <= data_reg;
                has_data <= '0;
        end else begin
            data_reg <= data_reg;
            has_data <= has_data;
        end
    end
end

// Output shift register
always_ff @(posedge CLK_sys or negedge RST_n) begin
    if (~RST_n) begin
        count_sample <= '0;
        count_bit <= '0;
        shift_out <= '1;
    end else begin
        if (count_bit != '0) begin
            // Sending data
            if (count_sample != COUNT_SAMPLE_MAX) begin
                count_sample <= count_sample + 1;
                count_bit <= count_bit;
                shift_out <= shift_out;
            end else begin
                count_sample <= '0;
                count_bit <= 
                    (count_bit != COUNT_BIT_DONE) ? count_bit + 1 :
                    read_next ? 'd1 : '0;
                shift_out <= {1'b1, shift_out[9:1]};
            end
        end else if (read_next) begin
            // Idle with new data available
            count_sample <= '0;
            count_bit <= 'd1;
            shift_out <= {1'b1, data_reg, 1'b0};
        end else begin
            count_sample <= '0;
            count_bit <= '0;
            shift_out <= '1;
        end
    end
end

endmodule
