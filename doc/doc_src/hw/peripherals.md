# Peripherals
## UART
Supports `8N1` serial.
### Parameters
- `CLK_DIV`: `round(CLK_FREQ/UART_BAUD)`
### IOs
- System: `CLK_sys`, `RST_n`,
- UART: `uart_RX`, `uart_TX`
- Bus:
### Sub blocks
- `uart_rx`
    #### Parameters
    - `UART_BAUD` default `'d9600`
    - `CLK_FREQ` default `'d50_000_000`
    #### IOs
    - System: `CLK_sys`, `RST_n`
    - UART: `uart_RX`
    - Internal
        - `recv_o`: 1 on cycle with data received
        - `[7:0] data_o`: received byte, update with `recv_o`
        - `err_o`: set on missing stop bit, cleared by `err_clr_i`
        - `err_clr_i`: 1 to clear `err_o`
