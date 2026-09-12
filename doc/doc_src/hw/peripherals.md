# Peripherals
## UART
Supports `8N1` serial.
### Parameters
- `CLK_DIV`: `round(CLK_FREQ/UART_BAUD)`
### IOs
- System: `CLK_sys`, `RST_n`, bus
- UART: `uart_RX`, `uart_TX`
### Memory 
```
Size: 0x40

0x00: DATA (RW), pops fifo
    READ: [8] valid, [7:0] data_rx (0x00 if no data)
    WRITE: [7:0] data_tx
0x04: PEEK (RO)
    READ: [8] valid, [7:0] data_rx (0x00 if no data)
0x08: FIFO_COUNT (RO)
    READ: [31:16] fifo_cnt_tx, [15:0] fifo_cnt_rx
0x0C: FIFO_CONFIG (RW)
    [23:16] tx_almost_empty_thres, [7:0] rx_almost_full_thres

0x10: STATUS (RO)
0x14: EVENT (R/W1C)
0x18: EVENT_MASKED (RO)
0x1C: EVENT_MASK (RW)
    [15] tx_almost_full
    [14] tx_almost_empty
    [13] tx_full
    [12] tx_empty
    [11] rx_almost_full
    [10] rx_almost_empty
    [ 9] rx_full
    [ 8] rx_empty
    [ 7] (resv)
    [ 6] (resv)
    [ 5] (resv)
    [ 4] tx_busy
    [ 3] (resv)
    [ 2] (resv)
    [ 1] rx_overrun
    [ 0] rx_err

0x20: CLK_DIV (RW): applies at next byte
    [12:0] clock_div

0x20 - 0x3C: (reserved)
```
