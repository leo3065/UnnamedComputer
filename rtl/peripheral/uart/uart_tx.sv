`default_nettype none
module uart_tx #(
    parameter int CLK_DIV_INIT,
    parameter int CLK_DIV_WIDTH = 13
) (
    input   wire CLK_sys,
    input   wire RST_n,

    output  wire uart_TX,

    input   wire [7:0] data_i,
    input   wire valid_i,
    output  wire ready_o,

    input   wire [CLK_DIV_WIDTH-1:0] clk_div_i
);

logic [CLK_DIV_WIDTH-1:0] count_sample;
logic [CLK_DIV_WIDTH-1:0] count_div_cur, count_div_cfg;
logic [CLK_DIV_WIDTH-1:0] count_sample_max;
assign count_sample_max = count_div_cur - 1;

logic [3:0] count_bit;
localparam logic [3:0] COUNT_BIT_DONE = 10;

always_ff @(posedge CLK_sys or negedge RST_n) begin : clk_div_cfg
    if (~RST_n) begin
        count_div_cfg <= CLK_DIV_INIT;
        count_div_cur <= CLK_DIV_INIT;
    end else begin
        count_div_cfg <= clk_div_i;
        if (count_bit != '0) begin
            count_div_cur <= count_div_cfg;
        end
    end
end

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
            if (count_sample < count_sample_max) begin
                count_sample <= count_sample + 1;
                count_bit <= count_bit;
                shift_out <= shift_out;
            end else begin
                count_sample <= '0;
                count_bit <= 
                    (count_bit < COUNT_BIT_DONE) ? count_bit + 1 :
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
