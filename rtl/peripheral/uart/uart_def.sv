package uart_pkg;

function automatic int calc_uart_clk_div (int UART_BAUD, int CLK_FREQ);
    calc_uart_clk_div = (CLK_FREQ + UART_BAUD/2) / UART_BAUD;
endfunction

endpackage
