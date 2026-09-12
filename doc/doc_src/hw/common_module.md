# Common modules
## FIFO
### Parameters
- `DATA_WIDTH`: default 8
- `FIFO_DEPTH`: Depth of FIFO
- `POINTER_WIDTH = clog2(FIFO_DEPTH)`
### IOs
- System: `CLK_sys`, `RST_n`
- Input side: `[DATA_WIDTH-1:0] data_i`, `in_valid_i`, `in_ready_o`
- Output side: `[DATA_WIDTH-1:0] data_o`, `out_valid_o`, `out_ready_i`
- FIFO status:
    - `[POINTER_WIDTH-1:0] count_o`,
    - `full_o`, `empty_o`, `almost_full_o`, `almost_empty_o`
- FIFO treshold setting:
    - `[POINTER_WIDTH-1:0] almost_full_thres_i`
    - `[POINTER_WIDTH-1:0] almost_full_thres_o`
